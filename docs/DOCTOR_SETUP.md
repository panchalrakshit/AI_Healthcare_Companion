# Doctor workspace — Firebase Spark

The doctor dashboard now loads the signed-in doctor's real data. It includes a
responsive overview, appointment search/status filters, assigned patients, medical
record viewing, visit assessments, follow-up alerts, practice reports, CSV copying,
profile editing and actual Firebase sign-out. Graphs show scheduled appointment
activity, outcomes, weekday patterns and latest clinician-recorded priorities.
7/30/90-day filters apply to appointment charts; priority patterns use the latest
saved assessment per patient. Undated appointments are excluded from date charts.

## Run the doctor branch

```powershell
cd "D:\MCA\MCA-SEM 3"
git fetch origin
git switch feature/complete-doctor-side
git pull --ff-only origin feature/complete-doctor-side
flutter pub get
flutter run
```

Publish this branch's `firestore.rules` in Firebase Console → Firestore Database →
Rules. No Cloud Functions, billing upgrade or new package is needed. The branch
includes the earlier free admin changes and its PR is based on that admin branch.

Doctor login requires `users/{Auth UID}` with `role: doctor`, `status: active`.
New admin-created doctors already get `doctors/{Auth UID}` with `uid: Auth UID`.
For an older doctor directory document whose ID is different, have the admin set
its `uid` field to the correct doctor's Auth UID. Names/emails are never used to
guess identity. Existing appointments keep their original doctorId and remain
readable through this explicit link. Unlinked directory entries do not grant access.

## Patient access and assessments

Only assigned appointments are queried, one query per explicitly linked directory
ID plus the Auth UID, then merged without duplicates. All linked queries must
load before counts appear. Stream errors are displayed and subscriptions are
cancelled when the workspace is no longer listening.

Confirm a pending appointment to open its patient's clinical workspace. Opening
the workspace creates/updates `doctorPatientAccess/{doctorUID}_{patientUID}` with
the appointment ID. Rules independently verify ownership, patient identity and a
confirmed/completed appointment before any profile/record read. Cancelling,
deleting or reassigning the referenced appointment revokes clinical access.
Suspended/removed doctor or patient accounts also lose this access.

Patient-provided healthProfiles/healthRecords remain read-only for doctors.
Doctor notes live separately in `doctorAssessments/{doctorUID}_{appointmentID}`.
One assessment per visit can be edited; identity and creation time stay immutable.
Symptoms, notes, care plan, selected priority and optional follow-up date are saved.
Priorities are entered by the clinician, not inferred or presented as an AI result.
The repository has no prediction model/API, so no fabricated diagnosis, accuracy,
probability or risk score is displayed.

Appointments follow pending → confirmed/cancelled and confirmed → completed/cancelled.
Completed and cancelled visits cannot be reopened by the doctor. Admin retains
oversight. Transactional status updates reject concurrent/stale changes.

Alerts derive from actual pending requests and due follow-ups on each patient's
latest assessment. Reports can copy filtered saved assessments as properly quoted
CSV; this happens only after clicking Copy. Profile edits synchronize the doctor's
user profile and explicitly linked directory entries. Email, UID, role and status
remain protected. Directory creation/removal remains admin-only.

## Validation

GitHub Actions runs Flutter analysis, admin/doctor widget tests and Firestore
emulator authorization tests on a demo database. No production data is read by
the tests. After publishing rules, use a temporary doctor/patient to verify:
book a visit, confirm it, open records, save/edit notes, complete it, and ensure
another doctor cannot read the patient's records or the first doctor's assessment.
Live project credentials are needed for this final end-to-end check.
