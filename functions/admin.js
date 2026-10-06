'use strict';

// Dependencies are injected so authorization and failure recovery can be tested
// without production Firebase credentials.
function createAdminHandlers({ db, auth, HttpsError, timestamp }) {
  const fail = (code, message) => { throw new HttpsError(code, message); };
  function text(value, field, required = false, max = 200) {
    if (value === undefined && !required) return '';
    if (typeof value !== 'string' || value.trim().length > max || (required && !value.trim())) {
      fail('invalid-argument', `Enter a valid ${field}.`);
    }
    return value.trim();
  }
  function id(value, field) {
    const result = text(value, field, true, 128);
    if (result.includes('/')) fail('invalid-argument', `Invalid ${field}.`);
    return result;
  }
  async function authorize(request) {
    if (!request.auth) fail('unauthenticated', 'Sign in as an admin.');
    const user = await db.collection('users').doc(request.auth.uid).get();
    if (!user.exists || user.data().role !== 'admin' || user.data().status !== 'active') {
      fail('permission-denied', 'An active admin account is required.');
    }
    const account = await auth.getUser(request.auth.uid);
    if (account.disabled) fail('permission-denied', 'This admin account is disabled.');
  }
  function details(data, role) {
    const result = {
      name: text(data.name, 'name', true),
      email: text(data.email, 'email', true, 254).toLowerCase(),
      phone: text(data.phone, 'phone', false, 40),
    };
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(result.email)) fail('invalid-argument', 'Enter a valid email.');
    if (role === 'doctor') {
      for (const field of ['specialization', 'qualification', 'experience', 'hospital', 'availability']) {
        result[field] = text(data[field], field, field === 'specialization');
      }
    }
    return result;
  }
  async function target(data, actor) {
    let uid = data.uid ? id(data.uid, 'user ID') : null;
    const doctorId = data.doctorId ? id(data.doctorId, 'doctor ID') : null;
    let doctor;
    if (doctorId) {
      doctor = await db.collection('doctors').doc(doctorId).get();
      if (!doctor.exists) fail('not-found', 'Doctor no longer exists. Refresh the list.');
      const linked = doctor.data().uid;
      if (linked && uid && linked !== uid) fail('invalid-argument', 'Doctor account does not match.');
      if (!uid && linked) uid = id(linked, 'linked user ID');
      if (!uid) {
        const sameId = await db.collection('users').doc(doctorId).get();
        if (sameId.exists && sameId.data().role === 'doctor') uid = doctorId;
      }
    }
    if (!uid && !doctor) fail('invalid-argument', 'Select an account.');
    if (uid === actor) fail('failed-precondition', 'You cannot remove or suspend your own admin account.');
    let profile;
    if (uid) {
      profile = await db.collection('users').doc(uid).get();
      if (!profile.exists) {
        if (doctor && !data.uid) { uid = null; profile = undefined; }
        else fail('not-found', 'User profile does not exist.');
      }
      if (profile && !['patient', 'doctor'].includes(profile.data().role)) {
        fail('failed-precondition', 'Only patient and doctor accounts can be managed here.');
      }
      if (doctor && profile && profile.data().role !== 'doctor') fail('invalid-argument', 'This account is not a doctor.');
    }
    const directories = new Map();
    if (doctor) directories.set(doctor.id, doctor.ref);
    if (uid && profile.data().role === 'doctor') {
      const linked = await db.collection('doctors').where('uid', '==', uid).get();
      linked.docs.forEach(doc => directories.set(doc.id, doc.ref));
      const sameId = await db.collection('doctors').doc(uid).get();
      if (sameId.exists) directories.set(sameId.id, sameId.ref);
      // A login profile without a directory entry becomes bookable after edit.
      if (!directories.size) directories.set(uid, db.collection('doctors').doc(uid));
    }
    return { uid, profile, directories, role: profile?.data().role || 'doctor' };
  }
  async function authUpdate(uid, fields, allowMissing = false) {
    try { await auth.updateUser(uid, fields); }
    catch (error) {
      if (!(allowMissing && error.code === 'auth/user-not-found')) throw error;
    }
  }
  function protectedHandler(fn) {
    return async request => {
      await authorize(request);
      try { return await fn(request.data || {}, request.auth.uid); }
      catch (error) {
        if (error instanceof HttpsError) throw error;
        if (error.code === 'auth/email-already-exists') fail('already-exists', 'That email already has a login account.');
        if (error.code === 'auth/user-not-found') fail('failed-precondition', 'This profile has no login account. Manage its directory entry or create a new account.');
        if (['auth/invalid-password', 'auth/password-does-not-meet-requirements'].includes(error.code)) {
          fail('invalid-argument', 'The password does not meet your Firebase password policy.');
        }
        console.error('Admin operation failed', error.code || error.message);
        fail('internal', 'The operation did not finish. Refresh the list and retry.');
      }
    };
  }
  return {
    adminCreateAccount: protectedHandler(async (data, actor) => {
      const role = data.role;
      if (!['patient', 'doctor'].includes(role)) fail('invalid-argument', 'Choose patient or doctor.');
      const fields = details(data, role);
      const password = text(data.password, 'temporary password', true, 128);
      if (password.length < 8) fail('invalid-argument', 'Use a password with at least 8 characters.');
      // Keep login disabled until all Firestore documents exist.
      const account = await auth.createUser({ email: fields.email, password, displayName: fields.name, disabled: true });
      const uid = account.uid;
      try {
        const batch = db.batch();
        const profile = { ...fields, uid, role, status: 'active', createdAt: timestamp(), createdBy: actor };
        batch.set(db.collection('users').doc(uid), profile);
        if (role === 'doctor') batch.set(db.collection('doctors').doc(uid), profile);
        if (role === 'patient') batch.set(db.collection('healthProfiles').doc(uid), { uid, createdAt: timestamp() });
        await batch.commit();
        await auth.updateUser(uid, { disabled: false });
      } catch (error) {
        // Compensate across Auth and Firestore; if cleanup fails, the login stays disabled.
        await auth.updateUser(uid, { disabled: true }).catch(() => {});
        const cleanup = db.batch();
        for (const collection of ['users', 'doctors', 'healthProfiles']) cleanup.delete(db.collection(collection).doc(uid));
        await cleanup.commit().catch(() => {});
        await auth.deleteUser(uid).catch(() => {});
        throw error;
      }
      return { uid };
    }),
    adminUpdateAccount: protectedHandler(async (data, actor) => {
      const selected = await target(data, actor);
      const fields = details(data, selected.role);
      if (selected.uid) await authUpdate(selected.uid, { email: fields.email, displayName: fields.name });
      const batch = db.batch();
      if (selected.uid) batch.update(selected.profile.ref, { ...fields, updatedAt: timestamp() });
      for (const ref of selected.directories.values()) {
        batch.set(ref, { ...fields, ...(selected.uid ? { uid: selected.uid, status: selected.profile.data().status || 'active' } : {}), updatedAt: timestamp() }, { merge: true });
      }
      await batch.commit();
      return { updated: true };
    }),
    adminSetAccountStatus: protectedHandler(async (data, actor) => {
      if (!['active', 'suspended'].includes(data.status)) fail('invalid-argument', 'Invalid account status.');
      const selected = await target(data, actor);
      // Disabling Auth also prevents future sign-in; Firestore rules block existing sessions.
      if (selected.uid) {
        await selected.profile.ref.update({ status: 'suspended', updatedAt: timestamp() });
        await authUpdate(selected.uid, { disabled: true }, true);
      }
      const batch = db.batch();
      const fields = { status: data.status, updatedAt: timestamp() };
      if (selected.uid) batch.update(selected.profile.ref, fields);
      for (const ref of selected.directories.values()) batch.set(ref, { ...fields, ...(selected.uid ? { uid: selected.uid } : {}) }, { merge: true });
      await batch.commit();
      if (selected.uid && data.status === 'active') await authUpdate(selected.uid, { disabled: false });
      return { updated: true };
    }),
    adminDeleteAccount: protectedHandler(async (data, actor) => {
      const selected = await target(data, actor);
      if (selected.uid) {
        await authUpdate(selected.uid, { disabled: true }, true);
        await db.collection('users').doc(selected.uid).update({ status: 'suspended' });
        try { await auth.deleteUser(selected.uid); }
        catch (error) { if (error.code !== 'auth/user-not-found') throw error; }
      }
      // Clinical history and appointments are retained, even when login is removed.
      // Delete Auth before profile so a failed batch can be safely retried.
      const batch = db.batch();
      if (selected.uid) {
        batch.set(db.collection('adminDeletedUsers').doc(selected.uid), { deletedAt: timestamp(), deletedBy: actor });
        batch.delete(selected.profile.ref);
      }
      for (const ref of selected.directories.values()) batch.delete(ref);
      await batch.commit();
      return { deleted: true, loginRemoved: Boolean(selected.uid) };
    }),
  };
}
module.exports = { createAdminHandlers };
