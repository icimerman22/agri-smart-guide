import { after, before, beforeEach, test } from 'node:test';
import { readFileSync } from 'node:fs';
import { strict as assert } from 'node:assert';
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { Timestamp, GeoPoint, doc, setDoc, getDoc, getDocs, collection, query, where, updateDoc, deleteDoc, writeBatch } from 'firebase/firestore';

const time = Timestamp.fromMillis(1700000000123);
const dates = { createdAt: time, updatedAt: time };
const fixtures = {
  users: { firstName: 'Ana', lastName: 'A', farmName: 'OPG', primaryLocation: {}, unitSystem: 'metric', notificationSettings: {}, ...dates },
  parcels: { ownerId: 'alice', name: 'Polje', areaHa: 2.5, soilType: 'loam', locationName: 'Zagreb', coordinates: new GeoPoint(45.8, 16), activePlantingId: null, ...dates },
  crops: { name: 'Corn', category: 'grain', description: '', sowingMonths: [4, 5], growthDays: 120, waterRequirement: 'medium', rowSpacingCm: 70, plantSpacingCm: 20, optimalPhMin: 6, optimalPhMax: 7 },
  plantings: { ownerId: 'alice', parcelId: 'parcel', cropId: 'crop', plantedAt: time, expectedHarvestAt: time, stage: 'sown', status: 'completed', seasonYear: 2027, ...dates },
  tasks: { ownerId: 'alice', parcelId: 'parcel', title: 'Work', description: '', type: 'watering', dueAt: time, priority: 'normal', status: 'pending', completedAt: null, costCents: null, costCategory: null, ...dates },
  soil_analyses: { ownerId: 'alice', parcelId: 'parcel', sampledAt: time, ph: 6.5, humusPercent: 3, nitrogenPercent: 1, phosphorusMgPer100g: 10, potassiumMgPer100g: 12, moisturePercent: null, createdAt: time },
  vegetation_records: { ownerId: 'alice', parcelId: 'parcel', measuredAt: time, ndvi: 0.7, healthStatus: 'healthy', summary: '', visualizationAssetPath: null, isDemo: true },
  notes: { ownerId: 'alice', parcelId: 'parcel', title: 'Note', content: '', photoPaths: ['photos/a.jpg'], ...dates },
  harvests: { ownerId: 'alice', parcelId: 'parcel', plantingId: 'planting', harvestedAt: time, quantityKg: 100, areaHaAtHarvest: 2.5, note: '', createdAt: time },
  notifications: { ownerId: 'alice', type: 'task', title: 'Reminder', body: '', relatedEntityType: 'tasks', relatedEntityId: 'record', createdAt: time, readAt: null },
  rotation_plans: { ownerId: 'alice', parcelId: 'parcel', seasonYear: 2027, cropId: 'crop', ...dates },
};
const idFor = name => ({ users: 'alice', parcels: 'parcel', crops: 'crop', plantings: 'planting', rotation_plans: 'parcel_2027' }[name] ?? 'record');
let env;
const db = uid => uid ? env.authenticatedContext(uid).firestore() : env.unauthenticatedContext().firestore();
const ref = (database, name) => doc(database, name, idFor(name));

before(async () => {
  // Refuse to connect unless the emulator runner supplied its endpoint.
  assert.match(process.env.FIRESTORE_EMULATOR_HOST ?? '', /^(127\.0\.0\.1|localhost):\d+$/);
  env = await initializeTestEnvironment({
    projectId: 'demo-agri-smart-guide',
    firestore: { rules: readFileSync(new URL('../../firestore.rules', import.meta.url), 'utf8') },
  });
});
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async context => {
    const database = context.firestore();
    for (const [name, data] of Object.entries(fixtures)) await setDoc(ref(database, name), data);
    await setDoc(doc(database, 'parcels', 'bob-parcel'), { ...fixtures.parcels, ownerId: 'bob' });
    await setDoc(doc(database, 'plantings', 'bob-planting'), { ...fixtures.plantings, ownerId: 'bob', parcelId: 'bob-parcel' });
  });
});
after(async () => { await env?.cleanup(); });

