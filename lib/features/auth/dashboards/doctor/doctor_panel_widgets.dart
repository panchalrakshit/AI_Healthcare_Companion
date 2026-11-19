import 'package:flutter/material.dart';

const _doctorAccent = Color(0xFF087B75);
const _doctorBorder = Color(0xFFE1ECE9);

class DoctorPatientCard extends StatelessWidget {
  final String name;
  final String email;
  final int appointmentCount;
  final String accessHint;
  final VoidCallback? onOpen;

  const DoctorPatientCard({
    super.key,
    required this.name,
    required this.email,
    required this.appointmentCount,
    required this.accessHint,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _doctorBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFE2F4F0),
                  child: Icon(Icons.person_outline, color: _doctorAccent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (email.trim().isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          email,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '$appointmentCount visits',
                    textAlign: TextAlign.end,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _doctorAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (onOpen != null)
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: onOpen,
                  icon: const Icon(Icons.folder_shared_outlined, size: 18),
                  label: const Text('Open patient workspace'),
                ),
              )
            else
              Text(
                accessHint,
                softWrap: true,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
          ],
        ),
      );
}

class DoctorAssessmentCard extends StatelessWidget {
  final String patientName;
  final String notes;
  final String updatedLabel;
  final String priority;
  final VoidCallback onTap;

  const DoctorAssessmentCard({
    super.key,
    required this.patientName,
    required this.notes,
    required this.updatedLabel,
    required this.priority,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _doctorBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        patientName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _PriorityLabel(value: priority),
                  ],
                ),
                if (notes.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    notes,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  updatedLabel,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 4),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Icon(
                    Icons.open_in_new,
                    size: 16,
                    color: _doctorAccent,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class DoctorFollowUpCard extends StatelessWidget {
  final String patientName;
  final String dueLabel;
  final VoidCallback onOpenAssessments;

  const DoctorFollowUpCard({
    super.key,
    required this.patientName,
    required this.dueLabel,
    required this.onOpenAssessments,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _doctorBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.event_repeat, color: Colors.orange),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Follow-up: $patientName',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                Text(
                  'Due $dueLabel',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                TextButton(
                  onPressed: onOpenAssessments,
                  child: const Text('View assessment'),
                ),
              ],
            ),
          ],
        ),
      );
}

class _PriorityLabel extends StatelessWidget {
  final String value;
  const _PriorityLabel({required this.value});

  @override
  Widget build(BuildContext context) {
    final normalized = value.toLowerCase();
    final color = normalized == 'high'
        ? Colors.redAccent
        : normalized == 'medium'
            ? Colors.orange
            : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        normalized.toUpperCase(),
        maxLines: 1,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
