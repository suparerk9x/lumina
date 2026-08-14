import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;

import '../storage/storage_service.dart';

/// ส่งข้อความแจ้งเตือนไปยัง LINE ของครอบครัวผ่าน backend (Cloudflare Worker) — ข้อ 6
///
/// ตั้งค่า [workerBaseUrl] และ [appKey] ให้ตรงกับ Worker ที่ deploy เอง
/// (ดูวิธีทำที่ docs/backend/README.md)
/// ถ้ายังไม่ได้ตั้งค่า จะไม่ทำอะไร (no-op) เพื่อไม่ให้แอปพัง
class LineService {
  LineService._();
  static final LineService _instance = LineService._();
  factory LineService() => _instance;

  /// URL ของ Cloudflare Worker เช่น `https://demenish-line.xxx.workers.dev`
  static const String workerBaseUrl = String.fromEnvironment(
    'LINE_WORKER_URL',
    defaultValue: '',
  );

  /// คีย์ลับที่แชร์กับ Worker (ป้องกันคนอื่นยิง push)
  static const String appKey = String.fromEnvironment(
    'LINE_APP_KEY',
    defaultValue: '',
  );

  bool get isConfigured => workerBaseUrl.isNotEmpty && appKey.isNotEmpty;

  /// ส่งข้อความหา 1 LINE userId
  Future<bool> pushToUser(String lineUserId, String message) async {
    if (!isConfigured || lineUserId.isEmpty) return false;
    try {
      final resp = await http
          .post(
            Uri.parse('$workerBaseUrl/push'),
            headers: {
              'content-type': 'application/json',
              'x-app-key': appKey,
            },
            body: jsonEncode({'to': lineUserId, 'message': message}),
          )
          .timeout(const Duration(seconds: 10));
      return resp.statusCode >= 200 && resp.statusCode < 300;
    } catch (e, s) {
      developer.log('LineService.pushToUser failed: $e',
          name: 'DemenishAI', error: e, stackTrace: s);
      return false;
    }
  }

  /// ส่งข้อความหาสมาชิกครอบครัวทุกคนที่ผูก LINE ไว้ (มี lineUserId)
  Future<int> notifyFamily(String message) async {
    if (!isConfigured) return 0;
    final contacts = StorageService()
        .getUserProfile()
        .contacts
        .where((c) => (c.lineUserId ?? '').isNotEmpty);
    var sent = 0;
    for (final c in contacts) {
      if (await pushToUser(c.lineUserId!, message)) sent++;
    }
    return sent;
  }
}
