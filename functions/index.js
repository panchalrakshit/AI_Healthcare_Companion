const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { createAdminHandlers } = require('./admin');

initializeApp();
const handlers = createAdminHandlers({
  db: getFirestore(), auth: getAuth(), HttpsError,
  timestamp: () => FieldValue.serverTimestamp(),
});
for (const [name, handler] of Object.entries(handlers)) {
  exports[name] = onCall({ region: 'us-central1', maxInstances: 5 }, handler);
}
