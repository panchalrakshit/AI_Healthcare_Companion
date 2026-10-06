import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

DateTime? adminDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return value is String ? DateTime.tryParse(value) : null;
}

class AdminAnalytics extends StatelessWidget {
  final List<Map<String, dynamic>> appointments;
  final List<Map<String, dynamic>> users;
  final int days;
  final ValueChanged<int> onDaysChanged;
  const AdminAnalytics({super.key, required this.appointments, required this.users,
    required this.days, required this.onDaysChanged});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(Duration(days: days - 1));
    final end = today.add(const Duration(days: 1));
    final scoped = appointments.where((a) {
      final d = adminDate(a['appointmentDate']);
      return d != null && !d.isBefore(start) && d.isBefore(end);
    }).toList();
    final bucketCount = days == 7 ? 7 : (days == 30 ? 10 : 9);
    final bucketDays = days ~/ bucketCount;
    final counts = List<int>.filled(bucketCount, 0);
    final weekdays = List<int>.filled(7, 0);
    final statuses = <String, int>{};
    final specialties = <String, int>{};
    for (final a in scoped) {
      final d = adminDate(a['appointmentDate'])!;
      final localDay = DateTime(d.year, d.month, d.day);
      final offset = DateTime.utc(localDay.year, localDay.month, localDay.day)
          .difference(DateTime.utc(start.year, start.month, start.day)).inDays;
      counts[math.min(bucketCount - 1, offset ~/ bucketDays)]++;
      weekdays[d.weekday - 1]++;
      final status = (a['status'] ?? 'pending').toString().toLowerCase();
      statuses[status] = (statuses[status] ?? 0) + 1;
      final specialty = (a['specialization'] ?? 'Unspecified').toString();
      specialties[specialty] = (specialties[specialty] ?? 0) + 1;
    }
    final top = specialties.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final recentUsers = users.where((u) {
      final d = adminDate(u['createdAt']);
      return d != null && !d.isBefore(start) && d.isBefore(end);
    }).length;
    final rate = scoped.isEmpty ? 0 : ((statuses['completed'] ?? 0) / scoped.length * 100).round();
    const weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final peak = weekdays.reduce(math.max);
    final peakDay = peak == 0 ? 'No appointments in this period' : '${weekdayNames[weekdays.indexOf(peak)]} is busiest ($peak appointments)';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(alignment: WrapAlignment.spaceBetween, spacing: 20, runSpacing: 10, children: [
        const Text('Activity & patterns', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        Wrap(spacing: 8, children: [7, 30, 90].map((d) => ChoiceChip(
          label: Text('Last $d days'), selected: days == d,
          onSelected: (_) => onDaysChanged(d),
        )).toList()),
      ]),
      const SizedBox(height: 16),
      LayoutBuilder(builder: (context, c) {
        final width = c.maxWidth > 900 ? (c.maxWidth - 18) / 2 : c.maxWidth;
        return Wrap(spacing: 18, runSpacing: 18, children: [
          SizedBox(width: width, child: _panel('Appointment trend', 'By scheduled date • ${bucketDays == 1 ? 'daily' : '$bucketDays-day buckets'}', [
            if (scoped.isEmpty) const Padding(padding: EdgeInsets.all(20), child: Text('No appointments in this period.'))
            else ...[
              SizedBox(height: 150, width: double.infinity, child: CustomPaint(painter: _TrendPainter(counts))),
              const SizedBox(height: 12),
              Row(children: List.generate(bucketCount, (i) {
                final d = start.add(Duration(days: bucketDays * i));
                return Expanded(child: Tooltip(message: '${d.day}/${d.month}: ${counts[i]} appointments',
                  child: Column(children: [Text('${counts[i]}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text('${d.day}/${d.month}', style: const TextStyle(fontSize: 10, color: Colors.grey))])));
              })),
            ],
          ])),
          SizedBox(width: width, child: _panel('Appointment outcomes', '${scoped.length} appointments in selected period', [
            if (scoped.isEmpty) const Padding(padding: EdgeInsets.all(20), child: Text('No outcomes to display.'))
            else Wrap(spacing: 22, runSpacing: 14, crossAxisAlignment: WrapCrossAlignment.center, children: [
              SizedBox(width: 145, height: 145, child: Stack(alignment: Alignment.center, children: [
                Positioned.fill(child: CustomPaint(painter: _DonutPainter(statuses))),
                Column(mainAxisSize: MainAxisSize.min, children: [Text('$rate%', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)), const Text('completed', style: TextStyle(fontSize: 11, color: Colors.grey))]),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: statuses.entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5), child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: _statusColor(e.key), shape: BoxShape.circle)),
                  const SizedBox(width: 8), Text('${e.key}: ${e.value}'),
                ]),
              )).toList()),
            ]),
          ])),
          SizedBox(width: width, child: _panel('Specialization demand', 'Top specialties in selected period', [
            if (top.isEmpty) const Text('No specialization data yet.'),
            ...top.take(5).map((e) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Column(children: [
              Row(children: [Expanded(child: Text(e.key)), Text('${e.value}')]),
              const SizedBox(height: 6),
              LinearProgressIndicator(value: e.value / top.first.value, minHeight: 8, borderRadius: BorderRadius.circular(6), color: const Color(0xFF7352D6), backgroundColor: const Color(0xFFEDE8F9)),
            ]))),
          ])),
          SizedBox(width: width, child: _panel('Weekly patterns', peakDay, [
            Row(children: List.generate(7, (i) => Expanded(child: Padding(padding: const EdgeInsets.all(3), child: Tooltip(
              message: '${weekdayNames[i]}: ${weekdays[i]} appointments',
              child: Column(children: [Container(height: 56, alignment: Alignment.center,
                decoration: BoxDecoration(color: Color.lerp(const Color(0xFFF0ECFA), const Color(0xFF6335D6), peak == 0 ? 0 : weekdays[i] / peak), borderRadius: BorderRadius.circular(9)),
                child: Text('${weekdays[i]}', style: TextStyle(fontWeight: FontWeight.w800, color: peak > 0 && weekdays[i] / peak > .5 ? Colors.white : const Color(0xFF6335D6)))),
                const SizedBox(height: 5), Text(weekdayNames[i], style: const TextStyle(fontSize: 10))]),
            ))))),
            const SizedBox(height: 20),
            Text('$recentUsers new accounts • $rate% completed', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 5),
            const Text('Account growth uses createdAt. Records without a date are excluded from trends.', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ])),
        ]);
      }),
    ]);
  }

  Widget _panel(String title, String subtitle, List<Widget> children) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE8E4EF))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), const SizedBox(height: 5),
      Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)), const SizedBox(height: 22), ...children,
    ]),
  );
}

