import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../shared/storage/hive_boxes.dart';
import '../../shared/storage/storage_service.dart';

/// ไฟล์นี้จัดการ state ของฟีเจอร์จำกัดเวลาหน้าจอ
/// เก็บข้อมูลเวลาใช้งาน, เวลาจำกัด, การจับเวลา, และประวัติสัปดาห์
/// ใช้ Riverpod Notifier pattern เพื่อแยก logic ออกจาก UI

// ─── State Model (โมเดลเก็บสถานะ) ────────────────────────────────────────────

/// โมเดลเก็บสถานะทั้งหมดของฟีเจอร์จำกัดเวลาหน้าจอ
class ScreenTimeState {
  const ScreenTimeState({
    this.dailyLimit = const Duration(hours: 2),
    this.todayUsage = Duration.zero,
    this.weekHistory = const [],
    this.isTracking = false,
    this.alertShown = false,
  });

  final Duration dailyLimit; // เวลาจำกัดต่อวัน
  final Duration todayUsage; // เวลาที่ใช้ไปวันนี้
  final List<Duration> weekHistory; // ประวัติ 7 วัน (index 0 = วันจันทร์)
  final bool isTracking; // กำลังจับเวลาอยู่หรือไม่
  final bool alertShown; // แสดงการเตือนไปแล้วหรือยัง (ป้องกันเตือนซ้ำ)

  /// ตรวจสอบว่าใช้เกินเวลาจำกัดหรือไม่
  bool get isOverLimit =>
      dailyLimit.inSeconds > 0 && todayUsage >= dailyLimit;

  /// คำนวณสัดส่วนเวลาที่ใช้ เทียบกับเวลาจำกัด (0.0 ถึง 1.5)
  double get usageRatio {
    if (dailyLimit.inSeconds == 0) return 0;
    return (todayUsage.inSeconds / dailyLimit.inSeconds).clamp(0.0, 1.5);
  }

  /// แปลงเวลาที่ใช้เป็นข้อความภาษาไทย เช่น "1 ชม. 30 น. 5 วิ."
  String get usageFormatted {
    final h = todayUsage.inHours;
    final m = todayUsage.inMinutes % 60;
    final s = todayUsage.inSeconds % 60;
    if (h > 0) return '$h ชม. $m น. $s วิ.';
    if (m > 0) return '$m น. $s วิ.';
    return '$s วินาที';
  }

  /// แปลงเวลาจำกัดเป็นข้อความภาษาไทย เช่น "2 ชม. 30 น."
  String get limitFormatted {
    final h = dailyLimit.inHours;
    final m = dailyLimit.inMinutes % 60;
    if (h > 0 && m > 0) return '$h ชม. $m น.';
    if (h > 0) return '$h ชั่วโมง';
    return '$m นาที';
  }

  /// สร้างสำเนาของ state พร้อมเปลี่ยนค่าบางตัว (Immutable pattern)
  ScreenTimeState copyWith({
    Duration? dailyLimit,
    Duration? todayUsage,
    List<Duration>? weekHistory,
    bool? isTracking,
    bool? alertShown,
  }) {
    return ScreenTimeState(
      dailyLimit: dailyLimit ?? this.dailyLimit,
      todayUsage: todayUsage ?? this.todayUsage,
      weekHistory: weekHistory ?? this.weekHistory,
      isTracking: isTracking ?? this.isTracking,
      alertShown: alertShown ?? this.alertShown,
    );
  }
}

// ─── คีย์สำหรับเก็บข้อมูลใน Hive ──────────────────────────────────────────────

/// ค่าคงที่สำหรับชื่อ key ที่ใช้เก็บข้อมูลใน Hive (ป้องกันพิมพ์ผิด)
class _Keys {
  static const todaySeconds = 'todayUsageSeconds';
  static const todayDate = 'todayDate';
  static const trackingStartTime = 'trackingStartTime';
  static const weekData = 'weekHistory'; // List<Map>
}

// ─── Notifier (ตัวจัดการ state) ───────────────────────────────────────────────

/// ตัวจัดการ logic ทั้งหมดของฟีเจอร์จำกัดเวลาหน้าจอ
/// รับผิดชอบ: เริ่ม/หยุดจับเวลา, บันทึกข้อมูล, แจ้งเตือนเมื่อเกินเวลา
class ScreenTimeNotifier extends Notifier<ScreenTimeState> {
  // Timer ที่นับทุก 1 วินาทีเมื่อกำลังจับเวลา
  Timer? _tickTimer;

  /// เข้าถึง Hive box สำหรับเก็บข้อมูลเวลาหน้าจอ
  Box get _box => Hive.box(HiveBoxes.screenTimeSettings);

