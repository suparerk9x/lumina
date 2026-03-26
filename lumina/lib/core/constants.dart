// ไฟล์นี้เก็บค่าคงที่ (constants) ที่ใช้ทั่วทั้งแอป
// เช่น ชื่อแอป, คำศัพท์สำหรับเกม, และการตั้งค่าเกมต่าง ๆ

/// คลาสรวมค่าคงที่ทั้งหมดของแอป ใช้ static const เพื่อไม่ต้องสร้าง object
class AppConstants {
  // ชื่อและเวอร์ชันของแอป
  static const String appName = 'Lumina';
  static const String appVersion = '1.0.0';

  // ─── Word Pool (Memory Game — 30 Thai words) ────────────
  /// คลังคำศัพท์ภาษาไทย 30 คำ สำหรับใช้ในเกมฝึกความจำ
  static const List<String> wordPool = [
    'บ้าน', 'แมว', 'น้ำ', 'ต้นไม้', 'รถ', 'ปลา', 'โต๊ะ',
    'ดวงดาว', 'หนังสือ', 'กล้วย', 'เก้าอี้', 'ดอกไม้', 'นาฬิกา',
    'แก้ว', 'รองเท้า', 'ประตู', 'หมอน', 'ข้าว', 'พระอาทิตย์',
    'จาน', 'โทรศัพท์', 'พัดลม', 'แม่น้ำ', 'เสื้อ', 'ช้อน',
    'จักรยาน', 'เทียน', 'ส้ม', 'หน้าต่าง', 'หมวก',
  ];

  // ─── Game Config (ค่าตั้งต้นของเกมต่าง ๆ) ──────────────
  /// จำนวนรอบของเกมจับคู่เสียง
  static const int soundMatchRounds = 10;
  /// จำนวนรอบของเกมเรียงลำดับ
  static const int sequenceGameRounds = 5;
  /// เวลา (วินาที) ที่แสดงคำให้ผู้เล่นจำก่อนเริ่มตอบ
  static const int memoryDisplaySeconds = 10;
  /// ระยะเวลาแสดงผลตอบกลับ (ถูก/ผิด) ก่อนไปข้อถัดไป
  static const Duration feedbackDuration = Duration(milliseconds: 800);
}
