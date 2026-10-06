import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? patientDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return value is String ? DateTime.tryParse(value) : null;
}
String patientDateLabel(dynamic value) {
  final d = patientDate(value);
  if (d == null) return 'Date unavailable';
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
double? patientNumber(dynamic value) {
  final n = value is num ? value.toDouble() : double.tryParse('$value');
  return n != null && n.isFinite ? n : null;
}

class PatientSnapshot {
  final Map<String, dynamic> user, profile;
  final List<Map<String, dynamic>> records, appointments;
  final Set<String> loading;
  final Map<String, String> errors;
  PatientSnapshot({this.user = const {}, this.profile = const {}, this.records = const [], this.appointments = const [], this.loading = const {}, this.errors = const {}});
}

// One subscription per source; cached streams survive dashboard navigation.
class PatientRepository {
  final FirebaseFirestore db;
  final String uid;
  final _controller = StreamController<PatientSnapshot>.broadcast();
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  Map<String, dynamic> _user = {}, _profile = {};
  List<Map<String, dynamic>> _records = [], _appointments = [];
  final Set<String> _loading = {'Profile', 'Vitals', 'Records', 'Appointments'};
  final Map<String, String> _errors = {};
  PatientRepository(this.db, this.uid) {
    _subscriptions.add(db.collection('users').doc(uid).snapshots().listen((s) {
      _user = s.data() ?? {}; _done('Profile');
    }, onError: (Object e) => _error('Profile', e)));
    _subscriptions.add(db.collection('healthProfiles').doc(uid).snapshots().listen((s) {
      _profile = s.data() ?? {}; _done('Vitals');
    }, onError: (Object e) => _error('Vitals', e)));
    _subscriptions.add(db.collection('healthRecords').where('patientId', isEqualTo: uid).snapshots().listen((s) {
      _records = s.docs.map((d) => {...d.data(), 'id': d.id}).toList(); _done('Records');
    }, onError: (Object e) => _error('Records', e)));
    _subscriptions.add(db.collection('appointments').where('patientId', isEqualTo: uid).snapshots().listen((s) {
      _appointments = s.docs.map((d) => {...d.data(), 'id': d.id}).toList(); _done('Appointments');
    }, onError: (Object e) => _error('Appointments', e)));
  }
  Stream<PatientSnapshot> get stream => _controller.stream;
  PatientSnapshot get current => PatientSnapshot(user: _user, profile: _profile, records: _records, appointments: _appointments,
    loading: Set.of(_loading), errors: Map.of(_errors));
  void _done(String source) { _loading.remove(source); _errors.remove(source); _emit(); }
  void _error(String source, Object e) {
    _loading.remove(source);
    _errors[source] = e is FirebaseException ? (e.message ?? e.code) : 'Unable to load data.';
    // Clear failed sources so old values cannot look like live information.
    switch (source) {
      case 'Profile': _user = {};
      case 'Vitals': _profile = {};
      case 'Records': _records = [];
      case 'Appointments': _appointments = [];
    }
    _emit();
  }
  void _emit() { if (!_controller.isClosed) _controller.add(current); }
  Future<void> dispose() async {
    await Future.wait(_subscriptions.map((s) => s.cancel()));
    await _controller.close();
  }
}

class VitalMetric {
  final String key, label, unit;
  const VitalMetric(this.key, this.label, this.unit);
}
const patientMetrics = [
  VitalMetric('heartRate', 'Heart rate', 'bpm'),
  VitalMetric('bloodSugar', 'Blood sugar', 'mg/dL'),
  VitalMetric('spo2', 'Oxygen saturation', '%'),
  VitalMetric('temperature', 'Temperature', '°C'),
  VitalMetric('weight', 'Weight', 'kg'),
];
class VitalPoint {
  final DateTime date;
  final double value;
  VitalPoint(this.date, this.value);
}
class PatientStats {
  final PatientSnapshot data;
  final DateTime now;
  final int days;
  PatientStats(this.data, {DateTime? now, this.days = 30}) : now = now ?? DateTime.now();
  DateTime get start => DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1));
  DateTime get end => DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
  bool inPeriod(DateTime d) => !d.isBefore(start) && d.isBefore(end) && !d.isAfter(now);
  List<Map<String, dynamic>> get period => data.appointments.where((a) {
    final d = patientDate(a['appointmentDate']); return d != null && !d.isBefore(start) && d.isBefore(end);
  }).toList();
  List<Map<String, dynamic>> get upcoming {
    final today = DateTime(now.year, now.month, now.day);
    final list = data.appointments.where((a) {
      final d = patientDate(a['appointmentDate']);
      return d != null && !d.isBefore(today) && ['pending', 'confirmed'].contains(a['status']);
    }).toList();
    list.sort((a, b) => patientDate(a['appointmentDate'])!.compareTo(patientDate(b['appointmentDate'])!));
    return list;
  }
  Map<String, int> get outcomes {
    final result = <String, int>{};
    for (final a in period) {
      final status = a['status']?.toString() ?? 'unknown';
      result[status] = (result[status] ?? 0) + 1;
    }
    return result;
  }
  List<int> get weekdays {
    final counts = List.filled(7, 0);
    for (final a in period) { counts[patientDate(a['appointmentDate'])!.weekday - 1]++; }
    return counts;
  }
  List<VitalPoint> points(String key) {
    final result = <VitalPoint>[];
    for (final record in data.records) {
      final raw = record['vitals'];
      if (raw is! Map) continue;
      final n = patientNumber(raw[key]);
      final d = patientDate(record['measuredAt'] ?? record['recordDate']);
      if (n != null && d != null && inPeriod(d)) result.add(VitalPoint(d, n));
    }
    result.sort((a, b) => a.date.compareTo(b.date));
    return result;
  }
  List<Map<String, dynamic>> get recentRecords {
    final list = [...data.records];
    list.sort((a, b) => (patientDate(b['recordDate']) ?? DateTime(1900)).compareTo(patientDate(a['recordDate']) ?? DateTime(1900)));
    return list;
  }
}
