import 'package:flutter/material.dart';

class AdminAppointmentCard extends StatelessWidget {
  final String patientName;
  final String doctorName;
  final String status;
  final String dateLabel;
  final String reason;
  final bool compact;
  final bool busy;
  final ValueChanged<String> onAction;

  const AdminAppointmentCard({
    super.key,
    required this.patientName,
    required this.doctorName,
    required this.status,
    required this.dateLabel,
    required this.reason,
    required this.onAction,
    this.compact = false,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedStatus = status.toLowerCase();
    final details = dateLabel + (reason.trim().isEmpty ? '' : ' • $reason');

    Widget statusLabel() {
      final color = ['active', 'confirmed', 'completed'].contains(normalizedStatus)
          ? const Color(0xFF168A62)
          : ['suspended', 'cancelled'].contains(normalizedStatus)
              ? const Color(0xFFC74747)
              : const Color(0xFFB7791F);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(.10),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          normalizedStatus.toUpperCase(),
          maxLines: 1,
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800),
        ),
      );
    }

    Widget actions() => PopupMenuButton<String>(
          enabled: !busy,
          tooltip: 'Appointment actions',
          onSelected: onAction,
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'pending', child: Text('Mark pending')),
            PopupMenuItem(value: 'confirmed', child: Text('Confirm')),
            PopupMenuItem(value: 'completed', child: Text('Mark completed')),
            PopupMenuItem(value: 'cancelled', child: Text('Cancel')),
            PopupMenuDivider(),
            PopupMenuItem(value: 'delete', child: Text('Delete appointment')),
          ],
        );

    Widget leading() => const CircleAvatar(
          backgroundColor: Color(0xFFEFE7FF),
          child: Icon(Icons.calendar_today, color: Color(0xFF6335D6), size: 20),
        );

    Widget title() => Text(
          '$patientName → $doctorName',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        );

    Widget detailText() => Text(
          details,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: Color(0xFF777384)),
        );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: compact
          ? null
          : BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFFE8E4EF)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(.025), blurRadius: 12, offset: const Offset(0, 5)),
              ],
            ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 540;
          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    leading(),
                    const SizedBox(width: 12),
                    Expanded(child: title()),
                    const SizedBox(width: 8),
                    statusLabel(),
                  ],
                ),
                const SizedBox(height: 10),
                Padding(padding: const EdgeInsets.only(left: 52), child: detailText()),
                if (!compact)
                  Align(
                    alignment: Alignment.centerRight,
                    child: busy
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                          )
                        : actions(),
                  ),
              ],
            );
          }

          return Row(
            children: [
              leading(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [title(), const SizedBox(height: 4), detailText()],
                ),
              ),
              const SizedBox(width: 10),
              statusLabel(),
              if (!compact) ...[
                const SizedBox(width: 8),
                busy
                    ? const SizedBox(width: 40, height: 24, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
                    : actions(),
              ],
            ],
          );
        },
      ),
    );
  }
}
