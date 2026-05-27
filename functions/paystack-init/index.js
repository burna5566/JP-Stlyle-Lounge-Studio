const crypto = require('node:crypto');

/**
 * Appwrite Function: paystack-init
 *
 * Required env vars:
 * - APPWRITE_ENDPOINT
 * - APPWRITE_PROJECT_ID
 * - APPWRITE_API_KEY
 * - APPWRITE_DATABASE_ID
 * - APPWRITE_BOOKINGS_COLLECTION_ID
 * - PAYSTACK_SECRET_KEY
 *
 * Optional env vars:
 * - APPWRITE_PAYMENTS_COLLECTION_ID
 * - BOOKING_PAYMENT_REF_FIELD (default: payment_ref)
 * - PAYMENT_REFERENCE_FIELD (default: reference)
 * - PAYMENT_STATUS_FIELD (default: status)
 */
module.exports = async ({ req, res, log, error }) => {
  try {
    if (req.method !== 'POST') {
      return res.json(
        { ok: false, message: 'Only POST method is allowed' },
        405,
      );
    }

    // Validate required environment variables
    const paystackSecret = process.env.PAYSTACK_SECRET_KEY;
    const appwriteEndpoint = process.env.APPWRITE_ENDPOINT;
    const appwriteProjectId = process.env.APPWRITE_PROJECT_ID;
    const appwriteApiKey = process.env.APPWRITE_API_KEY;
    const appwriteDatabaseId = process.env.APPWRITE_DATABASE_ID;
    const bookingsCollectionId = process.env.APPWRITE_BOOKINGS_COLLECTION_ID;

    if (
      !paystackSecret ||
      !appwriteEndpoint ||
      !appwriteProjectId ||
      !appwriteApiKey ||
      !appwriteDatabaseId ||
      !bookingsCollectionId
    ) {
      error('Missing required environment variables');
      return res.json(
        { ok: false, message: 'Server misconfiguration: missing env vars' },
        500,
      );
    }

    // Parse request body
    let payload;
    try {
      if (typeof req.body === 'string') {
        payload = JSON.parse(req.body);
      } else if (typeof req.body === 'object') {
        payload = req.body;
      } else if (req.bodyText) {
        payload = JSON.parse(req.bodyText);
      } else {
        payload = {};
      }
    } catch (parseError) {
      return res.json({ ok: false, message: 'Invalid JSON body' }, 400);
    }

    // Extract and validate request parameters
    const bookingId = String(payload.bookingId || '').trim();
    const amount = Number(payload.amount || 0);
    const email = String(payload.email || '').trim();
    const phone = String(payload.phone || '').trim();
    const callbackUrl = String(payload.callbackUrl || '').trim();

    log(
      JSON.stringify({
        stage: 'request.received',
        bookingId,
        hasEmail: Boolean(email),
        amount,
        hasCallbackUrl: Boolean(callbackUrl),
      }),
    );

    if (!bookingId) {
      return res.json(
        { ok: false, message: 'bookingId is required' },
        400,
      );
    }

    if (!email || !email.includes('@')) {
      return res.json(
        { ok: false, message: 'Valid email is required' },
        400,
      );
    }

    if (amount <= 0) {
      return res.json(
        { ok: false, message: 'Amount must be greater than 0' },
        400,
      );
    }

    // Initialize Paystack payment
    const amountKobo = Math.round(amount * 100);
    const reference = makeReference(bookingId);

    const paystackBody = {
      email,
      amount: amountKobo,
      reference,
      metadata: {
        bookingId,
        phone: phone || 'N/A',
      },
    };

    // Do NOT pass deep-link URLs to Paystack as callback_url
    // Paystack redirects are browser-based and cannot handle custom schemes
    // Instead rely on app lifecycle observer to verify payment on resume
    if (callbackUrl && callbackUrl.startsWith('http')) {
      paystackBody.callback_url = callbackUrl;
    }

    log(`Calling Paystack with ref: ${reference}`);

    const paystackResponse = await fetch(
      'https://api.paystack.co/transaction/initialize',
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${paystackSecret}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(paystackBody),
      },
    );

    const paystackJson = await paystackResponse.json();

    if (!paystackResponse.ok || !paystackJson.status) {
      const errorMsg = paystackJson.message || 'Unknown error';
      throw new Error(
        `Paystack API error (${paystackResponse.status}): ${errorMsg}`,
      );
    }

    const data = paystackJson.data || {};

    // Update booking with payment reference
    const bookingRefField =
      process.env.BOOKING_PAYMENT_REF_FIELD || 'payment_ref';

    await updateDocument(bookingsCollectionId, bookingId, {
      [bookingRefField]: data.reference,
    });

    log(
      `Updated booking ${bookingId} with payment ref: ${data.reference}`,
    );

    // Create payment record (optional)
    const paymentsCollectionId =
      process.env.APPWRITE_PAYMENTS_COLLECTION_ID;
    if (paymentsCollectionId && paymentsCollectionId.trim()) {
      try {
        const paymentRefField =
          process.env.PAYMENT_REFERENCE_FIELD || 'reference';
        const paymentStatusField = process.env.PAYMENT_STATUS_FIELD || 'status';

        await createDocument(
          paymentsCollectionId,
          makeDocumentId(),
          {
            bookingId,
            [paymentRefField]: data.reference,
            [paymentStatusField]: 'pending',
            amountGhs: amount,
          },
        );

        log(`Created payment record for booking ${bookingId}`);
      } catch (paymentError) {
        log(
          `Warning: Could not create payment record: ${paymentError.message}`,
        );
        // Don't fail the whole request if payment record creation fails
      }
    }

    log(
      `Successfully initialized Paystack payment for booking ${bookingId}`,
    );

    return res.json(
      {
        ok: true,
        data: {
          authorization_url: data.authorization_url || '',
          access_code: data.access_code || '',
          reference: data.reference || reference,
        },
      },
      200,
    );
  } catch (e) {
    log(
      JSON.stringify({
        stage: 'fatal',
        message: e.message,
      }),
    );
    error(`paystack-init fatal error: ${e.message}`);
    return res.json(
      {
        ok: false,
        message: `Payment initialization failed: ${e.message}`,
      },
      500,
    );
  }
};

