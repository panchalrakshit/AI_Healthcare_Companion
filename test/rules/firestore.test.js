const { test, before, after, beforeEach } = require('node:test');
const { readFileSync } = require('node:fs');
const { initializeTestEnvironment, assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');
const { doc, setDoc, updateDoc, deleteDoc, getDoc, getDocs, collection, query, where, writeBatch, Timestamp } = require('firebase/firestore');
let env;
before(async () => {
  env = await initializeTestEnvironment({ projectId: 'demo-health-admin', firestore: { rules: readFileSync('firestore.rules', 'utf8') } });
});
after(async () => { if (env) await env.cleanup(); });
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async context => {
    const db = context.firestore();
    for (const [uid, role, status] of [['admin', 'admin', 'active'], ['patient', 'patient', 'active'], ['other', 'patient', 'active'], ['doctor', 'doctor', 'active'], ['suspended', 'patient', 'suspended']]) {
      await setDoc(doc(db, 'users', uid), { uid, role, status, email: `${uid}@example.com`, name: uid });
    }
    await setDoc(doc(db, 'doctors', 'legacy-doctor'), { uid: 'doctor', name: 'Doctor', status: 'active' });
    await setDoc(doc(db, 'appointments', 'one'), { patientId: 'patient', doctorId: 'legacy-doctor', status: 'pending' });
    await setDoc(doc(db, 'healthRecords', 'private'), { patientId: 'other' });
    await setDoc(doc(db, 'healthProfiles', 'other'), { uid: 'other' });
    await setDoc(doc(db, 'adminDeletedUsers', 'deleted'), { deletedBy: 'admin' });
  });
});
const user = uid => env.authenticatedContext(uid, { email: `${uid}@example.com` }).firestore();
test('active admin can query all users and appointments and manage doctors', async () => {
  const db = user('admin');
  await assertSucceeds(getDocs(collection(db, 'users')));
  await assertSucceeds(getDocs(collection(db, 'appointments')));
  await assertSucceeds(setDoc(doc(db, 'doctors', 'new'), { name: 'New Doctor' }));
  await assertSucceeds(updateDoc(doc(db, 'users', 'patient'), { status: 'suspended' }));
  await assertSucceeds(deleteDoc(doc(db, 'doctors', 'new')));
  await assertSucceeds(getDoc(doc(db, 'healthRecords', 'private')));
  await assertSucceeds(getDoc(doc(db, 'healthProfiles', 'other')));
});
test('patient can edit contact details but cannot promote or reactivate themselves', async () => {
  const db = user('patient');
  await assertSucceeds(updateDoc(doc(db, 'users', 'patient'), { name: 'Updated', phone: '123' }));
  await assertFails(updateDoc(doc(db, 'users', 'patient'), { role: 'admin' }));
  await assertFails(updateDoc(doc(db, 'users', 'patient'), { status: 'suspended' }));
  await assertFails(deleteDoc(doc(db, 'users', 'patient')));
  await assertFails(getDocs(collection(db, 'users')));
});
test('self registration permits only an active patient with matching identity', async () => {
  const db = user('new');
  const profile = { uid: 'new', name: 'New', email: 'new@example.com', role: 'patient', status: 'active' };
  await assertFails(setDoc(doc(db, 'users', 'new'), { ...profile, role: 'admin' }));
  await assertFails(setDoc(doc(db, 'users', 'new'), { ...profile, uid: 'other' }));
  await assertSucceeds(setDoc(doc(db, 'users', 'new'), profile));
});
test('deleted-account tokens cannot recreate profiles', async () => {
  await assertFails(setDoc(doc(user('deleted'), 'users', 'deleted'), { uid: 'deleted', email: 'deleted@example.com', role: 'patient', status: 'active' }));
});
test('suspended users retain self-read but lose data access and self-reactivation', async () => {
  const db = user('suspended');
  await assertSucceeds(getDoc(doc(db, 'users', 'suspended')));
  await assertFails(updateDoc(doc(db, 'users', 'suspended'), { status: 'active' }));
  await assertFails(getDocs(collection(db, 'doctors')));
  await assertFails(setDoc(doc(db, 'healthProfiles', 'suspended'), { uid: 'suspended' }));
});
test('patients cannot read other patients clinical records', async () => {
  await assertFails(getDoc(doc(user('patient'), 'healthRecords', 'private')));
  await assertFails(getDoc(doc(user('patient'), 'healthProfiles', 'other')));
  await assertSucceeds(getDocs(query(collection(user('patient'), 'appointments'), where('patientId', '==', 'patient'))));
  await assertFails(getDocs(collection(user('patient'), 'appointments')));
});
test('patient cancellation and assigned doctor status updates cannot reassign identities', async () => {
  const patientDb = user('patient'), doctorDb = user('doctor');
  await assertSucceeds(updateDoc(doc(patientDb, 'appointments', 'one'), { status: 'cancelled' }));
  await assertFails(updateDoc(doc(patientDb, 'appointments', 'one'), { status: 'completed' }));
  await assertSucceeds(getDoc(doc(doctorDb, 'appointments', 'one')));
  await assertFails(updateDoc(doc(doctorDb, 'appointments', 'one'), { status: 'confirmed' }));
  await env.withSecurityRulesDisabled(async c => updateDoc(doc(c.firestore(), 'appointments', 'one'), { status: 'pending' }));
  await assertSucceeds(updateDoc(doc(doctorDb, 'appointments', 'one'), { status: 'confirmed' }));
  await assertFails(updateDoc(doc(doctorDb, 'appointments', 'one'), { patientId: 'other' }));
});
test('booking suspended doctors and accessing data anonymously are blocked', async () => {
  await env.withSecurityRulesDisabled(async context => updateDoc(doc(context.firestore(), 'doctors', 'legacy-doctor'), { status: 'suspended' }));
  await assertFails(setDoc(doc(user('patient'), 'appointments', 'new'), { patientId: 'patient', doctorId: 'legacy-doctor', status: 'pending' }));
  await assertFails(getDocs(collection(env.unauthenticatedContext().firestore(), 'doctors')));
});

