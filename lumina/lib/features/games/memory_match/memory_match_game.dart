import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../shared/widgets/exit_dialog.dart' show showExitConfirmation;
import 'memory_match_provider.dart';
import 'memory_match_result.dart';

/// หน้าเลือกความยากก่อนเข้าเกม
class MemoryMatchGame extends StatelessWidget {
  const MemoryMatchGame({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('จับคู่ภาพ')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.grid_view_rounded,
                  size: 80, color: primaryColor.withAlpha(120)),
              const SizedBox(height: 24),
              Text(
                'เลือกระดับความยาก',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ...MemoryDifficulty.values.map((diff) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) =>
                                _MemoryMatchBoard(difficulty: diff),
                          ),
                        );
                      },
                      child: Text('${diff.label}  (${diff.subtitle})'),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

/// หน้าจอเล่นเกมจริง
class _MemoryMatchBoard extends ConsumerStatefulWidget {
  const _MemoryMatchBoard({required this.difficulty});

  final MemoryDifficulty difficulty;

  @override
  ConsumerState<_MemoryMatchBoard> createState() => _MemoryMatchBoardState();
}

class _MemoryMatchBoardState extends ConsumerState<_MemoryMatchBoard> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(memoryMatchProvider.notifier).startGame(widget.difficulty);
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(memoryMatchProvider);

    ref.listen(memoryMatchProvider, (prev, next) {
      if (next.isComplete && !(prev?.isComplete ?? false)) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => MemoryMatchResult(
              attempts: next.attempts,
              totalPairs: next.totalPairs,
              difficulty: next.difficulty,
            ),
          ),
        );
      }
    });

    if (gameState.isLoading || gameState.cards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('จับคู่ภาพ')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final columns = gameState.difficulty.columns;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await showExitConfirmation(context);
        if (shouldPop && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('จับคู่ภาพ (${gameState.difficulty.label})'),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () async {
              final shouldPop = await showExitConfirmation(context);
              if (shouldPop && context.mounted) Navigator.of(context).pop();
            },
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  Icon(Icons.layers_rounded,
                      size: 20,
                      color: isDark
                          ? AppTheme.darkPrimary
                          : AppTheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    '${gameState.matchedPairs}/${gameState.totalPairs}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppTheme.darkPrimary
                          : AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.touch_app_rounded,
                      size: 20,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${gameState.attempts}',
                    style: TextStyle(
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final rows = (gameState.cards.length / columns).ceil();
              const spacing = 8.0;
              const padH = 12.0;
              const padTop = 8.0;
              const padBot = 12.0;

              final availW = constraints.maxWidth - padH * 2 - spacing * (columns - 1);
              final availH = constraints.maxHeight - padTop - padBot - spacing * (rows - 1);
              final cellW = availW / columns;
              final cellH = availH / rows;
              final aspect = cellW / cellH;

              // emoji ขนาดตาม cell height
              final emojiSize = (cellH * 0.55).clamp(28.0, 72.0);

              return Padding(
                padding: const EdgeInsets.fromLTRB(padH, padTop, padH, padBot),
                child: GridView.count(
                  crossAxisCount: columns,
                  mainAxisSpacing: spacing,
                  crossAxisSpacing: spacing,
                  childAspectRatio: aspect,
                  physics: const NeverScrollableScrollPhysics(),
                  children: List.generate(gameState.cards.length, (index) {
                    final card = gameState.cards[index];
                    return _MemoryCardWidget(
                      card: card,
                      isDark: isDark,
                      emojiSize: emojiSize,
                      onTap: () {
                        ref.read(memoryMatchProvider.notifier).flipCard(index);
                      },
                    );
                  }),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Widget การ์ด 1 ใบ
class _MemoryCardWidget extends StatelessWidget {
  const _MemoryCardWidget({
    required this.card,
    required this.isDark,
    required this.onTap,
    this.emojiSize = 56,
  });

  final MemoryCard card;
  final bool isDark;
  final VoidCallback onTap;
  final double emojiSize;

  @override
  Widget build(BuildContext context) {
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.primary;
    final secondaryColor = isDark ? AppTheme.darkSecondary : AppTheme.secondary;
    final isRevealed = card.isFlipped || card.isMatched;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: card.isMatched
              ? AppTheme.success.withAlpha(20)
              : isRevealed
                  ? (isDark ? AppTheme.darkSurface : Colors.white)
                  : secondaryColor.withAlpha(isDark ? 60 : 40),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: card.isMatched
                ? AppTheme.success
                : isRevealed
                    ? primaryColor
                    : secondaryColor.withAlpha(isDark ? 100 : 80),
            width: card.isMatched ? 3 : isRevealed ? 2 : 1.5,
          ),
          boxShadow: isRevealed
              ? [
                  BoxShadow(
                    color: primaryColor.withAlpha(30),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isRevealed
                ? Text(
                    card.emoji,
                    key: ValueKey('emoji_${card.id}'),
                    style: TextStyle(fontSize: emojiSize),
                  )
                : Icon(
                    Icons.question_mark_rounded,
                    key: ValueKey('hidden_${card.id}'),
                    size: emojiSize * 0.75,
                    color: primaryColor.withAlpha(150),
                  ),
          ),
        ),
      ),
    );
  }
}
