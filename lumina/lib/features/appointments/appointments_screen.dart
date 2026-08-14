import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../shared/services/notification_service.dart';
import '../../shared/storage/appointment.dart';
import '../../shared/utils/thai_date.dart';
import 'appointment_editor.dart';
import 'appointments_provider.dart';

/// หน้ารายการนัดหมายแพทย์ (ข้อ 1)
class AppointmentsScreen extends ConsumerWidget {
  const AppointmentsScreen({super.key});

  Future<void> _openEditor(BuildContext context, WidgetRef ref,
      {Appointment? existing}) async {
    // ขอสิทธิ์แจ้งเตือนก่อนเพิ่มนัดครั้งแรก
    await NotificationService().requestPermission();
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AppointmentEditor(existing: existing),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Appointment a) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('ลบนัดหมาย?'),
        content: Text('ต้องการลบ "${a.title}" หรือไม่'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(appointmentsProvider.notifier).remove(a.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(appointmentsProvider);
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('นัดหมายแพทย์')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('เพิ่มนัด', style: TextStyle(fontSize: 18)),
      ),
      body: items.isEmpty
          ? _EmptyState(onAdd: () => _openEditor(context, ref))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final a = items[index];
                final isPast = a.dateTime.isBefore(now);
                return _AppointmentCard(
                  appt: a,
                  isPast: isPast,
                  onTap: () => _openEditor(context, ref, existing: a),
                  onDelete: () => _confirmDelete(context, ref, a),
                );
              },
            ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.appt,
    required this.isPast,
    required this.onTap,
    required this.onDelete,
  });

  final Appointment appt;
  final bool isPast;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppTheme.darkPrimary : AppTheme.primary;
    final secondary =
        isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    final hh = appt.dateTime.hour.toString().padLeft(2, '0');
    final mm = appt.dateTime.minute.toString().padLeft(2, '0');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Opacity(
          opacity: isPast ? 0.55 : 1,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.event_available_rounded,
                      color: primary, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(appt.title,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text('${formatThaiDate(appt.dateTime)}  $hh:$mm น.',
                          style: TextStyle(fontSize: 16, color: secondary)),
                      if (appt.location.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(appt.location,
                            style: TextStyle(fontSize: 15, color: secondary)),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.notifications_active_rounded,
                              size: 16, color: primary),
                          const SizedBox(width: 4),
                          Text(appt.reminder.label,
                              style: TextStyle(fontSize: 14, color: primary)),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppTheme.error),
                  tooltip: 'ลบ',
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note_rounded,
                size: 80,
                color: (isDark ? AppTheme.darkPrimary : AppTheme.primary)
                    .withAlpha(120)),
            const SizedBox(height: 24),
            Text('ยังไม่มีนัดหมาย',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(
              'เพิ่มนัดหมายแพทย์\nแล้วแอปจะเตือนก่อนถึงเวลา',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
                label: const Text('เพิ่มนัดหมายแรก'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
