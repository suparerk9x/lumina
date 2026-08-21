import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../shared/storage/user_profile.dart';
import '../family_call/family_call_screen.dart';
import 'profile_provider.dart';

/// หน้าโปรไฟล์ — แก้ไข ชื่อ / ช่วงอายุ / เพศ ได้ทีหลัง (ตาม decision #4)
/// และเข้าไปจัดการรายชื่อครอบครัวได้
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: ref.read(profileProvider).name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final notifier = ref.read(profileProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(tr('profile.title'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SectionCard(
            icon: Icons.badge_rounded,
            title: tr('profile.name'),
            child: TextField(
              controller: _nameController,
              style: const TextStyle(fontSize: 20),
              decoration: InputDecoration(hintText: tr('profile.nameHint')),
              onChanged: (v) => notifier.setName(v),
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            icon: Icons.cake_rounded,
            title: tr('profile.ageRange'),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: AgeRange.values.map((range) {
                return _Chip(
                  label: range.label,
                  isSelected: profile.ageRange == range,
                  onTap: () => notifier.setAgeRange(range),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            icon: Icons.wc_rounded,
            title: tr('profile.gender'),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: Gender.values.map((g) {
                return _Chip(
                  label: g.label,
                  isSelected: profile.gender == g,
                  onTap: () => notifier.setGender(g),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: const Icon(Icons.groups_rounded,
                  color: AppTheme.primary, size: 28),
              title: Text(tr('profile.family'),
                  style: const TextStyle(fontSize: 18)),
              subtitle: Text(
                  trp('profile.familyCount',
                      {'n': '${profile.contacts.length}'}),
                  style: const TextStyle(fontSize: 15)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const FamilyCallScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppTheme.darkPrimary : AppTheme.primary;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: primary, size: 24),
                ),
                const SizedBox(width: 12),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
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
          constraints: const BoxConstraints(minHeight: 52, minWidth: 100),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
