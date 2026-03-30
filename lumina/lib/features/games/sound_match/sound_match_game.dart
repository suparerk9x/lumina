import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../core/theme.dart';
import '../../../shared/widgets/exit_dialog.dart';
import 'sound_match_provider.dart';
import 'sound_match_result.dart';
import 'word_emoji_map.dart' as fallback;

/// ไฟล์นี้เป็น UI หลักของเกม "จับคู่เสียง"
/// ผู้ใช้จะได้ยินเสียงอ่านคำภาษาไทย (ผ่าน Text-to-Speech)
/// แล้วต้องเลือก Emoji ที่ตรงกับคำนั้นจากตัวเลือก 4 ตัว

// ═══════════════════════════════════════════════════════════════
// จุดเริ่มต้น — บนเว็บจะแสดงหน้า "แตะเพื่อเริ่ม" ก่อน
// เพราะเบราว์เซอร์บล็อกเสียงอัตโนมัติจนกว่าผู้ใช้จะแตะ
// ═══════════════════════════════════════════════════════════════

/// Widget หลักที่ตรวจสอบว่าเป็นเว็บหรือไม่
/// ถ้าเป็นเว็บจะแสดงหน้าเริ่มต้นก่อน ถ้าเป็นมือถือจะเข้าเกมเลย
class SoundMatchGame extends StatelessWidget {
  const SoundMatchGame({super.key});

  @override
  Widget build(BuildContext context) {
    // บนเว็บ เบราว์เซอร์จะบล็อกเสียงอัตโนมัติจนกว่าผู้ใช้จะแตะหน้าจอ
    // จึงต้องแสดงหน้าเริ่มต้นก่อนเพื่อให้ TTS ทำงานได้หลังจากแตะ
    if (kIsWeb) {
      return const _WebStartScreen();
    }
    return const _SoundMatchGameInner();
  }
}

