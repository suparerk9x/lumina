import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      title: 'ผลเกมจับคู่ภาพ',
      score: score,
      total: totalPairs,
      goodMessage: 'ความจำเยี่ยม! 🎉',
      okMessage: 'จำได้ดี! 👍',
      fairMessage: 'พอใช้ ลองอีกครั้ง 💪',
      lowMessage: 'ค่อย ๆ ฝึกนะ 🙂',
      goodSub: 'จับคู่ครบ $totalPairs คู่ ใน $attempts ครั้ง — เก่งมาก!',
      okSub: 'ใช้ $attempts ครั้ง สำหรับ $totalPairs คู่ ลองฝึกเพิ่มจะดีขึ้น',
      fairSub: 'ใช้ $attempts ครั้ง ค่อย ๆ ฝึกจำตำแหน่ง',
      lowSub: 'ใช้ $attempts ครั้ง ไม่เป็นไร ลองเล่นอีก',
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
