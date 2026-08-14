// ไฟล์นี้เก็บชื่อ Hive box ทั้งหมดไว้ที่เดียว
// Hive box คือ "กล่องเก็บข้อมูล" แต่ละกล่องเก็บข้อมูลคนละประเภท

/// ค่าคงที่ชื่อ Hive box ทั้งหมดในแอป
/// รวมไว้ที่เดียวเพื่อป้องกันพิมพ์ผิดและแก้ไขง่าย
class HiveBoxes {
  HiveBoxes._(); // ป้องกันไม่ให้สร้าง instance

  static const String assessmentResults = 'assessment_results'; // กล่องผลประเมิน
  static const String screenTimeSettings = 'screen_time_settings'; // กล่องตั้งค่าเวลาหน้าจอ
  static const String gameScores = 'game_scores'; // กล่องคะแนนเกม
  static const String cachedGameData = 'cached_game_data'; // กล่องข้อมูลเกมจาก Google Sheets
  static const String userProfile = 'user_profile'; // กล่องโปรไฟล์ผู้ใช้ + รายชื่อครอบครัว

  /// รายชื่อ box ทั้งหมด ใช้ตอนเปิดแอปเพื่อเปิด box ทุกตัว
  static const List<String> all = [
    assessmentResults,
    screenTimeSettings,
    gameScores,
    cachedGameData,
    userProfile,
  ];
}
