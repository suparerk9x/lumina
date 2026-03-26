import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../shared/storage/game_score.dart';
import '../../../shared/storage/storage_service.dart';

/// ไฟล์นี้จัดการ "สถานะ" (state) ของเกมจับคู่เสียง
/// ใช้ Riverpod Notifier เพื่อเก็บข้อมูลเกม เช่น คำถาม, คะแนน, รอบปัจจุบัน
/// และมี method สำหรับเริ่มเกม, เลือกคำตอบ, ไปข้อถัดไป

// ─── โมเดลข้อมูลของแต่ละรอบ (1 ข้อ) ────────────────────────────────────────────

/// เก็บข้อมูล 1 รอบ: คำที่ถูกต้อง + ตัวเลือก 4 ตัว (สุ่มแล้ว)
class SoundMatchRound {
  const SoundMatchRound({
    required this.correctWord,
    required this.options, // ตัวเลือก 4 คำ (1 คำถูก + 3 คำผิด) สุ่มลำดับแล้ว
  });

  final String correctWord; // คำที่ถูกต้อง (คำที่ถูกอ่านออกเสียง)
  final List<String> options; // ตัวเลือกทั้ง 4 คำ
}

// ─── โมเดลสถานะรวมของเกมทั้งหมด ────────────────────────────────────────────

/// เก็บสถานะทั้งหมดของเกม: รอบทั้งหมด, ข้อปัจจุบัน, คะแนน, ตัวเลือกที่เลือก
class SoundMatchState {
  const SoundMatchState({
    this.rounds = const [],
    this.currentRound = 0,
    this.score = 0,
    this.selectedWord,
    this.showFeedback = false,
    this.isComplete = false,
    this.startTime,
  });

  final List<SoundMatchRound> rounds; // รอบทั้งหมด (เช่น 10 ข้อ)
  final int currentRound; // หมายเลขข้อปัจจุบัน (เริ่มจาก 0)
  final int score; // คะแนนสะสม
  final String? selectedWord; // คำที่ผู้ใช้เลือก (null = ยังไม่ได้เลือก)
  final bool showFeedback; // กำลังแสดงผลถูก/ผิด (เขียว/แดง)
  final bool isComplete; // เล่นครบทุกข้อแล้ว
  final DateTime? startTime; // เวลาเริ่มเกม (ใช้คำนวณระยะเวลา)

  /// จำนวนข้อทั้งหมด
  int get totalRounds => rounds.length;

  /// ข้อมูลรอบปัจจุบัน (null ถ้ายังไม่เริ่ม)
  SoundMatchRound? get current =>
      currentRound < rounds.length ? rounds[currentRound] : null;

  /// ตรวจว่าผู้ใช้เลือกคำตอบถูกหรือไม่
  bool get isCorrectSelection =>
      selectedWord != null && selectedWord == current?.correctWord;

  /// สร้าง state ใหม่โดยเปลี่ยนเฉพาะค่าที่ต้องการ (Immutable pattern)
  SoundMatchState copyWith({
    List<SoundMatchRound>? rounds,
    int? currentRound,
    int? score,
    String? selectedWord,
    bool? showFeedback,
    bool? isComplete,
    DateTime? startTime,
    bool clearSelected = false,
  }) {
    return SoundMatchState(
      rounds: rounds ?? this.rounds,
      currentRound: currentRound ?? this.currentRound,
      score: score ?? this.score,
      selectedWord: clearSelected ? null : (selectedWord ?? this.selectedWord),
      showFeedback: showFeedback ?? this.showFeedback,
      isComplete: isComplete ?? this.isComplete,
      startTime: startTime ?? this.startTime,
    );
  }
}

// ─── Notifier — ตัวจัดการ logic ของเกม ───────────────────────────────────────────────

/// Notifier ควบคุม logic หลักของเกม: สุ่มคำถาม, ตรวจคำตอบ, เปลี่ยนข้อ, บันทึกคะแนน
class SoundMatchNotifier extends Notifier<SoundMatchState> {
  final _random = Random(); // ตัวสุ่มลำดับ

  @override
  SoundMatchState build() => const SoundMatchState(); // สถานะเริ่มต้นว่างเปล่า

  /// สุ่มสร้าง 10 ข้อ โดยแต่ละข้อมีคำถูก 1 คำ + คำผิด 3 คำ
  void startGame() {
    // สุ่มคำจาก word pool แล้วเลือกมาตามจำนวนรอบ
    final pool = List<String>.from(AppConstants.wordPool)..shuffle(_random);
    final words = pool.take(AppConstants.soundMatchRounds).toList();

    final rounds = words.map((correctWord) {
      // เลือกคำผิด 3 คำ (ไม่ซ้ำกับคำถูก) เป็นตัวเลือกหลอก
      final others = List<String>.from(AppConstants.wordPool)
        ..remove(correctWord)
        ..shuffle(_random);
      final distractors = others.take(3).toList();
      final options = [correctWord, ...distractors]..shuffle(_random);
      return SoundMatchRound(correctWord: correctWord, options: options);
    }).toList();

    state = SoundMatchState(
      rounds: rounds,
      startTime: DateTime.now(),
    );
  }

  /// เมื่อผู้ใช้แตะตัวเลือก — ตรวจว่าถูกหรือผิด แล้วเพิ่มคะแนนถ้าถูก
  void selectAnswer(String word) {
    if (state.showFeedback || state.isComplete) return;

    final isCorrect = word == state.current?.correctWord;
    state = state.copyWith(
      selectedWord: word,
      showFeedback: true,
      score: isCorrect ? state.score + 1 : state.score,
    );
  }

  /// เรียกหลังแสดงผลถูก/ผิดเสร็จ — ไปข้อถัดไปหรือจบเกม
  void advanceRound() {
    final next = state.currentRound + 1;
    if (next >= state.totalRounds) {
      state = state.copyWith(
        isComplete: true,
        showFeedback: false,
        clearSelected: true,
      );
      _saveScore();
    } else {
      state = state.copyWith(
        currentRound: next,
        showFeedback: false,
        clearSelected: true,
      );
    }
  }

  /// บันทึกคะแนนลง local storage เมื่อเล่นจบ
  Future<void> _saveScore() async {
    final elapsed =
        DateTime.now().difference(state.startTime ?? DateTime.now());
    final score = GameScore(
      date: DateTime.now(),
      gameType: 'sound_match',
      score: state.score,
      total: state.totalRounds,
      durationSeconds: elapsed.inSeconds,
    );
    await StorageService().saveGameScore(score);
  }
}

// ─── Provider — ตัวแปรกลางให้ Widget อื่นเข้าถึง state ได้ ───────────────────────────────────────────────

/// Provider ที่ใช้ใน Widget เพื่ออ่าน/เปลี่ยนสถานะเกมจับคู่เสียง
final soundMatchProvider =
    NotifierProvider<SoundMatchNotifier, SoundMatchState>(
  SoundMatchNotifier.new,
);
