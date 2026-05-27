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
 * - PAYSTACK_SECRET_KEY    (used for HMAC and direct transaction verification)
 * - PAYSTACK_WEBHOOK_SECRET (same value as PAYSTACK_SECRET_KEY for Paystack)
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
  // ── Diagnostics: log every incoming call ──────────────────────────────────
  log(`[webhook] method=${req.method} path=${req.path || '/'}`);
  log(`[webhook] headers present: ${Object.keys(req.headers || {}).join(', ')}`);
  log(`[webhook] bodyText length: ${typeof req.bodyText === 'string' ? req.bodyText.length : 'N/A (not a string)'}`);

  if (req.method !== 'POST') {
    return res.json({ ok: false, message: 'Method Not Allowed' }, 405);
  }

  // Accept either env var name (PAYSTACK_WEBHOOK_SECRET or PAYSTACK_SECRET_KEY)
  const webhookSecret =
    process.env.PAYSTACK_WEBHOOK_SECRET || process.env.PAYSTACK_SECRET_KEY;
  if (!webhookSecret) {
    error('[webhook] Neither PAYSTACK_WEBHOOK_SECRET nor PAYSTACK_SECRET_KEY is set');
    return res.json({ ok: false, message: 'Server misconfiguration' }, 500);
  }

  const signature =
    req.headers['x-paystack-signature'] || req.headers['X-Paystack-Signature'];

  // ── Step 1: Try HMAC verification ────────────────────────────────────────
  let hmacVerified = false;
  if (signature) {
    // Prefer bodyText (exact raw bytes) over JSON.stringify which may differ in
    // key ordering / whitespace from what Paystack originally signed.
    const usingBodyText =
      typeof req.bodyText === 'string' && req.bodyText.length > 0;
    const rawBody = usingBodyText
      ? req.bodyText
      : JSON.stringify(req.body || {});

    log(`[webhook] HMAC: using ${usingBodyText ? 'req.bodyText' : 'JSON.stringify(req.body)'}, length=${rawBody.length}`);

    const expected = crypto
      .createHmac('sha512', webhookSecret)
      .update(rawBody)
      .digest('hex');

    hmacVerified = timingSafeHexEqual(signature, expected);
    log(`[webhook] HMAC verified: ${hmacVerified}`);
    if (!hmacVerified) {
      log(`[webhook] HMAC sig prefix: ${String(signature).slice(0, 16)}... expected prefix: ${expected.slice(0, 16)}...`);
    }
  } else {
    log('[webhook] No x-paystack-signature header present');
  }

  // ── Parse payload ─────────────────────────────────────────────────────────
  let payload;
  try {
    payload =
      req.body && typeof req.body === 'object'
        ? req.body
        : JSON.parse(
            typeof req.bodyText === 'string' && req.bodyText.length > 0
              ? req.bodyText
              : '{}',
          );
  } catch (e) {
    return res.json({ ok: false, message: 'Invalid JSON body' }, 400);
  }

  const event = payload?.event;
  const reference = payload?.data?.reference;
  log(`[webhook] event=${event}, reference=${reference}`);

  if (!event || !reference) {
    return res.json({ ok: false, message: 'Missing event/reference' }, 400);
  }

  // ── Step 2: If HMAC failed, fall back to direct Paystack verification ─────
  // This handles the case where req.bodyText is unavailable and JSON.stringify
  // produces different bytes than what Paystack signed.
  if (!hmacVerified) {
    if (event !== 'charge.success') {
      // We only support direct fallback for charge.success (we verify the txn).
      // Other events get rejected without HMAC.
      error(`[webhook] HMAC failed and event ${event} cannot be directly verified`);
      return res.json({ ok: false, message: 'Invalid signature' }, 401);
    }

    log(`[webhook] HMAC failed — attempting direct Paystack transaction verification for ref ${reference}`);
    const directOk = await verifyPaystackTransaction(reference, webhookSecret, log);
    if (!directOk) {
      error(`[webhook] Both HMAC and direct transaction verification failed for ref ${reference}`);
      return res.json({ ok: false, message: 'Verification failed' }, 401);
    }
    log(`[webhook] Direct Paystack verification PASSED for ref ${reference}`);
  }

  // ── Step 3: Handle the event ──────────────────────────────────────────────
  try {
    if (event === 'charge.success') {
      await handleChargeSuccess(reference, log);
      return res.json({ ok: true, handled: event }, 200);
    }

    if (event === 'refund.processed') {
      await handleRefundProcessed(reference, log);
      return res.json({ ok: true, handled: event }, 200);
    }

    log(`[webhook] Ignoring unsupported event: ${event}`);
    return res.json({ ok: true, handled: 'ignored', event }, 200);
  } catch (e) {
    error(`[webhook] Processing failed: ${e.message}`);
    return res.json({ ok: false, message: 'Processing error' }, 500);
  }
};

