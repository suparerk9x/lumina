import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/storage/game_score.dart';
import '../../../shared/storage/storage_service.dart';
import 'sequence_data.dart';

/// ไฟล์นี้จัดการ "สถานะ" (state) ของเกมเรียงลำดับ
/// ใช้ Riverpod Notifier เพื่อเก็บข้อมูลเกม เช่น โจทย์, คะแนน, ลำดับที่ผู้ใช้แตะ
/// และมี method สำหรับเริ่มเกม, แตะรายการ, ย้อนกลับ, ส่งคำตอบ, ไปข้อถัดไป

// ─── โมเดลข้อมูลของแต่ละรอบ (1 ข้อ) ────────────────────────────────────────────

/// เก็บข้อมูล 1 รอบ: หัวข้อ, ลำดับที่ถูกต้อง, และลำดับที่สลับแล้ว (แสดงบนจอ)
class SequenceRound {
  const SequenceRound({
    required this.datasetTitle,
    required this.correctOrder, // รายการเรียงลำดับถูกต้อง
    required this.scrambled, // รายการสลับลำดับแล้ว (แสดงบนจอ)
  });

  final String datasetTitle; // ชื่อหัวข้อ เช่น "กิจวัตรประจำวัน"
  final List<SequenceItem> correctOrder; // ลำดับที่ถูกต้อง (เฉลย)
  final List<SequenceItem> scrambled; // ลำดับที่สุ่มสลับแล้ว
}

// ─── ผลลัพธ์ของแต่ละรอบ ─────────────────────────────

/// สถานะผลลัพธ์: none = ยังไม่ส่งคำตอบ, correct = ถูก, wrong = ผิด
enum RoundResult { none, correct, wrong }

// ─── โมเดลสถานะรวมของเกมทั้งหมด ────────────────────────────────────────────

/// เก็บสถานะทั้งหมดของเกมเรียงลำดับ: รอบทั้งหมด, ข้อปัจจุบัน, ลำดับที่แตะ, คะแนน
class SequenceGameState {
  const SequenceGameState({
    this.rounds = const [],
    this.currentRound = 0,
    this.score = 0,
    this.tappedOrder = const [],
    this.roundResult = RoundResult.none,
    this.isComplete = false,
    this.startTime,
  });

  final List<SequenceRound> rounds; // รอบทั้งหมด
  final int currentRound; // หมายเลขข้อปัจจุบัน (เริ่มจาก 0)
  final int score; // คะแนนสะสม
  final List<SequenceItem> tappedOrder; // ลำดับที่ผู้ใช้แตะ
  final RoundResult roundResult; // ผลลัพธ์ของรอบนี้
  final bool isComplete; // เล่นครบทุกข้อแล้ว
  final DateTime? startTime; // เวลาเริ่มเกม

  /// จำนวนข้อทั้งหมด
  int get totalRounds => rounds.length;

  /// ข้อมูลรอบปัจจุบัน (null ถ้ายังไม่เริ่ม)
  SequenceRound? get current =>
      currentRound < rounds.length ? rounds[currentRound] : null;

  /// จำนวนรายการที่ต้องแตะในรอบนี้
  int get itemsInRound => current?.scrambled.length ?? 0;

  /// แตะครบทุกรายการแล้วหรือยัง (พร้อมส่งคำตอบ)
  bool get allTapped => tappedOrder.length >= itemsInRound;

  /// หาลำดับที่ผู้ใช้แตะรายการนี้ (คืน -1 ถ้ายังไม่แตะ)
  int tapIndexOf(SequenceItem item) => tappedOrder.indexOf(item);

  /// สร้าง state ใหม่โดยเปลี่ยนเฉพาะค่าที่ต้องการ (Immutable pattern)
  SequenceGameState copyWith({
    List<SequenceRound>? rounds,
    int? currentRound,
    int? score,
    List<SequenceItem>? tappedOrder,
    RoundResult? roundResult,
    bool? isComplete,
    DateTime? startTime,
  }) {
    return SequenceGameState(
      rounds: rounds ?? this.rounds,
      currentRound: currentRound ?? this.currentRound,
      score: score ?? this.score,
      tappedOrder: tappedOrder ?? this.tappedOrder,
      roundResult: roundResult ?? this.roundResult,
      isComplete: isComplete ?? this.isComplete,
      startTime: startTime ?? this.startTime,
    );
  }
}

// ─── Notifier — ตัวจัดการ logic ของเกม ───────────────────────────────────────────────