  /// สร้าง state เริ่มต้น: โหลดข้อมูลจาก Hive และเริ่มจับเวลาต่อถ้าค้างอยู่
  @override
  ScreenTimeState build() {
    ref.onDispose(() => _tickTimer?.cancel());

    final limit = StorageService().getScreenTimeLimit();
    final todayUsage = _loadTodayUsage();
    final weekHistory = _loadWeekHistory();
    final wasTracking = _box.get(_Keys.trackingStartTime) != null;

    final initialState = ScreenTimeState(
      dailyLimit: limit,
      todayUsage: todayUsage,
      weekHistory: weekHistory,
      isTracking: wasTracking,
    );

    // Resume tracking if app was closed while tracking
    if (wasTracking) {
      _resumeTracking();
    }

    return initialState;
  }

  // ─── โหลดเวลาที่ใช้วันนี้ (เก็บไว้ใน Hive) ────────────────────

  /// โหลดเวลาที่ใช้วันนี้ ถ้าเป็นวันใหม่จะรีเซ็ตและบันทึกข้อมูลเมื่อวานลงประวัติ
  Duration _loadTodayUsage() {
    final savedDate = _box.get(_Keys.todayDate) as String?;
    final today = _todayKey();

    if (savedDate != today) {
      // New day: save yesterday's usage to week history, reset
      _rollOverDay();
      return Duration.zero;
    }

    var seconds = (_box.get(_Keys.todaySeconds, defaultValue: 0) as num).toInt();

    // Add elapsed time if was tracking when app closed
    final startTimeStr = _box.get(_Keys.trackingStartTime) as String?;
    if (startTimeStr != null) {
      try {
        final startTime = DateTime.parse(startTimeStr);
        final elapsed = DateTime.now().difference(startTime).inSeconds;
        seconds += elapsed;
      } catch (_) {}
    }

    return Duration(seconds: seconds);
  }

  // ─── ประวัติสัปดาห์ (ข้อมูลจริงจาก Hive) ────────────────

  /// โหลดประวัติการใช้งาน 7 วันของสัปดาห์นี้ (จันทร์-อาทิตย์)
  List<Duration> _loadWeekHistory() {
    try {
      final raw = _box.get(_Keys.weekData);
      if (raw == null) return List.filled(7, Duration.zero);

      final list = List<Map<dynamic, dynamic>>.from(raw as List);
      // Map: { 'date': 'YYYY-MM-DD', 'seconds': int }
      final now = DateTime.now();
      final monday = now.subtract(Duration(days: now.weekday - 1));

      return List.generate(7, (i) {
        final dayKey = _dateKey(monday.add(Duration(days: i)));
        final entry = list.cast<Map>().where((e) => e['date'] == dayKey);
        if (entry.isNotEmpty) {
          return Duration(seconds: (entry.first['seconds'] as num).toInt());
        }
        return Duration.zero;
      });
    } catch (e) {
      developer.log('loadWeekHistory error: $e', name: 'DemenishAI');
      return List.filled(7, Duration.zero);
    }
  }

  /// เปลี่ยนวัน: บันทึกข้อมูลเมื่อวานลงประวัติสัปดาห์ แล้วรีเซ็ตเวลาวันนี้
  void _rollOverDay() {
    // Save yesterday's data to week history
    final savedDate = _box.get(_Keys.todayDate) as String?;
    final savedSeconds =
        (_box.get(_Keys.todaySeconds, defaultValue: 0) as num).toInt();

    if (savedDate != null && savedSeconds > 0) {
      _saveToWeekHistory(savedDate, savedSeconds);
    }

    // Reset today
    _box.put(_Keys.todayDate, _todayKey());
    _box.put(_Keys.todaySeconds, 0);
    _box.delete(_Keys.trackingStartTime);
  }

  /// บันทึกเวลาที่ใช้ของวันนั้น ๆ ลงประวัติสัปดาห์ (เก็บไม่เกิน 14 วัน)
  void _saveToWeekHistory(String dateKey, int seconds) {
    try {
      final raw = _box.get(_Keys.weekData);
      final list = raw != null
          ? List<Map<dynamic, dynamic>>.from(raw as List)
          : <Map<dynamic, dynamic>>[];

      // Remove old entry for same date
      list.removeWhere((e) => e['date'] == dateKey);
      list.add({'date': dateKey, 'seconds': seconds});

      // Keep last 14 days max
      if (list.length > 14) {
        list.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
        list.removeRange(0, list.length - 14);
      }

      _box.put(_Keys.weekData, list);
    } catch (e) {
      developer.log('saveToWeekHistory error: $e', name: 'DemenishAI');
    }
  }

