import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

import '../storage/hive_boxes.dart';

/// บริการโหลดข้อมูลเกมจาก Google Sheets ผ่าน Published CSV
///
/// วิธีตั้งค่า Google Sheet:
/// 1. สร้าง Google Sheet ตามรูปแบบที่กำหนด (ดูด้านล่าง)
/// 2. File → Share → Publish to web → เลือก Sheet → เลือก CSV → Publish
/// 3. คัดลอก URL มาใส่ในตัวแปร [soundMatchSheetUrl] และ [sequenceSheetUrl]
///
/// ─── รูปแบบ Google Sheet สำหรับเกม Sound Match ───
/// | word     | emoji |
/// |----------|-------|
/// | บ้าน     | 🏠    |
/// | แมว      | 🐱    |
/// | น้ำ      | 💧    |
///
/// ─── รูปแบบ Google Sheet สำหรับเกม Sequence ───
/// | title           | item1_label | item1_emoji | item2_label | item2_emoji | item3_label | item3_emoji | item4_label | item4_emoji | item5_label | item5_emoji | item6_label | item6_emoji |
/// |-----------------|-------------|-------------|-------------|-------------|-------------|-------------|-------------|-------------|-------------|-------------|-------------|-------------|
/// | กิจวัตรประจำวัน   | ตื่นนอน      | 🌅          | ล้างหน้า     | 🚿          | แปรงฟัน      | 🦷          | กินข้าว      | 🍚          | อาบน้ำ       | 🛁          | เข้านอน      | 🌙          |
///
class GoogleSheetsService {
  GoogleSheetsService._();
  static final GoogleSheetsService _instance = GoogleSheetsService._();
  factory GoogleSheetsService() => _instance;

  // ─── URL ของ Google Sheets (Published CSV) ───────────────────
  // เปลี่ยน URL เหล่านี้เป็น URL จริงของ Google Sheet ที่ Publish แล้ว
  // ตั้งเป็นค่าว่างถ้ายังไม่ได้ตั้งค่า → จะใช้ข้อมูล hardcoded แทน
  static const String soundMatchSheetUrl =
      'https://docs.google.com/spreadsheets/d/e/2PACX-1vQAvmGZYE1DT7BBpiPIljwnTKGfqmIJ02am4_7crRViJLu6FWOmk8ynFhX2gbZD_fHRaJEGm7zTOrc6/pub?gid=0&single=true&output=csv';
  static const String sequenceSheetUrl =
      'https://docs.google.com/spreadsheets/d/e/2PACX-1vQAvmGZYE1DT7BBpiPIljwnTKGfqmIJ02am4_7crRViJLu6FWOmk8ynFhX2gbZD_fHRaJEGm7zTOrc6/pub?gid=36045986&single=true&output=csv';

  // ─── Keys สำหรับ cache ใน Hive ─────────────────────────────
  static const String _soundMatchCacheKey = 'sound_match_csv';
  static const String _sequenceCacheKey = 'sequence_csv';
  static const String _lastFetchKey = 'last_fetch_time';

  /// ระยะเวลา cache (ไม่ fetch ซ้ำภายใน 30 นาที)
  static const Duration _cacheDuration = Duration(minutes: 30);

  /// โหลดข้อมูลเกม Sound Match จาก Google Sheets
  /// คืน null ถ้าไม่สามารถโหลดได้ (ให้ใช้ข้อมูล hardcoded แทน)
  Future<SoundMatchSheetData?> fetchSoundMatchData() async {
    if (soundMatchSheetUrl.isEmpty) return null;

    final csv = await _fetchCsvWithCache(
      url: soundMatchSheetUrl,
      cacheKey: _soundMatchCacheKey,
    );
    if (csv == null) return null;

    try {
      return _parseSoundMatchCsv(csv);
    } catch (e) {
      debugPrint('Error parsing Sound Match CSV: $e');
      return null;
    }
  }

  /// โหลดข้อมูลเกม Sequence จาก Google Sheets
  /// คืน null ถ้าไม่สามารถโหลดได้ (ให้ใช้ข้อมูล hardcoded แทน)
  Future<SequenceSheetData?> fetchSequenceData() async {
    if (sequenceSheetUrl.isEmpty) return null;

    final csv = await _fetchCsvWithCache(
      url: sequenceSheetUrl,
      cacheKey: _sequenceCacheKey,
    );
    if (csv == null) return null;

    try {
      return _parseSequenceCsv(csv);
    } catch (e) {
      debugPrint('Error parsing Sequence CSV: $e');
      return null;
    }
  }

