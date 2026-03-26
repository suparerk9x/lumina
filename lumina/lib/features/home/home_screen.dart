import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../shared/utils/thai_date.dart';
import '../assessment/assessment_screen.dart';
import '../assessment/assessment_state.dart';
import '../games/sequence/sequence_game.dart';
import '../games/sound_match/sound_match_game.dart';
import '../ai_tips/tips_widget.dart';
import '../history/history_screen.dart';
import '../settings/settings_screen.dart';
import '../screen_time/screen_time_screen.dart';

/// ไฟล์นี้เป็นหน้าหลักของแอป Lumina
/// มี Bottom Navigation Bar 4 แท็บ: ฝึกสมอง, ประเมิน, จำกัดเวลา, ตั้งค่า

/// HomeScreen เป็น Widget หลักที่แสดงหน้าจอแรกของแอป
/// ใช้ StatefulWidget เพราะต้องเก็บค่าแท็บที่เลือกอยู่ (_currentIndex)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// State ของ HomeScreen เก็บค่าว่าตอนนี้อยู่แท็บไหน
class _HomeScreenState extends State<HomeScreen> {
  // ตัวแปรเก็บลำดับแท็บที่กำลังเลือก (0=ฝึกสมอง, 1=ประเมิน, 2=จำกัดเวลา, 3=ตั้งค่า)
  int _currentIndex = 0;

  // รายการหน้าจอทั้ง 4 แท็บ
  final List<Widget> _tabs = const [
    _GamesTab(),
    _AssessmentTab(),
    _ScreenTimeTab(),
    SettingsScreen(),
  ];

  /// สร้างหน้าจอหลัก มี IndexedStack เพื่อเก็บสถานะแต่ละแท็บไว้
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack แสดงแท็บตาม index ที่เลือก แต่เก็บทุกแท็บไว้ในหน่วยความจำ
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      // แถบนำทางด้านล่าง (Bottom Navigation Bar)
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
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
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: AppTheme.textSecondary,
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

/// การ์ดทักทายผู้ใช้ แสดงข้อความ "สวัสดี!" พร้อมวันที่ภาษาไทย (พ.ศ.)
class _GreetingCard extends StatelessWidget {
  const _GreetingCard();

  /// แปลงวันที่วันนี้เป็นรูปแบบไทย เช่น "วันที่ 26/03/2569"
  String _todayThaiDate() => 'วันที่ ${formatThaiDate(DateTime.now())}';

  @override
  Widget build(BuildContext context) {
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
                    color: AppTheme.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.wb_sunny_rounded,
                    color: AppTheme.primary,
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
                              color: AppTheme.textSecondary,
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
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _todayThaiDate(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
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

/// แท็บ "ฝึกสมอง" แสดงรายการเกมฝึกสมองทั้งหมด
/// มีการ์ดทักทาย, คำแนะนำ AI, และเกมต่าง ๆ ให้เลือกเล่น
class _GamesTab extends StatelessWidget {
  const _GamesTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
            icon: Icons.music_note_rounded,
            title: 'จับคู่เสียง',
            subtitle: 'ฝึกความจำด้านการฟัง',
            color: const Color(0xFFE8F5E9),
            iconColor: AppTheme.success,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SoundMatchGame(),
                ),
              );
            },
          ),
          _GameCard(
            icon: Icons.format_list_numbered_rounded,
            title: 'เรียงลำดับ',
            subtitle: 'ฝึกการคิดเชิงตรรกะ',
            color: const Color(0xFFFFF3E0),
            iconColor: AppTheme.warning,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SequenceGame(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// การ์ดแสดงข้อมูลเกม มีไอคอน ชื่อเกม คำอธิบาย และลูกศรไปเล่นเกม
/// ใช้ซ้ำได้กับทุกเกม โดยส่ง parameter ต่างกัน
class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon; // ไอคอนของเกม
  final String title; // ชื่อเกม
  final String subtitle; // คำอธิบายสั้น ๆ
  final Color color; // สีพื้นหลังไอคอน
  final Color iconColor; // สีของไอคอน
  final VoidCallback onTap; // ฟังก์ชันที่เรียกเมื่อกดการ์ด

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
                            color: AppTheme.textSecondary,
                            fontSize: 16,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textSecondary,
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

/// แท็บ "ประเมิน" แสดงหน้าจอให้ผู้ใช้เริ่มทำแบบประเมินสุขภาพสมอง
/// ใช้ ConsumerWidget เพราะต้องเข้าถึง Riverpod provider สำหรับเริ่มการประเมิน
class _AssessmentTab extends ConsumerWidget {
  const _AssessmentTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                color: AppTheme.primary.withAlpha(120),
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
                      color: AppTheme.textSecondary,
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
// ใช้ ScreenTimeScreen โดยตรงเป็นเนื้อหาของแท็บจำกัดเวลา
// typedef คือการตั้งชื่อใหม่ให้กับ class เพื่อให้อ่านเข้าใจง่ายขึ้น
typedef _ScreenTimeTab = ScreenTimeScreen;
