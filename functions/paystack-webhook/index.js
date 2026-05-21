const crypto = require('node:crypto');

/**
 * Appwrite Function: paystack-webhook
 *
 * Required env vars in Appwrite Function settings:
 * - APPWRITE_ENDPOINT
 * - APPWRITE_PROJECT_ID
 * - APPWRITE_API_KEY
 * - APPWRITE_DATABASE_ID
 * - APPWRITE_BOOKINGS_COLLECTION_ID
 * - PAYSTACK_WEBHOOK_SECRET
 *
 * Optional env vars:
 * - APPWRITE_PAYMENTS_COLLECTION_ID
 * - BOOKING_PAYMENT_REF_FIELD (default: payment_ref)
 * - BOOKING_DEPOSIT_PAID_FIELD (default: deposit_paid)
 * - BOOKING_STATUS_FIELD (default: status)
 * - PAYMENT_REFERENCE_FIELD (default: reference)
 * - PAYMENT_STATUS_FIELD (default: status)
 */
module.exports = async ({ req, res, log, error }) => {
  if (req.method !== 'POST') {
    return res.json({ ok: false, message: 'Method Not Allowed' }, 405);
  }

  const webhookSecret = process.env.PAYSTACK_WEBHOOK_SECRET;
  if (!webhookSecret) {
    error('PAYSTACK_WEBHOOK_SECRET is missing');
    return res.json({ ok: false, message: 'Server misconfiguration' }, 500);
  }

  const signature =
    req.headers['x-paystack-signature'] || req.headers['X-Paystack-Signature'];
  if (!signature) {
    return res.json({ ok: false, message: 'Missing signature' }, 401);
  }

  const rawBody =
    typeof req.bodyText === 'string' && req.bodyText.length > 0
      ? req.bodyText
      : JSON.stringify(req.body || {});

  const expected = crypto
    .createHmac('sha512', webhookSecret)
    .update(rawBody)
    .digest('hex');

  if (!timingSafeHexEqual(signature, expected)) {
    return res.json({ ok: false, message: 'Invalid signature' }, 401);
  }

  let payload;
  try {
    payload = req.body || JSON.parse(rawBody);
  } catch (e) {
    return res.json({ ok: false, message: 'Invalid JSON body' }, 400);
  }

  const event = payload?.event;
  const reference = payload?.data?.reference;

  if (!event || !reference) {
    return res.json({ ok: false, message: 'Missing event/reference' }, 400);
  }

  try {
    if (event === 'charge.success') {
      await handleChargeSuccess(reference, log);
      return res.json({ ok: true, handled: event }, 200);
    }

    if (event === 'refund.processed') {
      await handleRefundProcessed(reference, log);
      return res.json({ ok: true, handled: event }, 200);
    }

    log(`Ignoring unsupported event: ${event}`);
    return res.json({ ok: true, handled: 'ignored', event }, 200);
  } catch (e) {
    error(`Webhook processing failed: ${e.message}`);
    return res.json({ ok: false, message: 'Processing error' }, 500);
  }
};

async function handleChargeSuccess(reference, log) {
  const bookingRefField = process.env.BOOKING_PAYMENT_REF_FIELD || 'payment_ref';
  const bookingDepositField =
    process.env.BOOKING_DEPOSIT_PAID_FIELD || 'deposit_paid';
  const bookingStatusField = process.env.BOOKING_STATUS_FIELD || 'status';

  const paymentRefField = process.env.PAYMENT_REFERENCE_FIELD || 'reference';
  const paymentStatusField = process.env.PAYMENT_STATUS_FIELD || 'status';

  const booking = await findBookingByReference(reference, bookingRefField);
  if (!booking) {
    throw new Error(`Booking not found for payment reference: ${reference}`);
  }

  const currentStatus = String(booking[bookingStatusField] || '').toLowerCase();
  const alreadyPaid = booking[bookingDepositField] === true;

  // Idempotency: do nothing if webhook already applied.
  if (alreadyPaid && currentStatus === 'confirmed') {
    log(`Already processed booking ${booking.$id} for ref ${reference}`);
    return;
  }

  const bookingPatch = {
    [bookingDepositField]: true,
    [bookingStatusField]: 'confirmed',
  };

  await updateDocument(
    process.env.APPWRITE_BOOKINGS_COLLECTION_ID,
    booking.$id,
    bookingPatch,
  );

  if (process.env.APPWRITE_PAYMENTS_COLLECTION_ID) {
    const payment = await findPaymentByReference(reference, paymentRefField);
    if (payment) {
      await updateDocument(process.env.APPWRITE_PAYMENTS_COLLECTION_ID, payment.$id, {
        [paymentStatusField]: 'success',
      });
    }
  }

  log(`Processed charge.success for ref ${reference}, booking ${booking.$id}`);
}

