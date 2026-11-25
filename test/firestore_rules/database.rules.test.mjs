import { after, before, beforeEach, test } from 'node:test';
import { readFileSync } from 'node:fs';
import { strict as assert } from 'node:assert';
import { assertFails, assertSucceeds, initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { get, ref, remove, serverTimestamp, set, update } from 'firebase/database';

const namespace = 'demo-agri-smart-guide-default-rtdb';
const databaseURL = `https://${namespace}.firebaseio.com`;
const localEmulatorHost = /^(127\.0\.0\.1|localhost):\d+$/;
const ownerTasks = 'users/alice/tasks';
const taskPath = `${ownerTasks}/task-1`;
const pendingTask = {
  title: 'Zalij vrt',
  description: '',
  dueAt: Date.UTC(2030, 3, 14),
  type: 'general',
  priority: 'normal',
  status: 'pending',
  createdAt: serverTimestamp(),
  updatedAt: serverTimestamp(),
};

let env;
const database = uid => (uid ? env.authenticatedContext(uid) : env.unauthenticatedContext()).database(databaseURL);

before(async () => {
  assert.match(process.env.FIREBASE_DATABASE_EMULATOR_HOST ?? '', localEmulatorHost);
  assert.match(process.env.FIREBASE_AUTH_EMULATOR_HOST ?? '', localEmulatorHost);
  env = await initializeTestEnvironment({
    projectId: 'demo-agri-smart-guide',
    database: { rules: readFileSync(new URL('../../database.rules.json', import.meta.url), 'utf8') },
  });
});
beforeEach(async () => env.clearDatabase());
after(async () => env?.cleanup());

async function authenticate(action, email) {
  const host = process.env.FIREBASE_AUTH_EMULATOR_HOST;
  const response = await fetch(`http://${host}/identitytoolkit.googleapis.com/v1/accounts:${action}?key=demo-key`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password: 'LocalEmulator123!', returnSecureToken: true }),
  });
  assert.equal(response.status, 200);
  return response.json();
}

function requestTask(path, { method = 'GET', token, value } = {}) {
  const url = new URL(`http://${process.env.FIREBASE_DATABASE_EMULATOR_HOST}/${path}.json`);
  url.searchParams.set('ns', namespace);
  if (token) url.searchParams.set('auth', token);
  return fetch(url, {
    method,
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(value),
  });
}

test('owner can list, create, edit, complete, reopen and delete tasks', async () => {
  const db = database('alice');
  const task = ref(db, taskPath);
  await assertSucceeds(set(task, pendingTask));
  const created = (await assertSucceeds(get(ref(db, ownerTasks)))).child('task-1').val();
  assert.equal(created.status, 'pending');
  assert.equal(typeof created.createdAt, 'number');

  await assertSucceeds(update(task, { status: 'completed', completedAt: serverTimestamp(), updatedAt: serverTimestamp() }));
  await assertSucceeds(update(task, { title: 'Zalij rajčice', updatedAt: serverTimestamp() }));
  const completed = (await get(task)).val();
  assert.equal(completed.title, 'Zalij rajčice');
  assert.equal(completed.status, 'completed');
  assert.equal(typeof completed.completedAt, 'number');

  await assertSucceeds(update(task, { status: 'pending', completedAt: null, updatedAt: serverTimestamp() }));
  assert.equal((await get(task)).child('status').val(), 'pending');
  assert.equal((await get(task)).child('completedAt').exists(), false);
  await assertSucceeds(remove(task));
  assert.equal((await get(ref(db, ownerTasks))).exists(), false);
});

test('unauthenticated users and other accounts cannot read or write tasks', async () => {
  const owner = database('alice');
  await assertSucceeds(set(ref(owner, taskPath), pendingTask));
  await assertSucceeds(set(ref(database('bob'), 'users/bob/tasks/task-2'), pendingTask));

  for (const uid of [null, 'bob']) {
    const db = database(uid);
    await assertFails(get(ref(db, ownerTasks)));
    await assertFails(get(ref(db, taskPath)));
    await assertFails(set(ref(db, `${ownerTasks}/task-2`), pendingTask));
    await assertFails(update(ref(db, taskPath), { title: 'Tuđa izmjena' }));
    await assertFails(remove(ref(db, taskPath)));
  }
});

test('parent paths grant no access and partial updates cannot recreate deleted tasks', async () => {
  const db = database('alice');
  await assertSucceeds(set(ref(db, taskPath), pendingTask));
  for (const path of ['/', 'users', 'users/alice']) {
    await assertFails(get(ref(db, path)));
    await assertFails(remove(ref(db, path)));
  }
  await assertFails(update(ref(db), {
    [`${taskPath}/title`]: 'Novi naslov',
    'users/bob/tasks/task-2': pendingTask,
  }));
  await assertFails(update(ref(db, taskPath), { status: 'completed' }));
  await assertFails(update(ref(db, `${ownerTasks}/missing`), { title: 'Novi naslov' }));
});

test('direct REST access is owner-only and a fresh login sees saved edits', async () => {
  const ownerEmail = 'asg25-owner@example.com';
  const owner = await authenticate('signUp', ownerEmail);
  const other = await authenticate('signUp', 'asg25-other@example.com');
  const listPath = `users/${owner.localId}/tasks`;
  const recordPath = `${listPath}/task-1`;

  const created = await requestTask(recordPath, { method: 'PUT', token: owner.idToken, value: pendingTask });
  assert.equal(created.status, 200);
  assert.equal((await created.json()).description, '');

  const changes = {
    title: 'Zalij rajčice',
    dueAt: Date.UTC(2030, 3, 15),
    status: 'completed',
    completedAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  };
  const edited = await requestTask(recordPath, { method: 'PATCH', token: owner.idToken, value: changes });
  assert.equal(edited.status, 200);
  await edited.json();

  for (const token of [other.idToken, undefined]) {
    for (const [path, options] of [
      [listPath, {}],
      [recordPath, {}],
      [recordPath, { method: 'PATCH', value: { title: 'Tuđa izmjena' } }],
      [recordPath, { method: 'DELETE' }],
    ]) {
      const denied = await requestTask(path, { token, ...options });
      assert.ok([401, 403].includes(denied.status), `Expected access denied for ${options.method ?? 'GET'}`);
      assert.match((await denied.json()).error, /permission denied/i);
    }
  }

  const freshLogin = await authenticate('signInWithPassword', ownerEmail);
  assert.equal(freshLogin.localId, owner.localId);
  const response = await requestTask(listPath, { token: freshLogin.idToken });
  assert.equal(response.status, 200);
  const task = (await response.json())['task-1'];
  assert.equal(task.title, changes.title);
  assert.equal(task.dueAt, changes.dueAt);
  assert.equal(task.description, '');
  assert.equal(task.status, 'completed');
  assert.equal(typeof task.completedAt, 'number');
});
