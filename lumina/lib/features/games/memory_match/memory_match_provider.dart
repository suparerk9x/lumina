import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings.dart';
import '../../../shared/services/google_sheets_service.dart';
import '../../../shared/storage/game_score.dart';
import '../../../shared/storage/storage_service.dart';
import '../sound_match/word_emoji_map.dart';

/// ไฟล์นี้จัดการ state ของเกมจับคู่ภาพ (Memory Match)
/// รองรับ 4, 6, หรือ 8 คู่ (8, 12, 16 การ์ด)

/// ระดับความยากของเกม
enum MemoryDifficulty {
  easy(4, 'game.memoryMatch.easy'),
  medium(6, 'game.memoryMatch.medium'),
  hard(8, 'game.memoryMatch.hard');

  const MemoryDifficulty(this.pairs, this.labelKey);

  final int pairs; // จำนวนคู่
  final String labelKey;

  String get label => tr(labelKey);
  String get subtitle => trp('game.memoryMatch.cardCount', {'n': '${pairs * 2}'});

  /// จำนวน column ของ grid ตามความยาก
  int get columns => pairs <= 4 ? 2 : pairs <= 6 ? 3 : 4;

  /// คำนวณคะแนนแบบยุติธรรม
  /// หลักการ: ครั้งแรก ๆ ต้องเปิดสุ่ม (ยังไม่เคยเห็น) ถือเป็น "ต้นทุน"
  /// - ต้นทุนเริ่มต้น = ceil(pairs / 2) ครั้ง (ที่ต้องสุ่มเปิดเพื่อดูภาพก่อน)
  /// - หลังจากนั้นถ้าจำได้หมด = pairs ครั้ง
  /// - ดังนั้น minimum ที่เป็นไปได้จริง ≈ pairs + ceil(pairs / 2)
  ///
  /// 4 คู่: min ~6, good ≤8, ok ≤12, fair ≤16
  /// 6 คู่: min ~9, good ≤12, ok ≤18, fair ≤24
  /// 8 คู่: min ~12, good ≤16, ok ≤24, fair ≤32
  int calculateScore(int attempts) {
    final minRealistic = pairs + (pairs / 2).ceil(); // ต้นทุนขั้นต่ำจริง
    final ratio = attempts / minRealistic;

    if (ratio <= 1.3) return pairs; // เต็ม — เกือบ perfect
    if (ratio <= 2.0) return (pairs * 0.75).round(); // ดี
    if (ratio <= 3.0) return (pairs * 0.5).round(); // พอใช้
    return (pairs * 0.25).ceil(); // ต้องฝึกเพิ่ม
  }
}

/// ข้อมูลการ์ด 1 ใบ
class MemoryCard {
  MemoryCard({
    required this.id,
    required this.pairId,
    required this.emoji,
    required this.label,
    this.isFlipped = false,
    this.isMatched = false,
  });

  final int id;
  final int pairId;
  final String emoji;
  final String label;
  bool isFlipped;
  bool isMatched;

  MemoryCard copyWith({bool? isFlipped, bool? isMatched}) {
    return MemoryCard(
      id: id,
      pairId: pairId,
      emoji: emoji,
      label: label,
      isFlipped: isFlipped ?? this.isFlipped,
      isMatched: isMatched ?? this.isMatched,
    );
  }
}

/// สถานะรวมของเกม
class MemoryMatchState {
  const MemoryMatchState({
    this.cards = const [],
    this.flippedIndices = const [],
    this.matchedPairs = 0,
    this.totalPairs = 4,
    this.attempts = 0,
    this.isComplete = false,
    this.isChecking = false,
    this.startTime,
    this.isLoading = false,
    this.difficulty = MemoryDifficulty.easy,
  });

  final List<MemoryCard> cards;
  final List<int> flippedIndices;
  final int matchedPairs;
  final int totalPairs;
  final int attempts;
  final bool isComplete;
  final bool isChecking;
  final DateTime? startTime;
  final bool isLoading;
  final MemoryDifficulty difficulty;

  MemoryMatchState copyWith({
    List<MemoryCard>? cards,
    List<int>? flippedIndices,
    int? matchedPairs,
    int? totalPairs,
    int? attempts,
    bool? isComplete,
    bool? isChecking,
    DateTime? startTime,
    bool? isLoading,
    MemoryDifficulty? difficulty,
  }) {
    return MemoryMatchState(
      cards: cards ?? this.cards,
      flippedIndices: flippedIndices ?? this.flippedIndices,
      matchedPairs: matchedPairs ?? this.matchedPairs,
      totalPairs: totalPairs ?? this.totalPairs,
      attempts: attempts ?? this.attempts,
      isComplete: isComplete ?? this.isComplete,
      isChecking: isChecking ?? this.isChecking,
      startTime: startTime ?? this.startTime,
      isLoading: isLoading ?? this.isLoading,
      difficulty: difficulty ?? this.difficulty,
    );
  }
}

