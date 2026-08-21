import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/strings.dart';
import '../../../shared/widgets/game_result_screen.dart';
import 'memory_match_game.dart';
import 'memory_match_provider.dart';

/// หน้าแสดงผลลัพธ์เกมจับคู่ภาพ

class MemoryMatchResult extends ConsumerWidget {
  const MemoryMatchResult({
    super.key,
    required this.attempts,
    required this.totalPairs,
    required this.difficulty,
  });

  final int attempts;
  final int totalPairs;
  final MemoryDifficulty difficulty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final score = difficulty.calculateScore(attempts);

    return GameResultScreen(
      title: tr('game.memoryMatch.resultTitle'),
      score: score,
      total: totalPairs,
      goodMessage: tr('game.memoryMatch.goodMessage'),
      okMessage: tr('game.memoryMatch.okMessage'),
      fairMessage: tr('game.memoryMatch.fairMessage'),
      lowMessage: tr('game.memoryMatch.lowMessage'),
      goodSub: trp('game.memoryMatch.goodSub',
          {'pairs': '$totalPairs', 'attempts': '$attempts'}),
      okSub: trp('game.memoryMatch.okSub',
          {'attempts': '$attempts', 'pairs': '$totalPairs'}),
      fairSub: trp('game.memoryMatch.fairSub', {'attempts': '$attempts'}),
      lowSub: trp('game.memoryMatch.lowSub', {'attempts': '$attempts'}),
      onPlayAgain: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => MemoryMatchGame()),
        );
      },
      onGoHome: () {
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
    );
  }
}
