import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../shared/storage/appointment.dart';
import '../../shared/utils/thai_date.dart';
import 'appointments_provider.dart';

/// หน้าเพิ่ม/แก้ไขนัดหมายแพทย์
class AppointmentEditor extends ConsumerStatefulWidget {
  const AppointmentEditor({super.key, this.existing});

  final Appointment? existing;

  @override
  ConsumerState<AppointmentEditor> createState() => _AppointmentEditorState();
}

class _AppointmentEditorState extends ConsumerState<AppointmentEditor> {
  late final TextEditingController _titleController;
  late final TextEditingController _locationController;
  late final TextEditingController _noteController;
  late DateTime _date;
  late TimeOfDay _time;
  late ReminderLead _reminder;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleController = TextEditingController(text: e?.title ?? '');
    _locationController = TextEditingController(text: e?.location ?? '');
    _noteController = TextEditingController(text: e?.note ?? '');
    final base = e?.dateTime ?? DateTime.now().add(const Duration(hours: 1));
    _date = DateTime(base.year, base.month, base.day);
    _time = TimeOfDay(hour: base.hour, minute: base.minute);
    _reminder = e?.reminder ?? ReminderLead.hour1;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  DateTime get _combined =>
      DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกหัวข้อนัดหมาย')),
      );
      return;
    }
    final notifier = ref.read(appointmentsProvider.notifier);
    if (widget.existing != null) {
      await notifier.update(widget.existing!.copyWith(
        title: title,
        dateTime: _combined,
        location: _locationController.text.trim(),
        note: _noteController.text.trim(),
        reminderMinutes: _reminder.minutes,
      ));
    } else {
      await notifier.add(
        title: title,
        dateTime: _combined,
        location: _locationController.text.trim(),
        note: _noteController.text.trim(),
        reminderMinutes: _reminder.minutes,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    final hh = _time.hour.toString().padLeft(2, '0');
    final mm = _time.minute.toString().padLeft(2, '0');

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'แก้ไขนัดหมาย' : 'เพิ่มนัดหมาย')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('หัวข้อนัดหมาย',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            style: const TextStyle(fontSize: 20),
            decoration: const InputDecoration(
              hintText: 'เช่น ตรวจเบาหวาน, พบหมอหัวใจ',
              prefixIcon: Icon(Icons.event_note_rounded),
            ),
          ),
          const SizedBox(height: 20),

          // วันที่ + เวลา
          Row(
            children: [
              Expanded(
                child: _PickerTile(
                  icon: Icons.calendar_today_rounded,
                  label: 'วันที่',
                  value: formatThaiDate(_date),
                  onTap: _pickDate,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PickerTile(
                  icon: Icons.access_time_rounded,
                  label: 'เวลา',
                  value: '$hh:$mm น.',
                  onTap: _pickTime,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Text('สถานที่ / แพทย์',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _locationController,
            style: const TextStyle(fontSize: 20),
            decoration: const InputDecoration(
              hintText: 'เช่น รพ.ศิริราช แผนกอายุรกรรม',
              prefixIcon: Icon(Icons.local_hospital_rounded),
            ),
          ),
          const SizedBox(height: 20),

          Text('เตือนล่วงหน้า',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: ReminderLead.values.map((r) {
              final selected = _reminder == r;
              return _ReminderChip(
                label: r.label,
                selected: selected,
                onTap: () => setState(() => _reminder = r),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          Text('บันทึกเพิ่มเติม',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            style: const TextStyle(fontSize: 18),
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'เช่น งดน้ำงดอาหารก่อนตรวจ',
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_rounded),
              label: const Text('บันทึกนัดหมาย'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppTheme.darkPrimary : AppTheme.primary;
    final secondary =
        isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: primary),
                const SizedBox(width: 6),
                Text(label, style: TextStyle(fontSize: 14, color: secondary)),
              ],
            ),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _ReminderChip extends StatelessWidget {
  const _ReminderChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppTheme.darkPrimary : AppTheme.primary;
    final textColor = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;

    return Material(
      color: selected ? primary.withAlpha(20) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? primary
                  : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
              width: selected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? primary : textColor,
            ),
          ),
        ),
      ),
    );
  }
}
