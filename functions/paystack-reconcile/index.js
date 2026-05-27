const crypto = require('node:crypto');

/**
 * Appwrite Function: paystack-reconcile
 *
 * Admin-only endpoint used to reconcile stale bookings where payment_ref exists
 * but deposit_paid is still null/false.
 *
 * Required env vars:
 * - APPWRITE_ENDPOINT
 * - APPWRITE_PROJECT_ID
 * - APPWRITE_API_KEY
 * - APPWRITE_DATABASE_ID
 * - APPWRITE_BOOKINGS_COLLECTION_ID
 * - PAYSTACK_SECRET_KEY
 * - RECONCILE_ADMIN_TOKEN
 *
 * Optional env vars:
 * - BOOKING_PAYMENT_REF_FIELD (default: payment_ref)
 * - BOOKING_DEPOSIT_PAID_FIELD (default: deposit_paid)
 * - BOOKING_STATUS_FIELD (default: status)
 */
module.exports = async ({ req, res, log, error }) => {
  if (req.method !== 'POST') {
    return res.json({ ok: false, message: 'Method Not Allowed' }, 405);
  }

  const expectedToken = process.env.RECONCILE_ADMIN_TOKEN;
  if (!expectedToken) {
    error('[reconcile] RECONCILE_ADMIN_TOKEN missing');
    return res.json({ ok: false, message: 'Server misconfiguration' }, 500);
  }

  const suppliedToken =
    req.headers['x-reconcile-token'] ||
    req.headers['X-Reconcile-Token'] ||
    req.headers.authorization ||
    req.headers.Authorization;

  if (!isTokenValid(suppliedToken, expectedToken)) {
    return res.json({ ok: false, message: 'Unauthorized' }, 401);
  }

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
  } catch (_) {
    return res.json({ ok: false, message: 'Invalid JSON body' }, 400);
  }

  const reference = String(payload?.reference || '').trim();
  const bookingId = String(payload?.bookingId || '').trim();
  const force = payload?.force === true;

  if (!reference && !bookingId) {
    return res.json(
      {
        ok: false,
        message: 'Provide reference or bookingId in request body.',
      },
      400,
    );
  }

  try {
    const result = await reconcileOne({ reference, bookingId, force, log });
    return res.json({ ok: true, result }, 200);
  } catch (e) {
    error(`[reconcile] Failed: ${e.message}`);
    return res.json({ ok: false, message: e.message }, 500);
  }
};

async function reconcileOne({ reference, bookingId, force, log }) {
  const bookingRefField = process.env.BOOKING_PAYMENT_REF_FIELD || 'payment_ref';
  const bookingDepositField =
    process.env.BOOKING_DEPOSIT_PAID_FIELD || 'deposit_paid';
  const bookingStatusField = process.env.BOOKING_STATUS_FIELD || 'status';

  let booking = null;

  if (bookingId) {
    booking = await getDocument(process.env.APPWRITE_BOOKINGS_COLLECTION_ID, bookingId);
  } else {
    booking = await findBookingByReference(reference, bookingRefField);
  }

  if (!booking) {
    throw new Error('Booking not found for reconciliation target.');
  }

  const effectiveReference = String(
    reference || booking[bookingRefField] || '',
  ).trim();

  if (!effectiveReference) {
    throw new Error('Target booking has no payment reference.');
  }

  const verify = await verifyPaystackTransaction(
    effectiveReference,
    process.env.PAYSTACK_SECRET_KEY,
  );

  if (!verify.ok) {
    throw new Error(`Paystack verification failed: ${verify.message}`);
  }

  if (!force) {
    const currentStatus = String(booking[bookingStatusField] || '').toLowerCase();
    const alreadyPaid = booking[bookingDepositField] === true;
    if (alreadyPaid && currentStatus === 'confirmed') {
      return {
        bookingId: booking.$id,
        reference: effectiveReference,
        action: 'noop',
        reason: 'already_confirmed',
      };
    }
  }

  const patch = {
    [bookingDepositField]: true,
    [bookingStatusField]: 'confirmed',
  };

  await updateDocument(process.env.APPWRITE_BOOKINGS_COLLECTION_ID, booking.$id, patch);

  log(`[reconcile] Updated booking ${booking.$id} for reference ${effectiveReference}`);

  return {
    bookingId: booking.$id,
    reference: effectiveReference,
    action: 'updated',
    paystackStatus: verify.status,
    paidAt: verify.paidAt,
  };
}

async function verifyPaystackTransaction(reference, secretKey) {
  if (!secretKey) {
    return { ok: false, message: 'PAYSTACK_SECRET_KEY missing' };
  }

  const url = `https://api.paystack.co/transaction/verify/${encodeURIComponent(reference)}`;
  const response = await fetch(url, {
    method: 'GET',
    headers: { Authorization: `Bearer ${secretKey}` },
  });

  if (!response.ok) {
    return { ok: false, message: `HTTP ${response.status}` };
  }

  const payload = await response.json();
  const status = String(payload?.data?.status || '').toLowerCase();
  if (payload?.status !== true || status !== 'success') {
    return {
      ok: false,
      message: `transaction status is ${status || 'unknown'}`,
    };
  }

  return {
    ok: true,
    status,
    paidAt: payload?.data?.paid_at || null,
  };
}

async function findBookingByReference(reference, refField) {
  const rows = await listDocuments(process.env.APPWRITE_BOOKINGS_COLLECTION_ID, [
    JSON.stringify({ method: 'equal', attribute: refField, values: [reference] }),
    JSON.stringify({ method: 'limit', values: [1] }),
  ]);

  return rows[0] || null;
}

async function getDocument(collectionId, documentId) {
  return appwriteRequest(
    'GET',
    `/databases/${process.env.APPWRITE_DATABASE_ID}/collections/${collectionId}/documents/${documentId}`,
  );
}

async function listDocuments(collectionId, queries) {
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

function isTokenValid(supplied, expected) {
  const input = normalizeToken(supplied);
  const target = normalizeToken(expected);

  if (!input || !target) {
    return false;
  }

  try {
    const a = Buffer.from(input);
    const b = Buffer.from(target);
    if (a.length !== b.length) {
      return false;
    }
    return crypto.timingSafeEqual(a, b);
  } catch (_) {
    return false;
  }
}

function normalizeToken(raw) {
  const text = String(raw || '').trim();
  if (!text) {
    return '';
  }

  if (text.toLowerCase().startsWith('bearer ')) {
    return text.substring(7).trim();
  }

  return text;
}
