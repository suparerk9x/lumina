import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../shared/storage/storage_service.dart';
import '../home/home_screen.dart';
import '../onboarding/onboarding_screen.dart';

/// หน้า Splash Screen แสดงโลโก้ Demenish AI เมื่อเปิดแอป
/// แสดง 2 วินาทีแล้ว navigate ไปหน้าหลัก

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    // Navigate หลัง 2 วินาที: ครั้งแรกไป Onboarding, ครั้งต่อไปไปหน้าหลัก
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      final onboardingDone = StorageService().getUserProfile().onboardingDone;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, _, _) =>
              onboardingDone ? const HomeScreen() : const OnboardingScreen(),
          transitionsBuilder: (_, animation, _, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.darkBackground
          : const Color(0xFF8BBCE0), // สีฟ้าจาก logo background
      body: Center(
        child: FadeTransition(
          opacity: _fadeIn,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // โลโก้
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 260,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'A Brain Tracker App',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white.withAlpha(200),
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
