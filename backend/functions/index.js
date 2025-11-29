import * as functions from 'firebase-functions';
import admin from 'firebase-admin';
admin.initializeApp();
const db = admin.firestore();

export const scanNFC = functions.https.onRequest(async (req, res) => {
  res.json({ ok: true, method: 'NFC' });
});

export const scanQR = functions.https.onRequest(async (req, res) => {
  res.json({ ok: true, method: 'QR' });
});

export const scanBLE = functions.https.onRequest(async (req, res) => {
  res.json({ ok: true, method: 'BLE' });
});

export const scanWIFI = functions.https.onRequest(async (req, res) => {
  res.json({ ok: true, method: 'WIFI' });
});

export const logAttendance = functions.https.onRequest(async (req, res) => {
  try {
    if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });
    const { user_id, method, timestamp, device_id, offline_sync, event_id } = req.body || {};
    if (!user_id || !method) return res.status(400).json({ error: 'user_id and method are required' });
    const doc = {
      user_id,
      method,
      device_id: device_id || null,
      timestamp: timestamp ? admin.firestore.Timestamp.fromDate(new Date(timestamp)) : admin.firestore.FieldValue.serverTimestamp(),
      offline_sync: Boolean(offline_sync),
      event_id: event_id || null,
    };
    const ref = await db.collection('attendance_logs').add(doc);
    res.json({ ok: true, id: ref.id });
  } catch (e) {
    res.status(500).json({ error: String(e) });
  }
});

export const syncOfflineLogs = functions.https.onRequest(async (req, res) => {
  try {
    if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });
    const { items } = req.body || {};
    if (!Array.isArray(items) || items.length === 0) return res.status(400).json({ error: 'items[] required' });
    const batch = db.batch();
    for (const it of items) {
      const ref = db.collection('attendance_logs').doc();
      batch.set(ref, {
        user_id: it.user_id,
        method: it.method,
        device_id: it.device_id || null,
        timestamp: it.timestamp ? admin.firestore.Timestamp.fromDate(new Date(it.timestamp)) : admin.firestore.FieldValue.serverTimestamp(),
        offline_sync: true,
        event_id: it.event_id || null,
      });
    }
    await batch.commit();
    res.json({ ok: true, synced: items.length });
  } catch (e) {
    res.status(500).json({ error: String(e) });
  }
});

export const generateIdentityTokens = functions.https.onRequest(async (req, res) => {
  res.json({ ok: true, tokens: { nfc: '...', qr: '...', ble: '...', wifi: '...' } });
});