class MemoryMatchNotifier extends Notifier<MemoryMatchState> {
  final _random = Random();

  @override
  MemoryMatchState build() => const MemoryMatchState();

  /// เริ่มเกม — รับจำนวนคู่ตาม difficulty
  Future<void> startGame([MemoryDifficulty difficulty = MemoryDifficulty.easy]) async {
    state = const MemoryMatchState(isLoading: true);

    final pairCount = difficulty.pairs;

    Map<String, String> emojiMap;

    try {
      final sheetData = await GoogleSheetsService().fetchSoundMatchData();
      if (sheetData != null && sheetData.words.length >= pairCount) {
        emojiMap = sheetData.emojiMap;
        debugPrint('Memory Match: ใช้ข้อมูลจาก Google Sheets');
      } else {
        emojiMap = wordEmojiMap;
        debugPrint('Memory Match: ใช้ข้อมูล hardcoded');
      }
    } catch (e) {
      emojiMap = wordEmojiMap;
      debugPrint('Memory Match: fallback เนื่องจาก error: $e');
    }

    // สุ่มเลือกตามจำนวนคู่
    final entries = emojiMap.entries.toList()..shuffle(_random);
    final selected = entries.take(pairCount).toList();

    final cards = <MemoryCard>[];
    for (int i = 0; i < selected.length; i++) {
      final entry = selected[i];
      cards.add(MemoryCard(
        id: i * 2,
        pairId: i,
        emoji: entry.value,
        label: entry.key,
      ));
      cards.add(MemoryCard(
        id: i * 2 + 1,
        pairId: i,
        emoji: entry.value,
        label: entry.key,
      ));
    }

    cards.shuffle(_random);

    state = MemoryMatchState(
      cards: cards,
      totalPairs: pairCount,
      startTime: DateTime.now(),
      difficulty: difficulty,
    );
  }

  void flipCard(int index) {
    if (state.isChecking) return;
    if (state.isComplete) return;
    if (index < 0 || index >= state.cards.length) return;

    final card = state.cards[index];
    if (card.isFlipped || card.isMatched) return;
    if (state.flippedIndices.length >= 2) return;

    final newCards = List<MemoryCard>.from(state.cards);
    newCards[index] = card.copyWith(isFlipped: true);
    final newFlipped = [...state.flippedIndices, index];

    state = state.copyWith(cards: newCards, flippedIndices: newFlipped);

    if (newFlipped.length == 2) {
      state = state.copyWith(isChecking: true);
      _checkMatch();
    }
  }

  Future<void> _checkMatch() async {
    await Future.delayed(const Duration(milliseconds: 800));

    final idx1 = state.flippedIndices[0];
    final idx2 = state.flippedIndices[1];
    final card1 = state.cards[idx1];
    final card2 = state.cards[idx2];

    final newCards = List<MemoryCard>.from(state.cards);
    final newAttempts = state.attempts + 1;

    if (card1.pairId == card2.pairId) {
      newCards[idx1] = card1.copyWith(isMatched: true, isFlipped: true);
      newCards[idx2] = card2.copyWith(isMatched: true, isFlipped: true);
      final newMatched = state.matchedPairs + 1;
      final isComplete = newMatched >= state.totalPairs;

      state = state.copyWith(
        cards: newCards,
        flippedIndices: [],
        matchedPairs: newMatched,
        attempts: newAttempts,
        isChecking: false,
        isComplete: isComplete,
      );

      if (isComplete) _saveScore();
    } else {
      newCards[idx1] = card1.copyWith(isFlipped: false);
      newCards[idx2] = card2.copyWith(isFlipped: false);

      state = state.copyWith(
        cards: newCards,
        flippedIndices: [],
        attempts: newAttempts,
        isChecking: false,
      );
    }
  }

  Future<void> _saveScore() async {
    final elapsed =
        DateTime.now().difference(state.startTime ?? DateTime.now());
    final score = state.difficulty.calculateScore(state.attempts);

    final gameScore = GameScore(
      date: DateTime.now(),
      gameType: 'memory_match',
      score: score,
      total: state.totalPairs,
      durationSeconds: elapsed.inSeconds,
    );
    await StorageService().saveGameScore(gameScore);
  }
}

final memoryMatchProvider =
    NotifierProvider<MemoryMatchNotifier, MemoryMatchState>(
  MemoryMatchNotifier.new,
);