test('Spark admin can atomically provision and remove app accounts with deletion markers', async () => {
  const db = user('admin');
  const create = writeBatch(db);
  create.set(doc(db, 'users', 'new-doctor'), { uid: 'new-doctor', role: 'doctor', status: 'active' });
  create.set(doc(db, 'doctors', 'new-doctor'), { uid: 'new-doctor', status: 'active' });
  await assertSucceeds(create.commit());
  const remove = writeBatch(db);
  remove.set(doc(db, 'adminDeletedUsers', 'new-doctor'), { deletedBy: 'admin' });
  remove.delete(doc(db, 'users', 'new-doctor'));
  remove.delete(doc(db, 'doctors', 'new-doctor'));
  await assertSucceeds(remove.commit());
  await assertFails(setDoc(doc(user('new-doctor'), 'users', 'new-doctor'), { uid: 'new-doctor', email: 'new-doctor@example.com', role: 'patient', status: 'active' }));
  await assertFails(setDoc(doc(user('patient'), 'adminDeletedUsers', 'other'), { deletedBy: 'patient' }));
});

const care = { doctorUid: 'doctor', patientId: 'patient', appointmentId: 'one', updatedAt: Timestamp.now() };
async function grantCare() {
  await env.withSecurityRulesDisabled(async c => updateDoc(doc(c.firestore(), 'appointments', 'one'), { status: 'confirmed' }));
  await assertSucceeds(setDoc(doc(user('doctor'), 'doctorPatientAccess', 'doctor_patient'), care));
}
function assessment() {
  return { doctorUid: 'doctor', patientId: 'patient', appointmentId: 'one', patientName: 'Patient', symptoms: 'Reported symptoms',
    notes: 'Clinician notes', plan: 'Recorded plan', priority: 'low', followUpAt: null, createdAt: Timestamp.now(), updatedAt: Timestamp.now() };
}
test('doctor queries include assigned legacy IDs but cannot list every appointment', async () => {
  const db = user('doctor');
  await assertSucceeds(getDocs(query(collection(db, 'appointments'), where('doctorId', '==', 'legacy-doctor'))));
  await assertSucceeds(getDocs(query(collection(db, 'appointments'), where('doctorId', '==', 'doctor'))));
  await assertFails(getDocs(collection(db, 'appointments')));
});
test('clinical records require confirmed assignment and access links cannot be forged', async () => {
  const db = user('doctor');
  await assertFails(setDoc(doc(db, 'doctorPatientAccess', 'doctor_patient'), care));
  await grantCare();
  await assertSucceeds(getDoc(doc(db, 'users', 'patient')));
  await assertSucceeds(getDoc(doc(db, 'healthProfiles', 'patient')));
  await assertSucceeds(getDocs(query(collection(db, 'healthRecords'), where('patientId', '==', 'patient'))));
  await assertFails(getDoc(doc(db, 'healthRecords', 'private')));
  await assertFails(setDoc(doc(db, 'doctorPatientAccess', 'doctor_other'), { ...care, patientId: 'other' }));
  await assertFails(setDoc(doc(user('patient'), 'doctorPatientAccess', 'doctor_patient'), care));
  await assertFails(setDoc(doc(db, 'healthProfiles', 'patient'), { bloodSugar: 123 }));
});
test('cancelled or reassigned visits revoke clinical access', async () => {
  await grantCare();
  await assertSucceeds(getDoc(doc(user('doctor'), 'users', 'patient')));
  await env.withSecurityRulesDisabled(async c => updateDoc(doc(c.firestore(), 'appointments', 'one'), { status: 'cancelled' }));
  await assertFails(getDoc(doc(user('doctor'), 'users', 'patient')));
  await env.withSecurityRulesDisabled(async c => updateDoc(doc(c.firestore(), 'appointments', 'one'), { status: 'confirmed', doctorId: 'someone-else' }));
  await assertFails(getDoc(doc(user('doctor'), 'healthProfiles', 'patient')));
});
test('doctor may save/edit only their assessment with immutable identities and valid priority', async () => {
  await grantCare(); const db = user('doctor'), note = assessment();
  await assertSucceeds(getDoc(doc(db, 'doctorAssessments', 'doctor_one')));
  await assertSucceeds(setDoc(doc(db, 'doctorAssessments', 'doctor_one'), note));
  await assertSucceeds(updateDoc(doc(db, 'doctorAssessments', 'doctor_one'), { notes: 'Updated notes', priority: 'high' }));
  await assertSucceeds(getDocs(query(collection(db, 'doctorAssessments'), where('doctorUid', '==', 'doctor'))));
  await assertFails(getDocs(collection(db, 'doctorAssessments')));
  await assertFails(updateDoc(doc(db, 'doctorAssessments', 'doctor_one'), { patientId: 'other' }));
  await assertFails(updateDoc(doc(db, 'doctorAssessments', 'doctor_one'), { priority: 'predicted-critical' }));
  await assertFails(deleteDoc(doc(db, 'doctorAssessments', 'doctor_one')));
  await assertFails(getDoc(doc(user('patient'), 'doctorAssessments', 'doctor_one')));
});
test('other doctors and suspended doctors cannot read clinical data or another assessment', async () => {
  await grantCare(); await setDoc(doc(user('doctor'), 'doctorAssessments', 'doctor_one'), assessment());
  await env.withSecurityRulesDisabled(async c => setDoc(doc(c.firestore(), 'users', 'other-doctor'), { role: 'doctor', status: 'active' }));
  await assertFails(getDoc(doc(user('other-doctor'), 'doctorAssessments', 'doctor_one')));
  await assertFails(getDoc(doc(user('other-doctor'), 'users', 'patient')));
  await env.withSecurityRulesDisabled(async c => updateDoc(doc(c.firestore(), 'users', 'doctor'), { status: 'suspended' }));
  await assertFails(getDoc(doc(user('doctor'), 'healthProfiles', 'patient')));
  await assertFails(getDoc(doc(user('doctor'), 'doctorAssessments', 'doctor_one')));
});
test('doctor may edit only own directory fields and cannot change identity or status', async () => {
  const db = user('doctor');
  await assertSucceeds(updateDoc(doc(db, 'doctors', 'legacy-doctor'), { qualification: 'Recorded qualification', availability: 'Weekdays' }));
  await assertFails(updateDoc(doc(db, 'doctors', 'legacy-doctor'), { uid: 'other' }));
  await assertFails(updateDoc(doc(db, 'doctors', 'legacy-doctor'), { status: 'suspended' }));
  await assertFails(setDoc(doc(db, 'doctors', 'new'), { uid: 'doctor' }));
});
test('doctor cannot complete pending visits or reopen completed visits', async () => {
  const db = user('doctor');
  await assertFails(updateDoc(doc(db, 'appointments', 'one'), { status: 'completed' }));
  await assertSucceeds(updateDoc(doc(db, 'appointments', 'one'), { status: 'confirmed' }));
  await assertSucceeds(updateDoc(doc(db, 'appointments', 'one'), { status: 'completed' }));
  await assertFails(updateDoc(doc(db, 'appointments', 'one'), { status: 'pending' }));
});