async function createDocument(collectionId, documentId, data) {
  return appwriteRequest(
    'POST',
    `/databases/${process.env.APPWRITE_DATABASE_ID}/collections/${collectionId}/documents`,
    {
      documentId,
      data,
    },
  );
}

async function updateDocument(collectionId, documentId, data) {
  return appwriteRequest(
    'PATCH',
    `/databases/${process.env.APPWRITE_DATABASE_ID}/collections/${collectionId}/documents/${documentId}`,
    { data },
  );
}

async function appwriteRequest(method, path, body = null) {
  const endpoint = process.env.APPWRITE_ENDPOINT;
  const projectId = process.env.APPWRITE_PROJECT_ID;
  const apiKey = process.env.APPWRITE_API_KEY;

  const base = endpoint.endsWith('/') ? endpoint.slice(0, -1) : endpoint;
  const url = `${base}${path}`;

  const response = await fetch(url, {
    method,
    headers: {
      'X-Appwrite-Project': projectId,
      'X-Appwrite-Key': apiKey,
      'Content-Type': 'application/json',
    },
    body: body ? JSON.stringify(body) : undefined,
  });

  const text = await response.text();

  if (!response.ok) {
    const bodyPreview = body ? JSON.stringify(body).slice(0, 500) : '';
    throw new Error(
      `Appwrite request failed (${response.status}) on ${method} ${path}. body=${bodyPreview} response=${text}`,
    );
  }

  if (response.status === 204 || !text) {
    return {};
  }

  try {
    return JSON.parse(text);
  } catch {
    return {};
  }
}

function makeReference(bookingId) {
  const timestamp = Date.now();
  const random = crypto.randomBytes(4).toString('hex');
  return `jp_${bookingId.substring(0, 8)}_${timestamp}_${random}`;
}

function makeDocumentId() {
  return `payment_${Date.now()}_${crypto.randomBytes(4).toString('hex')}`;
}
