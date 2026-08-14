import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../shared/utils/thai_date.dart';
import '../assessment/assessment_screen.dart';
import '../assessment/assessment_state.dart';
import '../games/color_sequence/color_sequence_game.dart';
import '../games/memory_match/memory_match_game.dart';
import '../games/sound_match/sound_match_game.dart';
import '../ai_tips/tips_widget.dart';
import '../appointments/appointments_screen.dart';
import '../family_call/family_call_screen.dart';
import '../flash_card/flash_card_dialog.dart';
import '../flash_card/flash_card_service.dart';
import '../history/history_screen.dart';
import '../settings/settings_screen.dart';
import '../screen_time/screen_time_screen.dart';

/// หน้าหลักของแอป Demenish AI
/// มี Bottom Navigation Bar 4 แท็บ: ฝึกสมอง, ประเมิน, จำกัดเวลา, ตั้งค่า

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // แสดง flash card รายวัน ครั้งแรกที่เข้าแอปของวันนั้น (ข้อ 8)
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowFlashCard());
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
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.psychology_outlined),
              activeIcon: Icon(Icons.psychology),
              label: 'ฝึกสมอง',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment),
              label: 'ประเมิน',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.phone_android_outlined),
              activeIcon: Icon(Icons.phone_android),
              label: 'จำกัดเวลา',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'ตั้งค่า',
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

  String _todayThaiDate() => 'วันที่ ${formatThaiDate(DateTime.now())}';

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
                        'สวัสดี!',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'วันนี้เป็นอย่างไรบ้าง?',
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
        title: const Text('ฝึกสมอง'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'ประวัติคะแนน',
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
            title: 'โทรหาครอบครัว',
            subtitle: 'กดโทรหาลูกหลานได้ทันที',
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
            title: 'นัดหมายแพทย์',
            subtitle: 'บันทึกนัด แล้วเตือนก่อนถึงเวลา',
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
            icon: Icons.music_note_rounded,
            title: 'จับคู่เสียง',
            subtitle: 'ฝึกความจำด้านการฟัง',
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
            title: 'จับคู่ภาพ',
            subtitle: 'ฝึกความจำด้านภาพ',
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
            title: 'กดปุ่มตามลำดับ',
            subtitle: 'ฝึกความจำและการสังเกต',
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
      appBar: AppBar(title: const Text('ประเมินสุขภาพสมอง')),
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
                'พร้อมประเมินหรือยัง?',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'ทำแบบประเมินเพื่อดูสุขภาพสมองของคุณ',
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
                child: const Text('เริ่มประเมิน'),
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
