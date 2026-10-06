# Admin setup — Firebase Spark (free)

This version does not use Cloud Functions, Firebase Admin SDK, or a billing upgrade.
Keep your project on Spark. Firebase free usage limits still apply.

## Pull and run

```powershell
cd "D:\MCA\MCA-SEM 3"
git fetch origin
git switch feature/complete-admin-side
git pull --ff-only origin feature/complete-admin-side
flutter pub get
flutter run
```

Before using account actions, copy the repository's `firestore.rules` into
Firebase Console → Firestore Database → Rules and click Publish. This requires no
Functions deployment. Keep your admin's `users/{Authentication UID}` profile with
`role: admin` and `status: active`. Email/Password sign-in must be enabled.

## Available features

- Live dashboard graphs, metrics, specialization demand, weekday patterns and
  7/30/90-day filters remain available.
- Add patients and doctors with email/password login accounts. A separate temporary
  Firebase Auth session creates the new account, while all Firestore writes use the
  logged-in admin's default session. The admin stays signed in. Matching user,
  doctor-directory or health-profile documents are written in one batch.
- Edit profile and doctor-directory details. Existing login email is read-only;
  another person's Auth email cannot be changed by the Flutter client.
- Suspend/reactivate app access by updating Firestore status. Security rules block
  suspended users' data access and the app rejects their login. The underlying
  Firebase Authentication account is not disabled by this operation.
- Remove app profiles and linked doctor directory entries in an atomic batch.
  A deleted-user marker prevents the remaining Auth account from recreating its
  profile. Appointments and health history are retained. The Firebase Auth account
  remains; delete it manually via Firebase Console → Authentication → Users if
  permanent login deletion is needed. Its email remains reserved until then.
- Search appointments, update status and delete records with confirmation.
- Forgot Password sends a reset email so users can replace temporary passwords.

Admin-only rules grant access to the five existing collections. Non-admins cannot
change their own role/status or read another patient's health data. Legacy doctor
records without a linked login can still be edited, suspended or removed.

If Firestore creation fails after a new Auth account is created, the temporary
session attempts to delete its own newly created account. If a network failure
prevents cleanup, remove that unused account in Firebase Console before retrying.
No passwords or privileged server credentials are stored in Firestore or Flutter.

## Checks

GitHub Actions runs Flutter analysis, analytics/form widget tests and Firestore
emulator security tests against a demo project. Production Firebase access is not
used by those checks. Test one temporary doctor and patient in your own project
before the college demonstration: add, edit, suspend, reactivate, then remove.
