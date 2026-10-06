# Patient workspace

The patient branch includes the existing admin and doctor work. It stays on Firebase Spark and uses the rules already supplied for the doctor branch. No billing upgrade, Cloud Functions, Storage, paid API, new collection or additional composite index is needed.

Use a Firebase Authentication email/password account with a matching `users/{authUid}` document containing `uid`, `name`, `email`, `role: patient`, and `status: active`. Use Admin > Patients > Add or the existing signup flow. Existing doctor directory IDs and UID links are preserved.

## Live data

The workspace subscribes to the signed-in patient's user profile, health profile, health records, and appointments. Loading and errors are visible, failed source values are cleared, retry replaces subscriptions, and sign-out/account changes cancel subscriptions. Query filters use `patientId == authUid`; sorting is local.

Overview, Health insights, Health records, Appointments, Reminders and My profile have responsive desktop/mobile layouts. Reminders are derived from pending/confirmed visits today or later; they are in-app reminders, not push notifications. Appointment requests require future date/time and a reason, validate the current doctor status transactionally, and remain pending until the doctor confirms them. Cancellation rechecks current ownership/status in a transaction.

## Measured readings

Add reading accepts optional positive numeric measurements and systolic/diastolic blood pressure. Enter only actual measured values. Saving atomically merges entered measurements into `healthProfiles/{uid}` and adds a `healthRecords` document:

- `patientId`: authenticated patient UID
- `title`: Measured health readings
- `recordType`: Vital Signs
- `vitals`: only entered metrics (`heartRate`, `bloodSugar`, `spo2`, `temperature`, `weight`, `height`, `bloodPressure`)
- `measuredAt` and `recordDate`: measurement submission timestamp
- `createdAt`: server timestamp

BMI is calculated from the latest saved weight (kg) and height (cm) if both are available. Omitted measurements keep previous latest-profile values. History charts use only dated record snapshots, never fabricate historical readings from an existing current profile. The 7/30/90-day controls apply to history charts and appointment patterns. Charts support selecting individual points and metrics. Profile cards represent the latest saved value for each field; different fields may have been measured at different times. History preserves the timestamp of each entry. Deleting a history entry does not erase latest profile values; confirmation explains this.

## Records and profile

Medical record metadata can be added, searched, filtered, edited and deleted. Reading snapshots are not editable through medical-record forms. CSV copying occurs only after clicking Copy records CSV and includes only that patient's records; formula-leading fields are escaped. This is metadata storage and clipboard export, not report file uploading. Personal profile edits update only name/phone and updatedAt; email, role and status remain protected. Password reset uses Firebase Authentication.

The app has no trained prediction model or prediction endpoint. Health insights show real observed readings and patterns, not fabricated risk scores or diagnoses. Doctor assessments retain their existing doctor/admin permissions.

## Verify in your Firebase project

1. Start the patient branch and sign in as a test patient.
2. Add two measured readings; check current profile values and dated history charts.
3. Add/edit a report, search/filter it, and copy CSV.
4. Request an appointment with an active linked doctor.
5. Confirm it from the doctor dashboard; verify the patient status/reminder updates.
6. Cancel a pending/confirmed visit and ensure completed/cancelled visits have no cancel action.
7. Edit name/phone and test password reset.
8. Check narrow mobile navigation and loading/error recovery.

GitHub checks run targeted Flutter analysis, patient/admin/doctor tests, and Firestore emulator authorization tests. Live Firebase and email delivery must be verified with your project credentials.
