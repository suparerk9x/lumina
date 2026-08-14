import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/storage/storage_service.dart';
import '../../shared/storage/user_profile.dart';

/// ไฟล์นี้จัดการ state ของโปรไฟล์ผู้ใช้
/// เก็บ ชื่อ / ช่วงอายุ / เพศ / รายชื่อครอบครัว และบันทึกลง Hive
/// ใช้ร่วมกับ onboarding (ข้อ F1), แบบประเมินตามอายุ (ข้อ 5), โทรครอบครัว (ข้อ 2)

class ProfileNotifier extends Notifier<UserProfile> {
  @override
  UserProfile build() => StorageService().getUserProfile();

  Future<void> _persist(UserProfile next) async {
    state = next;
    await StorageService().saveUserProfile(next);
  }

  Future<void> setName(String name) =>
      _persist(state.copyWith(name: name.trim()));

  Future<void> setAgeRange(AgeRange range) =>
      _persist(state.copyWith(ageRange: range));

  Future<void> setGender(Gender gender) =>
      _persist(state.copyWith(gender: gender));

  /// บันทึกข้อมูลพื้นฐานจากหน้า onboarding พร้อมทั้งปิด flag onboarding
  Future<void> completeOnboarding({
    String? name,
    AgeRange? ageRange,
    Gender? gender,
  }) {
    return _persist(state.copyWith(
      name: name?.trim() ?? state.name,
      ageRange: ageRange ?? state.ageRange,
      gender: gender ?? state.gender,
      onboardingDone: true,
    ));
  }

  /// ปิด onboarding โดยไม่กรอกข้อมูล (กดข้าม)
  Future<void> skipOnboarding() =>
      _persist(state.copyWith(onboardingDone: true));

  // ─── รายชื่อครอบครัว ─────────────────────────────────────

  Future<void> addContact(FamilyContact contact) {
    final list = [...state.contacts, contact];
    return _persist(state.copyWith(contacts: list));
  }

  Future<void> updateContact(int index, FamilyContact contact) {
    if (index < 0 || index >= state.contacts.length) return Future.value();
    final list = [...state.contacts];
    list[index] = contact;
    return _persist(state.copyWith(contacts: list));
  }

  Future<void> removeContact(int index) {
    if (index < 0 || index >= state.contacts.length) return Future.value();
    final list = [...state.contacts]..removeAt(index);
    return _persist(state.copyWith(contacts: list));
  }
}

/// Provider หลักที่ UI ใช้เข้าถึงโปรไฟล์ผู้ใช้
final profileProvider =
    NotifierProvider<ProfileNotifier, UserProfile>(ProfileNotifier.new);
