import 'dart:developer' as developer;

import 'package:hive_flutter/hive_flutter.dart';

import 'assessment_result.dart';
import 'game_score.dart';
import 'hive_boxes.dart';
import 'user_profile.dart';

/// ไฟล์นี้เป็น service กลางสำหรับจัดการข้อมูลทั้งหมดในแอป
/// ใช้ Hive (ฐานข้อมูลท้องถิ่น) เก็บผลประเมิน คะแนนเกม และการตั้งค่าเวลาจำกัด

/// Service แบบ Singleton (สร้างได้แค่ตัวเดียว) สำหรับอ่าน/เขียนข้อมูล Hive
/// Singleton หมายถึง ไม่ว่าจะเรียก StorageService() กี่ครั้ง ก็ได้ object ตัวเดิม
class StorageService {
  StorageService._(); // constructor ส่วนตัว ไม่ให้สร้างจากภายนอก
  static final StorageService _instance = StorageService._(); // instance เดียว
  factory StorageService() => _instance; // คืน instance เดิมเสมอ

  // ─── ผลการประเมิน (Assessment Results) ─────────────────────────────────

  /// บันทึกผลการประเมินลง Hive เก็บไม่เกิน 100 รายการ
  Future<void> saveAssessmentResult(AssessmentResult result) async {
    try {
      final box = Hive.box(HiveBoxes.assessmentResults);
      final list = _getMapList(box, 'history');
      list.add(result.toMap());
      // Cap at 100 entries
      if (list.length > 100) list.removeAt(0);
      await box.put('history', list);
    } catch (e, stack) {
      _log('saveAssessmentResult', e, stack);
    }
  }

  /// ดึงประวัติผลการประเมิน เรียงจากล่าสุด จำกัดจำนวนตาม limit
  List<AssessmentResult> getAssessmentHistory({int limit = 10}) {
    try {
      final box = Hive.box(HiveBoxes.assessmentResults);
      final list = _getMapList(box, 'history');

      final results = <AssessmentResult>[];
      for (final m in list) {
        try {
          results.add(AssessmentResult.fromMap(m));
        } catch (_) {
          // Skip malformed entries instead of failing all
        }
      }
      results.sort((a, b) => b.date.compareTo(a.date));
      return results.take(limit).toList();
    } catch (e, stack) {
      _log('getAssessmentHistory', e, stack);
      return [];
    }
  }

  // ─── คะแนนเกม (Game Scores) ────────────────────────────────────────

  /// บันทึกคะแนนเกมลง Hive เก็บไม่เกิน 200 รายการ
  Future<void> saveGameScore(GameScore score) async {
    try {
      final box = Hive.box(HiveBoxes.gameScores);
      final list = _getMapList(box, 'scores');
      list.add(score.toMap());
      if (list.length > 200) list.removeAt(0);
      await box.put('scores', list);
    } catch (e, stack) {
      _log('saveGameScore', e, stack);
    }
  }

  /// ดึงคะแนนเกมตามประเภท (sound_match หรือ sequence) เรียงจากล่าสุด
  List<GameScore> getGameScores(String gameType, {int limit = 20}) {
    try {
      final box = Hive.box(HiveBoxes.gameScores);
      final list = _getMapList(box, 'scores');

      final scores = <GameScore>[];
      for (final m in list) {
        try {
          final s = GameScore.fromMap(m);
          if (s.gameType == gameType) scores.add(s);
        } catch (_) {
          // Skip malformed entries
        }
      }
      scores.sort((a, b) => b.date.compareTo(a.date));
      return scores.take(limit).toList();
    } catch (e, stack) {
      _log('getGameScores($gameType)', e, stack);
      return [];
    }
  }

  // ─── เวลาจำกัดหน้าจอ (Screen Time) ────────────────────────────────────────

  /// บันทึกเวลาจำกัดหน้าจอลง Hive (เก็บเป็นนาที)
  Future<void> saveScreenTimeLimit(Duration limit) async {
    try {
      final box = Hive.box(HiveBoxes.screenTimeSettings);
      await box.put('dailyLimitMinutes', limit.inMinutes);
    } catch (e, stack) {
      _log('saveScreenTimeLimit', e, stack);
    }
  }

  /// ดึงเวลาจำกัดหน้าจอ ถ้าไม่มีจะคืนค่าเริ่มต้น 2 ชั่วโมง
  Duration getScreenTimeLimit(
      {Duration defaultLimit = const Duration(hours: 2)}) {
    try {
      final box = Hive.box(HiveBoxes.screenTimeSettings);
      final minutes = box.get('dailyLimitMinutes') as int?;
      if (minutes == null) return defaultLimit;
      return Duration(minutes: minutes);
    } catch (e, stack) {
      _log('getScreenTimeLimit', e, stack);
      return defaultLimit;
    }
  }

  // ─── โปรไฟล์ผู้ใช้ (User Profile) ──────────────────────────────────

  /// ดึงโปรไฟล์ผู้ใช้ ถ้ายังไม่มีจะคืนค่าเริ่มต้น (ว่าง + ยังไม่ผ่าน onboarding)
  UserProfile getUserProfile() {
    try {
      final box = Hive.box(HiveBoxes.userProfile);
      final raw = box.get('profile');
      if (raw == null) return const UserProfile();
      return UserProfile.fromMap(Map<dynamic, dynamic>.from(raw as Map));
    } catch (e, stack) {
      _log('getUserProfile', e, stack);
      return const UserProfile();
    }
  }

  /// บันทึกโปรไฟล์ผู้ใช้ลง Hive
  Future<void> saveUserProfile(UserProfile profile) async {
    try {
      final box = Hive.box(HiveBoxes.userProfile);
      await box.put('profile', profile.toMap());
    } catch (e, stack) {
      _log('saveUserProfile', e, stack);
    }
  }

  // ─── จัดการข้อมูล (Data Management) ──────────────────────────────────

  /// ลบข้อมูลทั้งหมดในแอป (ผลประเมิน, คะแนนเกม, การตั้งค่า)
  /// หมายเหตุ: ไม่ลบโปรไฟล์ผู้ใช้ (ชื่อ/อายุ/เพศ/รายชื่อครอบครัว)
  Future<void> clearAllData() async {
    try {
      await Hive.box(HiveBoxes.assessmentResults).clear();
      await Hive.box(HiveBoxes.gameScores).clear();
      await Hive.box(HiveBoxes.screenTimeSettings).clear();
    } catch (e, stack) {
      _log('clearAllData', e, stack);
    }
  }

  // ─── ฟังก์ชันช่วย ────────────────────────────────────────────

  /// ดึงข้อมูลจาก Hive box ในรูปแบบ List ของ Map
  List<Map<dynamic, dynamic>> _getMapList(Box box, String key) {
    final raw = box.get(key);
    if (raw == null) return [];
    return List<Map<dynamic, dynamic>>.from(raw as List);
  }

  /// บันทึก log เมื่อเกิดข้อผิดพลาด เพื่อช่วย debug
  void _log(String method, Object error, StackTrace stack) {
    developer.log(
      'StorageService.$method failed: $error',
      name: 'DemenishAI',
      error: error,
      stackTrace: stack,
    );
  }
}
