import 'dart:convert';
import 'dart:developer' as developer;

import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

import '../storage/hive_boxes.dart';
import '../storage/storage_service.dart';

/// Service เชื่อม backend multi-tenant (เฟส 1) — ข้อ 6
///
/// จุดสำคัญด้านความปลอดภัย: **ไม่ฝัง secret ในแอป**
/// - Worker URL ไม่ใช่ความลับ (ฝังเป็น default ได้)
/// - แต่ละเครื่อง register เอง → ได้ device JWT ของตัวเอง เก็บในเครื่อง
/// - เรียก /alert ด้วย JWT ตัวเอง → APK แจกสาธารณะได้อย่างปลอดภัย
class DeviceService {
  DeviceService._();
  static final DeviceService _instance = DeviceService._();
  factory DeviceService() => _instance;

  /// URL ของ Cloudflare Worker (ไม่ใช่ความลับ — override ได้ด้วย --dart-define)
  static const String workerBaseUrl = String.fromEnvironment(
    'LINE_WORKER_URL',
    defaultValue: 'https://demenish-line.suparerk9x.workers.dev',
  );

  bool get isConfigured => workerBaseUrl.isNotEmpty;

  Box get _box => Hive.box(HiveBoxes.userProfile);
  String? get _token => _box.get('deviceToken') as String?;
  String? get householdId => _box.get('householdId') as String?;

  /// คืน device JWT (register ครั้งแรกให้อัตโนมัติ)
  Future<String?> _ensureToken() async {
    final existing = _token;
    if (existing != null && existing.isNotEmpty) return existing;
    return _register();
  }

  Future<String?> _register() async {
    if (!isConfigured) return null;
    try {
      final profile = StorageService().getUserProfile();
      final houseName =
          profile.name.isNotEmpty ? '${profile.name} home' : 'My home';
      final resp = await http
          .post(
            Uri.parse('$workerBaseUrl/device/register'),
            headers: {'content-type': 'application/json'},
            body: jsonEncode(
                {'householdName': houseName, 'seniorName': profile.name}),
          )
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        await _box.put('deviceToken', data['deviceToken']);
        await _box.put('householdId', data['householdId']);
        return data['deviceToken'] as String?;
      }
    } catch (e, s) {
      _log('register', e, s);
    }
    return null;
  }

  /// ส่งแจ้งเตือนไปยังผู้ดูแลในบ้านนี้ (คืนจำนวนคนที่ push สำเร็จ; -1 ถ้าเรียกไม่ได้)
  Future<int> alert({
    String type = 'drowsy',
    String severity = 'info',
    required String message,
  }) async {
    final token = await _ensureToken();
    if (token == null) return -1;
    try {
      final resp = await http
          .post(
            Uri.parse('$workerBaseUrl/alert'),
            headers: {
              'content-type': 'application/json',
              'authorization': 'Bearer $token',
            },
            body: jsonEncode(
                {'type': type, 'severity': severity, 'message': message}),
          )
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        return (data['pushed'] as num?)?.toInt() ?? 0;
      }
    } catch (e, s) {
      _log('alert', e, s);
    }
    return -1;
  }

  /// เพิ่มผู้ดูแลด้วย LINE userId
  Future<bool> addCaregiver(String userId, {String displayName = ''}) async {
    final token = await _ensureToken();
    if (token == null) return false;
    try {
      final resp = await http
          .post(
            Uri.parse('$workerBaseUrl/caregiver/add'),
            headers: {
              'content-type': 'application/json',
              'authorization': 'Bearer $token',
            },
            body: jsonEncode({'userId': userId, 'displayName': displayName}),
          )
          .timeout(const Duration(seconds: 10));
      return resp.statusCode >= 200 && resp.statusCode < 300;
    } catch (e, s) {
      _log('addCaregiver', e, s);
      return false;
    }
  }

  Future<bool> removeCaregiver(String userId) async {
    final token = await _ensureToken();
    if (token == null) return false;
    try {
      final resp = await http
          .post(
            Uri.parse('$workerBaseUrl/caregiver/remove'),
            headers: {
              'content-type': 'application/json',
              'authorization': 'Bearer $token',
            },
            body: jsonEncode({'userId': userId}),
          )
          .timeout(const Duration(seconds: 10));
      return resp.statusCode >= 200 && resp.statusCode < 300;
    } catch (e, s) {
      _log('removeCaregiver', e, s);
      return false;
    }
  }

  /// รายชื่อผู้ดูแลในบ้านนี้ [{userId, displayName, role}]
  Future<List<Map<String, dynamic>>> listCaregivers() async {
    final token = await _ensureToken();
    if (token == null) return [];
    try {
      final resp = await http.get(
        Uri.parse('$workerBaseUrl/household'),
        headers: {'authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(
            (data['caregivers'] as List?) ?? const []);
      }
    } catch (e, s) {
      _log('listCaregivers', e, s);
    }
    return [];
  }

  void _log(String m, Object e, StackTrace s) => developer.log(
      'DeviceService.$m failed: $e',
      name: 'DemenishAI', error: e, stackTrace: s);
}