async function handleRefundProcessed(reference, log) {
  const paymentRefField = process.env.PAYMENT_REFERENCE_FIELD || 'reference';
  const paymentStatusField = process.env.PAYMENT_STATUS_FIELD || 'status';

  if (!process.env.APPWRITE_PAYMENTS_COLLECTION_ID) {
    log('APPWRITE_PAYMENTS_COLLECTION_ID not set; skipping payment status update');
    return;
  }

  const payment = await findPaymentByReference(reference, paymentRefField);
  if (!payment) {
    log(`Payment not found for refund reference ${reference}`);
    return;
  }

  const current = String(payment[paymentStatusField] || '').toLowerCase();
  if (current === 'refunded') {
    log(`Already refunded payment ${payment.$id}`);
    return;
  }

  await updateDocument(process.env.APPWRITE_PAYMENTS_COLLECTION_ID, payment.$id, {
    [paymentStatusField]: 'refunded',
  });

  log(`Processed refund.processed for payment ${payment.$id}`);
}

async function findBookingByReference(reference, refField) {
  const rows = await listDocuments(
    process.env.APPWRITE_BOOKINGS_COLLECTION_ID,
    [
      JSON.stringify({ method: 'equal', attribute: refField, values: [reference] }),
      JSON.stringify({ method: 'limit', values: [1] }),
    ],
  );

  return rows[0] || null;
}

async function findPaymentByReference(reference, refField) {
  const rows = await listDocuments(
    process.env.APPWRITE_PAYMENTS_COLLECTION_ID,
    [
      JSON.stringify({ method: 'equal', attribute: refField, values: [reference] }),
      JSON.stringify({ method: 'limit', values: [1] }),
    ],
  );

  return rows[0] || null;
}

async function listDocuments(collectionId, queries) {
  if (!collectionId) {
    return [];
  }

  const response = await appwriteRequest(
    'GET',
    `/databases/${process.env.APPWRITE_DATABASE_ID}/collections/${collectionId}/documents`,
    null,
    queries,
  );

  return response.documents || [];
}

async function updateDocument(collectionId, documentId, data) {
  await appwriteRequest(
    'PATCH',
    `/databases/${process.env.APPWRITE_DATABASE_ID}/collections/${collectionId}/documents/${documentId}`,
    data,
  );
}

async function appwriteRequest(method, path, body = null, queryValues = []) {
  const endpoint = process.env.APPWRITE_ENDPOINT;
  const projectId = process.env.APPWRITE_PROJECT_ID;
  const apiKey = process.env.APPWRITE_API_KEY;
  const databaseId = process.env.APPWRITE_DATABASE_ID;

  if (!endpoint || !projectId || !apiKey || !databaseId) {
    throw new Error(
      'Missing one of APPWRITE_ENDPOINT/APPWRITE_PROJECT_ID/APPWRITE_API_KEY/APPWRITE_DATABASE_ID',
    );
  }

  const qs = new URLSearchParams();
  for (const query of queryValues) {
    qs.append('queries[]', query);
  }

  const base = endpoint.endsWith('/') ? endpoint.slice(0, -1) : endpoint;
  const url = `${base}${path}${qs.toString() ? `?${qs.toString()}` : ''}`;

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

function timingSafeHexEqual(a, b) {
  try {
    const left = Buffer.from(String(a).trim().toLowerCase(), 'hex');
    const right = Buffer.from(String(b).trim().toLowerCase(), 'hex');
    if (left.length !== right.length) {
      return false;
    }
    return crypto.timingSafeEqual(left, right);
  } catch (_) {
    return false;
  }
}
