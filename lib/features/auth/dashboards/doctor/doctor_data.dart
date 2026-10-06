import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

typedef DoctorDoc = QueryDocumentSnapshot<Map<String, dynamic>>;

DateTime? doctorDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return value is String ? DateTime.tryParse(value) : null;
}

bool sameDoctorDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

List<String> doctorNextStatuses(String status) => switch (status) {
  'pending' => ['confirmed', 'cancelled'],
  'confirmed' => ['completed', 'cancelled'],
  _ => [],
};

class DoctorStats {
  final List<Map<String, dynamic>> appointments;
  final List<Map<String, dynamic>> assessments;
  final DateTime now;
  final int days;
  DoctorStats(this.appointments, this.assessments, {required this.now, this.days = 30});
  DateTime get start => DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1));
  List<Map<String, dynamic>> get period => appointments.where((a) {
    final date = doctorDate(a['appointmentDate']);
    return date != null && !date.isBefore(start) && date.isBefore(DateTime(now.year, now.month, now.day + 1));
  }).toList();
  int get patientCount => appointments.where((a) => a['status'] != 'cancelled')
    .map((a) => a['patientId']).whereType<String>().where((id) => id.isNotEmpty).toSet().length;
  int get todayCount => appointments.where((a) {
    final date = doctorDate(a['appointmentDate']);
    return date != null && sameDoctorDay(date, now) && a['status'] != 'cancelled';
  }).length;
  Map<String, int> get outcomes {
    final counts = <String, int>{};
    for (final a in period) {
      final key = (a['status'] ?? 'pending').toString();
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }
  Map<String, Map<String, dynamic>> get latestAssessments {
    final sorted = [...assessments]..sort((a, b) => (doctorDate(a['updatedAt']) ?? doctorDate(a['createdAt']) ?? DateTime(1970))
      .compareTo(doctorDate(b['updatedAt']) ?? doctorDate(b['createdAt']) ?? DateTime(1970)));
    return {for (final a in sorted) if (a['patientId'] is String) a['patientId'] as String: a};
  }
  int get highPriority => latestAssessments.values.where((a) => a['priority'] == 'high').length;
  List<int> get weekdays {
    final result = List<int>.filled(7, 0);
    for (final a in period) { result[doctorDate(a['appointmentDate'])!.weekday - 1]++; }
    return result;
  }
  List<int> get trend {
    final count = days == 7 ? 7 : days == 30 ? 10 : 9;
    final width = days ~/ count;
    final result = List<int>.filled(count, 0);
    for (final a in period) {
      final d = doctorDate(a['appointmentDate'])!;
      final offset = DateTime.utc(d.year, d.month, d.day).difference(DateTime.utc(start.year, start.month, start.day)).inDays;
      result[(offset ~/ width).clamp(0, count - 1)]++;
    }
    return result;
  }
}

class DoctorRepository {
  final FirebaseFirestore db;
  final String uid;
  DoctorRepository(this.db, this.uid);

  Stream<List<DoctorDoc>> watchAppointments() {
    late StreamController<List<DoctorDoc>> controller;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? directory;
    var appointments = <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[];
    var generation = 0;
    controller = StreamController<List<DoctorDoc>>.broadcast(onListen: () {
      directory = db.collection('doctors').where('uid', isEqualTo: uid).snapshots().listen((snapshot) async {
        final epoch = ++generation;
        final old = appointments;
        appointments = [];
        for (final sub in old) { await sub.cancel(); }
        if (controller.isClosed || epoch != generation) return;
        final ids = {uid, ...snapshot.docs.map((d) => d.id)};
        final results = <String, List<DoctorDoc>>{};
        for (final id in ids) {
          final sub = db.collection('appointments').where('doctorId', isEqualTo: id).snapshots().listen((data) {
            if (controller.isClosed || epoch != generation) return;
            results[id] = data.docs;
            if (results.length != ids.length) return;
            final merged = <String, DoctorDoc>{};
            for (final docs in results.values) { for (final doc in docs) { merged[doc.id] = doc; } }
            final sorted = merged.values.toList()..sort((a, b) => (doctorDate(a.data()['appointmentDate']) ?? DateTime(1970))
              .compareTo(doctorDate(b.data()['appointmentDate']) ?? DateTime(1970)));
            controller.add(sorted);
          }, onError: (Object error) { if (!controller.isClosed && epoch == generation) controller.addError(error); });
          appointments.add(sub);
        }
      }, onError: (Object error) { if (!controller.isClosed) controller.addError(error); });
    }, onCancel: () {
      generation++;
      directory?.cancel();
      directory = null;
      final old = appointments;
      appointments = [];
      for (final sub in old) { sub.cancel(); }
    });
    return controller.stream;
  }

  Future<void> changeStatus(String appointmentId, String status) async {
    final ref = db.collection('appointments').doc(appointmentId);
    await db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) throw Exception('Appointment no longer exists.');
      final current = (snapshot.data()?['status'] ?? 'pending').toString();
      if (!doctorNextStatuses(current).contains(status)) throw Exception('The appointment changed. Refresh and try again.');
      transaction.update(ref, {'status': status, 'updatedAt': FieldValue.serverTimestamp()});
    });
  }

  Future<void> openCare(DoctorDoc appointment) async {
    final data = appointment.data();
    final patientId = data['patientId'] as String;
    await db.collection('doctorPatientAccess').doc('${uid}_$patientId').set({
      'doctorUid': uid, 'patientId': patientId, 'appointmentId': appointment.id,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
