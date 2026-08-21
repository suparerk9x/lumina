// ไฟล์นี้เป็นโมเดลข้อมูลโปรไฟล์ผู้ใช้ + รายชื่อครอบครัว
// ใช้เก็บ ชื่อ / ช่วงอายุ / เพศ เพื่อปรับแบบประเมินให้เหมาะสม (ข้อ 5)
// และเก็บรายชื่อครอบครัวสำหรับปุ่มโทรด่วน (ข้อ 2) + แจ้ง LINE (ข้อ 6)

import '../../core/strings.dart';

/// ช่วงอายุของผู้ใช้ ใช้ปรับความยากของแบบประเมิน
enum AgeRange {
  below60('age.below60'),
  age60to69('age.60to69'),
  age70to79('age.70to79'),
  age80plus('age.80plus');

  const AgeRange(this.labelKey);

  final String labelKey;

  String get label => tr(labelKey);
}

/// เพศของผู้ใช้ (ปรับได้ที่ตั้งค่า)
enum Gender {
  male('gender.male'),
  female('gender.female'),
  unspecified('gender.unspecified');

  const Gender(this.labelKey);

  final String labelKey;

  String get label => tr(labelKey);
}

/// โมเดลสมาชิกครอบครัว 1 คน (สำหรับปุ่มโทร + แจ้ง LINE)
class FamilyContact {
  const FamilyContact({
    required this.name,
    required this.phone,
    this.photoBase64,
    this.lineUserId,
  });

  final String name; // ชื่อที่แสดง เช่น "ลูกสาว"
  final String phone; // เบอร์โทรศัพท์
  final String? photoBase64; // รูปภาพเก็บเป็น base64 (ไม่ต้องพึ่ง path ในเครื่อง)
  final String? lineUserId; // LINE userId สำหรับแจ้งเตือน (ข้อ 6)

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      if (photoBase64 != null) 'photoBase64': photoBase64,
      if (lineUserId != null) 'lineUserId': lineUserId,
    };
  }

  factory FamilyContact.fromMap(Map<dynamic, dynamic> map) {
    final name = map['name'];
    final phone = map['phone'];
    if (name == null || phone == null) {
      throw const FormatException('Missing required family contact fields');
    }
    return FamilyContact(
      name: '$name',
      phone: '$phone',
      photoBase64: map['photoBase64'] as String?,
      lineUserId: map['lineUserId'] as String?,
    );
  }

  FamilyContact copyWith({
    String? name,
    String? phone,
    String? photoBase64,
    String? lineUserId,
  }) {
    return FamilyContact(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      photoBase64: photoBase64 ?? this.photoBase64,
      lineUserId: lineUserId ?? this.lineUserId,
    );
  }
}

/// โมเดลโปรไฟล์ผู้ใช้ทั้งหมด
class UserProfile {
  const UserProfile({
    this.name = '',
    this.ageRange,
    this.gender = Gender.unspecified,
    this.contacts = const [],
    this.onboardingDone = false,
  });

  final String name;
  final AgeRange? ageRange; // null = ยังไม่ได้ระบุ
  final Gender gender;
  final List<FamilyContact> contacts;
  final bool onboardingDone; // ผ่านหน้าเริ่มต้น (onboarding) แล้วหรือยัง

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'ageRangeIndex': ageRange?.index,
      'genderIndex': gender.index,
      'contacts': contacts.map((c) => c.toMap()).toList(),
      'onboardingDone': onboardingDone,
    };
  }

  factory UserProfile.fromMap(Map<dynamic, dynamic> map) {
    final ageIdx = map['ageRangeIndex'];
    final genderIdx = map['genderIndex'];

    final rawContacts = map['contacts'];
    final contacts = <FamilyContact>[];
    if (rawContacts is List) {
      for (final c in rawContacts) {
        try {
          contacts.add(FamilyContact.fromMap(c as Map<dynamic, dynamic>));
        } catch (_) {
          // ข้ามรายการที่เสียหาย
        }
      }
    }

    return UserProfile(
      name: '${map['name'] ?? ''}',
      ageRange: (ageIdx is int && ageIdx >= 0 && ageIdx < AgeRange.values.length)
          ? AgeRange.values[ageIdx]
          : null,
      gender:
          (genderIdx is int && genderIdx >= 0 && genderIdx < Gender.values.length)
              ? Gender.values[genderIdx]
              : Gender.unspecified,
      contacts: contacts,
      onboardingDone: map['onboardingDone'] == true,
    );
  }

  UserProfile copyWith({
    String? name,
    AgeRange? ageRange,
    bool clearAgeRange = false,
    Gender? gender,
    List<FamilyContact>? contacts,
    bool? onboardingDone,
  }) {
    return UserProfile(
      name: name ?? this.name,
      ageRange: clearAgeRange ? null : (ageRange ?? this.ageRange),
      gender: gender ?? this.gender,
      contacts: contacts ?? this.contacts,
      onboardingDone: onboardingDone ?? this.onboardingDone,
    );
  }
}
