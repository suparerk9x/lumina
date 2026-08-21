import 'package:flutter/material.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';

/// ไฟล์นี้เป็นหน้าจอแสดงผลลัพธ์หลังเล่นเกมฝึกสมองเสร็จ
/// ใช้ร่วมกันได้กับทุกเกม แสดงดาว คะแนน ข้อความชม และปุ่มเล่นอีก

/// หน้าจอแสดงผลลัพธ์เกม มีดาว 0-3 ดวงตามคะแนน
/// ปรับข้อความได้ตามระดับคะแนน (ดีมาก/ดี/พอใช้/ลองใหม่)
class GameResultScreen extends StatelessWidget {
  const GameResultScreen({
    super.key,
    required this.title,
    required this.score,
    required this.total,
    required this.onPlayAgain,
    required this.onGoHome,
    this.goodMessage,
    this.okMessage,
    this.fairMessage,
    this.lowMessage,
    this.goodSub,
    this.okSub,
    this.fairSub,
    this.lowSub,
  });

  final String title;
  final int score;
  final int total;
  final VoidCallback onPlayAgain;
  final VoidCallback onGoHome;
  final String? goodMessage, okMessage, fairMessage, lowMessage;
  final String? goodSub, okSub, fairSub, lowSub;

  /// คำนวณจำนวนดาว: >=80% = 3 ดาว, >=50% = 2 ดาว, >=25% = 1 ดาว
  int get _stars {
    if (total == 0) return 0;
    final ratio = score / total;
    if (ratio >= 0.8) return 3;
    if (ratio >= 0.5) return 2;
    if (ratio >= 0.25) return 1;
    return 0;
  }

  /// เลือกสีตามจำนวนดาว: เขียว(3), เหลือง(2), แดง(0-1)
  Color get _color {
    switch (_stars) {
      case 3: return AppTheme.success;
      case 2: return AppTheme.warning;
      default: return AppTheme.error;
    }
  }

  /// เลือกข้อความหลักตามจำนวนดาว
  String get _message {
    switch (_stars) {
      case 3: return goodMessage ?? tr('game.result.goodMessage');
      case 2: return okMessage ?? tr('game.result.okMessage');
      case 1: return fairMessage ?? tr('game.result.fairMessage');
      default: return lowMessage ?? tr('game.result.lowMessage');
    }
  }

  /// เลือกข้อความรองตามจำนวนดาว
  String get _sub {
    switch (_stars) {
      case 3: return goodSub ?? tr('game.result.goodSub');
      case 2: return okSub ?? tr('game.result.okSub');
      case 1: return fairSub ?? tr('game.result.fairSub');
      default: return lowSub ?? tr('game.result.lowSub');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Stars
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      i < _stars
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 56,
                      color: i < _stars
                          ? const Color(0xFFFFB300)
                          : Colors.grey.shade400,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),

              // Score circle
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _color.withAlpha(25),
                  border: Border.all(color: _color, width: 4),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$score',
                      style: Theme.of(context)
                          .textTheme
                          .displayMedium
                          ?.copyWith(
                            color: _color,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      trp('game.result.outOf', {'total': '$total'}),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Message
              Text(
                _message,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: _color,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _sub,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Buttons
              ElevatedButton.icon(
                onPressed: onPlayAgain,
                icon: const Icon(Icons.replay_rounded),
                label: Text(tr('game.playAgain')),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: onGoHome,
                child: Text(tr('game.goHome')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
