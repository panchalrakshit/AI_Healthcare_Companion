"""Train and export the offline symptom demo model.

The grouped hold-out split is used only for honest evaluation. After metrics
are calculated, a deployment tree is refitted on every validated row and the
app's pattern metadata is built from the complete validated dataset.
Usage: python ml/train_symptom_model.py --data path/to/preprocessed_data.csv
"""
import argparse
import hashlib
import json
from pathlib import Path

import numpy as np
import pandas as pd
import sklearn
from sklearn.dummy import DummyClassifier
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix, f1_score
from sklearn.model_selection import GridSearchCV, GroupShuffleSplit, StratifiedGroupKFold
from sklearn.tree import DecisionTreeClassifier

FEATURES = [
    'fever', 'cough', 'headache', 'fatigue', 'vomiting', 'joint_pain',
    'sore_throat', 'runny_nose', 'chills', 'body_pain',
]
DISEASES = ['Common Cold', 'Dengue', 'Influenza', 'Malaria', 'Typhoid']
ROOT = Path(__file__).resolve().parents[1]


def load_data(path):
    data = pd.read_csv(path)
    if set(data.columns) != set(FEATURES + ['disease']):
        raise ValueError('CSV must contain the ten documented symptom columns and disease.')
    if data.isna().any().any():
        raise ValueError('Missing values found. Supply verified symptoms; unknown is not absent.')

    data['disease'] = data['disease'].astype(str).str.strip()
    if data['disease'].eq('').any():
        raise ValueError('Disease labels cannot be blank.')
    # Compare sets: DISEASES is a documented order, not alphabetical order.
    if set(data['disease'].unique()) != set(DISEASES):
        raise ValueError('Dataset must contain exactly the five documented disease labels.')

    for feature in FEATURES:
        data[feature] = pd.to_numeric(data[feature], errors='raise')
        if not data[feature].isin([0, 1]).all():
            raise ValueError(f'{feature} must contain only 0 (absent) or 1 (present).')
        data[feature] = data[feature].astype(int)
    return data[FEATURES + ['disease']]


def pattern_keys(frame):
    return frame[FEATURES].astype(str).agg(''.join, axis=1)


def export_tree(model):
    nodes = []
    for i in range(model.tree_.node_count):
        value = model.tree_.value[i][0]
        distribution = (value / value.sum()).tolist()
        nodes.append({
            'feature': int(model.tree_.feature[i]),
            'threshold': float(model.tree_.threshold[i]),
            'left': int(model.tree_.children_left[i]),
            'right': int(model.tree_.children_right[i]),
            'distribution': distribution,
        })
    return nodes


def tree_predict(export, vector):
    node = 0
    for _ in range(len(export['nodes']) + 1):
        item = export['nodes'][node]
        if item['feature'] < 0:
            return int(np.argmax(item['distribution']))
        node = item['left'] if vector[item['feature']] <= item['threshold'] else item['right']
    raise ValueError('Exported tree contains a cycle.')


def build_pattern_metadata(frame):
    """Keep every observed label for a vector; conflicting vectors stay ambiguous."""
    grouped = frame.groupby(FEATURES, sort=True)['disease'].agg(lambda labels: sorted(set(labels)))
    patterns = {}
    for values, labels in grouped.items():
        key = ''.join(str(int(value)) for value in values)
        patterns[key] = labels
    return dict(sorted(patterns.items()))


