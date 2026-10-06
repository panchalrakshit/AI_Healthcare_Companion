import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'doctor_data.dart';

class DoctorInsights extends StatelessWidget {
  final DoctorStats stats;
  final ValueChanged<int> onRange;
  const DoctorInsights({super.key, required this.stats, required this.onRange});
  @override
  Widget build(BuildContext context) {
    final values = stats.trend;
    final maxCount = math.max(1, values.reduce(math.max));
    final weekdays = stats.weekdays;
    final peak = weekdays.reduce(math.max);
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final outcomes = stats.outcomes;
    final total = stats.period.length;
    final completed = outcomes['completed'] ?? 0;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 18, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
        const Text('Practice insights', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
        ...[7, 30, 90].map((d) => ChoiceChip(label: Text('$d days'), selected: stats.days == d, onSelected: (_) => onRange(d))),
      ]),
      const SizedBox(height: 18),
      LayoutBuilder(builder: (context, c) {
        final width = c.maxWidth >= 850 ? (c.maxWidth - 16) / 2 : c.maxWidth;
        return Wrap(spacing: 16, runSpacing: 16, children: [
          SizedBox(width: width, child: _panel('Appointment activity', 'Scheduled dates • $total appointments', [
            if (total == 0) const Padding(padding: EdgeInsets.all(20), child: Text('No appointments in this period.'))
            else SizedBox(height: 190, child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: SizedBox(
              width: math.max(width - 44, values.length * 42.0), child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: List.generate(values.length, (i) {
              final date = stats.start.add(Duration(days: i * (stats.days ~/ values.length)));
              return Expanded(child: Tooltip(message: '${date.day}/${date.month}: ${values[i]} appointments', child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3), child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Text('${values[i]}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), const SizedBox(height: 4),
                  AnimatedContainer(duration: const Duration(milliseconds: 300), height: 130 * values[i] / maxCount + 2,
                    decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF18B8A6), Color(0xFF087A78)]), borderRadius: BorderRadius.circular(5))),
                  const SizedBox(height: 7), Text('${date.day}/${date.month}', maxLines: 1, style: const TextStyle(fontSize: 9, color: Colors.grey)),
                ]),
              )));
            }))))),
          ])),
          SizedBox(width: width, child: _panel('Appointment outcomes', total == 0 ? 'No outcomes recorded' : '${(completed / total * 100).round()}% completed', [
            if (total == 0) const Text('No outcomes to display.')
            else ...outcomes.entries.map((e) => Padding(padding: const EdgeInsets.only(bottom: 16), child: Column(children: [
              Row(children: [Expanded(child: Text(e.key.toUpperCase(), style: const TextStyle(fontSize: 11))), Text('${e.value}')]),
              const SizedBox(height: 7), LinearProgressIndicator(value: e.value / total, minHeight: 10, borderRadius: BorderRadius.circular(8),
                backgroundColor: const Color(0xFFF0F4F6), color: e.key == 'cancelled' ? const Color(0xFFEC7E85) : e.key == 'pending' ? const Color(0xFFE7B24D) : const Color(0xFF0A948B)),
            ]))),
          ])),
          SizedBox(width: width, child: _panel('Weekly patterns', peak == 0 ? 'No pattern yet' : '${names[weekdays.indexOf(peak)]} is busiest • $peak visits', [
            Row(children: List.generate(7, (i) => Expanded(child: Padding(padding: const EdgeInsets.all(3), child: Column(children: [
              Tooltip(message: '${names[i]}: ${weekdays[i]} appointments', child: Container(height: 60, alignment: Alignment.center,
                decoration: BoxDecoration(color: Color.lerp(const Color(0xFFEAF5F2), const Color(0xFF078B82), peak == 0 ? 0 : weekdays[i] / peak), borderRadius: BorderRadius.circular(8)),
                child: Text('${weekdays[i]}', style: TextStyle(fontWeight: FontWeight.bold, color: peak > 0 && weekdays[i] / peak > .5 ? Colors.white : const Color(0xFF076E68))))),
              const SizedBox(height: 6), Text(names[i], style: const TextStyle(fontSize: 10)),
            ]))))),
          ])),
          SizedBox(width: width, child: _panel('Assessment priorities', 'Latest clinician-recorded priority for each assessed patient', [
            if (stats.latestAssessments.isEmpty) const Text('Save a patient assessment to see priority patterns.')
            else ...['high', 'medium', 'low'].map((priority) {
              final count = stats.latestAssessments.values.where((a) => a['priority'] == priority).length;
              return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [
                CircleAvatar(radius: 6, backgroundColor: priority == 'high' ? Colors.redAccent : priority == 'medium' ? Colors.amber : Colors.teal),
                const SizedBox(width: 10), Expanded(child: Text(priority.toUpperCase())), Text('$count'),
              ]));
            }),
            const SizedBox(height: 8), const Text('Priorities reflect saved assessments. They are not automated diagnoses.', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ])),
        ]);
      }),
    ]);
  }
  Widget _panel(String title, String subtitle, List<Widget> children) => Container(padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE3ECEB)), borderRadius: BorderRadius.circular(18)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)), const SizedBox(height: 5),
      Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)), const SizedBox(height: 22), ...children,
    ]));
}
