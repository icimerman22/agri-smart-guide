import { after, before, beforeEach, test } from 'node:test';
import { readFileSync } from 'node:fs';
import { strict as assert } from 'node:assert';
import { assertFails, assertSucceeds, initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { get, ref, remove, serverTimestamp, set, update } from 'firebase/database';

const databaseURL = 'https://demo-agri-smart-guide-default-rtdb.firebaseio.com';
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
  assert.match(process.env.FIREBASE_DATABASE_EMULATOR_HOST ?? '', /^(127\.0\.0\.1|localhost):\d+$/);
  env = await initializeTestEnvironment({
    projectId: 'demo-agri-smart-guide',
    database: { rules: readFileSync(new URL('../../database.rules.json', import.meta.url), 'utf8') },
  });
});
beforeEach(async () => env.clearDatabase());
after(async () => env?.cleanup());

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
