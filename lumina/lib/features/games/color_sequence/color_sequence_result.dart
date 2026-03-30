import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/game_result_screen.dart';
import 'color_sequence_game.dart';
import 'color_sequence_provider.dart';

/// หน้าแสดงผลลัพธ์เกมกดปุ่มตามลำดับ

class ColorSequenceResult extends ConsumerWidget {
  const ColorSequenceResult({
    super.key,
    required this.level,
    required this.passedLevels,
  });

  final int level; // ด่านที่พยายาม
  final int passedLevels; // ด่านที่ผ่าน

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GameResultScreen(
      title: 'ผลเกมกดปุ่มตามลำดับ',
      score: passedLevels,
      total: ColorSequenceNotifier.targetLevels,
      goodMessage: 'ความจำเป็นเลิศ! 🎉',
      okMessage: 'เก่งมาก! 👍',
      fairMessage: 'ดีแล้ว ลองอีกครั้ง 💪',
      lowMessage: 'ค่อย ๆ ฝึกนะ 🙂',
      goodSub: 'ผ่าน $passedLevels ด่าน — จำลำดับได้ยอดเยี่ยม!',
      okSub: 'ผ่าน $passedLevels ด่าน ลองฝึกเพิ่มจะไปได้ไกลกว่านี้',
      fairSub: 'ผ่าน $passedLevels ด่าน ค่อย ๆ ฝึกจะดีขึ้น',
      lowSub: 'ไม่เป็นไร ลองเล่นอีกครั้ง',
      onPlayAgain: () {
        ref.read(colorSequenceProvider.notifier).startGame();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => ColorSequenceGame()),
        );
      },
      onGoHome: () {
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
    );
  }
}
