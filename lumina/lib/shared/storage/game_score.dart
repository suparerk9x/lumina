// ไฟล์นี้เป็นโมเดลข้อมูลสำหรับเก็บคะแนนเกมฝึกสมอง

/// โมเดลเก็บคะแนนเกม 1 ครั้ง มีวันที่ ประเภทเกม คะแนน คะแนนเต็ม และเวลาที่ใช้
class GameScore {
  const GameScore({
    required this.date,
    required this.gameType,
    required this.score,
    required this.total,
    required this.durationSeconds,
  });

  final DateTime date; // วันที่เล่น
  final String gameType; // ประเภทเกม เช่น 'sound_match' หรือ 'sequence'
  final int score; // คะแนนที่ได้
  final int total; // คะแนนเต็ม
  final int durationSeconds; // เวลาที่ใช้เล่น (วินาที)

  /// แปลงข้อมูลเป็น Map เพื่อบันทึกลง Hive
  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'gameType': gameType,
      'score': score,
      'total': total,
      'durationSeconds': durationSeconds,
    };
  }

  /// สร้าง GameScore จาก Map (ข้อมูลที่อ่านจาก Hive)
  /// ถ้าข้อมูลไม่ครบจะ throw error เพื่อข้ามรายการที่เสียหาย
  factory GameScore.fromMap(Map<dynamic, dynamic> map) {
    final dateStr = map['date'];
    final gameType = map['gameType'];
    final score = map['score'];
    final total = map['total'];

    if (dateStr == null || gameType == null || score == null || total == null) {
      throw const FormatException('Missing required game score fields');
    }

    return GameScore(
      date: DateTime.parse(dateStr as String),
      gameType: '$gameType',
      score: (score as num).toInt(),
      total: (total as num).toInt(),
      durationSeconds: ((map['durationSeconds'] ?? 0) as num).toInt(),
    );
  }
}
