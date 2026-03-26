// ไฟล์นี้เป็นโมเดลข้อมูลสำหรับเก็บผลการประเมินสุขภาพสมอง

/// โมเดลเก็บผลการประเมิน 1 ครั้ง มีวันที่ คะแนนรวม คะแนนเต็ม และคะแนนแต่ละส่วน
class AssessmentResult {
  const AssessmentResult({
    required this.date,
    required this.totalScore,
    required this.maxScore,
    required this.sectionScores,
  });

  final DateTime date; // วันที่ทำแบบประเมิน
  final int totalScore; // คะแนนที่ได้
  final int maxScore; // คะแนนเต็ม
  final Map<String, int> sectionScores; // คะแนนแยกตามหมวด

  /// แปลงข้อมูลเป็น Map เพื่อบันทึกลง Hive
  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'totalScore': totalScore,
      'maxScore': maxScore,
      'sectionScores': sectionScores,
    };
  }

  /// สร้าง AssessmentResult จาก Map (ข้อมูลที่อ่านจาก Hive)
  /// ถ้าข้อมูลไม่ครบจะ throw error เพื่อข้ามรายการที่เสียหาย
  factory AssessmentResult.fromMap(Map<dynamic, dynamic> map) {
    final dateStr = map['date'];
    final total = map['totalScore'];
    final max = map['maxScore'];
    final sections = map['sectionScores'];

    if (dateStr == null || total == null || max == null) {
      throw const FormatException('Missing required assessment fields');
    }

    return AssessmentResult(
      date: DateTime.parse(dateStr as String),
      totalScore: (total as num).toInt(),
      maxScore: (max as num).toInt(),
      sectionScores: sections != null
          ? Map<String, int>.from(
              (sections as Map).map((k, v) => MapEntry('$k', (v as num).toInt())),
            )
          : {},
    );
  }
}
