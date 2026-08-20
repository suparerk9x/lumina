import 'face_sample.dart';
// เลือก implementation ตาม platform: native (dart:io) ใช้กล้อง+ML Kit, web ใช้ stub
import 'face_capture_stub.dart'
    if (dart.library.io) 'face_capture_io.dart' as capture;

export 'face_sample.dart';

/// Service ถ่ายภาพหน้าแบบเป็นช่วง (ข้อ 4 & 6)
/// เปิดกล้องหน้าแวบเดียว → ถ่าย 1 เฟรม → ตรวจใบหน้า → ปิดกล้อง
/// บนเว็บจะคืน null เสมอ (ไม่มีกล้อง/ML Kit)
class FaceSamplingService {
  FaceSamplingService._();
  static final FaceSamplingService _instance = FaceSamplingService._();
  factory FaceSamplingService() => _instance;

  /// ถ่าย + ตรวจ 1 ครั้ง (คืน null ถ้าทำไม่ได้ เช่น ไม่มีกล้อง/ไม่ได้สิทธิ์/เว็บ)
  Future<FaceSample?> captureOnce() => capture.captureOnce();

  void dispose() => capture.disposeDetector();
}
