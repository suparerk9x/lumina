import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/strings.dart';
import '../../../shared/widgets/game_result_screen.dart';
import 'sound_match_game.dart';
import 'sound_match_provider.dart';

/// ไฟล์นี้แสดงหน้าผลคะแนนหลังเล่นเกมจับคู่เสียงจบ
/// แสดงคะแนน ข้อความให้กำลังใจ และปุ่มเล่นอีกครั้งหรือกลับหน้าหลัก

/// หน้าผลคะแนนของเกมจับคู่เสียง
/// ใช้ GameResultScreen ที่เป็น Widget กลางสำหรับแสดงผลคะแนนทุกเกม
class SoundMatchResult extends ConsumerWidget {
  const SoundMatchResult({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(soundMatchProvider); // อ่านสถานะเกมเพื่อดูคะแนน

    // ใช้ GameResultScreen แสดงคะแนนพร้อมข้อความตามระดับผลลัพธ์
    return GameResultScreen(
      title: tr('game.result.title'),
      score: state.score, // คะแนนที่ได้
      total: state.totalRounds, // คะแนนเต็ม
      goodSub: tr('game.soundMatch.goodSub'), // ข้อความเมื่อคะแนนดี
      okSub: tr('game.result.okSub'), // ข้อความเมื่อคะแนนปานกลาง
      fairSub: tr('game.result.fairSub'), // ข้อความเมื่อคะแนนพอใช้
      lowSub: tr('game.result.lowSub'), // ข้อความเมื่อคะแนนน้อย
      onPlayAgain: () {
        ref.read(soundMatchProvider.notifier).startGame(); // เริ่มเกมใหม่
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SoundMatchGame()),
        );
      },
      onGoHome: () => Navigator.of(context).pop(), // กลับหน้าหลัก
    );
  }
}
