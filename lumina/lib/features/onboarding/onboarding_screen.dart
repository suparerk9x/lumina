import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../shared/storage/user_profile.dart';
import '../home/home_screen.dart';
import '../profile/profile_provider.dart';

/// หน้าเริ่มต้นครั้งแรก (Onboarding) — ถามชื่อ / อายุ / เพศ
/// ข้ามได้ (ผู้ใช้สูงอายุอาจไม่อยากกรอก) แต่ถ้ากรอกจะช่วยปรับแบบประเมินให้เหมาะสม
/// แสดงครั้งเดียว หลังจากนั้น splash จะพาไปหน้าหลักตรง ๆ
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nameController = TextEditingController();
  AgeRange? _ageRange;
  Gender _gender = Gender.unspecified;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _goHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  Future<void> _start() async {
    await ref.read(profileProvider.notifier).completeOnboarding(
          name: _nameController.text,
          ageRange: _ageRange,
          gender: _gender,
        );
    if (mounted) _goHome();
  }

  Future<void> _skip() async {
    await ref.read(profileProvider.notifier).skipOnboarding();
    if (mounted) _goHome();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryText =
        isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 8),
            Center(
              child: Image.asset(
                'assets/images/logo.png',
                width: 200,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'ยินดีต้อนรับสู่ Demenish AI',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'บอกเราหน่อยเพื่อปรับแอปให้เหมาะกับคุณ\n(ข้ามได้ แล้วมาตั้งทีหลังที่หน้าตั้งค่า)',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: secondaryText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // ── ชื่อ ──
            Text('ชื่อของคุณ',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              textInputAction: TextInputAction.done,
              style: const TextStyle(fontSize: 20),
              decoration: const InputDecoration(
                hintText: 'เช่น สมชาย',
                prefixIcon: Icon(Icons.person_rounded),
              ),
            ),
            const SizedBox(height: 28),

            // ── ช่วงอายุ ──
            Text('ช่วงอายุ',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _AgeRangeSelector(
              selected: _ageRange,
              onSelect: (r) => setState(() => _ageRange = r),
            ),
            const SizedBox(height: 28),

            // ── เพศ ──
            Text('เพศ', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _GenderSelector(
              selected: _gender,
              onSelect: (g) => setState(() => _gender = g),
            ),
            const SizedBox(height: 40),

            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _start,
                child: const Text('เริ่มใช้งาน'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 52,
              child: TextButton(
                onPressed: _skip,
                child: Text(
                  'ข้ามไปก่อน',
                  style: TextStyle(fontSize: 18, color: secondaryText),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ตัวเลือกช่วงอายุ (ปุ่มใหญ่ตามมาตรฐานผู้สูงอายุ)
class _AgeRangeSelector extends StatelessWidget {
  const _AgeRangeSelector({required this.selected, required this.onSelect});

  final AgeRange? selected;
  final ValueChanged<AgeRange> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: AgeRange.values.map((range) {
        final isSelected = selected == range;
        return _ChoiceChipButton(
          label: range.label,
          isSelected: isSelected,
          onTap: () => onSelect(range),
        );
      }).toList(),
    );
  }
}

/// ตัวเลือกเพศ
class _GenderSelector extends StatelessWidget {
  const _GenderSelector({required this.selected, required this.onSelect});

  final Gender selected;
  final ValueChanged<Gender> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: Gender.values.map((g) {
        final isSelected = selected == g;
        return _ChoiceChipButton(
          label: g.label,
          isSelected: isSelected,
          onTap: () => onSelect(g),
        );
      }).toList(),
    );
  }
}

/// ปุ่มตัวเลือกแบบ chip ขนาดใหญ่ ใช้ร่วมกันหลายที่
class _ChoiceChipButton extends StatelessWidget {
  const _ChoiceChipButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppTheme.darkPrimary : AppTheme.primary;
    final textColor = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;

    return Material(
      color: isSelected ? primary.withAlpha(20) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 56, minWidth: 120),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? primary
                  : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? primary : textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