Color _statusColor(String status) => switch (status) {
  'completed' => const Color(0xFF16A085), 'confirmed' => const Color(0xFF7352D6),
  'cancelled' => const Color(0xFFED7180), 'pending' => const Color(0xFFF1B34B), _ => const Color(0xFF8092AC),
};

class _TrendPainter extends CustomPainter {
  final List<int> values;
  _TrendPainter(this.values);
  @override
  void paint(Canvas canvas, Size size) {
    final maxValue = math.max(1, values.reduce(math.max));
    final grid = Paint()..color = const Color(0xFFEDEBF3)..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = 10 + (size.height - 20) * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final points = List.generate(values.length, (i) => Offset(
      6 + (size.width - 12) * i / (values.length - 1),
      size.height - 10 - values[i] / maxValue * (size.height - 20)));
    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) { line.lineTo(point.dx, point.dy); }
    final fill = Path.from(line)..lineTo(points.last.dx, size.height)..lineTo(points.first.dx, size.height)..close();
    canvas.drawPath(fill, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [Color(0x447352D6), Color(0x007352D6)]).createShader(Offset.zero & size));
    canvas.drawPath(line, Paint()..color = const Color(0xFF7352D6)..strokeWidth = 3..style = PaintingStyle.stroke..strokeJoin = StrokeJoin.round);
    for (final point in points) { canvas.drawCircle(point, 4, Paint()..color = const Color(0xFF7352D6)); }
  }
  @override
  bool shouldRepaint(covariant _TrendPainter old) => old.values != values;
}

class _DonutPainter extends CustomPainter {
  final Map<String, int> values;
  _DonutPainter(this.values);
  @override
  void paint(Canvas canvas, Size size) {
    final total = values.values.fold(0, (a, b) => a + b);
    if (total == 0) return;
    final rect = Rect.fromLTWH(10, 10, size.width - 20, size.height - 20);
    double start = -math.pi / 2;
    for (final e in values.entries) {
      final sweep = e.value / total * math.pi * 2;
      canvas.drawArc(rect, start, math.max(0, sweep - .035), false,
        Paint()..color = _statusColor(e.key)..strokeWidth = 16..style = PaintingStyle.stroke);
      start += sweep;
    }
  }
  @override
  bool shouldRepaint(covariant _DonutPainter old) => old.values != values;
}
