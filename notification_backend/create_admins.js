const admin = require('firebase-admin');
const path = require('path');
require('dotenv').config();

const serviceAccount = require(path.resolve('./serviceAccountKey.json'));
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });

const db = admin.firestore();

const admins = [
  { name: 'Admin One',   username: 'admin1', email: 'admin1@tiu.edu.iq', password: 'Admin@1234' },
  { name: 'Admin Two',   username: 'admin2', email: 'admin2@tiu.edu.iq', password: 'Admin@5678' },
  { name: 'Admin Three', username: 'admin3', email: 'admin3@tiu.edu.iq', password: 'Admin@9012' },
  { name: 'Admin Four',  username: 'admin4', email: 'admin4@tiu.edu.iq', password: 'Admin@3456' },
  { name: 'Admin Five',  username: 'admin5', email: 'admin5@tiu.edu.iq', password: 'Admin@7890' },
];

async function createAdmins() {
  console.log('Creating admin accounts...\n');

  for (const a of admins) {
    try {
      // Create in Firebase Auth
      const userRecord = await admin.auth().createUser({
        email: a.email,
        password: a.password,
        displayName: a.name,
      });

      // Create Firestore profile with admin role
      await db.collection('users').doc(userRecord.uid).set({
        email: a.email,
        name: a.name,
        username: a.username,
        role: 'admin',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`✅ ${a.name}`);
      console.log(`   Email:    ${a.email}`);
      console.log(`   Password: ${a.password}\n`);

    } catch (e) {
      if (e.code === 'auth/email-already-exists') {
        console.log(`⚠️  ${a.email} already exists — skipped\n`);
      } else {
        console.error(`❌ Failed to create ${a.email}: ${e.message}\n`);
      }
    }
  }

  console.log('Done.');
  process.exit(0);
}

createAdmins();
