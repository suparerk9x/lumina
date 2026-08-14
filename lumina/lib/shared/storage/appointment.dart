// โมเดลข้อมูลนัดหมายแพทย์ (ข้อ 1)
// เก็บหัวข้อ วันเวลา สถานที่ และช่วงเวลาที่ต้องการให้เตือนล่วงหน้า

/// ตัวเลือกเตือนล่วงหน้า (นาทีก่อนถึงเวลานัด)
enum ReminderLead {
  atTime(0, 'ตอนถึงเวลา'),
  min30(30, 'ก่อน 30 นาที'),
  hour1(60, 'ก่อน 1 ชั่วโมง'),
  hour3(180, 'ก่อน 3 ชั่วโมง'),
  day1(1440, 'ก่อน 1 วัน');

  const ReminderLead(this.minutes, this.label);

  final int minutes;
  final String label;

  static ReminderLead fromMinutes(int m) {
    return ReminderLead.values.firstWhere(
      (e) => e.minutes == m,
      orElse: () => ReminderLead.hour1,
    );
  }
}

/// โมเดลนัดหมาย 1 รายการ
class Appointment {
  const Appointment({
    required this.id,
    required this.title,
    required this.dateTime,
    this.location = '',
    this.note = '',
    this.reminderMinutes = 60,
  });

  final int id; // ใช้เป็น notification id ด้วย (ต้องไม่ซ้ำ)
  final String title; // เช่น "ตรวจเบาหวาน"
  final DateTime dateTime; // วันเวลานัด
  final String location; // โรงพยาบาล/แผนก/หมอ
  final String note; // บันทึกเพิ่มเติม
  final int reminderMinutes; // เตือนก่อนกี่นาที

  ReminderLead get reminder => ReminderLead.fromMinutes(reminderMinutes);

  /// เวลาที่จะยิงการแจ้งเตือน
  DateTime get reminderTime =>
      dateTime.subtract(Duration(minutes: reminderMinutes));

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'dateTime': dateTime.toIso8601String(),
      'location': location,
      'note': note,
      'reminderMinutes': reminderMinutes,
    };
  }

  factory Appointment.fromMap(Map<dynamic, dynamic> map) {
    final id = map['id'];
    final title = map['title'];
    final dt = map['dateTime'];
    if (id == null || title == null || dt == null) {
      throw const FormatException('Missing required appointment fields');
    }
    return Appointment(
      id: (id as num).toInt(),
      title: '$title',
      dateTime: DateTime.parse(dt as String),
      location: '${map['location'] ?? ''}',
      note: '${map['note'] ?? ''}',
      reminderMinutes: ((map['reminderMinutes'] ?? 60) as num).toInt(),
    );
  }

  Appointment copyWith({
    int? id,
    String? title,
    DateTime? dateTime,
    String? location,
    String? note,
    int? reminderMinutes,
  }) {
    return Appointment(
      id: id ?? this.id,
      title: title ?? this.title,
      dateTime: dateTime ?? this.dateTime,
      location: location ?? this.location,
      note: note ?? this.note,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
    );
  }
}
