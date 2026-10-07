"""Train locally and export a symptom Decision Tree for offline Dart inference.
Usage: python ml/train_symptom_model.py --data path/to/preprocessed_data.csv
"""
import argparse
import hashlib
import json
from pathlib import Path
import numpy as np
import pandas as pd
from sklearn.dummy import DummyClassifier
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix, f1_score
from sklearn.model_selection import GridSearchCV, GroupShuffleSplit, StratifiedGroupKFold
from sklearn.tree import DecisionTreeClassifier
import sklearn

FEATURES = ['fever', 'cough', 'headache', 'fatigue', 'vomiting', 'joint_pain',
            'sore_throat', 'runny_nose', 'chills', 'body_pain']
DISEASES = ['Common Cold', 'Dengue', 'Influenza', 'Malaria', 'Typhoid']
ROOT = Path(__file__).resolve().parents[1]


def load_data(path):
    data = pd.read_csv(path)
    if set(data.columns) != set(FEATURES + ['disease']):
        raise ValueError('CSV must contain the ten documented symptom columns and disease.')
    if data.isna().any().any():
        raise ValueError('Missing values found. Supply verified symptoms; unknown is not absent.')
    data['disease'] = data['disease'].astype(str).str.strip()
    if sorted(data['disease'].unique().tolist()) != DISEASES:
        raise ValueError('Dataset must contain exactly the five documented disease labels.')
    if data['disease'].eq('').any():
        raise ValueError('Disease labels cannot be blank.')
    for feature in FEATURES:
        data[feature] = pd.to_numeric(data[feature], errors='raise')
        if not data[feature].isin([0, 1]).all():
            raise ValueError(f'{feature} must contain only 0 (absent) or 1 (present).')
        data[feature] = data[feature].astype(int)
    return data[FEATURES + ['disease']]


def pattern_keys(frame):
    return frame[FEATURES].astype(str).agg(''.join, axis=1)


def tree_predict(export, vector):
    node = 0
    while export['nodes'][node]['feature'] >= 0:
        item = export['nodes'][node]
        node = item['left'] if vector[item['feature']] <= item['threshold'] else item['right']
    return int(np.argmax(export['nodes'][node]['distribution']))