/// หน้าเริ่มต้นสำหรับเว็บ — แสดงคำแนะนำและปุ่ม "เริ่มเล่น"
/// เมื่อผู้ใช้แตะปุ่ม จะเปิดเกมจริงขึ้นมา (และเบราว์เซอร์จะอนุญาตให้เล่นเสียงได้)
class _WebStartScreen extends StatelessWidget {
  const _WebStartScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('จับคู่เสียง'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.volume_up_rounded,
                  size: 80, color: AppTheme.primary),
              const SizedBox(height: 24),
              Text(
                'เกมจับคู่เสียง',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'ฟังเสียงคำศัพท์ แล้วเลือกรูปที่ตรงกัน',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'เปิดลำโพงให้พร้อม 🔊',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => const _SoundMatchGameInner(),
                    ),
                  );
                },
                icon: const Icon(Icons.play_arrow_rounded, size: 28),
                label: const Text('เริ่มเล่น'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Widget ตัวเกมจริง — จัดการ TTS, แสดงตัวเลือก, รับคำตอบ
// ═══════════════════════════════════════════════════════════════

/// Widget หลักของเกมจับคู่เสียง ใช้ ConsumerStatefulWidget
/// เพื่อเข้าถึง state จาก Riverpod และจัดการ TTS ได้
class _SoundMatchGameInner extends ConsumerStatefulWidget {
  const _SoundMatchGameInner();

  @override
  ConsumerState<_SoundMatchGameInner> createState() =>
      _SoundMatchGameInnerState();
}

class _SoundMatchGameInnerState extends ConsumerState<_SoundMatchGameInner> {
  late FlutterTts _tts; // ตัวแปลงข้อความเป็นเสียง (Text-to-Speech)
  bool _ttsReady = false; // TTS พร้อมใช้งานหรือยัง
  bool _navigated = false; // ป้องกันการนำทางไปหน้าผลลัพธ์ซ้ำ
  bool _firstSpoken = false; // เสียงคำแรกถูกพูดแล้วหรือยัง
  bool _showHint = false; // แสดงคำใบ้ (คำตอบเป็นตัวอักษร) หรือไม่
  Timer? _feedbackTimer; // ตัวจับเวลาสำหรับแสดงผลถูก/ผิดก่อนไปข้อถัดไป

  /// เริ่มต้น: ตั้งค่า TTS และเริ่มเกมใหม่หลัง Widget ถูกสร้าง
  @override
  void initState() {
    super.initState();
    _initTts(); // ตั้งค่าเสียงพูดภาษาไทย
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(soundMatchProvider.notifier).startGame(); // สุ่มโจทย์ทุกข้อ
    });
  }

  /// ตั้งค่า Text-to-Speech ให้พูดภาษาไทย
  /// บนเว็บต้องค้นหาเสียงภาษาไทยจากเบราว์เซอร์
  /// บนมือถือใช้ setLanguage('th-TH') ได้เลย
  Future<void> _initTts() async {
    _tts = FlutterTts();

    try {
      await _tts.setVolume(1.0); // ตั้งความดังเต็ม
      await _tts.setPitch(1.0); // ตั้งระดับเสียงปกติ

      if (kIsWeb) {
        // บนเว็บ ต้องค้นหาและตั้งค่าเสียงภาษาไทยด้วยตนเอง
        // รอสักครู่ให้เบราว์เซอร์โหลดรายการเสียง
        await Future.delayed(const Duration(milliseconds: 500));

        final voices = await _tts.getVoices as List<dynamic>?;
        if (voices != null) {
          // ค้นหาเสียงภาษาไทยจากรายการเสียงทั้งหมดของเบราว์เซอร์
          Map<dynamic, dynamic>? thaiVoice;
          for (final v in voices) {
            final map = v as Map;
            final locale = (map['locale'] ?? map['lang'] ?? '') as String;
            if (locale.startsWith('th')) {
              thaiVoice = map;
              break;
            }
          }

          if (thaiVoice != null) {
            final voiceName = thaiVoice['name'] as String;
            await _tts.setVoice({'name': voiceName, 'locale': 'th-TH'});
            developer.log('Thai voice set: $voiceName', name: 'Lumina');
          } else {
            // ไม่เจอเสียงไทย — ใช้ setLanguage เป็นทางเลือกสำรอง
            await _tts.setLanguage('th-TH');
            developer.log('No Thai voice found, using setLanguage fallback',
                name: 'Lumina');
          }
        }
        await _tts.setSpeechRate(0.8);
      } else {
        // มือถือ: setLanguage ทำงานได้ปกติ
        await _tts.setLanguage('th-TH');
        await _tts.setSpeechRate(0.4); // พูดช้าลงให้ฟังชัด
      }
    } catch (e) {
      developer.log('TTS init error: $e', name: 'Lumina');
    }

    if (mounted) setState(() => _ttsReady = true);
  }

  /// ทำความสะอาดเมื่อ Widget ถูกทำลาย — หยุดเสียงและยกเลิก Timer
  @override
  void dispose() {
    _feedbackTimer?.cancel();
    _tts.stop();
    super.dispose();
  }

  /// สั่งให้ TTS อ่านคำที่กำหนดออกเสียง
  Future<void> _speak(String word) async {
    if (!_ttsReady) return;
    try {
      await _tts.speak(word);
    } catch (e) {
      developer.log('TTS speak error: $e', name: 'Lumina');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(soundMatchProvider); // อ่านสถานะเกมปัจจุบัน

    // เมื่อเล่นครบทุกข้อแล้ว นำทางไปหน้าผลคะแนน (ทำครั้งเดียว)
    if (state.isComplete && !_navigated) {
      _navigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const SoundMatchResult()),
          );
        }
      });
      return const SizedBox.shrink();
    }

    final round = state.current; // ข้อมูลรอบปัจจุบัน (คำถูกต้อง + ตัวเลือก)
    if (round == null) {
      // ยังไม่มีข้อมูล แสดงตัวหมุนรอ
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // เมื่อเปลี่ยนข้อใหม่ — อ่านคำใหม่อัตโนมัติ + ซ่อนคำใบ้
    ref.listen(soundMatchProvider, (prev, next) {
      if (prev?.currentRound != next.currentRound && !next.isComplete) {
        _showHint = false;
        final word = next.current?.correctWord;
        if (word != null) _speak(word);
      }
    });

    // อ่านคำในข้อแรกออกเสียง (ทำครั้งเดียว)
    if (!_firstSpoken &&
        state.currentRound == 0 &&
        !state.showFeedback &&
        state.selectedWord == null) {
      _firstSpoken = true;
      Future.microtask(() => _speak(round.correctWord));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('จับคู่เสียง'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () async {
            final exit = await showExitConfirmation(context,
                title: 'ออกจากเกม?', message: 'คะแนนจะไม่ถูกบันทึก');
            if (exit && context.mounted) Navigator.of(context).pop();
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 8),

              // ─── แถบคะแนนและจุดแสดงความคืบหน้า ───────────────
              _ScoreBar(
                score: state.score,
                current: state.currentRound,
                total: state.totalRounds,
              ),
              const SizedBox(height: 20),

              // ─── ปุ่มลำโพงสำหรับฟังเสียงซ้ำ ───────────────────────
              _SpeakerButton(onTap: () => _speak(round.correctWord)),
              const SizedBox(height: 8),
              Text(
                'แตะรูปที่ตรงกับเสียง',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
              // คำใบ้แสดงตัวอักษร สำหรับผู้ที่ไม่ได้ยินเสียง
              if (_showHint)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withAlpha(15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '💡 "${round.correctWord}"',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: AppTheme.primary),
                    ),
                  ),
                )
              else
                TextButton(
                  onPressed: () => setState(() => _showHint = true),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: Text(
                    'ไม่ได้ยิน? แสดงคำ',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ),
              const SizedBox(height: 20),

              // ─── ตาราง 2x2 แสดง Emoji ตัวเลือก 4 ตัว ────────────────────────────
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.95,
                  children: round.options.map((word) {
                    // ใช้ emoji map จาก state (อาจมาจาก Google Sheets หรือ hardcoded)
                  final emojiMap = state.activeEmojiMap.isNotEmpty
                      ? state.activeEmojiMap
                      : fallback.wordEmojiMap;
                  return _OptionCard(
                      key: ValueKey('${state.currentRound}_$word'),
                      word: word,
                      emoji: emojiMap[word] ?? '❓',
                      isCorrect: word == round.correctWord,
                      isSelected: state.selectedWord == word,
                      showFeedback: state.showFeedback,
                      onTap: () => _onTapOption(word),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// เมื่อผู้ใช้แตะตัวเลือก — ตรวจคำตอบและตั้งเวลาไปข้อถัดไป
  void _onTapOption(String word) {
    // ถ้ากำลังแสดงผลถูก/ผิดอยู่ ไม่รับคำตอบใหม่
    if (_feedbackTimer?.isActive ?? false) return;

    final notifier = ref.read(soundMatchProvider.notifier);
    notifier.selectAnswer(word); // ส่งคำตอบไปตรวจ

    // รอ 1.5 วินาทีให้ผู้ใช้เห็นผลถูก/ผิด แล้วไปข้อถัดไป
    _feedbackTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        notifier.advanceRound();
      }
    });
  }
}

// ─── แถบคะแนนพร้อมจุดแสดงความคืบหน้าของแต่ละข้อ ──────────────────────────────

/// แถบด้านบนแสดงคะแนน (เช่น 3/10) และจุดกลมแสดงว่าทำถึงข้อไหนแล้ว
class _ScoreBar extends StatelessWidget {
  const _ScoreBar({
    required this.score,
    required this.current,
    required this.total,
  });

  final int score;
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$score/$total',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(total, (i) {
              return Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < current
                      ? AppTheme.success
                      : i == current
                          ? AppTheme.primary
                          : Colors.grey.shade300,
                ),
              );
            }),
          ),
        ),
        Text(
          'ข้อ ${current + 1}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
                fontSize: 16,
              ),
        ),
      ],
    );
  }
}

