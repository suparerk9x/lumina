import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../shared/services/face_sampling_service.dart';
import '../../shared/storage/hive_boxes.dart';

/// เกณฑ์ "นั่งใกล้จอเกินไป" — สัดส่วนความกว้างใบหน้าเทียบด้านสั้นของภาพ
/// (ค่าประมาณ อาจต้องปรับจูนบนเครื่องจริง)
const double kTooCloseRatio = 0.55;

/// ตัวเลือกความถี่ในการตรวจ (นาที)
const List<int> kDistanceIntervals = [5, 10, 15, 30];

class ScreenDistanceState {
  const ScreenDistanceState({
    this.enabled = false,
    this.intervalMinutes = 5,
    this.warningSeq = 0,
    this.monitoring = false,
  });

  final bool enabled; // เปิดใช้ฟีเจอร์หรือไม่
  final int intervalMinutes; // ตรวจทุกกี่นาที
  final int warningSeq; // เพิ่มขึ้นทุกครั้งที่ตรวจพบว่านั่งใกล้เกินไป
  final bool monitoring; // timer กำลังทำงาน (foreground + enabled)

  ScreenDistanceState copyWith({
    bool? enabled,
    int? intervalMinutes,
    int? warningSeq,
    bool? monitoring,
  }) {
    return ScreenDistanceState(
      enabled: enabled ?? this.enabled,
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
      warningSeq: warningSeq ?? this.warningSeq,
      monitoring: monitoring ?? this.monitoring,
    );
  }
}

/// จัดการการเตือนระยะห่างหน้าจอ (ข้อ 4)
/// ตรวจเป็นช่วง (default 5 นาที) เฉพาะตอนแอปเปิดอยู่ (foreground)
class ScreenDistanceNotifier extends Notifier<ScreenDistanceState> {
  Timer? _timer;
  bool _foreground = true;

  static const _kEnabled = 'screenDistanceEnabled';
  static const _kInterval = 'screenDistanceIntervalMin';

  @override
  ScreenDistanceState build() {
    final box = Hive.box(HiveBoxes.screenTimeSettings);
    final enabled = box.get(_kEnabled, defaultValue: false) as bool;
    final interval = box.get(_kInterval, defaultValue: 5) as int;
    ref.onDispose(() => _timer?.cancel());
    return ScreenDistanceState(enabled: enabled, intervalMinutes: interval);
  }

  Box get _box => Hive.box(HiveBoxes.screenTimeSettings);

  /// เปิด/ปิดฟีเจอร์ (ขอสิทธิ์กล้องตอนเปิด)
  Future<void> setEnabled(bool value) async {
    if (value) {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        // ไม่ได้สิทธิ์ → ไม่เปิด
        state = state.copyWith(enabled: false, monitoring: false);
        await _box.put(_kEnabled, false);
        _timer?.cancel();
        return;
      }
    }
    await _box.put(_kEnabled, value);
    state = state.copyWith(enabled: value);
    _reschedule();
  }

  Future<void> setInterval(int minutes) async {
    await _box.put(_kInterval, minutes);
    state = state.copyWith(intervalMinutes: minutes);
    _reschedule();
  }

  /// อัปเดตสถานะ foreground/background จาก lifecycle (ตัวเรียกที่หน้า Home)
  void setForeground(bool value) {
    _foreground = value;
    _reschedule();
  }

  void _reschedule() {
    _timer?.cancel();
    final active = state.enabled && _foreground;
    state = state.copyWith(monitoring: active);
    if (!active) return;
    _timer = Timer.periodic(
      Duration(minutes: state.intervalMinutes),
      (_) => _sample(),
    );
  }

  /// เรียกตรวจทันที 1 ครั้ง (ใช้ปุ่ม "ทดสอบ" ในตั้งค่า)
  Future<bool?> checkNow() async {
    final sample = await FaceSamplingService().captureOnce();
    if (sample == null || !sample.faceFound) return null;
    final tooClose = sample.faceRatio > kTooCloseRatio;
    if (tooClose) {
      state = state.copyWith(warningSeq: state.warningSeq + 1);
    }
    return tooClose;
  }

  Future<void> _sample() async {
    final sample = await FaceSamplingService().captureOnce();
    if (sample == null || !sample.faceFound) return;
    if (sample.faceRatio > kTooCloseRatio) {
      state = state.copyWith(warningSeq: state.warningSeq + 1);
    }
  }
}

final screenDistanceProvider =
    NotifierProvider<ScreenDistanceNotifier, ScreenDistanceState>(
  ScreenDistanceNotifier.new,
);
