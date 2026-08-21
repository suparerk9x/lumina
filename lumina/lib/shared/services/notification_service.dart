import 'dart:developer' as developer;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../core/strings.dart';

/// Service กลางสำหรับการแจ้งเตือนในเครื่อง (local notification)
/// ใช้ร่วมกับ เตือนนัดหมายแพทย์ (ข้อ 1) และฟีเจอร์อื่นที่ต้องเตือนตามเวลา
///
/// เป็น Singleton — เรียก NotificationService() ที่ไหนก็ได้ instance เดิม
class NotificationService {
  NotificationService._();
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// ช่องแจ้งเตือนนัดหมาย (Android ต้องมี channel) — ชื่อ channel แปลตามภาษา
  NotificationDetails get _appointmentDetails => NotificationDetails(
        android: AndroidNotificationDetails(
          'appointments',
          tr('notif.channel.apptName'),
          channelDescription: tr('notif.channel.apptDesc'),
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      );

  /// ช่องแจ้งเตือนทั่วไป (เช่น เตือนพักสายตา/ง่วง — ข้อ 6)
  NotificationDetails get _alertDetails => NotificationDetails(
        android: AndroidNotificationDetails(
          'alerts',
          tr('notif.channel.alertName'),
          channelDescription: tr('notif.channel.alertDesc'),
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      );

  /// เริ่มต้นระบบแจ้งเตือน (เรียกครั้งเดียวตอนเปิดแอปใน main)
  Future<void> init() async {
    if (_initialized) return;
    try {
      // ตั้งค่า timezone เป็นเวลาไทย เพื่อให้ตั้งเวลาแจ้งเตือนแม่นยำ
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Bangkok'));

      const androidInit =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _plugin.initialize(
        const InitializationSettings(android: androidInit, iOS: iosInit),
      );
      _initialized = true;
    } catch (e, s) {
      _log('init', e, s);
    }
  }

  /// ขอสิทธิ์แจ้งเตือน (Android 13+ และ iOS) — เรียกเมื่อผู้ใช้เริ่มใช้ฟีเจอร์เตือน
  Future<bool> requestPermission() async {
    try {
      await init();
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        final granted = await android.requestNotificationsPermission();
        return granted ?? true;
      }
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        final granted = await ios.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
      return true;
    } catch (e, s) {
      _log('requestPermission', e, s);
      return false;
    }
  }

  /// ตั้งเวลาแจ้งเตือน 1 รายการตามวันเวลาที่กำหนด
  /// [id] ต้องไม่ซ้ำกัน (ใช้อ้างอิงตอนยกเลิก)
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime dateTime,
  }) async {
    try {
      await init();
      final when = tz.TZDateTime.from(dateTime, tz.local);
      // ถ้าเวลาผ่านไปแล้ว ไม่ต้องตั้ง
      if (when.isBefore(tz.TZDateTime.now(tz.local))) return;

      await _plugin.zonedSchedule(
        id,
        title,
        body,
        when,
        _appointmentDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e, s) {
      _log('schedule', e, s);
    }
  }

  /// แสดงการแจ้งเตือนทันที (ไม่ตั้งเวลา) — ใช้เตือนพักสายตา/ง่วง
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      await init();
      await _plugin.show(id, title, body, _alertDetails);
    } catch (e, s) {
      _log('showNow', e, s);
    }
  }

  /// ยกเลิกการแจ้งเตือนตาม id
  Future<void> cancel(int id) async {
    try {
      await _plugin.cancel(id);
    } catch (e, s) {
      _log('cancel', e, s);
    }
  }

  void _log(String method, Object error, StackTrace stack) {
    developer.log(
      'NotificationService.$method failed: $error',
      name: 'DemenishAI',
      error: error,
      stackTrace: stack,
    );
  }
}
