const admin = require('firebase-admin');
const path  = require('path');
const fs    = require('fs');

if (!admin.apps.length) {
  const serviceAccountPath = path.resolve(
    process.env.FIREBASE_SERVICE_ACCOUNT || './serviceAccountKey.json'
  );

  if (!fs.existsSync(serviceAccountPath)) {
    console.error('\n❌  serviceAccountKey.json TIDAK DITEMUKAN!');
    console.error('');
    console.error('Cara mendapatkannya:');
    console.error('  1. Buka https://console.firebase.google.com');
    console.error('  2. Pilih project "ehmti-1"');
    console.error('  3. Klik ikon ⚙️  (Project Settings) di sidebar kiri');
    console.error('  4. Buka tab "Service accounts"');
    console.error('  5. Klik tombol "Generate new private key" → Download');
    console.error(`  6. Rename file-nya menjadi "serviceAccountKey.json"`);
    console.error(`  7. Taruh di folder: ${path.dirname(serviceAccountPath)}`);
    console.error('');
    process.exit(1);
  }

  admin.initializeApp({
    credential: admin.credential.cert(require(serviceAccountPath)),
    projectId: process.env.FIREBASE_PROJECT_ID || 'ehmti-1',
  });
}

const db = admin.firestore();

// ── Koleksi (mirror dari firebase_service.dart) ───────────────────────────────
const collections = {
  users:       db.collection('users'),
  admins:      db.collection('loginAdmin'),
  events:      db.collection('events'),
  pendaftaran: db.collection('pendaftaran_event'),
};

module.exports = { admin, db, collections };
