/// ผลการ sample ใบหน้า 1 ครั้ง (ไม่มี dependency กับ platform)
class FaceSample {
  const FaceSample({
    required this.faceFound,
    this.faceRatio = 0,
    this.leftEyeOpen,
    this.rightEyeOpen,
    this.headAngleX = 0,
    this.headAngleZ = 0,
  });

  final bool faceFound;
  final double faceRatio; // ความกว้างใบหน้า / ด้านสั้นของภาพ (ยิ่งมาก = ยิ่งใกล้จอ)
  final double? leftEyeOpen; // โอกาสตาซ้ายเปิด (0–1) — ใช้กับตรวจง่วง (ข้อ 6)
  final double? rightEyeOpen;
  final double headAngleX; // ก้ม/เงย (pitch)
  final double headAngleZ; // เอียงหน้า (roll)
}