/**
 * Verify a Paystack transaction directly via GET /transaction/verify/{reference}.
 * Returns true only if status === 'success'.
 */
async function verifyPaystackTransaction(reference, secretKey, log) {
  try {
    const url = `https://api.paystack.co/transaction/verify/${encodeURIComponent(reference)}`;
    const resp = await fetch(url, {
      method: 'GET',
      headers: { Authorization: `Bearer ${secretKey}` },
    });
    const json = await resp.json();
    log(`[webhook] Paystack verify response: status=${json?.data?.status}, amount=${json?.data?.amount}`);
    return json?.status === true && json?.data?.status === 'success';
  } catch (e) {
    log(`[webhook] Paystack verify fetch error: ${e.message}`);
    return false;
  }
}

async function handleChargeSuccess(reference, log) {
  const bookingRefField = process.env.BOOKING_PAYMENT_REF_FIELD || 'payment_ref';
  const bookingDepositField =
    process.env.BOOKING_DEPOSIT_PAID_FIELD || 'deposit_paid';
  const bookingStatusField = process.env.BOOKING_STATUS_FIELD || 'status';

  const paymentRefField = process.env.PAYMENT_REFERENCE_FIELD || 'reference';
  const paymentStatusField = process.env.PAYMENT_STATUS_FIELD || 'status';

  log(`[handleChargeSuccess] Looking up booking by ${bookingRefField}=${reference}`);
  log(`[handleChargeSuccess] DB=${process.env.APPWRITE_DATABASE_ID}, collection=${process.env.APPWRITE_BOOKINGS_COLLECTION_ID}`);

  const booking = await findBookingByReference(reference, bookingRefField);
  log(`[handleChargeSuccess] findBookingByReference result: ${booking ? booking.$id : 'null (NOT FOUND)'}`);

  if (!booking) {
    throw new Error(`Booking not found for payment reference: ${reference}`);
  }

  const currentStatus = String(booking[bookingStatusField] || '').toLowerCase();
  const alreadyPaid = booking[bookingDepositField] === true;
  log(`[handleChargeSuccess] booking ${booking.$id}: deposit_paid=${booking[bookingDepositField]}, status=${currentStatus}`);

  // Idempotency: do nothing if webhook already applied.
  if (alreadyPaid && currentStatus === 'confirmed') {
    log(`[handleChargeSuccess] Already processed booking ${booking.$id} for ref ${reference}`);
    return;
  }

  const bookingPatch = {
    [bookingDepositField]: true,
    [bookingStatusField]: 'confirmed',
  };
  log(`[handleChargeSuccess] Patching booking ${booking.$id} with ${JSON.stringify(bookingPatch)}`);

  await updateDocument(
    process.env.APPWRITE_BOOKINGS_COLLECTION_ID,
    booking.$id,
    bookingPatch,
  );
  log(`[handleChargeSuccess] PATCH complete for booking ${booking.$id}`);

  if (process.env.APPWRITE_PAYMENTS_COLLECTION_ID) {
    const payment = await findPaymentByReference(reference, paymentRefField);
    if (payment) {
      await updateDocument(process.env.APPWRITE_PAYMENTS_COLLECTION_ID, payment.$id, {
        [paymentStatusField]: 'success',
      });
    }
  }

  log(`[handleChargeSuccess] Done — ref ${reference}, booking ${booking.$id}`);
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

  const dbId = process.env.APPWRITE_DATABASE_ID;
  const response = await appwriteRequest(
    'GET',
    `/databases/${dbId}/collections/${collectionId}/documents`,
    null,
    queries,
  );

  const docs = response.documents || [];
  // log total for debugging — note: log is not in scope here, errors surface via throw
  return docs;
}

async function updateDocument(collectionId, documentId, data) {
  await appwriteRequest(
    'PATCH',
    `/databases/${process.env.APPWRITE_DATABASE_ID}/collections/${collectionId}/documents/${documentId}`,
    { data },
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
