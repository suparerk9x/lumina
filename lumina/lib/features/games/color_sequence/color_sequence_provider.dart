import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/storage/game_score.dart';
import '../../../shared/storage/storage_service.dart';

/// ไฟล์นี้จัดการ state ของเกมกดปุ่มตามลำดับ (Simon Says)
/// ระบบแสดงลำดับสี → ผู้เล่นกดตาม → ถูก=ด่านถัดไป (ยาวขึ้น) → ผิด=จบ

/// สีที่ใช้ในเกม 4 สี
enum GameColor {
  red(Color(0xFFE53935), Color(0xFFFF6F60), 'แดง'),
  green(Color(0xFF43A047), Color(0xFF76D275), 'เขียว'),
  blue(Color(0xFF1E88E5), Color(0xFF6AB7FF), 'น้ำเงิน'),
  yellow(Color(0xFFFDD835), Color(0xFFFFFF6B), 'เหลือง');

  const GameColor(this.color, this.lightColor, this.label);

  final Color color;
  final Color lightColor; // สีตอนกำลัง highlight
  final String label;
}

/// เฟสของเกม
enum GamePhase {
  ready, // พร้อมเริ่ม
  showing, // ระบบกำลังแสดงลำดับ
  inputting, // ผู้เล่นกำลังกด
  correct, // กดถูก แสดง feedback
  wrong, // กดผิด เกมจบ
}

class ColorSequenceState {
  const ColorSequenceState({
    this.sequence = const [],
    this.playerInput = const [],
    this.currentShowIndex = -1,
    this.phase = GamePhase.ready,
    this.level = 0,
    this.highlightColor,
    this.startTime,
  });

  final List<GameColor> sequence; // ลำดับสีที่ระบบสุ่ม
  final List<GameColor> playerInput; // สีที่ผู้เล่นกดแล้ว
  final int currentShowIndex; // index ที่กำลังแสดง (-1 = ไม่แสดง)
  final GamePhase phase;
  final int level; // ด่านปัจจุบัน (เริ่มจาก 1)
  final GameColor? highlightColor; // สีที่กำลัง highlight
  final DateTime? startTime;

  int get sequenceLength => sequence.length;

  ColorSequenceState copyWith({
    List<GameColor>? sequence,
    List<GameColor>? playerInput,
    int? currentShowIndex,
    GamePhase? phase,
    int? level,
    GameColor? highlightColor,
    bool clearHighlight = false,
    DateTime? startTime,
  }) {
    return ColorSequenceState(
      sequence: sequence ?? this.sequence,
      playerInput: playerInput ?? this.playerInput,
      currentShowIndex: currentShowIndex ?? this.currentShowIndex,
      phase: phase ?? this.phase,
      level: level ?? this.level,
      highlightColor: clearHighlight ? null : (highlightColor ?? this.highlightColor),
      startTime: startTime ?? this.startTime,
    );
  }
}

class ColorSequenceNotifier extends Notifier<ColorSequenceState> {
  final _random = Random();

  @override
  ColorSequenceState build() => const ColorSequenceState();

  /// เริ่มเกมใหม่จากด่าน 1
  void startGame() {
    state = ColorSequenceState(
      startTime: DateTime.now(),
      level: 0,
    );
    _nextLevel();
  }

  /// เพิ่มสีใหม่ 1 สีแล้วแสดงลำดับ
  void _nextLevel() {
    final newColor = GameColor.values[_random.nextInt(GameColor.values.length)];
    final newSequence = [...state.sequence, newColor];
    final newLevel = state.level + 1;

    state = state.copyWith(
      sequence: newSequence,
      playerInput: [],
      level: newLevel,
      phase: GamePhase.showing,
    );

    _showSequence();
  }

  /// แสดงลำดับสีทีละตัว
  Future<void> _showSequence() async {
    await Future.delayed(const Duration(milliseconds: 500));

    for (int i = 0; i < state.sequence.length; i++) {
      if (state.phase != GamePhase.showing) return; // ถูก cancel

      state = state.copyWith(
        currentShowIndex: i,
        highlightColor: state.sequence[i],
      );

      await Future.delayed(const Duration(milliseconds: 600));

      state = state.copyWith(
        currentShowIndex: -1,
        clearHighlight: true,
      );

      await Future.delayed(const Duration(milliseconds: 300));
    }

    // เปลี่ยนเป็น inputting mode
    state = state.copyWith(phase: GamePhase.inputting);
  }

  /// ผู้เล่นกดปุ่มสี
  void tapColor(GameColor color) {
    if (state.phase != GamePhase.inputting) return;

    final inputIndex = state.playerInput.length;
    final expected = state.sequence[inputIndex];

    // Highlight ปุ่มที่กด
    state = state.copyWith(highlightColor: color);

    if (color != expected) {
      // กดผิด → จบเกม
      state = state.copyWith(
        phase: GamePhase.wrong,
        playerInput: [...state.playerInput, color],
      );
      _saveScore();
      return;
    }

    // กดถูก
    final newInput = [...state.playerInput, color];
    state = state.copyWith(playerInput: newInput);

    if (newInput.length == state.sequence.length) {
      // กดครบลำดับ → ไปด่านถัดไป
      state = state.copyWith(phase: GamePhase.correct);
      Future.delayed(const Duration(milliseconds: 800), () {
        if (state.phase == GamePhase.correct) {
          state = state.copyWith(clearHighlight: true);
          _nextLevel();
        }
      });
    } else {
      // ยังไม่ครบ clear highlight
      Future.delayed(const Duration(milliseconds: 200), () {
        state = state.copyWith(clearHighlight: true);
      });
    }
  }

  /// เป้าหมาย 20 ด่าน ใช้เป็น benchmark
  /// ผ่าน 20+ = 3 ดาว (100%), 10+ = 2 ดาว (50%), 5+ = 1 ดาว (30%)
  static const int targetLevels = 20;

  Future<void> _saveScore() async {
    final elapsed =
        DateTime.now().difference(state.startTime ?? DateTime.now());
    final passedLevels = state.level - 1;
    final gameScore = GameScore(
      date: DateTime.now(),
      gameType: 'color_sequence',
      score: passedLevels,
      total: targetLevels,
      durationSeconds: elapsed.inSeconds,
    );
    await StorageService().saveGameScore(gameScore);
  }
}

final colorSequenceProvider =
    NotifierProvider<ColorSequenceNotifier, ColorSequenceState>(
  ColorSequenceNotifier.new,
);
