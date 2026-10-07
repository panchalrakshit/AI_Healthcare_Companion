# Offline symptom model: educational college demo

The bundled Decision Tree was trained from the user's `preprocessed_data.csv`. Original data collection, licensing, clinical verification and preprocessing provenance are unknown. The raw dataset is not included in the public repository. Keep your uploaded CSV locally. This model must not guide diagnosis, medication, triage or exclusion of disease.

## Train and test on Windows

From the Flutter project directory, with Python 3.11 or 3.12 installed:

```powershell
py -3.11 -m venv .venv-ml
.\.venv-ml\Scripts\python.exe -m pip install -r ml\requirements.txt
.\.venv-ml\Scripts\python.exe ml\train_symptom_model.py --data "D:\path\to\preprocessed_data.csv"
flutter pub get
flutter test test/symptom_model_test.dart
flutter run
```

Use `py -3.12` instead if that is your installed version. Training writes `assets/models/symptom_tree.json`, `ml/evaluation_report.json`, and `test/fixtures/symptom_predictions.json`. No model API, paid hosting, pickle runtime, Cloud Function or Firestore change is required. Changing the model asset requires a full restart/rebuild, not just hot reload. It works with Flutter Web and mobile using pure Dart inference.

## Evaluation

The supplied CSV has 200 rows, 77 exact duplicates, 94 distinct symptom patterns and 21 patterns with conflicting disease labels. Exact duplicates are removed while conflicting labels are retained and reported. Identical complete symptom vectors are grouped so no pattern appears in both train and test. Seed 42 holds out 20% of groups: 100 training rows and 23 test rows. Tree depth and leaf size are selected only within training data using three-fold StratifiedGroupKFold and macro F1. No test-set tuning or post-evaluation refitting occurs.

The exported tree uses depth 3 and minimum leaf size 4. Bare-tree accuracy is 14/23 (60.9%), macro F1 0.5205; the majority-class baseline is 4/23 (17.4%). Class-wise metrics and the confusion matrix are in the evaluation report. These estimates are noisy and do not establish clinical accuracy. Zero cross-split symptom overlap does not establish independence of original patients; identifiers/source provenance were not supplied. Already-preprocessed missing-value handling cannot be audited. The trainer rejects missing, nonbinary, blank-label or wrong-schema input rather than treating unknown symptoms as absent.

## App policy and coverage

Patients explicitly answer Yes/No for all ten symptoms. Incomplete inputs cannot run. All-absent symptoms have no healthy training class and produce no suggestion. Unseen symptom combinations, combinations with conflicting training labels, and disagreement between the tree and an unambiguous training label produce no suggestion. Only a supported, unambiguous training pattern matching the tree output can display an experimental suggestion.

This conservative display policy differs from the bare tree evaluated above: every held-out group is unseen by definition, so app-policy coverage on the grouped test is 0%. The displayed tree score is explicitly identified as before abstention. The demo does not demonstrate validated generalisation; a larger, verified and more representative dataset is needed before broader deployment. Leaf distributions are implementation details, not displayed as confidence or medical risk percentages.

The checker performs inference on-device and does not persist inputs or outputs to Firestore. Answer changes clear results. The user can open the existing doctor booking screen. No automatic treatment or doctor priority is generated.

## Export verification

Training compares the exported JSON tree with sklearn predictions for all 1024 binary input combinations. The generated parity fixture lets the Dart test repeat the same exhaustive comparison. Model feature order and class mapping are explicit; tree indices, values and format are validated when loading. Retrain and regenerate all three files together.

Features in order: fever, cough, headache, fatigue, vomiting, joint_pain, sore_throat, runny_nose, chills, body_pain. Labels: Common Cold, Dengue, Influenza, Malaria, Typhoid.
