const test = require('node:test');
const assert = require('node:assert/strict');
const { createAdminHandlers } = require('../admin');
class HttpsError extends Error { constructor(code, message) { super(message); this.code = code; } }

function harness() {
  const docs = new Map([['users/admin', { role: 'admin', status: 'active' }]]);
  const accounts = new Map([['admin', { uid: 'admin', disabled: false }]]);
  let failBatch = false;
  const ref = (path) => ({
    id: path.split('/')[1], path,
    get: async () => ({ id: path.split('/')[1], ref: ref(path), exists: docs.has(path), data: () => docs.get(path) }),
    update: async data => docs.set(path, { ...docs.get(path), ...data }),
  });
  const db = {
    collection: name => ({ doc: id => ref(`${name}/${id}`), where: (key, op, value) => ({ get: async () => ({
      docs: [...docs.entries()].filter(([path, data]) => path.startsWith(`${name}/`) && data[key] === value)
        .map(([path]) => ({ id: path.split('/')[1], ref: ref(path) })),
    }) }) }),
    batch: () => {
      const writes = [];
      return {
        set: (r, data, opts) => writes.push(() => docs.set(r.path, opts?.merge ? { ...docs.get(r.path), ...data } : data)),
        update: (r, data) => writes.push(() => docs.set(r.path, { ...docs.get(r.path), ...data })),
        delete: r => writes.push(() => docs.delete(r.path)),
        commit: async () => { if (failBatch) { failBatch = false; throw new Error('Injected batch failure'); } writes.forEach(fn => fn()); },
      };
    },
  };
  const auth = {
    getUser: async uid => { if (!accounts.has(uid)) throw Object.assign(new Error('missing'), { code: 'auth/user-not-found' }); return accounts.get(uid); },
    createUser: async fields => { accounts.set('new-user', { ...fields, uid: 'new-user' }); return accounts.get('new-user'); },
    updateUser: async (uid, fields) => { await auth.getUser(uid); accounts.set(uid, { ...accounts.get(uid), ...fields }); },
    deleteUser: async uid => { await auth.getUser(uid); accounts.delete(uid); },
  };
  const handlers = createAdminHandlers({ db, auth, HttpsError, timestamp: () => 'server-time' });
  const call = (name, data, uid = 'admin') => handlers[name]({ data, auth: uid ? { uid } : null });
  const seed = (uid, role) => { docs.set(`users/${uid}`, { uid, role, status: 'active', name: uid, email: `${uid}@example.com` }); accounts.set(uid, { uid, disabled: false }); };
  return { docs, accounts, call, seed, failNextBatch: () => { failBatch = true; } };
}
const doctor = { role: 'doctor', name: 'Doctor One', email: 'doctor@example.com', password: 'TemporaryPass123!', specialization: 'Cardiology' };