for (const [name, data] of Object.entries(fixtures)) {
  test(`${name}: read isolation and default deny`, async () => {
    await assertSucceeds(getDoc(ref(db('alice'), name)));
    await assertFails(getDoc(ref(db(), name)));
    if (name === 'crops') await assertSucceeds(getDoc(ref(db('bob'), name)));
    else {
      await assertFails(getDoc(ref(db('bob'), name)));
      await assertFails(updateDoc(ref(db('bob'), name), data));
      await assertFails(deleteDoc(ref(db('bob'), name)));
      await assertFails(setDoc(ref(db('bob'), name), data));
      await assertFails(getDocs(collection(db('alice'), name)));
      if (name !== 'users') {
        await assertSucceeds(getDocs(query(collection(db('alice'), name), where('ownerId', '==', 'alice'))));
        await assertFails(getDocs(query(collection(db('alice'), name), where('ownerId', '==', 'bob'))));
      }
    }
  });
  test(`${name}: create update delete authorization`, async () => {
    const database = db('alice');
    await assertFails(setDoc(ref(db(), name), data));
    const newId = name === 'rotation_plans' ? 'parcel_2028' : 'new-document';
    const forged = { ...data, ...(name === 'rotation_plans' ? { seasonYear: 2028 } : {}) };
    await assertFails(setDoc(doc(db('bob'), name, newId), forged));
    await assertFails(setDoc(doc(db(), name, newId), forged));
    if (name !== 'users' && name !== 'crops') {
      await assertFails(setDoc(doc(database, name, newId), { ...forged, ownerId: 'bob' }));
    }
    if (name === 'crops') {
      await assertFails(setDoc(ref(database, name), data));
      await assertFails(updateDoc(ref(database, name), { name: 'changed' }));
      await assertFails(deleteDoc(ref(database, name)));
      return;
    }
    await assertSucceeds(updateDoc(ref(database, name), data));
    await assertSucceeds(deleteDoc(ref(database, name)));
    await assertSucceeds(setDoc(ref(database, name), data));
    if (name !== 'users') await assertFails(updateDoc(ref(database, name), { ownerId: 'bob' }));
  });
  if (name !== 'crops') test(`${name}: reject malformed writes`, async () => {
    const target = ref(db('alice'), name);
    await assertFails(updateDoc(target, { unexpected: true }));
    const required = Object.keys(data).filter(key => data[key] !== null
      && !(key === 'parcelId' && ['tasks', 'notes'].includes(name)));
    for (const key of required) {
      const incomplete = { ...data };
      delete incomplete[key];
      await assertFails(setDoc(target, incomplete));
      await assertFails(setDoc(target, { ...data, [key]: null }));
      await assertFails(setDoc(target, { ...data, [key]: Array.isArray(data[key]) ? false : ['wrong-type'] }));
    }
  });
  if ('parcelId' in data) test(`${name}: reject missing and foreign parcel`, async () => {
    for (const parcelId of ['missing', 'bob-parcel']) {
      await assertFails(updateDoc(ref(db('alice'), name), { parcelId }));
      await assertFails(setDoc(doc(db('alice'), name, name === 'rotation_plans' ? `${parcelId}_2027` : 'new'), { ...data, parcelId }));
    }
  });
}

