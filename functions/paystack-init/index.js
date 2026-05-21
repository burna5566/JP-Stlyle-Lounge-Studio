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
  if (req.method !== 'POST') {
    return res.json({ ok: false, message: 'Method Not Allowed' }, 405);
  }

  const paystackSecret = process.env.PAYSTACK_SECRET_KEY;
  if (!paystackSecret) {
    error('PAYSTACK_SECRET_KEY is missing');
    return res.json({ ok: false, message: 'Server misconfiguration' }, 500);
  }

  let payload;
  try {
    payload = req.body || JSON.parse(req.bodyText || '{}');
  } catch (_) {
    return res.json({ ok: false, message: 'Invalid JSON body' }, 400);
  }

  const bookingId = String(payload.bookingId || '').trim();
  const amount = Number(payload.amount || 0);
  const email = String(payload.email || '').trim();
  const phone = String(payload.phone || '').trim();
  const callbackUrl = String(payload.callbackUrl || '').trim();

  if (!bookingId || !email || amount <= 0) {
    return res.json(
      { ok: false, message: 'bookingId, email, and positive amount are required' },
      400,
    );
  }

  try {
    const amountKobo = Math.round(amount * 100);
    const reference = makeReference(bookingId);

    const paystackBody = {
      email,
      amount: amountKobo,
      reference,
      metadata: {
        bookingId,
        phone,
      },
    };

    if (callbackUrl) {
      paystackBody.callback_url = callbackUrl;
    }

    const paystackResponse = await fetch('https://api.paystack.co/transaction/initialize', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${paystackSecret}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(paystackBody),
    });

    const paystackJson = await paystackResponse.json();
    if (!paystackResponse.ok || !paystackJson.status) {
      throw new Error(
        `Paystack initialize failed: ${paystackResponse.status} ${JSON.stringify(paystackJson)}`,
      );
    }

    const data = paystackJson.data || {};
    const bookingRefField = process.env.BOOKING_PAYMENT_REF_FIELD || 'payment_ref';

    await updateDocument(
      process.env.APPWRITE_BOOKINGS_COLLECTION_ID,
      bookingId,
      {
        [bookingRefField]: data.reference,
      },
    );

    const paymentsCollectionId = process.env.APPWRITE_PAYMENTS_COLLECTION_ID;
    if (paymentsCollectionId) {
      const paymentRefField = process.env.PAYMENT_REFERENCE_FIELD || 'reference';
      const paymentStatusField = process.env.PAYMENT_STATUS_FIELD || 'status';

      await createDocument(paymentsCollectionId, ID.unique(), {
        bookingId,
        [paymentRefField]: data.reference,
        [paymentStatusField]: 'pending',
        amountGhs: amount,
      });
    }

    log(`Initialized Paystack payment for booking ${bookingId}, ref ${data.reference}`);

    return res.json(
      {
        ok: true,
        data: {
          authorization_url: data.authorization_url,
          access_code: data.access_code,
          reference: data.reference,
        },
      },
      200,
    );
  } catch (e) {
    error(`paystack-init failed: ${e.message}`);
    return res.json({ ok: false, message: 'Payment initialization failed' }, 500);
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
    data,
  );
}

async function appwriteRequest(method, path, body = null) {
  const endpoint = process.env.APPWRITE_ENDPOINT;
  const projectId = process.env.APPWRITE_PROJECT_ID;
  const apiKey = process.env.APPWRITE_API_KEY;
  const databaseId = process.env.APPWRITE_DATABASE_ID;

  if (!endpoint || !projectId || !apiKey || !databaseId) {
    throw new Error(
      'Missing one of APPWRITE_ENDPOINT/APPWRITE_PROJECT_ID/APPWRITE_API_KEY/APPWRITE_DATABASE_ID',
    );
  }

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

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`Appwrite request failed (${response.status}): ${text}`);
  }

  if (response.status === 204) {
    return {};
  }

  return response.json();
}

function makeReference(bookingId) {
  const random = crypto.randomBytes(4).toString('hex');
  return `jp_${bookingId}_${Date.now()}_${random}`;
}

const ID = {
  unique() {
    return 'unique()';
  },
};