test('rejects signed-out, patient, suspended and Auth-disabled admins', async () => {
  const h = harness();
  await assert.rejects(h.call('adminCreateAccount', doctor, null), { code: 'unauthenticated' });
  h.seed('patient', 'patient');
  await assert.rejects(h.call('adminCreateAccount', doctor, 'patient'), { code: 'permission-denied' });
  h.docs.set('users/admin', { role: 'admin', status: 'suspended' });
  await assert.rejects(h.call('adminCreateAccount', doctor), { code: 'permission-denied' });
  h.docs.set('users/admin', { role: 'admin', status: 'active' }); h.accounts.get('admin').disabled = true;
  await assert.rejects(h.call('adminCreateAccount', doctor), { code: 'permission-denied' });
});
test('creates matching doctor Auth/profile/directory without storing the password in Firestore', async () => {
  const h = harness();
  await h.call('adminCreateAccount', doctor);
  assert.equal(h.accounts.get('new-user').disabled, false);
  assert.equal(h.docs.get('users/new-user').uid, 'new-user');
  assert.equal(h.docs.get('doctors/new-user').specialization, 'Cardiology');
  assert.equal(h.docs.get('users/new-user').password, undefined);
});
test('creates patient health profile and refuses creation of admin roles', async () => {
  const h = harness();
  await assert.rejects(h.call('adminCreateAccount', { ...doctor, role: 'admin' }), { code: 'invalid-argument' });
  await h.call('adminCreateAccount', { ...doctor, role: 'patient' });
  assert.equal(h.docs.get('healthProfiles/new-user').uid, 'new-user');
  assert.equal(h.docs.has('doctors/new-user'), false);
});
test('cleans up Auth when initial Firestore creation fails', async () => {
  const h = harness(); h.failNextBatch();
  await assert.rejects(h.call('adminCreateAccount', doctor), { code: 'internal' });
  assert.equal(h.accounts.has('new-user'), false);
  assert.equal(h.docs.has('users/new-user'), false);
});
test('suspension and reactivation synchronize Auth, profile and legacy linked directory', async () => {
  const h = harness(); h.seed('doctor', 'doctor'); h.docs.set('doctors/legacy', { uid: 'doctor' });
  await h.call('adminSetAccountStatus', { uid: 'doctor', doctorId: 'legacy', status: 'suspended' });
  assert.equal(h.accounts.get('doctor').disabled, true);
  assert.equal(h.docs.get('doctors/legacy').status, 'suspended');
  await h.call('adminSetAccountStatus', { uid: 'doctor', status: 'active' });
  assert.equal(h.accounts.get('doctor').disabled, false);
  assert.equal(h.docs.get('users/doctor').status, 'active');
});
test('failed suspension leaves Auth disabled', async () => {
  const h = harness(); h.seed('patient', 'patient'); h.failNextBatch();
  await assert.rejects(h.call('adminSetAccountStatus', { uid: 'patient', status: 'suspended' }), { code: 'internal' });
  assert.equal(h.accounts.get('patient').disabled, true);
  assert.equal(h.docs.get('users/patient').status, 'suspended');
});
test('edits doctor contact and directory metadata in both collections', async () => {
  const h = harness(); h.seed('doctor', 'doctor'); h.docs.set('doctors/legacy', { uid: 'doctor' });
  await h.call('adminUpdateAccount', { ...doctor, uid: 'doctor', doctorId: 'legacy', hospital: 'City Hospital' });
  assert.equal(h.accounts.get('doctor').email, doctor.email);
  assert.equal(h.docs.get('users/doctor').hospital, 'City Hospital');
  assert.equal(h.docs.get('doctors/legacy').name, doctor.name);
});
test('deletes login and directory, retains clinical history, and records a tombstone', async () => {
  const h = harness(); h.seed('doctor', 'doctor'); h.docs.set('doctors/legacy', { uid: 'doctor' });
  h.docs.set('appointments/history', { doctorId: 'legacy' });
  await h.call('adminDeleteAccount', { uid: 'doctor', doctorId: 'legacy' });
  assert.equal(h.accounts.has('doctor'), false); assert.equal(h.docs.has('users/doctor'), false);
  assert.equal(h.docs.has('doctors/legacy'), false); assert.equal(h.docs.has('appointments/history'), true);
  assert.equal(h.docs.has('adminDeletedUsers/doctor'), true);
});
test('failed deletion batch can be retried after Auth removal', async () => {
  const h = harness(); h.seed('patient', 'patient'); h.failNextBatch();
  await assert.rejects(h.call('adminDeleteAccount', { uid: 'patient' }), { code: 'internal' });
  assert.equal(h.docs.get('users/patient').status, 'suspended'); assert.equal(h.accounts.has('patient'), false);
  await h.call('adminDeleteAccount', { uid: 'patient' });
  assert.equal(h.docs.has('users/patient'), false);
});
test('directory-only removal does not delete an unrelated login', async () => {
  const h = harness(); h.seed('patient', 'patient'); h.docs.set('doctors/legacy', { name: 'Legacy Doctor' });
  const result = await h.call('adminDeleteAccount', { doctorId: 'legacy' });
  assert.equal(result.loginRemoved, false); assert.equal(h.accounts.has('patient'), true);
});
test('rejects self-management, admin deletion, path injection and mismatched identities', async () => {
  const h = harness(); h.seed('other-admin', 'admin'); h.seed('doctor', 'doctor'); h.seed('patient', 'patient');
  h.docs.set('doctors/legacy', { uid: 'doctor' });
  for (const data of [{ uid: 'admin' }, { uid: 'other-admin' }, { uid: 'patient', doctorId: 'legacy' }, { uid: '../patient' }]) {
    await assert.rejects(h.call('adminDeleteAccount', data), error => error instanceof HttpsError);
  }
  assert.equal(h.accounts.has('doctor'), true);
});
