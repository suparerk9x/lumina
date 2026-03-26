import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'shared/storage/hive_boxes.dart';

/// ไฟล์นี้เป็นจุดเริ่มต้นของแอป Lumina
/// ทำหน้าที่เตรียมระบบ (Hive database) แล้วรันแอป

/// ฟังก์ชันหลักที่ระบบเรียกเป็นอันดับแรกเมื่อเปิดแอป
void main() async {
  // บอก Flutter ให้เตรียม binding ก่อน เพราะเราจะใช้ async/await ใน main
  WidgetsFlutterBinding.ensureInitialized();

  // เริ่มต้นระบบฐานข้อมูล Hive สำหรับเก็บข้อมูลในเครื่อง (เช่น การตั้งค่า)
  await Hive.initFlutter();

  // เปิด "กล่อง" (box) ทุกกล่องที่แอปต้องใช้เก็บข้อมูล
  for (final name in HiveBoxes.all) {
    await Hive.openBox(name);
  }

  // รันแอป โดยครอบด้วย ProviderScope เพื่อให้ Riverpod จัดการ state ได้ทั้งแอป
  runApp(
    const ProviderScope(
      child: LuminaApp(),
    ),
  );
}
