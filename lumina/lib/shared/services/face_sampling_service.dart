import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// ผลการ sample ใบหน้า 1 ครั้ง
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

/// Service ถ่ายภาพหน้าแบบเป็นช่วง (ข้อ 4 & 6)
/// เปิดกล้องหน้าแวบเดียว → ถ่าย 1 เฟรม → ตรวจใบหน้า → ปิดกล้อง
/// ทำงานเฉพาะตอนแอปเปิดอยู่ (foreground) — ตัวเรียกเป็นคนคุมจังหวะ
class FaceSamplingService {
  FaceSamplingService._();
  static final FaceSamplingService _instance = FaceSamplingService._();
  factory FaceSamplingService() => _instance;

  FaceDetector? _detector;
  bool _busy = false;

  FaceDetector get _faceDetector => _detector ??= FaceDetector(
        options: FaceDetectorOptions(
          enableClassification: true, // ได้ค่า eyeOpenProbability
          performanceMode: FaceDetectorMode.fast,
        ),
      );

  /// ถ่าย + ตรวจ 1 ครั้ง (คืน null ถ้าทำไม่ได้ เช่น ไม่มีกล้อง/ไม่ได้สิทธิ์)
  Future<FaceSample?> captureOnce() async {
    if (_busy) return null;
    _busy = true;
    CameraController? controller;
    String? tempPath;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return null;
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      controller = CameraController(
        front,
        ResolutionPreset.low,
        enableAudio: false,
      );
      await controller.initialize();
      final file = await controller.takePicture();
      tempPath = file.path;
      await controller.dispose();
      controller = null;

      // ขนาดภาพ (ใช้ด้านสั้นเป็นฐานคำนวณสัดส่วนใบหน้า)
      final bytes = await File(tempPath).readAsBytes();
      final decoded = await ui.instantiateImageCodec(bytes);
      final frame = await decoded.getNextFrame();
      final shortSide =
          math.min(frame.image.width, frame.image.height).toDouble();
      frame.image.dispose();

      final faces =
          await _faceDetector.processImage(InputImage.fromFilePath(tempPath));

      if (faces.isEmpty) {
        return const FaceSample(faceFound: false);
      }
      // เลือกใบหน้าใหญ่สุด (ใกล้กล้องสุด)
      faces.sort((a, b) =>
          b.boundingBox.width.compareTo(a.boundingBox.width));
      final f = faces.first;
      final ratio = shortSide > 0 ? f.boundingBox.width / shortSide : 0.0;

      return FaceSample(
        faceFound: true,
        faceRatio: ratio,
        leftEyeOpen: f.leftEyeOpenProbability,
        rightEyeOpen: f.rightEyeOpenProbability,
        headAngleX: f.headEulerAngleX ?? 0,
        headAngleZ: f.headEulerAngleZ ?? 0,
      );
    } catch (e, s) {
      developer.log('FaceSamplingService.captureOnce failed: $e',
          name: 'DemenishAI', error: e, stackTrace: s);
      return null;
    } finally {
      try {
        await controller?.dispose();
      } catch (_) {}
      if (tempPath != null) {
        try {
          final tf = File(tempPath);
          if (await tf.exists()) await tf.delete();
        } catch (_) {}
      }
      _busy = false;
    }
  }

  void dispose() {
    _detector?.close();
    _detector = null;
  }
}
