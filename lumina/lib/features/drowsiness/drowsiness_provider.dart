import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../shared/services/face_sampling_service.dart';
import '../../shared/services/line_service.dart';
import '../../shared/services/notification_service.dart';
import '../../shared/storage/hive_boxes.dart';
import '../../shared/storage/storage_service.dart';

/// เกณฑ์ "ตาเกือบปิด" (ค่าเฉลี่ยโอกาสตาเปิดซ้าย-ขวา ต่ำกว่านี้ = ง่วง)
const double kEyesClosedThreshold = 0.25;

/// ตัวเลือกความถี่ตรวจง่วง (นาที) — ถี่กว่าระยะจอเพราะต้องจับจังหวะสัปหงก
const List<int> kDrowsyIntervals = [1, 2, 5];

/// id การแจ้งเตือนง่วง (คงที่ เพื่อไม่ให้เด้งซ้อน)
const int _kDrowsyNotifId = 900001;

class DrowsinessState {
  const DrowsinessState({
    this.enabled = false,
    this.intervalMinutes = 2,
    this.warningSeq = 0,
    this.monitoring = false,
  });

  final bool enabled;
  final int intervalMinutes;
  final int warningSeq;
  final bool monitoring;

  DrowsinessState copyWith({
    bool? enabled,
    int? intervalMinutes,
    int? warningSeq,
    bool? monitoring,
  }) {
    return DrowsinessState(
      enabled: enabled ?? this.enabled,
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
      warningSeq: warningSeq ?? this.warningSeq,
      monitoring: monitoring ?? this.monitoring,
    );
  }
}

/// ตรวจจับอาการง่วง (ข้อ 6)
/// - sample ใบหน้าเป็นช่วง (foreground เท่านั้น)
/// - ยืนยัน 2 ครั้งติดเพื่อลดการเตือนพลาด (กันกระพริบตา)
/// - เมื่อพบ: เตือนผู้ใช้ + แจ้งครอบครัวผ่าน LINE (ถ้าตั้งค่า backend ไว้)
class DrowsinessNotifier extends Notifier<DrowsinessState> {
  Timer? _timer;
  bool _foreground = true;

  static const _kEnabled = 'drowsyEnabled';
  static const _kInterval = 'drowsyIntervalMin';

  @override
  DrowsinessState build() {
    final box = Hive.box(HiveBoxes.screenTimeSettings);
    final enabled = box.get(_kEnabled, defaultValue: false) as bool;
    final interval = box.get(_kInterval, defaultValue: 2) as int;
    ref.onDispose(() => _timer?.cancel());
    return DrowsinessState(enabled: enabled, intervalMinutes: interval);
  }

  Box get _box => Hive.box(HiveBoxes.screenTimeSettings);

  Future<void> setEnabled(bool value) async {
    if (value) {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
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

  bool _isDrowsy(FaceSample? s) {
    if (s == null || !s.faceFound) return false;
    final l = s.leftEyeOpen, r = s.rightEyeOpen;
    if (l == null || r == null) return false;
    return (l + r) / 2 < kEyesClosedThreshold;
  }

  Future<void> _sample() async {
    // ตรวจครั้งแรก
    final first = await FaceSamplingService().captureOnce();
    if (!_isDrowsy(first)) return;
    // ยืนยันอีกครั้งหลัง 1.5 วินาที (กันกระพริบตาชั่วขณะ)
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    final second = await FaceSamplingService().captureOnce();
    if (!_isDrowsy(second)) return;
    await _onDrowsy();
  }

  Future<void> _onDrowsy() async {
    state = state.copyWith(warningSeq: state.warningSeq + 1);

    await NotificationService().showNow(
      id: _kDrowsyNotifId,
      title: 'พักสักครู่นะ',
      body: 'ดูเหมือนกำลังง่วง ลองพักสายตาหรืองีบสักครู่',
    );

    final name = StorageService().getUserProfile().name;
    final who = name.isNotEmpty ? name : 'คนที่บ้าน';
    // เฟส 0: broadcast หาทุกคนที่แอด OA (multi-tenant จะเปลี่ยนเป็น push ต่อบ้าน)
    await LineService()
        .broadcast('$who ดูเหมือนกำลังง่วง/เหนื่อยล้า ลองโทรถามอาการหน่อยนะ');
  }
}

final drowsinessProvider =
    NotifierProvider<DrowsinessNotifier, DrowsinessState>(
  DrowsinessNotifier.new,
);
