import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/services/notification_service.dart';
import '../../shared/storage/appointment.dart';
import '../../shared/storage/storage_service.dart';

/// จัดการ state ของนัดหมายแพทย์ (ข้อ 1)
/// เพิ่ม/แก้/ลบ พร้อมตั้ง–ยกเลิกการแจ้งเตือนอัตโนมัติ
class AppointmentsNotifier extends Notifier<List<Appointment>> {
  @override
  List<Appointment> build() => StorageService().getAppointments();

  Future<void> _persist(List<Appointment> items) async {
    items.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    state = items;
    await StorageService().saveAppointments(items);
  }

  String _reminderText(Appointment a) {
    final t = a.dateTime;
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    final place = a.location.isNotEmpty ? ' ที่ ${a.location}' : '';
    return 'วันนี้เวลา $hh:$mm น.$place';
  }

  Future<void> _scheduleFor(Appointment a) async {
    await NotificationService().schedule(
      id: a.id,
      title: 'นัดหมาย: ${a.title}',
      body: _reminderText(a),
      dateTime: a.reminderTime,
    );
  }

  /// เพิ่มนัดหมายใหม่ (สร้าง id จากเวลาปัจจุบัน)
  Future<void> add({
    required String title,
    required DateTime dateTime,
    String location = '',
    String note = '',
    int reminderMinutes = 60,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.remainder(2147483647);
    final appt = Appointment(
      id: id,
      title: title,
      dateTime: dateTime,
      location: location,
      note: note,
      reminderMinutes: reminderMinutes,
    );
    await _persist([...state, appt]);
    await _scheduleFor(appt);
  }

  /// แก้ไขนัดหมายเดิม (ยกเลิกแจ้งเตือนเก่าแล้วตั้งใหม่)
  Future<void> update(Appointment updated) async {
    await NotificationService().cancel(updated.id);
    final list = [
      for (final a in state)
        if (a.id == updated.id) updated else a,
    ];
    await _persist(list);
    await _scheduleFor(updated);
  }

  /// ลบนัดหมาย + ยกเลิกการแจ้งเตือน
  Future<void> remove(int id) async {
    await NotificationService().cancel(id);
    await _persist([
      for (final a in state)
        if (a.id != id) a,
    ]);
  }
}

final appointmentsProvider =
    NotifierProvider<AppointmentsNotifier, List<Appointment>>(
  AppointmentsNotifier.new,
);
