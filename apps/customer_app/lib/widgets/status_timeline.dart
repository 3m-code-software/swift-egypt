import 'package:flutter/material.dart';
import 'package:swift_egypt_shared/swift_egypt_shared.dart';
import '../core/theme.dart';

class StatusTimeline extends StatelessWidget {
  final List<TrackingEvent> events;

  const StatusTimeline({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const SizedBox.shrink();
    }

    final sorted = List<TrackingEvent>.from(events)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return Column(
      children: List.generate(sorted.length, (i) {
        final event = sorted[i];
        final isLast = i == sorted.length - 1;
        final statusIcons = {
          TrackingEventType.created: Icons.add_circle_outline,
          TrackingEventType.statusChanged: Icons.swap_horiz,
          TrackingEventType.locationUpdate: Icons.location_on,
          TrackingEventType.documentUploaded: Icons.description,
          TrackingEventType.paymentUpdated: Icons.payment,
          TrackingEventType.assigned: Icons.person,
          TrackingEventType.noteAdded: Icons.note_add,
        };

        final isCompleted = true;
        final icon = statusIcons[event.eventType] ?? Icons.circle;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 40,
                child: Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppTheme.accentGreen.withValues(alpha: 0.15)
                            : Colors.grey.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isCompleted ? AppTheme.accentGreen : Colors.grey,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        icon,
                        size: 16,
                        color: isCompleted ? AppTheme.accentGreen : Colors.grey,
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: isCompleted
                              ? AppTheme.accentGreen.withValues(alpha: 0.3)
                              : Colors.grey.withValues(alpha: 0.2),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.description ?? event.eventType.name,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      if (event.location != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 13, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Text(event.location!, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          ],
                        ),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(event.createdAt),
                        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
