import 'package:flutter/material.dart';
import 'patient_data.dart';
import 'patient_widgets.dart';

class PatientRecords extends StatefulWidget {
  final List<Map<String, dynamic>> records;
  final VoidCallback onAdd;
  final ValueChanged<Map<String, dynamic>> onEdit, onDelete;
  const PatientRecords({super.key, required this.records, required this.onAdd, required this.onEdit, required this.onDelete});
  @override
  State<PatientRecords> createState() => _PatientRecordsState();
}
class _PatientRecordsState extends State<PatientRecords> {
  String _query = '', _type = 'All';
  @override
  Widget build(BuildContext context) {
    final types = {'All', ...widget.records.map((r) => r['recordType']?.toString() ?? 'Other')};
    final selectedType = types.contains(_type) ? _type : 'All';
    final records = widget.records.where((r) => (selectedType == 'All' || (r['recordType'] ?? 'Other') == selectedType)
      && '${r['title'] ?? ''} ${r['doctorName'] ?? ''} ${r['hospitalName'] ?? ''} ${r['description'] ?? ''}'.toLowerCase().contains(_query)).toList();
    return PatientPanel(title: 'Your health records', subtitle: '${widget.records.length} saved records • stored in your Firebase account',
      action: FilledButton.icon(onPressed: widget.onAdd, icon: const Icon(Icons.add, size: 18), label: const Text('Add record')),
      child: Column(children: [
        TextField(onChanged: (v) => setState(() => _query = v.trim().toLowerCase()), decoration: InputDecoration(hintText: 'Search records, doctor or clinic', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
        const SizedBox(height: 12), Align(alignment: Alignment.centerLeft, child: Wrap(spacing: 7, runSpacing: 7, children: types.map((t) => ChoiceChip(label: Text(t), selected: selectedType == t, onSelected: (_) => setState(() => _type = t))).toList())),
        const SizedBox(height: 18),
        if (records.isEmpty) const PatientEmpty('No matching records. Add a record or change your filters.', icon: Icons.folder_outlined)
        else ...records.map((r) => Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: patientBackground, borderRadius: BorderRadius.circular(14)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.description_outlined, color: patientPurple), const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r['title']?.toString() ?? 'Untitled record', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 5), Text('${r['recordType'] ?? 'Other'} • ${patientDateLabel(r['recordDate'])}', style: const TextStyle(color: patientMuted, fontSize: 12)),
              ])),
              PopupMenuButton<String>(onSelected: (v) => v == 'edit' ? widget.onEdit(r) : widget.onDelete(r), itemBuilder: (_) => [
                if (r['vitals'] is! Map) const PopupMenuItem(value: 'edit', child: Text('Edit record')),
                const PopupMenuItem(value: 'delete', child: Text('Delete record')),
              ]),
            ]),
            if ('${r['doctorName'] ?? ''}${r['hospitalName'] ?? ''}'.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Text([r['doctorName'], r['hospitalName']].where((v) => v != null && '$v'.isNotEmpty).join(' • '))),
            if ((r['description'] ?? '').toString().isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10), child: Text('${r['description']}')),
            if (r['vitals'] is Map) Padding(padding: const EdgeInsets.only(top: 12), child: Wrap(spacing: 8, runSpacing: 8,
              children: (r['vitals'] as Map).entries.map((e) => Chip(label: Text('${e.key}: ${e.value}', style: const TextStyle(fontSize: 11)))).toList())),
          ]))),
      ]));
  }
}
