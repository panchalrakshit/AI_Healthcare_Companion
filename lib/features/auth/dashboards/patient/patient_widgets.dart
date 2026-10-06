import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'patient_data.dart';

const patientPurple = Color(0xFF6335D6);
const patientInk = Color(0xFF28253F);
const patientMuted = Color(0xFF77748C);
const patientBackground = Color(0xFFF6F5FB);

class PatientPanel extends StatelessWidget {
  final String title, subtitle;
  final Widget child;
  final Widget? action;
  const PatientPanel({super.key, required this.title, this.subtitle = '', required this.child, this.action});
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFFE8E4F3))),
    child: Padding(padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: patientInk)), if (action != null) action!,
      ]),
      if (subtitle.isNotEmpty) ...[const SizedBox(height: 6), Text(subtitle, style: const TextStyle(fontSize: 12, color: patientMuted))],
      const SizedBox(height: 20), child,
    ])),
  );
}
class PatientEmpty extends StatelessWidget {
  final String message;
  final IconData icon;
  const PatientEmpty(this.message, {super.key, this.icon = Icons.insights_outlined});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 26), child: Column(children: [
    Icon(icon, size: 36, color: patientPurple), const SizedBox(height: 12), Text(message, textAlign: TextAlign.center, style: const TextStyle(color: patientMuted)),
  ]));
}
class PatientColumns extends StatelessWidget {
  final List<Widget> children;
  const PatientColumns({super.key, required this.children});
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
    final width = c.maxWidth >= 900 ? (c.maxWidth - 18) / 2 : c.maxWidth;
    return Wrap(spacing: 18, runSpacing: 18, children: children.map((child) => SizedBox(width: width, child: child)).toList());
  });
}
class PatientStatus extends StatelessWidget {
  final String status;
  const PatientStatus(this.status, {super.key});
  @override
  Widget build(BuildContext context) {
    final color = status == 'cancelled' ? Colors.redAccent : status == 'pending' ? const Color(0xFFBA7A13) : const Color(0xFF008F7B);
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: .09), borderRadius: BorderRadius.circular(8)),
      child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color)));
  }
}

