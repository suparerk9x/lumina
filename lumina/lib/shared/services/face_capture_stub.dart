import 'face_sample.dart';

/// Stub สำหรับ platform ที่ไม่มีกล้อง/ML Kit (เช่น Web)
/// คืน null เสมอ — ฟีเจอร์กล้อง (ระยะจอ/ง่วง) จึงไม่ทำงานบนเว็บ
Future<FaceSample?> captureOnce() async => null;

void disposeDetector() {}
