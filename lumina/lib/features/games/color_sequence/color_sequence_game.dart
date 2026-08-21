import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/strings.dart';
import '../../../core/theme.dart';
import '../../../shared/widgets/exit_dialog.dart' show showExitConfirmation;
import 'color_sequence_provider.dart';
import 'color_sequence_result.dart';

/// หน้าจอเกมกดปุ่มตามลำดับ (Simon Says)

class ColorSequenceGame extends ConsumerStatefulWidget {
  const ColorSequenceGame({super.key});

  @override
  ConsumerState<ColorSequenceGame> createState() => _ColorSequenceGameState();
}

class _ColorSequenceGameState extends ConsumerState<ColorSequenceGame> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(colorSequenceProvider.notifier).startGame();
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(colorSequenceProvider);

    // นำทางไปผลลัพธ์เมื่อกดผิด
    ref.listen(colorSequenceProvider, (prev, next) {
      if (next.phase == GamePhase.wrong &&
          prev?.phase != GamePhase.wrong) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (context.mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => ColorSequenceResult(
                  level: next.level,
                  passedLevels: next.level - 1,
                ),
              ),
            );
          }
        });
      }
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await showExitConfirmation(context);
        if (shouldPop && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr('game.colorSequence.title')),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () async {
              final shouldPop = await showExitConfirmation(context);
              if (shouldPop && context.mounted) Navigator.of(context).pop();
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // ─── สถานะ ──────────────────────────────
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        icon: Icons.flag_rounded,
                        label: tr('game.colorSequence.levelLabel'),
                        value: '${gameState.level}',
                        isDark: isDark,
                      ),
                      _StatItem(
                        icon: Icons.timeline_rounded,
                        label: tr('game.colorSequence.sequenceLabel'),
                        value: trp('game.colorSequence.colorCount',
                            {'n': '${gameState.sequenceLength}'}),
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ─── คำแนะนำ (ความสูงคงที่ไม่ให้ปุ่มขยับ) ────
              SizedBox(
                height: 32,
                child: Center(
                  child: Text(
                    _phaseMessage(gameState.phase),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: gameState.phase == GamePhase.wrong
                              ? AppTheme.error
                              : gameState.phase == GamePhase.correct
                                  ? AppTheme.success
                                  : isDark
                                      ? AppTheme.darkTextSecondary
                                      : AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // ─── Progress dots ──────────────────────
              if (gameState.phase == GamePhase.inputting)
                _ProgressDots(
                  total: gameState.sequenceLength,
                  filled: gameState.playerInput.length,
                  isDark: isDark,
                ),
              const SizedBox(height: 24),

              // ─── ปุ่มสี 2x2 ──────────────────────────
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: GameColor.values.map((color) {
                        final isHighlighted =
                            gameState.highlightColor == color;
                        final isDisabled =
                            gameState.phase != GamePhase.inputting;

                        return _ColorButton(
                          gameColor: color,
                          isHighlighted: isHighlighted,
                          isDisabled: isDisabled,
                          onTap: () {
                            ref
                                .read(colorSequenceProvider.notifier)
                                .tapColor(color);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _phaseMessage(GamePhase phase) {
    switch (phase) {
      case GamePhase.ready:
        return tr('game.colorSequence.phaseReady');
      case GamePhase.showing:
        return tr('game.colorSequence.phaseShowing');
      case GamePhase.inputting:
        return tr('game.colorSequence.phaseInputting');
      case GamePhase.correct:
        return tr('game.colorSequence.phaseCorrect');
      case GamePhase.wrong:
        return tr('game.colorSequence.phaseWrong');
    }
  }
}

/// Widget แสดงสถิติ
class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.primary;

    return Column(
      children: [
        Icon(icon, color: primaryColor, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

/// แสดง progress dots ว่ากดไปกี่สีแล้ว
class _ProgressDots extends StatelessWidget {
  const _ProgressDots({
    required this.total,
    required this.filled,
    required this.isDark,
  });

  final int total;
  final int filled;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.primary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i < filled ? primaryColor : primaryColor.withAlpha(40),
            border: Border.all(color: primaryColor, width: 1.5),
          ),
        );
      }),
    );
  }
}

/// ปุ่มสีกลมใหญ่
class _ColorButton extends StatelessWidget {
  const _ColorButton({
    required this.gameColor,
    required this.isHighlighted,
    required this.isDisabled,
    required this.onTap,
  });

  final GameColor gameColor;
  final bool isHighlighted;
  final bool isDisabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final displayColor =
        isHighlighted ? gameColor.lightColor : gameColor.color;

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: displayColor.withAlpha(isDisabled && !isHighlighted ? 100 : 255),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isHighlighted
                ? Colors.white
                : displayColor.withAlpha(180),
            width: isHighlighted ? 4 : 2,
          ),
          boxShadow: isHighlighted
              ? [
                  BoxShadow(
                    color: displayColor.withAlpha(120),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ]
              : [
                  BoxShadow(
                    color: displayColor.withAlpha(60),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
        ),
        child: Center(
          child: Text(
            gameColor.label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black.withAlpha(80),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
