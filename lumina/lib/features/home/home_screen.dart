import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../shared/utils/thai_date.dart';
import '../assessment/assessment_screen.dart';
import '../assessment/assessment_state.dart';
import '../games/color_sequence/color_sequence_game.dart';
import '../games/memory_match/memory_match_game.dart';
import '../games/sound_match/sound_match_game.dart';
import '../ai_tips/tips_widget.dart';
import '../appointments/appointments_screen.dart';
import '../drowsiness/drowsiness_provider.dart';
import '../family_call/family_call_screen.dart';
import '../flash_card/flash_card_dialog.dart';
import '../flash_card/flash_card_service.dart';
import '../history/history_screen.dart';
import '../scam_check/scam_check_screen.dart';
import '../screen_distance/screen_distance_provider.dart';
import '../settings/settings_screen.dart';
import '../screen_time/screen_time_screen.dart';

/// หน้าหลักของแอป Demenish AI
/// มี Bottom Navigation Bar 4 แท็บ: ฝึกสมอง, ประเมิน, จำกัดเวลา, ตั้งค่า

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // แสดง flash card รายวัน ครั้งแรกที่เข้าแอปของวันนั้น (ข้อ 8)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowFlashCard();
      // เริ่มตรวจกล้อง (ระยะจอ ข้อ 4 / ง่วง ข้อ 6) ถ้าเปิดไว้ — foreground เท่านั้น
      _setMonitorsForeground(true);
    });
  }

  void _setMonitorsForeground(bool value) {
    ref.read(screenDistanceProvider.notifier).setForeground(value);
    ref.read(drowsinessProvider.notifier).setForeground(value);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // ตรวจกล้องเฉพาะตอนแอปเปิดอยู่ (ข้อ 4/6 — parity iOS/Android)
    _setMonitorsForeground(state == AppLifecycleState.resumed);
  }

  void _showWarning(String text, Color color) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(text, style: const TextStyle(fontSize: 18)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _maybeShowFlashCard() async {
    final service = FlashCardService();
    if (!service.shouldShowToday()) return;
    final card = service.buildTodayCard();
    if (card == null) return;
    await service.markShownToday();
    if (!mounted) return;
    await showFlashCardDialog(context, card);
  }

  final List<Widget> _tabs = const [
    _GamesTab(),
    _AssessmentTab(),
    _ScreenTimeTab(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // เตือนเมื่อ monitor ตรวจพบว่านั่งใกล้จอเกินไป (ข้อ 4)
    ref.listen<ScreenDistanceState>(screenDistanceProvider, (prev, next) {
      if (prev != null && next.warningSeq > prev.warningSeq) {
        _showWarning(tr('sd.warn'), AppTheme.warning);
      }
    });
    // เตือนเมื่อตรวจพบอาการง่วง (ข้อ 6)
    ref.listen<DrowsinessState>(drowsinessProvider, (prev, next) {
      if (prev != null && next.warningSeq > prev.warningSeq) {
        _showWarning(tr('drowsy.warn'), AppTheme.primary);
      }
    });

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor:
              isDark ? AppTheme.darkPrimary : AppTheme.primary,
          unselectedItemColor:
              isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
          iconSize: 32,
          selectedFontSize: 16,
          unselectedFontSize: 16,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.psychology_outlined),
              activeIcon: const Icon(Icons.psychology),
              label: tr('nav.games'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.assignment_outlined),
              activeIcon: const Icon(Icons.assignment),
              label: tr('nav.assessment'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.phone_android_outlined),
              activeIcon: const Icon(Icons.phone_android),
              label: tr('nav.screenTime'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.settings_outlined),
              activeIcon: const Icon(Icons.settings),
              label: tr('nav.settings'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Greeting Card ──────────────────────────────────────────

class _GreetingCard extends StatelessWidget {
  const _GreetingCard();

  String _todayThaiDate() =>
      '${tr('home.dateLabel')} ${formatThaiDate(DateTime.now())}';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isDark ? AppTheme.darkPrimary : AppTheme.primary)
                        .withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.wb_sunny_rounded,
                    color: isDark ? AppTheme.darkPrimary : AppTheme.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('home.hello'),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tr('home.howAreYou'),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkBackground : AppTheme.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _todayThaiDate(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.textSecondary,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tab: ฝึกสมอง (Games) ───────────────────────────────────

class _GamesTab extends StatelessWidget {
  const _GamesTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/icon.png',
              width: 36,
              height: 36,
              fit: BoxFit.cover,
            ),
          ),
        ),
        title: Text(tr('home.appbar')),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: tr('home.historyTooltip'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const HistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          const _GreetingCard(),
          const AiTipsCard(),
          const SizedBox(height: 8),
          _GameCard(
            icon: Icons.phone_in_talk_rounded,
            title: tr('home.familyCall.title'),
            subtitle: tr('home.familyCall.subtitle'),
            color: const Color(0xFFE3F2FD),
            iconColor: Colors.blue,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const FamilyCallScreen(),
                ),
              );
            },
          ),
          _GameCard(
            icon: Icons.event_available_rounded,
            title: tr('home.appointment.title'),
            subtitle: tr('home.appointment.subtitle'),
            color: const Color(0xFFFCE4EC),
            iconColor: const Color(0xFFD81B60),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AppointmentsScreen(),
                ),
              );
            },
          ),
          _GameCard(
            icon: Icons.shield_rounded,
            title: tr('home.scam.title'),
            subtitle: tr('home.scam.subtitle'),
            color: const Color(0xFFFFF3E0),
            iconColor: const Color(0xFFEF6C00),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ScamCheckScreen(),
                ),
              );
            },
          ),
          _GameCard(
            icon: Icons.music_note_rounded,
            title: tr('home.soundMatch.title'),
            subtitle: tr('home.soundMatch.subtitle'),
            color: const Color(0xFFE0F2F1),
            iconColor: AppTheme.primary,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SoundMatchGame(),
                ),
              );
            },
          ),
          _GameCard(
            icon: Icons.grid_view_rounded,
            title: tr('home.memoryMatch.title'),
            subtitle: tr('home.memoryMatch.subtitle'),
            color: const Color(0xFFE8F5E9),
            iconColor: AppTheme.success,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const MemoryMatchGame(),
                ),
              );
            },
          ),
          _GameCard(
            icon: Icons.gamepad_rounded,
            title: tr('home.colorSequence.title'),
            subtitle: tr('home.colorSequence.subtitle'),
            color: const Color(0xFFFFF3E0),
            iconColor: AppTheme.warning,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ColorSequenceGame(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// การ์ดแสดงข้อมูลเกม
class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.textSecondary,
                            fontSize: 16,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.textSecondary,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Tab: ประเมิน (Assessment) ──────────────────────────────

class _AssessmentTab extends ConsumerWidget {
  const _AssessmentTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(tr('assessment.tab.title'))),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.assignment_outlined,
                size: 80,
                color: (isDark ? AppTheme.darkPrimary : AppTheme.primary)
                    .withAlpha(120),
              ),
              const SizedBox(height: 24),
              Text(
                tr('assessment.tab.ready'),
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                tr('assessment.tab.desc'),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  ref.read(assessmentProvider.notifier).startAssessment();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AssessmentScreen(),
                    ),
                  );
                },
                child: Text(tr('assessment.tab.start')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Tab: จำกัดเวลา (Screen Time) ───────────────────────────
typedef _ScreenTimeTab = ScreenTimeScreen;
