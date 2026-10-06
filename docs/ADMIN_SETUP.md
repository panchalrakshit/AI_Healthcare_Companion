# Admin dashboard and account management

The admin screen now includes live counts, appointment trends, outcome charts,
specialization demand, weekday patterns, and 7/30/90-day filters. Analytics use
scheduled appointment dates; undated records are excluded. Recent appointments
use creation date, falling back to scheduled date. There is no fabricated data.

Patients come from `users` with `role: patient`. Doctors combine the `doctors`
directory with doctor login profiles, matching an explicit `uid` or matching
document IDs. Legacy directory records without login links remain manageable.
They are not linked by name or email. Counts deduplicate explicitly linked users.

## Deploy once before using account actions

From PowerShell in the Flutter project directory:

```powershell
cd "D:\MCA\MCA-SEM 3"
git fetch origin
git switch feature/complete-admin-side
git pull --ff-only origin feature/complete-admin-side
flutter pub get

# Requires Node.js 22 and the Firebase CLI.
npm install -g firebase-tools
firebase login
npm --prefix functions install
firebase deploy --project aihealthcompanion-ac088 --only functions:admin,firestore:rules

flutter run
```

Cloud Functions deployment requires the Firebase project's Blaze billing plan.
The callable functions and client both use `us-central1`. No service-account key
is placed in Flutter or committed to GitHub. `firebase.json` preserves the existing
Flutter configuration and adds the admin functions codebase and Firestore rules.

Keep the admin's `users/{Authentication UID}` document with exact lowercase fields
`role: admin` and `status: active`. Create admin accounts through the Firebase
Console; this panel creates only patients and doctors and protects admin accounts
from accidental deletion/suspension. Use the Firebase Console for admin-role changes.

## Available actions

- **Add patient / doctor:** creates Firebase Auth and matching Firestore profiles;
  doctors also get a bookable `doctors/{UID}` directory entry. Patients get an empty
  health profile. Passwords are never stored in Firestore.
- **Edit:** updates contact details and doctor specialization, qualification,
  experience, hospital and availability. Linked Auth email/display name are updated.
- **Activate / suspend:** synchronizes directory/profile status and Auth's disabled
  flag. Rules block suspended sessions; suspended doctors cannot be booked.
- **Remove:** removes the login and profile plus linked doctor directory entries.
  A confirmation is required. Existing appointment and clinical history is retained
  for authorized admin access. Directory-only doctors remove only their directory
  entry. Deleted-user tombstones prevent stale tokens from recreating profiles.
- **Appointments:** search/filter, change status, or permanently delete a record.

The rules give active admins read/write access to the five existing collections:
`users`, `doctors`, `appointments`, `healthProfiles`, and `healthRecords`. Non-admins
cannot change their own role/status or access another patient's health data.

## Validation

```powershell
node --test functions/test/*.test.js
flutter analyze --no-fatal-infos --no-fatal-warnings lib/features/auth/dashboards/AdminDashboard.dart lib/features/auth/dashboards/admin test/admin_analytics_test.dart
flutter test test/admin_analytics_test.dart

# Rules tests use a demo project, never the live database. Requires Java 21.
npm --prefix test/rules install
./test/rules/node_modules/.bin/firebase emulators:exec --only firestore --project demo-health-admin "node --test test/rules/firestore.test.js"
```

The GitHub workflow runs these checks. Functions tests exercise authorization,
account creation, rollback, legacy directory links, suspension, deletion recovery,
clinical-history retention and identity mismatch rejection.

Auth and Firestore are separate services, so operations cannot be a single atomic
transaction. Creation compensates failures; suspension marks the profile first;
deletion removes Auth before the final atomic profile/directory/tombstone batch,
allowing retries after a partial failure. Refresh and retry a failed operation.
An edit that fails after Auth updates can be retried with the same details.

After deployment, test with one temporary patient and one temporary doctor:
create, sign in, edit, suspend (verify sign-in/data access is denied), reactivate,
and remove. Verify existing appointments and patient history are preserved.
Deployment and live-account verification require project-owner Firebase access.
