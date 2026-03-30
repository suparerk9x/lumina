import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../shared/services/google_sheets_service.dart';
import '../../../shared/storage/game_score.dart';
import '../../../shared/storage/storage_service.dart';
import 'word_emoji_map.dart';

/// ไฟล์นี้จัดการ "สถานะ" (state) ของเกมจับคู่เสียง
/// รองรับโหลดข้อมูลจาก Google Sheets พร้อม fallback ใช้ข้อมูล hardcoded

// ─── โมเดลข้อมูลของแต่ละรอบ (1 ข้อ) ────────────────────────────────────────────

/// เก็บข้อมูล 1 รอบ: คำที่ถูกต้อง + ตัวเลือก 4 ตัว (สุ่มแล้ว)
class SoundMatchRound {
  const SoundMatchRound({
    required this.correctWord,
    required this.options,
  });

  final String correctWord;
  final List<String> options;
}

// ─── โมเดลสถานะรวมของเกมทั้งหมด ────────────────────────────────────────────

class SoundMatchState {
  const SoundMatchState({
    this.rounds = const [],
    this.currentRound = 0,
    this.score = 0,
    this.selectedWord,
    this.showFeedback = false,
    this.isComplete = false,
    this.startTime,
    this.activeWordPool = const [],
    this.activeEmojiMap = const {},
    this.isLoading = false,
  });

  final List<SoundMatchRound> rounds;
  final int currentRound;
  final int score;
  final String? selectedWord;
  final bool showFeedback;
  final bool isComplete;
  final DateTime? startTime;
  final List<String> activeWordPool; // คำศัพท์ที่ใช้ (จาก Sheet หรือ hardcoded)
  final Map<String, String> activeEmojiMap; // emoji map ที่ใช้
  final bool isLoading; // กำลังโหลดข้อมูลจาก Sheet

  int get totalRounds => rounds.length;

  SoundMatchRound? get current =>
      currentRound < rounds.length ? rounds[currentRound] : null;

  bool get isCorrectSelection =>
      selectedWord != null && selectedWord == current?.correctWord;

  SoundMatchState copyWith({
    List<SoundMatchRound>? rounds,
    int? currentRound,
    int? score,
    String? selectedWord,
    bool? showFeedback,
    bool? isComplete,
    DateTime? startTime,
    bool clearSelected = false,
    List<String>? activeWordPool,
    Map<String, String>? activeEmojiMap,
    bool? isLoading,
  }) {
    return SoundMatchState(
      rounds: rounds ?? this.rounds,
      currentRound: currentRound ?? this.currentRound,
      score: score ?? this.score,
      selectedWord: clearSelected ? null : (selectedWord ?? this.selectedWord),
      showFeedback: showFeedback ?? this.showFeedback,
      isComplete: isComplete ?? this.isComplete,
      startTime: startTime ?? this.startTime,
      activeWordPool: activeWordPool ?? this.activeWordPool,
      activeEmojiMap: activeEmojiMap ?? this.activeEmojiMap,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// ─── Notifier ───────────────────────────────────────────────

class SoundMatchNotifier extends Notifier<SoundMatchState> {
  final _random = Random();

  @override
  SoundMatchState build() => const SoundMatchState();

  /// เริ่มเกม — โหลดข้อมูลจาก Google Sheets ก่อน ถ้าไม่ได้ใช้ hardcoded
  Future<void> startGame() async {
    state = state.copyWith(isLoading: true);

    // พยายามโหลดจาก Google Sheets
    List<String> pool;
    Map<String, String> emojiMap;

    try {
      final sheetData = await GoogleSheetsService().fetchSoundMatchData();
      if (sheetData != null && sheetData.words.length >= 4) {
        pool = sheetData.words;
        emojiMap = sheetData.emojiMap;
        debugPrint('Sound Match: ใช้ข้อมูลจาก Google Sheets (${pool.length} คำ)');
      } else {
        // Fallback ใช้ข้อมูล hardcoded
        pool = AppConstants.wordPool;
        emojiMap = wordEmojiMap;
        debugPrint('Sound Match: ใช้ข้อมูล hardcoded');
      }
    } catch (e) {
      pool = AppConstants.wordPool;
      emojiMap = wordEmojiMap;
      debugPrint('Sound Match: fallback เนื่องจาก error: $e');
    }

    // สุ่มสร้างรอบเกม
    final shuffled = List<String>.from(pool)..shuffle(_random);
    final words = shuffled.take(AppConstants.soundMatchRounds).toList();

    final rounds = words.map((correctWord) {
      final others = List<String>.from(pool)
        ..remove(correctWord)
        ..shuffle(_random);
      final distractors = others.take(3).toList();
      final options = [correctWord, ...distractors]..shuffle(_random);
      return SoundMatchRound(correctWord: correctWord, options: options);
    }).toList();

    state = SoundMatchState(
      rounds: rounds,
      startTime: DateTime.now(),
      activeWordPool: pool,
      activeEmojiMap: emojiMap,
    );
  }

  void selectAnswer(String word) {
    if (state.showFeedback || state.isComplete) return;

    final isCorrect = word == state.current?.correctWord;
    state = state.copyWith(
      selectedWord: word,
      showFeedback: true,
      score: isCorrect ? state.score + 1 : state.score,
    );
  }

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

final soundMatchProvider =
    NotifierProvider<SoundMatchNotifier, SoundMatchState>(
  SoundMatchNotifier.new,
);