  /// Fetch CSV จาก URL พร้อมระบบ cache
  /// 1. เช็ค cache ก่อน → ถ้ายังไม่หมดอายุ ใช้ cache
  /// 2. ถ้าหมดอายุ → fetch ใหม่แล้วเก็บ cache
  /// 3. ถ้า fetch ไม่ได้ → ใช้ cache เก่า (ถ้ามี)
  Future<String?> _fetchCsvWithCache({
    required String url,
    required String cacheKey,
  }) async {
    final box = Hive.box(HiveBoxes.cachedGameData);

    // เช็คว่ามี cache อยู่และยังไม่หมดอายุ
    final lastFetch = box.get('${cacheKey}_$_lastFetchKey') as int?;
    final cachedCsv = box.get(cacheKey) as String?;

    if (lastFetch != null && cachedCsv != null) {
      final elapsed = DateTime.now().millisecondsSinceEpoch - lastFetch;
      if (elapsed < _cacheDuration.inMilliseconds) {
        return cachedCsv; // ใช้ cache
      }
    }

    // Fetch ใหม่จาก Google Sheets
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final csv = utf8.decode(response.bodyBytes);
        // บันทึก cache
        await box.put(cacheKey, csv);
        await box.put('${cacheKey}_$_lastFetchKey',
            DateTime.now().millisecondsSinceEpoch);
        return csv;
      }
    } catch (e) {
      debugPrint('Error fetching CSV from $url: $e');
    }

    // ถ้า fetch ไม่ได้ ใช้ cache เก่า (ถ้ามี)
    return cachedCsv;
  }

  /// Parse CSV สำหรับ Sound Match
  /// คอลัมน์: word, emoji
  SoundMatchSheetData _parseSoundMatchCsv(String csv) {
    final lines = const LineSplitter().convert(csv);
    if (lines.length < 2) {
      throw FormatException('CSV ต้องมีอย่างน้อย 2 บรรทัด (header + data)');
    }

    final words = <String>[];
    final emojiMap = <String, String>{};

    // ข้ามบรรทัดแรก (header)
    for (int i = 1; i < lines.length; i++) {
      final fields = _parseCsvLine(lines[i]);
      if (fields.length < 2) continue;

      final word = fields[0].trim();
      final emoji = fields[1].trim();
      if (word.isEmpty || emoji.isEmpty) continue;

      words.add(word);
      emojiMap[word] = emoji;
    }

    if (words.length < 4) {
      throw FormatException('ต้องมีคำศัพท์อย่างน้อย 4 คำ (มี ${words.length})');
    }

    return SoundMatchSheetData(words: words, emojiMap: emojiMap);
  }

  /// Parse CSV สำหรับ Sequence
  /// คอลัมน์: title, item1_label, item1_emoji, item2_label, item2_emoji, ...
  SequenceSheetData _parseSequenceCsv(String csv) {
    final lines = const LineSplitter().convert(csv);
    if (lines.length < 2) {
      throw FormatException('CSV ต้องมีอย่างน้อย 2 บรรทัด (header + data)');
    }

    final datasets = <SequenceSheetDataset>[];

    for (int i = 1; i < lines.length; i++) {
      final fields = _parseCsvLine(lines[i]);
      if (fields.length < 3) continue; // ต้องมี title + อย่างน้อย 1 item (label+emoji)

      final title = fields[0].trim();
      if (title.isEmpty) continue;

      final items = <SequenceSheetItem>[];
      // อ่าน label+emoji เป็นคู่ ๆ ตั้งแต่คอลัมน์ที่ 2 เป็นต้นไป
      for (int j = 1; j + 1 < fields.length; j += 2) {
        final label = fields[j].trim();
        final emoji = fields[j + 1].trim();
        if (label.isEmpty) break; // หยุดเมื่อเจอช่องว่าง
        items.add(SequenceSheetItem(label: label, emoji: emoji));
      }

      if (items.length >= 2) {
        datasets.add(SequenceSheetDataset(title: title, items: items));
      }
    }

    if (datasets.isEmpty) {
      throw FormatException('ไม่พบข้อมูลชุดคำถามที่ถูกต้อง');
    }

    return SequenceSheetData(datasets: datasets);
  }

  /// Parse บรรทัด CSV ให้เป็น list of strings รองรับ comma ใน quoted string
  List<String> _parseCsvLine(String line) {
    final result = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    result.add(buffer.toString());
    return result;
  }
}

// ─── โมเดลข้อมูลจาก Google Sheets ──────────────────────────────

/// ข้อมูลเกม Sound Match จาก Sheet
class SoundMatchSheetData {
  const SoundMatchSheetData({
    required this.words,
    required this.emojiMap,
  });

  final List<String> words; // รายการคำทั้งหมด
  final Map<String, String> emojiMap; // คำ → emoji
}

/// ข้อมูลเกม Sequence จาก Sheet
class SequenceSheetData {
  const SequenceSheetData({required this.datasets});

  final List<SequenceSheetDataset> datasets;
}

/// ชุดข้อมูล 1 ชุด (1 แถวใน Sheet)
class SequenceSheetDataset {
  const SequenceSheetDataset({
    required this.title,
    required this.items,
  });

  final String title;
  final List<SequenceSheetItem> items;
}

/// รายการ 1 ตัวในชุดคำถาม Sequence
class SequenceSheetItem {
  const SequenceSheetItem({
    required this.label,
    required this.emoji,
  });

  final String label;
  final String emoji;
}
