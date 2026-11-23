// Upisuje kulture iz crops.json u Firestore kolekciju `crops`.

import { readFileSync } from 'node:fs';
import { initializeApp, applicationDefault } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

const projectId = process.env.GCLOUD_PROJECT ?? 'agri-smart-guide';
const usingEmulator = Boolean(process.env.FIRESTORE_EMULATOR_HOST);

initializeApp(
  usingEmulator
    ? { projectId }
    : { projectId, credential: applicationDefault() },
);

const { crops } = JSON.parse(
  readFileSync(new URL('./crops.json', import.meta.url), 'utf8'),
);

const db = getFirestore();
const batch = db.batch();
for (const [id, data] of Object.entries(crops)) {
  batch.set(db.collection('crops').doc(id), data);
}
await batch.commit();

console.log(
  `Upisano ${Object.keys(crops).length} kultura u '${projectId}' ` +
    `(${usingEmulator ? 'emulator' : 'pravi Firestore'}).`,
);