  // ─── การจับเวลา (นับทุกวินาที) ───────────────────────────

  /// เริ่มจับเวลา: บันทึกเวลาเริ่มและตั้ง timer นับทุกวินาที
  void startTracking() {
    if (state.isTracking) return;

    // Save start time for resume-on-reopen
    _box.put(_Keys.trackingStartTime, DateTime.now().toIso8601String());
    _box.put(_Keys.todayDate, _todayKey());

    state = state.copyWith(isTracking: true, alertShown: false);
    _startTick();
  }

  /// จับเวลาต่อจากที่ค้างไว้ (เมื่อเปิดแอปกลับมา)
  void _resumeTracking() {
    // Timer will start, state already has accumulated usage from _loadTodayUsage
    Future.microtask(() {
      // Clear the old start time and set fresh one
      _box.put(_Keys.trackingStartTime, DateTime.now().toIso8601String());
      _startTick();
    });
  }

  /// เริ่ม timer นับทุกวินาที อัปเดต state และบันทึกลง Hive ทุก 10 วินาที
  void _startTick() {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final newUsage = state.todayUsage + const Duration(seconds: 1);
      final justCrossedLimit = !state.alertShown &&
          state.dailyLimit.inSeconds > 0 &&
          newUsage >= state.dailyLimit;

      state = state.copyWith(
        todayUsage: newUsage,
        alertShown: justCrossedLimit ? true : state.alertShown,
      );

      // Save to Hive every 10 seconds (not every second for performance)
      if (newUsage.inSeconds % 10 == 0) {
        _persistUsage(newUsage);
      }

      // Trigger notification when limit crossed
      if (justCrossedLimit) {
        _triggerOverLimitAlert();
      }
    });
  }

  /// หยุดจับเวลา: ยกเลิก timer และบันทึกเวลาที่ใช้ลง Hive
  void stopTracking() {
    _tickTimer?.cancel();
    _tickTimer = null;
    _box.delete(_Keys.trackingStartTime);
    _persistUsage(state.todayUsage);
    state = state.copyWith(isTracking: false);
  }

  /// บันทึกเวลาที่ใช้ลง Hive
  void _persistUsage(Duration usage) {
    _box.put(_Keys.todaySeconds, usage.inSeconds);
    _box.put(_Keys.todayDate, _todayKey());
  }

  /// แจ้งเตือนเมื่อใช้เกินเวลา (UI ดูค่า alertShown เพื่อแสดง dialog)
  void _triggerOverLimitAlert() {
    // This flag is watched by the UI to show an alert dialog
    // Also attempt browser notification on web
    if (kIsWeb) {
      _sendWebNotification();
    }
  }

  void _sendWebNotification() {
    // Web Notifications API is handled via JS interop
    // For now we rely on the in-app alert (UI watches alertShown)
    developer.log('Over limit alert triggered', name: 'DemenishAI');
  }

  /// ตั้งเวลาจำกัดรายวันใหม่ และบันทึกลง Storage
  Future<void> setDailyLimit(Duration limit) async {
    await StorageService().saveScreenTimeLimit(limit);
    state = state.copyWith(dailyLimit: limit, alertShown: false);
  }

  /// รีเซ็ตเวลาที่ใช้วันนี้กลับเป็น 0
  void resetTodayUsage() {
    _tickTimer?.cancel();
    _tickTimer = null;
    _box.put(_Keys.todaySeconds, 0);
    _box.delete(_Keys.trackingStartTime);
    state = state.copyWith(
      todayUsage: Duration.zero,
      isTracking: false,
      alertShown: false,
    );
  }

  /// ลบประวัติสัปดาห์ทั้งหมด
  void clearWeekHistory() {
    _box.delete(_Keys.weekData);
    state = state.copyWith(weekHistory: List.filled(7, Duration.zero));
  }

  // ─── ฟังก์ชันช่วย ───────────────────────────────────────────

  /// สร้าง key ของวันนี้ในรูปแบบ "YYYY-MM-DD"
  String _todayKey() => _dateKey(DateTime.now());

  /// แปลง DateTime เป็น key รูปแบบ "YYYY-MM-DD" สำหรับใช้เป็น key ใน Hive
  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

// ─── Provider (ตัวให้บริการ state) ───────────────────────────────────────────────

/// Provider หลักที่ UI ใช้เข้าถึง state และ notifier ของฟีเจอร์จำกัดเวลาหน้าจอ
final screenTimeProvider =
    NotifierProvider<ScreenTimeNotifier, ScreenTimeState>(
  ScreenTimeNotifier.new,
);
