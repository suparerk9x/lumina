import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../shared/storage/assessment_result.dart';
import '../../shared/storage/storage_service.dart';

/// ไฟล์นี้เก็บ state (สถานะ) ทั้งหมดของแบบประเมินสมอง
/// รวมถึง Notifier ที่ควบคุมการเปลี่ยนแปลง state และคำนวณคะแนน
/// ใช้ Riverpod สำหรับ state management

// ─── โมเดลข้อมูลสถานะแบบประเมิน ────────────────────────────

/// คลาส AssessmentState เก็บข้อมูลสถานะทั้งหมดของแบบประเมิน
/// เช่น อยู่ขั้นตอนไหน คะแนนแต่ละส่วน คำที่ต้องจำ เป็นต้น
class AssessmentState {
  const AssessmentState({
    this.currentStep = 0,
    this.dateTimeScore = 0,
    this.memorizeWords = const [],
    this.countdownScore = 0,
    this.recallScore = 0,
    this.recallOptions = const [],
    this.selectedRecallWords = const {},
    this.isComplete = false,
  });

  final int currentStep; // ขั้นตอนปัจจุบัน 0-3 (มี 4 ขั้นตอน)
  final int dateTimeScore; // คะแนนวัน/เวลา (เต็ม 2)
  final List<String> memorizeWords; // คำ 3 คำที่สุ่มมาให้จำ
  final int countdownScore; // คะแนนนับถอยหลัง (เต็ม 5)
  final int recallScore; // คะแนนจำคำ (เต็ม 3)
  final List<String> recallOptions; // ตัวเลือก 6 คำ (3 ถูก + 3 หลอก)
  final Set<String> selectedRecallWords; // คำที่ผู้ใช้เลือกในขั้นตอนจำคำ
  final bool isComplete; // ทำแบบประเมินครบหรือยัง

  /// คะแนนรวมทั้งหมด = วัน/เวลา + นับถอยหลัง + จำคำ
  int get totalScore => dateTimeScore + countdownScore + recallScore;

  /// คะแนนเต็ม = 10 (2 + 5 + 3)
  int get maxScore => 10;

  /// ชื่อแต่ละขั้นตอนที่แสดงบนแถบความคืบหน้า
  static const List<String> stepTitles = [
    'วัน/เวลา',
    'จำคำ 3 คำ',
    'นับถอยหลัง',
    'จำคำได้ไหม',
  ];

  /// สร้าง state ใหม่โดยเปลี่ยนเฉพาะค่าที่ระบุ (ใช้หลัก immutability)
  AssessmentState copyWith({
    int? currentStep,
    int? dateTimeScore,
    List<String>? memorizeWords,
    int? countdownScore,
    int? recallScore,
    List<String>? recallOptions,
    Set<String>? selectedRecallWords,
    bool? isComplete,
  }) {
    return AssessmentState(
      currentStep: currentStep ?? this.currentStep,
      dateTimeScore: dateTimeScore ?? this.dateTimeScore,
      memorizeWords: memorizeWords ?? this.memorizeWords,
      countdownScore: countdownScore ?? this.countdownScore,
      recallScore: recallScore ?? this.recallScore,
      recallOptions: recallOptions ?? this.recallOptions,
      selectedRecallWords: selectedRecallWords ?? this.selectedRecallWords,
      isComplete: isComplete ?? this.isComplete,
    );
  }
}

// ─── ตัวควบคุม state (Notifier) ─────────────────────────────

/// คลาส AssessmentNotifier ควบคุมการเปลี่ยนแปลง state ทั้งหมด
/// เช่น เริ่มแบบประเมิน, เปลี่ยน step, คำนวณคะแนน, บันทึกผล
class AssessmentNotifier extends Notifier<AssessmentState> {
  @override
  AssessmentState build() => const AssessmentState();

  /// ตัวสุ่มตัวเลข ใช้สำหรับสุ่มคำที่จะให้จำ
  final _random = Random();

  /// รีเซ็ตทุกอย่างแล้วสุ่มคำใหม่สำหรับการทดสอบความจำ
  void startAssessment() {
    // สุ่มคำจากคลังคำ แล้วเลือก 3 คำแรกให้จำ
    final pool = List<String>.from(AppConstants.wordPool)..shuffle(_random);
    final words = pool.take(3).toList();

    // สร้างตัวเลือกสำหรับขั้นตอนจำคำ: 3 คำถูก + 3 คำหลอก (สุ่มลำดับ)
    final remaining = pool.skip(3).toList()..shuffle(_random);
    final distractors = remaining.take(3).toList();
    final options = [...words, ...distractors]..shuffle(_random);

    state = AssessmentState(
      memorizeWords: words,
      recallOptions: options,
    );
  }

  /// ข้ามไปยัง step ที่ระบุ (0-3)
  void goToStep(int step) {
    if (step >= 0 && step < 4) {
      state = state.copyWith(currentStep: step);
    }
  }

  /// ไปขั้นตอนถัดไป
  void nextStep() {
    if (state.currentStep < 3) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  /// ย้อนกลับขั้นตอนก่อนหน้า
  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  /// ขั้นตอนที่ 1: บันทึกคะแนนวัน/เวลา (เต็ม 2 คะแนน)
  void setDateTimeScore(int score) {
    state = state.copyWith(dateTimeScore: score);
  }

  /// ขั้นตอนที่ 3: บันทึกคะแนนนับถอยหลัง (เต็ม 5 คะแนน)
  void setCountdownScore(int score) {
    state = state.copyWith(countdownScore: score);
  }

  /// ขั้นตอนที่ 4: เลือก/ยกเลิกคำที่คิดว่าเคยจำได้
  void toggleRecallWord(String word) {
    if (!state.recallOptions.contains(word)) return; // ตรวจสอบว่าคำนี้อยู่ในตัวเลือก
    final updated = Set<String>.from(state.selectedRecallWords);
    if (updated.contains(word)) {
      updated.remove(word); // ถ้าเลือกอยู่แล้ว ให้ยกเลิก
    } else {
      updated.add(word); // ถ้ายังไม่เลือก ให้เพิ่มเข้าไป
    }
    state = state.copyWith(selectedRecallWords: updated);
  }

  /// ส่งคำตอบขั้นตอนจำคำ แล้วคำนวณคะแนน
  void submitRecall() {
    int score = 0;
    // นับจำนวนคำที่เลือกถูก (ตรงกับคำที่ต้องจำ)
    for (final word in state.selectedRecallWords) {
      if (state.memorizeWords.contains(word)) {
        score++;
      }
      // ไม่หักคะแนนถ้าเลือกผิด
    }
    state = state.copyWith(
      recallScore: score,
      isComplete: true,
    );
  }

  /// บันทึกผลการประเมินลง Hive (ฐานข้อมูลในเครื่อง) ผ่าน StorageService
  Future<void> saveResult() async {
    final result = AssessmentResult(
      date: DateTime.now(),
      totalScore: state.totalScore,
      maxScore: state.maxScore,
      sectionScores: {
        'step1': state.dateTimeScore,
        'step2': 0, // memorize has no score itself
        'step3': state.countdownScore,
        'step4': state.recallScore,
      },
    );
    await StorageService().saveAssessmentResult(result);
  }
}

// ─── Provider (ตัวให้บริการ state สำหรับทั้งแอป) ───────────

/// assessmentProvider ใช้แชร์ state ของแบบประเมินให้ทุกหน้าจอเข้าถึงได้
final assessmentProvider =
    NotifierProvider<AssessmentNotifier, AssessmentState>(
  AssessmentNotifier.new,
);