// ─── ปุ่มลำโพงสำหรับกดฟังเสียงซ้ำ ──────────────────────────────────

/// ปุ่มกลมสีหลัก มีไอคอนลำโพง ผู้ใช้แตะเพื่อฟังเสียงคำอีกครั้ง
class _SpeakerButton extends StatelessWidget {
  const _SpeakerButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.primary,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: AppTheme.primary.withAlpha(60),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 80,
          height: 80,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.volume_up_rounded, color: Colors.white, size: 36),
              Text(
                'ฟังอีกครั้ง',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── การ์ดตัวเลือก Emoji ──────────────────────────────────────

/// การ์ดแสดง Emoji ตัวเลือก 1 ใบ
/// เมื่อผู้ใช้ตอบแล้ว จะเปลี่ยนสีขอบ: เขียว = ถูก, แดง = ผิด
class _OptionCard extends StatelessWidget {
  const _OptionCard({
    super.key,
    required this.word,
    required this.emoji,
    required this.isCorrect,
    required this.isSelected,
    required this.showFeedback,
    required this.onTap,
  });

  final String word;
  final String emoji;
  final bool isCorrect;
  final bool isSelected;
  final bool showFeedback;
  final VoidCallback onTap;

  /// คำนวณสีขอบตามสถานะ: ปกติ = เทา, ถูก = เขียว, ผิด = แดง
  Color get _borderColor {
    if (!showFeedback) return Colors.grey.shade300;
    if (isCorrect) return AppTheme.success;
    if (isSelected) return AppTheme.error;
    return Colors.grey.shade300;
  }

  /// คำนวณสีพื้นหลังตามสถานะ: ปกติ = ขาว, ถูก = เขียวอ่อน, ผิด = แดงอ่อน
  Color get _bgColor {
    if (!showFeedback) return Colors.white;
    if (isCorrect) return AppTheme.success.withAlpha(20);
    if (isSelected) return AppTheme.error.withAlpha(20);
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _bgColor,
      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      elevation: showFeedback ? 0 : 2,
      shadowColor: Colors.black.withAlpha(15),
      child: InkWell(
        onTap: showFeedback ? null : onTap,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Container(
          constraints: const BoxConstraints(minHeight: 140),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            border: Border.all(
              color: _borderColor,
              width: showFeedback && (isCorrect || isSelected) ? 3 : 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 56)),
              const SizedBox(height: 8),
              if (showFeedback && isCorrect)
                Text(
                  word,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.success,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              if (showFeedback && isCorrect)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Icon(Icons.check_circle_rounded,
                      color: AppTheme.success, size: 24),
                ),
              if (showFeedback && isSelected && !isCorrect)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Icon(Icons.cancel_rounded,
                      color: AppTheme.error, size: 24),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