def train(path, output, report_path, parity_path):
    raw = load_data(path)
    data = raw.drop_duplicates().reset_index(drop=True)
    groups = pattern_keys(data)
    train_index, test_index = next(GroupShuffleSplit(test_size=.2, random_state=42).split(data, groups=groups))
    x_train, x_test = data.loc[train_index, FEATURES], data.loc[test_index, FEATURES]
    y_train, y_test = data.loc[train_index, 'disease'], data.loc[test_index, 'disease']
    train_groups, test_groups = groups.iloc[train_index], groups.iloc[test_index]
    if set(train_groups) & set(test_groups):
        raise AssertionError('Symptom pattern leakage detected.')
    if set(y_train) != set(data.disease) or set(y_test) != set(data.disease):
        raise ValueError('Every disease must appear in train and test; this dataset needs more independent examples.')
    search = GridSearchCV(DecisionTreeClassifier(random_state=42),
        {'max_depth': [2, 3, 4, 5, None], 'min_samples_leaf': [2, 4, 6]},
        scoring='f1_macro', cv=StratifiedGroupKFold(n_splits=3, shuffle=True, random_state=42),
        n_jobs=1, error_score='raise')
    search.fit(x_train, y_train, groups=train_groups)
    model = search.best_estimator_
    predicted = model.predict(x_test)
    baseline = DummyClassifier(strategy='most_frequent').fit(x_train, y_train)
    labels = model.classes_.tolist()
    conflicting = data.groupby(FEATURES)['disease'].nunique()
    report = {
        'educationalOnly': True, 'datasetProvenance': 'User-supplied preprocessed CSV; original source unverified',
        'rawRows': len(raw), 'exactDuplicateRowsRemoved': len(raw) - len(data),
        'uniqueRows': len(data), 'uniquePatterns': int(groups.nunique()),
        'conflictingPatterns': int((conflicting > 1).sum()),
        'trainRows': len(train_index), 'testRows': len(test_index),
        'trainPatterns': int(train_groups.nunique()), 'testPatterns': int(test_groups.nunique()),
        'split': 'Grouped by complete symptom vector; seed 42; 20% of groups held out',
        'patternOverlap': 0, 'appPolicyTestCoverage': 0.0,
        'appPolicy': 'Abstain for unseen, conflicting, all-absent or tree/label-disagreement inputs; all grouped test patterns are unseen',
        'bestParameters': search.best_params_,
        'trainingCrossValidationMacroF1': float(search.best_score_),
        'testAccuracy': float(accuracy_score(y_test, predicted)),
        'testMacroF1': float(f1_score(y_test, predicted, average='macro', zero_division=0)),
        'baselineAccuracy': float(accuracy_score(y_test, baseline.predict(x_test))),
        'labels': labels, 'confusionMatrix': confusion_matrix(y_test, predicted, labels=labels).tolist(),
        'classificationReport': classification_report(y_test, predicted, labels=labels, output_dict=True, zero_division=0),
        'limitations': ['Small held-out sample, not clinical validation',
                       'Only five disease labels; other conditions are outside coverage',
                       'Conflicting symptom patterns cannot be resolved from these inputs alone',
                       'Original preprocessing and dataset collection could not be audited',
                       'Leaf distributions are not calibrated medical probabilities'],
    }
    patterns = {}
    for key, label in zip(train_groups, y_train):
        patterns.setdefault(key, set()).add(label)
    nodes = []
    for i in range(model.tree_.node_count):
        value = model.tree_.value[i][0]
        distribution = (value / value.sum()).tolist()
        nodes.append({'feature': int(model.tree_.feature[i]), 'threshold': float(model.tree_.threshold[i]),
                      'left': int(model.tree_.children_left[i]), 'right': int(model.tree_.children_right[i]),
                      'distribution': distribution})
    export = {'schemaVersion': 1, 'modelVersion': 'symptom-demo-v1', 'educationalOnly': True,
              'features': FEATURES, 'classes': labels, 'nodes': nodes,
              'trainingPatterns': {key: sorted(value) for key, value in sorted(patterns.items())},
              'evaluation': report, 'datasetSha256': hashlib.sha256(Path(path).read_bytes()).hexdigest(),
              'sklearnVersion': sklearn.__version__}
    # Verify every possible input, including combinations not seen in training.
    vectors = np.array([[int(bit) for bit in f'{i:010b}'] for i in range(1024)])
    expected = model.predict(pd.DataFrame(vectors, columns=FEATURES))
    expected_ids = [labels.index(label) for label in expected]
    actual = [tree_predict(export, vector) for vector in vectors]
    if actual != expected_ids:
        raise AssertionError('Exported tree differs from sklearn.')
    for destination, value in [(output, export), (report_path, report),
                               (parity_path, {'features': FEATURES, 'classes': labels, 'predictions': expected_ids})]:
        destination = Path(destination)
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_text(json.dumps(value, indent=2, allow_nan=False) + '\n', encoding='utf-8')
    print(json.dumps({key: report[key] for key in ['rawRows', 'exactDuplicateRowsRemoved', 'conflictingPatterns',
          'trainRows', 'testRows', 'bestParameters', 'testAccuracy', 'testMacroF1', 'baselineAccuracy']}, indent=2))
    print('Export parity verified for all 1024 binary symptom combinations. Educational use only.')
    return export


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--data', required=True, type=Path)
    parser.add_argument('--output', type=Path, default=ROOT / 'assets/models/symptom_tree.json')
    parser.add_argument('--report', type=Path, default=ROOT / 'ml/evaluation_report.json')
    parser.add_argument('--parity', type=Path, default=ROOT / 'test/fixtures/symptom_predictions.json')
    args = parser.parse_args()
    train(args.data, args.output, args.report, args.parity)


if __name__ == '__main__':
    main()
