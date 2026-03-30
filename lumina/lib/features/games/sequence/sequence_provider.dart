import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/services/google_sheets_service.dart';
import '../../../shared/storage/game_score.dart';
import '../../../shared/storage/storage_service.dart';
import 'sequence_data.dart';

/// ไฟล์นี้จัดการ "สถานะ" (state) ของเกมเรียงลำดับ
/// รองรับโหลดข้อมูลจาก Google Sheets พร้อม fallback ใช้ข้อมูล hardcoded

// ─── โมเดลข้อมูลของแต่ละรอบ ────────────────────────────────────────────

class SequenceRound {
  const SequenceRound({
    required this.datasetTitle,
    required this.correctOrder,
    required this.scrambled,
  });

  final String datasetTitle;
  final List<SequenceItem> correctOrder;
  final List<SequenceItem> scrambled;
}

enum RoundResult { none, correct, wrong }

// ─── โมเดลสถานะรวมของเกมทั้งหมด ────────────────────────────────────────────

class SequenceGameState {
  const SequenceGameState({
    this.rounds = const [],
    this.currentRound = 0,
    this.score = 0,
    this.tappedOrder = const [],
    this.roundResult = RoundResult.none,
    this.isComplete = false,
    this.startTime,
    this.isLoading = false,
  });

  final List<SequenceRound> rounds;
  final int currentRound;
  final int score;
  final List<SequenceItem> tappedOrder;
  final RoundResult roundResult;
  final bool isComplete;
  final DateTime? startTime;
  final bool isLoading;

  int get totalRounds => rounds.length;

  SequenceRound? get current =>
      currentRound < rounds.length ? rounds[currentRound] : null;

  int get itemsInRound => current?.scrambled.length ?? 0;

  bool get allTapped => tappedOrder.length >= itemsInRound;

  int tapIndexOf(SequenceItem item) => tappedOrder.indexOf(item);

  SequenceGameState copyWith({
    List<SequenceRound>? rounds,
    int? currentRound,
    int? score,
    List<SequenceItem>? tappedOrder,
    RoundResult? roundResult,
    bool? isComplete,
    DateTime? startTime,
    bool? isLoading,
  }) {
    return SequenceGameState(
      rounds: rounds ?? this.rounds,
      currentRound: currentRound ?? this.currentRound,
      score: score ?? this.score,
      tappedOrder: tappedOrder ?? this.tappedOrder,
      roundResult: roundResult ?? this.roundResult,
      isComplete: isComplete ?? this.isComplete,
      startTime: startTime ?? this.startTime,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// ─── Notifier ───────────────────────────────────────────────

class SequenceGameNotifier extends Notifier<SequenceGameState> {
  final _random = Random();

  @override
  SequenceGameState build() => const SequenceGameState();

  /// เริ่มเกม — โหลดข้อมูลจาก Google Sheets ก่อน ถ้าไม่ได้ใช้ hardcoded
  Future<void> startGame() async {
    state = state.copyWith(isLoading: true);

    // พยายามโหลดจาก Google Sheets
    List<SequenceDataset> datasets;

    try {
      final sheetData = await GoogleSheetsService().fetchSequenceData();
      if (sheetData != null && sheetData.datasets.isNotEmpty) {
        // แปลงจาก Sheet format เป็น SequenceDataset
        datasets = sheetData.datasets
            .map((d) => SequenceDataset(
                  title: d.title,
                  items: d.items
                      .map((item) =>
                          SequenceItem(label: item.label, emoji: item.emoji))
                      .toList(),
                ))
            .toList();
        debugPrint(
            'Sequence: ใช้ข้อมูลจาก Google Sheets (${datasets.length} ชุด)');
      } else {
        datasets = sequenceDatasets;
        debugPrint('Sequence: ใช้ข้อมูล hardcoded');
      }
    } catch (e) {
      datasets = sequenceDatasets;
      debugPrint('Sequence: fallback เนื่องจาก error: $e');
    }

    // สร้างรอบเกม
    final rounds = <SequenceRound>[];

    for (final dataset in datasets) {
      // ใช้ items ทั้งหมดจาก dataset (รองรับจำนวนเท่าไหร่ก็ได้)
      final correctOrder = List<SequenceItem>.from(dataset.items);
      final scrambled = List<SequenceItem>.from(correctOrder);

      do {
        scrambled.shuffle(_random);
      } while (_listsEqual(scrambled, correctOrder) && correctOrder.length > 1);

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

  void tapItem(SequenceItem item) {
    if (state.roundResult != RoundResult.none) return;
    if (state.tappedOrder.contains(item)) return;

    state = state.copyWith(
      tappedOrder: [...state.tappedOrder, item],
    );
  }

  void undoLastTap() {
    if (state.tappedOrder.isEmpty) return;
    if (state.roundResult != RoundResult.none) return;

    state = state.copyWith(
      tappedOrder: state.tappedOrder.sublist(0, state.tappedOrder.length - 1),
    );
  }

  void submitAnswer() {
    final round = state.current;
    if (round == null || !state.allTapped) return;

    final isCorrect = _listsEqual(state.tappedOrder, round.correctOrder);

    state = state.copyWith(
      roundResult: isCorrect ? RoundResult.correct : RoundResult.wrong,
      score: isCorrect ? state.score + 1 : state.score,
    );
  }

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

  bool _listsEqual(List<SequenceItem> a, List<SequenceItem> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].label != b[i].label) return false;
    }
    return true;
  }
}

final sequenceGameProvider =
    NotifierProvider<SequenceGameNotifier, SequenceGameState>(
  SequenceGameNotifier.new,
);