class PatientInsights extends StatefulWidget {
  final PatientStats stats;
  final ValueChanged<int> onRange;
  const PatientInsights({super.key, required this.stats, required this.onRange});
  @override
  State<PatientInsights> createState() => _PatientInsightsState();
}
class _PatientInsightsState extends State<PatientInsights> {
  String _metric = 'heartRate';
  int? _selected;
  @override
  Widget build(BuildContext context) {
    final stats = widget.stats;
    final metric = patientMetrics.firstWhere((m) => m.key == _metric);
    final points = stats.points(_metric);
    final chosen = points.isEmpty ? null : points[math.min(_selected ?? points.length - 1, points.length - 1)];
    final outcomes = stats.outcomes;
    final weekdays = stats.weekdays;
    final peak = weekdays.reduce(math.max);
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
        const Text('Your health patterns', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        ...[7, 30, 90].map((d) => ChoiceChip(label: Text('$d days'), selected: stats.days == d, onSelected: (_) { setState(() => _selected = null); widget.onRange(d); })),
      ]),
      const SizedBox(height: 18),
      PatientPanel(title: 'Recorded readings', subtitle: 'Only dated readings you saved are plotted. Tap the chart to inspect a reading.', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 8, runSpacing: 8, children: patientMetrics.map((m) => ChoiceChip(label: Text(m.label), selected: _metric == m.key,
          onSelected: (_) => setState(() { _metric = m.key; _selected = null; }))).toList()),
        const SizedBox(height: 20),
        if (points.isEmpty) const PatientEmpty('No readings for this metric in the selected period. Add a reading to begin your history.')
        else ...[
          Text('${chosen!.value.toStringAsFixed(1)} ${metric.unit}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: patientPurple)),
          Text('${patientDateLabel(chosen.date)} • ${points.length} saved readings', style: const TextStyle(color: patientMuted)),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, c) => Semantics(label: '${metric.label} chart, ${points.length} readings. Selected ${chosen.value} ${metric.unit}.',
            child: GestureDetector(onTapDown: (event) {
              if (points.length == 1) { setState(() => _selected = 0); return; }
              final first = points.first.date.millisecondsSinceEpoch;
              final span = points.last.date.millisecondsSinceEpoch - first;
              final ratio = ((event.localPosition.dx - 16) / math.max(1, c.maxWidth - 32)).clamp(0.0, 1.0);
              final target = first + span * ratio;
              var nearest = 0;
              for (var i = 1; i < points.length; i++) {
                if ((points[i].date.millisecondsSinceEpoch - target).abs() < (points[nearest].date.millisecondsSinceEpoch - target).abs()) nearest = i;
              }
              setState(() => _selected = nearest);
            }, child: SizedBox(height: 190, width: double.infinity, child: CustomPaint(painter: _VitalPainter(points, points.indexOf(chosen))))))),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(patientDateLabel(points.first.date), style: const TextStyle(fontSize: 10)), Text(patientDateLabel(points.last.date), style: const TextStyle(fontSize: 10))]),
          const SizedBox(height: 12), Text('Observed range: ${points.map((p) => p.value).reduce(math.min).toStringAsFixed(1)}–${points.map((p) => p.value).reduce(math.max).toStringAsFixed(1)} ${metric.unit}. This describes saved measurements; it is not a diagnosis.', style: const TextStyle(fontSize: 12, color: patientMuted)),
        ],
      ])),
      const SizedBox(height: 18),
      PatientColumns(children: [
        PatientPanel(title: 'Appointment outcomes', subtitle: '${stats.period.length} scheduled visits in this period', child: outcomes.isEmpty ? const PatientEmpty('No appointments in this period.') : Column(children: outcomes.entries.map((e) => Padding(padding: const EdgeInsets.only(bottom: 16), child: Column(children: [
          Row(children: [Expanded(child: PatientStatus(e.key)), Text('${e.value} visits')]), const SizedBox(height: 8),
          LinearProgressIndicator(value: e.value / stats.period.length, minHeight: 9, borderRadius: BorderRadius.circular(8), color: patientPurple, backgroundColor: patientBackground),
        ]))).toList())),
        PatientPanel(title: 'Weekly visit pattern', subtitle: peak == 0 ? 'No pattern yet' : '${names[weekdays.indexOf(peak)]} has the most scheduled visits', child: Row(children: List.generate(7, (i) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: Column(children: [
          Tooltip(message: '${names[i]}: ${weekdays[i]} visits', child: Container(height: 64, alignment: Alignment.center,
            decoration: BoxDecoration(color: Color.lerp(const Color(0xFFF0EBFD), patientPurple, peak == 0 ? 0 : weekdays[i] / peak), borderRadius: BorderRadius.circular(9)),
            child: Text('${weekdays[i]}', style: TextStyle(fontWeight: FontWeight.bold, color: peak > 0 && weekdays[i] / peak > .5 ? Colors.white : patientPurple)))),
          const SizedBox(height: 8), Text(names[i], style: const TextStyle(fontSize: 9)),
        ])))))),
      ]),
    ]);
  }
}
class _VitalPainter extends CustomPainter {
  final List<VitalPoint> points;
  final int selected;
  _VitalPainter(this.points, this.selected);
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()..color = const Color(0xFFEDE9F5)..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) { final y = 12 + (size.height - 24) * i / 4; canvas.drawLine(Offset(16, y), Offset(size.width - 16, y), grid); }
    final low = points.map((p) => p.value).reduce(math.min);
    final high = points.map((p) => p.value).reduce(math.max);
    final padding = math.max((high - low) * .15, 1.0);
    final first = points.first.date.millisecondsSinceEpoch;
    final span = points.last.date.millisecondsSinceEpoch - first;
    Offset pos(VitalPoint p) => Offset(span == 0 ? size.width / 2 : 16 + (size.width - 32) * (p.date.millisecondsSinceEpoch - first) / span,
      size.height - 12 - (size.height - 24) * (p.value - low + padding) / (high - low + padding * 2));
    final path = Path()..moveTo(pos(points.first).dx, pos(points.first).dy);
    for (final p in points.skip(1)) { path.lineTo(pos(p).dx, pos(p).dy); }
    if (points.length > 1) {
      final fill = Path.from(path)..lineTo(pos(points.last).dx, size.height - 12)..lineTo(pos(points.first).dx, size.height - 12)..close();
      canvas.drawPath(fill, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x446335D6), Color(0x006335D6)]).createShader(Offset.zero & size));
    }
    canvas.drawPath(path, Paint()..color = patientPurple..strokeWidth = 3..style = PaintingStyle.stroke);
    for (var i = 0; i < points.length; i++) {
      canvas.drawCircle(pos(points[i]), i == selected ? 7 : 3, Paint()..color = i == selected ? const Color(0xFF08A995) : patientPurple);
    }
  }
  @override
  bool shouldRepaint(covariant _VitalPainter oldDelegate) => oldDelegate.points != points || oldDelegate.selected != selected;
}