def train(path, output, report_path, parity_path):
    source_path = Path(path)
    raw = load_data(source_path)
    data = raw.drop_duplicates().reset_index(drop=True)
    groups = pattern_keys(data)

    train_index, test_index = next(
        GroupShuffleSplit(test_size=.2, random_state=42).split(data, groups=groups)
    )
    x_train, x_test = data.loc[train_index, FEATURES], data.loc[test_index, FEATURES]
    y_train, y_test = data.loc[train_index, 'disease'], data.loc[test_index, 'disease']
    train_groups, test_groups = groups.iloc[train_index], groups.iloc[test_index]

    if set(train_groups) & set(test_groups):
        raise AssertionError('Symptom pattern leakage detected.')
    if set(y_train) != set(data.disease) or set(y_test) != set(data.disease):
        raise ValueError(
            'Every disease must appear in train and test; this dataset needs more independent examples.'
        )

    search = GridSearchCV(
        DecisionTreeClassifier(random_state=42),
        {'max_depth': [2, 3, 4, 5, None], 'min_samples_leaf': [2, 4, 6]},
        scoring='f1_macro',
        cv=StratifiedGroupKFold(n_splits=3, shuffle=True, random_state=42),
        n_jobs=1,
        error_score='raise',
    )
    search.fit(x_train, y_train, groups=train_groups)

    # Report metrics on the untouched grouped hold-out set BEFORE refitting.
    evaluation_model = search.best_estimator_
    predicted = evaluation_model.predict(x_test)
    baseline = DummyClassifier(strategy='most_frequent').fit(x_train, y_train)
    labels = evaluation_model.classes_.tolist()
    conflicting = data.groupby(FEATURES)['disease'].nunique()

    # This coverage figure intentionally uses only training-fold metadata.
    # Because groups are disjoint, held-out patterns are unseen by definition.
    fold_patterns = {}
    for key, label in zip(train_groups, y_train):
        fold_patterns.setdefault(key, set()).add(label)
    fold_supported = {
        key for key, values in fold_patterns.items()
        if len(values) == 1 and '1' in key
    }
    fold_coverage = (
        sum(key in fold_supported for key in test_groups) / len(test_groups)
        if len(test_groups) else 0.0
    )

    report = {
        'educationalOnly': True,
        'datasetProvenance': 'User-supplied preprocessed CSV; original source unverified',
        'rawRows': len(raw),
        'exactDuplicateRowsRemoved': len(raw) - len(data),
        'uniqueRows': len(data),
        'uniquePatterns': int(groups.nunique()),
        'conflictingPatterns': int((conflicting > 1).sum()),
        'trainRows': len(train_index),
        'testRows': len(test_index),
        'trainPatterns': int(train_groups.nunique()),
        'testPatterns': int(test_groups.nunique()),
        'split': 'Grouped by complete symptom vector; seed 42; 20% of groups held out',
        'patternOverlap': 0,
        'appPolicyTestCoverage': float(fold_coverage),
        'appPolicyTestCoverageDefinition': (
            'Measured against training-fold patterns only, before final refit; '
            'held-out symptom groups are unseen by design.'
        ),
        'bestParameters': search.best_params_,
        'trainingCrossValidationMacroF1': float(search.best_score_),
        'testAccuracy': float(accuracy_score(y_test, predicted)),
        'testMacroF1': float(f1_score(y_test, predicted, average='macro', zero_division=0)),
        'baselineAccuracy': float(accuracy_score(y_test, baseline.predict(x_test))),
        'labels': labels,
        'confusionMatrix': confusion_matrix(y_test, predicted, labels=labels).tolist(),
        'classificationReport': classification_report(
            y_test, predicted, labels=labels, output_dict=True, zero_division=0
        ),
        'deploymentModelFitRows': len(data),
        'deploymentPatternCount': int(groups.nunique()),
        'deploymentConflictingPatterns': int((conflicting > 1).sum()),
        'limitations': [
            'Small held-out sample, not clinical validation',
            'Only five disease labels; other conditions are outside coverage',
            'Conflicting symptom patterns cannot be resolved from these inputs alone',
            'Original preprocessing and dataset collection could not be audited',
            'Leaf distributions are not calibrated medical probabilities',
            'The deployment tree is refitted on all rows after evaluation; reported test metrics remain from the separate hold-out split',
        ],
    }

    # Refit a deployment model on all validated rows only AFTER evaluation.
    # This avoids shipping a model that has deliberately discarded 20% of
    # known examples. The test metrics above remain independent of this fit.
    deployment_model = DecisionTreeClassifier(
        random_state=42, **search.best_params_
    )
    deployment_model.fit(data[FEATURES], data['disease'])
    deployment_labels = deployment_model.classes_.tolist()
    patterns = build_pattern_metadata(data)

    export = {
        'schemaVersion': 1,
        'modelVersion': 'symptom-demo-v2',
        'educationalOnly': True,
        'features': FEATURES,
        'classes': deployment_labels,
        'nodes': export_tree(deployment_model),
        # Full validated dataset patterns are used for app lookup. Conflicting
        # labels remain arrays with multiple values and are rejected by Dart.
        'trainingPatterns': patterns,
        'evaluation': report,
        'datasetSha256': hashlib.sha256(source_path.read_bytes()).hexdigest(),
        'sklearnVersion': sklearn.__version__,
    }

    # Verify every possible input, including combinations not seen in training.
    vectors = np.array([[int(bit) for bit in f'{i:010b}'] for i in range(1024)])
    expected = deployment_model.predict(pd.DataFrame(vectors, columns=FEATURES))
    expected_ids = [deployment_labels.index(label) for label in expected]
    actual = [tree_predict(export, vector) for vector in vectors]
    if actual != expected_ids:
        raise AssertionError('Exported tree differs from sklearn.')

    outputs = [
        (output, export),
        (report_path, report),
        (parity_path, {
            'features': FEATURES,
            'classes': deployment_labels,
            'predictions': expected_ids,
        }),
    ]
    for destination, value in outputs:
        destination = Path(destination)
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_text(
            json.dumps(value, indent=2, allow_nan=False) + '\n',
            encoding='utf-8',
        )

    print(json.dumps({
        key: report[key] for key in [
            'rawRows', 'exactDuplicateRowsRemoved', 'uniquePatterns',
            'conflictingPatterns', 'trainRows', 'testRows', 'bestParameters',
            'testAccuracy', 'testMacroF1', 'baselineAccuracy',
            'deploymentModelFitRows', 'deploymentPatternCount',
        ]
    }, indent=2))
    print('Deployment tree parity verified for all 1024 binary symptom combinations.')
    print('Educational use only; this model is not clinically validated.')
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