test('optional fields accept null or absence and reject malformed values', async () => {
  const fields = { parcels: ['activePlantingId'], tasks: ['parcelId', 'completedAt', 'costCents', 'costCategory'], notes: ['parcelId'], soil_analyses: ['moisturePercent'], vegetation_records: ['visualizationAssetPath'], notifications: ['readAt'] };
  for (const [name, keys] of Object.entries(fields)) for (const key of keys) {
    const data = { ...fixtures[name] };
    delete data[key];
    await assertSucceeds(setDoc(ref(db('alice'), name), data));
    await assertSucceeds(updateDoc(ref(db('alice'), name), { [key]: null }));
    await assertFails(updateDoc(ref(db('alice'), name), { [key]: [] }));
  }
});
test('tasks and notes can be independent', async () => {
  for (const name of ['tasks', 'notes']) await assertSucceeds(updateDoc(ref(db('alice'), name), { parcelId: null }));
});
test('crop and planting relationships and rotation ID', async () => {
  for (const name of ['plantings', 'rotation_plans']) await assertFails(updateDoc(ref(db('alice'), name), { cropId: 'missing' }));
  for (const plantingId of ['missing', 'bob-planting']) await assertFails(updateDoc(ref(db('alice'), 'harvests'), { plantingId }));
  await env.withSecurityRulesDisabled(c => setDoc(doc(c.firestore(), 'plantings', 'other'), { ...fixtures.plantings, parcelId: 'bob-parcel' }));
  await assertFails(updateDoc(ref(db('alice'), 'harvests'), { plantingId: 'other' }));
  await assertFails(setDoc(doc(db('alice'), 'rotation_plans', 'random'), fixtures.rotation_plans));
  await assertFails(updateDoc(ref(db('alice'), 'rotation_plans'), { seasonYear: 2028 }));
});
test('notification references require allowed existing owned targets', async () => {
  const target = ref(db('alice'), 'notifications');
  for (const [relatedEntityType, relatedEntityId] of [['unknown', 'record'], ['tasks', 'missing'], ['parcels', 'bob-parcel'], ['users', 'bob']]) {
    await assertFails(updateDoc(target, { relatedEntityType, relatedEntityId }));
  }
  for (const name of Object.keys(fixtures).filter(n => n !== 'notifications')) {
    await assertSucceeds(updateDoc(target, { relatedEntityType: name, relatedEntityId: idFor(name) }));
  }
});
test('notification history can be marked read after the related task is deleted', async () => {
  const database = db('alice');
  await assertSucceeds(deleteDoc(ref(database, 'tasks')));
  const target = ref(database, 'notifications');
  await assertSucceeds(getDoc(target));
  await assertSucceeds(updateDoc(target, { readAt: time }));
  await assertSucceeds(updateDoc(target, { readAt: null }));
  await assertFails(updateDoc(ref(db('bob'), 'notifications'), { readAt: time }));
  await assertFails(updateDoc(target, { readAt: 'invalid' }));
  await assertFails(updateDoc(target, { readAt: time, relatedEntityId: 'missing' }));
  await assertFails(updateDoc(target, { readAt: time, ownerId: 'bob' }));
});
test('active cycle starts and finishes atomically; duplicate and dangling pointers fail', async () => {
  const database = db('alice');
  const parcel = ref(database, 'parcels');
  const first = doc(database, 'plantings', 'first');
  await assertFails(setDoc(first, { ...fixtures.plantings, status: 'active' }));
  await assertFails(updateDoc(parcel, { activePlantingId: 'missing' }));
  let batch = writeBatch(database);
  batch.set(first, { ...fixtures.plantings, status: 'active' });
  batch.update(parcel, { activePlantingId: 'first' });
  await assertSucceeds(batch.commit());
  await assertFails(updateDoc(parcel, { activePlantingId: null }));
  await assertFails(updateDoc(first, { status: 'completed' }));
  await assertFails(deleteDoc(first));
  await assertFails(updateDoc(first, { status: 'unknown' }));
  const second = doc(database, 'plantings', 'second');
  batch = writeBatch(database);
  batch.set(second, { ...fixtures.plantings, status: 'active' });
  batch.update(parcel, { activePlantingId: 'second' });
  await assertFails(batch.commit());
  batch = writeBatch(database);
  batch.set(second, { ...fixtures.plantings, status: 'active' });
  batch.update(first, { status: 'completed' });
  batch.update(parcel, { activePlantingId: 'second' });
  await assertSucceeds(batch.commit());
  batch = writeBatch(database);
  batch.update(second, { status: 'completed' });
  batch.update(parcel, { activePlantingId: null });
  await assertSucceeds(batch.commit());
});
test('foreign and mismatched active planting pointers fail', async () => {
  await assertFails(updateDoc(ref(db('alice'), 'parcels'), { activePlantingId: 'bob-planting' }));
  await assertFails(updateDoc(ref(db('alice'), 'parcels'), { activePlantingId: 'planting' }));
});
test('owner can clean up children after parent deletion', async () => {
  await assertSucceeds(deleteDoc(ref(db('alice'), 'parcels')));
  for (const name of ['plantings', 'tasks', 'notes', 'harvests', 'soil_analyses', 'vegetation_records', 'rotation_plans']) {
    await assertSucceeds(deleteDoc(ref(db('alice'), name)));
  }
});
test('unknown collections and nested documents deny every access', async () => {
  for (const path of ['unknown/id', 'parcels/parcel/notes/id']) {
    const target = doc(db('alice'), path);
    await assertFails(getDoc(target));
    await assertFails(setDoc(target, { ownerId: 'alice' }));
    await assertFails(deleteDoc(target));
  }
});