/// Notifier ควบคุม logic หลักของเกมเรียงลำดับ:
/// สร้างโจทย์, รับการแตะ, ตรวจคำตอบ, บันทึกคะแนน
class SequenceGameNotifier extends Notifier<SequenceGameState> {
  final _random = Random(); // ตัวสุ่มลำดับ

  @override
  SequenceGameState build() => const SequenceGameState(); // สถานะเริ่มต้นว่างเปล่า

  /// สร้างโจทย์จาก dataset ทั้งหมด โดยสุ่มสลับลำดับรายการในแต่ละข้อ
  void startGame() {
    final rounds = <SequenceRound>[];

    for (final dataset in sequenceDatasets) {
      // เลือก 4 รายการแรก (หรือทั้งหมดถ้ามีน้อยกว่า 4)
      final count = dataset.items.length < 4 ? dataset.items.length : 4;
      final correctOrder = dataset.items.sublist(0, count);
      final scrambled = List<SequenceItem>.from(correctOrder);

      // สุ่มจนกว่าลำดับจะต่างจากเฉลยจริง ๆ (ไม่งั้นจะง่ายเกินไป)
      do {
        scrambled.shuffle(_random);
      } while (_listsEqual(scrambled, correctOrder) && count > 1);

      rounds.add(SequenceRound(
        datasetTitle: dataset.title,
        correctOrder: correctOrder,
        scrambled: scrambled,
      ));
    }

    state = SequenceGameState(
      rounds: rounds,
      startTime: DateTime.now(),
    );
  }

  /// เมื่อผู้ใช้แตะรายการ — เพิ่มเข้าลำดับที่เลือก
  void tapItem(SequenceItem item) {
    if (state.roundResult != RoundResult.none) return; // ตอบแล้ว ไม่รับเพิ่ม
    if (state.tappedOrder.contains(item)) return; // แตะแล้ว ไม่รับซ้ำ

    state = state.copyWith(
      tappedOrder: [...state.tappedOrder, item],
    );
  }

  /// ยกเลิกการแตะล่าสุด (ลบรายการสุดท้ายออกจากลำดับที่เลือก)
  void undoLastTap() {
    if (state.tappedOrder.isEmpty) return;
    if (state.roundResult != RoundResult.none) return;

    state = state.copyWith(
      tappedOrder: state.tappedOrder.sublist(0, state.tappedOrder.length - 1),
    );
  }

  /// ส่งคำตอบ — เปรียบเทียบลำดับที่ผู้ใช้แตะกับเฉลย
  void submitAnswer() {
    final round = state.current;
    if (round == null || !state.allTapped) return;

    final isCorrect = _listsEqual(state.tappedOrder, round.correctOrder);

    state = state.copyWith(
      roundResult: isCorrect ? RoundResult.correct : RoundResult.wrong,
      score: isCorrect ? state.score + 1 : state.score,
    );
  }

  /// ไปข้อถัดไป หรือจบเกมถ้าเป็นข้อสุดท้าย
  void nextRound() {
    final next = state.currentRound + 1;
    if (next >= state.totalRounds) {
      state = state.copyWith(isComplete: true);
      _saveScore();
    } else {
      state = state.copyWith(
        currentRound: next,
        tappedOrder: [],
        roundResult: RoundResult.none,
      );
    }
  }

  /// บันทึกคะแนนลง local storage เมื่อเล่นจบ
  Future<void> _saveScore() async {
    final elapsed =
        DateTime.now().difference(state.startTime ?? DateTime.now());
    final score = GameScore(
      date: DateTime.now(),
      gameType: 'sequence',
      score: state.score,
      total: state.totalRounds,
      durationSeconds: elapsed.inSeconds,
    );
    await StorageService().saveGameScore(score);
  }

  /// เปรียบเทียบ 2 ลิสต์ว่าเหมือนกันหรือไม่ (ตรวจทีละตำแหน่ง)
  bool _listsEqual(List<SequenceItem> a, List<SequenceItem> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].label != b[i].label) return false;
    }
    return true;
  }
}

// ─── Provider — ตัวแปรกลางให้ Widget อื่นเข้าถึง state ได้ ───────────────────────────────────────────────

/// Provider ที่ใช้ใน Widget เพื่ออ่าน/เปลี่ยนสถานะเกมเรียงลำดับ
final sequenceGameProvider =
    NotifierProvider<SequenceGameNotifier, SequenceGameState>(
  SequenceGameNotifier.new,
);
