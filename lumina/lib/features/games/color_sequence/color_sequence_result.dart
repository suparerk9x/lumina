import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/strings.dart';
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
      title: tr('game.colorSequence.resultTitle'),
      score: passedLevels,
      total: ColorSequenceNotifier.targetLevels,
      goodMessage: tr('game.colorSequence.goodMessage'),
      okMessage: tr('game.colorSequence.okMessage'),
      fairMessage: tr('game.colorSequence.fairMessage'),
      lowMessage: tr('game.colorSequence.lowMessage'),
      goodSub: trp('game.colorSequence.goodSub', {'levels': '$passedLevels'}),
      okSub: trp('game.colorSequence.okSub', {'levels': '$passedLevels'}),
      fairSub: trp('game.colorSequence.fairSub', {'levels': '$passedLevels'}),
      lowSub: tr('game.result.lowSub'),
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
