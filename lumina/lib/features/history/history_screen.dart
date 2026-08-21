import 'package:flutter/material.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../shared/storage/assessment_result.dart';
import '../../shared/storage/game_score.dart';
import '../../shared/storage/storage_service.dart';

/// ไฟล์นี้เป็นหน้าจอประวัติคะแนน แสดงผลการประเมินและคะแนนเกมที่ผ่านมา
/// แบ่งเป็น 3 ส่วน: ผลประเมิน, คะแนนเกม, แนวโน้มพัฒนาการ

/// หน้าจอแสดงประวัติคะแนนทั้งหมดของผู้ใช้
/// ใช้ StatefulWidget เพราะต้องโหลดข้อมูลจาก Storage
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

/// State ของหน้าประวัติ เก็บข้อมูลผลประเมินและคะแนนเกม
class _HistoryScreenState extends State<HistoryScreen> {
  // ตัวช่วยเข้าถึงข้อมูลที่เก็บใน Hive (ฐานข้อมูลท้องถิ่น)
  final _storage = StorageService();

  // ข้อมูลผลการประเมิน, คะแนนเกมจับคู่เสียง, คะแนนเกมเรียงลำดับ
  late List<AssessmentResult> _assessments;
  late List<GameScore> _soundScores;
  late List<GameScore> _sequenceScores;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// โหลดข้อมูลจาก Storage: ผลประเมิน 7 รายการล่าสุด และคะแนนเกมอย่างละ 5 รายการ
  void _loadData() {
    _assessments = _storage.getAssessmentHistory(limit: 7);
    _soundScores = _storage.getGameScores('sound_match', limit: 5);
    _sequenceScores = _storage.getGameScores('sequence', limit: 5);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('history.title'))),
      body: RefreshIndicator(
        onRefresh: () async => setState(_loadData),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _AssessmentHistorySection(assessments: _assessments),
            const SizedBox(height: 24),
            _GamePerformanceSection(
              soundScores: _soundScores,
              sequenceScores: _sequenceScores,
            ),
            const SizedBox(height: 24),
            _TrendSection(assessments: _assessments),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ส่วนที่ 1 — ประวัติผลการประเมิน
// ═══════════════════════════════════════════════════════════════

/// แสดงรายการผลการประเมินที่ผ่านมา ถ้ายังไม่มีจะแสดงข้อความว่าง
class _AssessmentHistorySection extends StatelessWidget {
  const _AssessmentHistorySection({required this.assessments});

  final List<AssessmentResult> assessments;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          icon: Icons.assignment_rounded,
          title: tr('history.pastAssessments'),
        ),
        const SizedBox(height: 12),
        if (assessments.isEmpty)
          _EmptyCard(
            message: tr('history.noAssessments'),
            icon: Icons.assignment_outlined,
          )
        else
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                for (int i = 0; i < assessments.length; i++) ...[
                  _AssessmentRow(result: assessments[i]),
                  if (i < assessments.length - 1)
                    Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: Colors.grey.shade200),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

/// แถวแสดงผลการประเมินแต่ละครั้ง มีจุดสี วันที่ และคะแนน
class _AssessmentRow extends StatelessWidget {
  const _AssessmentRow({required this.result});

  final AssessmentResult result;

  /// คำนวณสีของจุดตามอัตราส่วนคะแนน: เขียว(>=80%), เหลือง(>=50%), แดง(<50%)
  Color _dotColor() {
    final ratio = result.maxScore > 0
        ? result.totalScore / result.maxScore
        : 0.0;
    if (ratio >= 0.8) return AppTheme.success;
    if (ratio >= 0.5) return AppTheme.warning;
    return AppTheme.error;
  }

  /// แปลงวันที่เป็นรูปแบบไทย DD/MM/YYYY+543 (พ.ศ.)
  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year + 543}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // จุดสีบอกระดับคะแนน (เขียว/เหลือง/แดง)
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: _dotColor(),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 14),
          // Date
          Expanded(
            child: Text(
              _formatDate(result.date),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 18,
                  ),
            ),
          ),
          // Score
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _dotColor().withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${result.totalScore}/${result.maxScore}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: _dotColor(),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ส่วนที่ 2 — คะแนนเกมฝึกสมอง
// ═══════════════════════════════════════════════════════════════

/// แสดงสถิติคะแนนเกมทั้งสองเกม (จับคู่เสียง และ เรียงลำดับ)
/// มีการ์ดสรุปค่าเฉลี่ย และรายการคะแนนล่าสุด
class _GamePerformanceSection extends StatelessWidget {
  const _GamePerformanceSection({
    required this.soundScores,
    required this.sequenceScores,
  });

  final List<GameScore> soundScores;
  final List<GameScore> sequenceScores;

  /// คำนวณค่าเฉลี่ยคะแนนจากรายการคะแนน
  double _avg(List<GameScore> scores) {
    if (scores.isEmpty) return 0;
    final total = scores.fold<int>(0, (sum, s) => sum + s.score);
    return total / scores.length;
  }

  /// ดึงคะแนนเต็มจากรายการแรก (ทุกครั้งคะแนนเต็มเท่ากัน)
  int _avgTotal(List<GameScore> scores) {
    if (scores.isEmpty) return 0;
    return scores.first.total;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          icon: Icons.sports_esports_rounded,
          title: tr('history.recentGameScores'),
        ),
        const SizedBox(height: 12),

        // Mini stat cards
        Row(
          children: [
            Expanded(
              child: _MiniStatCard(
                title: tr('history.soundMatch'),
                emoji: '🔊',
                avg: _avg(soundScores),
                total: _avgTotal(soundScores),
                isEmpty: soundScores.isEmpty,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MiniStatCard(
                title: tr('history.sequence'),
                emoji: '🔢',
                avg: _avg(sequenceScores),
                total: _avgTotal(sequenceScores),
                isEmpty: sequenceScores.isEmpty,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Recent game list
        if (soundScores.isEmpty && sequenceScores.isEmpty)
          _EmptyCard(
            message: tr('history.noGameScores'),
            icon: Icons.sports_esports_outlined,
          )
        else
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                ..._mergedRecent().asMap().entries.map((entry) {
                  final i = entry.key;
                  final score = entry.value;
                  return Column(
                    children: [
                      _GameScoreRow(score: score),
                      if (i < _mergedRecent().length - 1)
                        Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                            color: Colors.grey.shade200),
                    ],
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }

  /// รวมคะแนนทั้งสองเกมแล้วเรียงตามวันที่ล่าสุด เอาแค่ 5 รายการ
  List<GameScore> _mergedRecent() {
    final all = [...soundScores, ...sequenceScores]
      ..sort((a, b) => b.date.compareTo(a.date));
    return all.take(5).toList();
  }
}

/// การ์ดเล็กแสดงค่าเฉลี่ยคะแนนของแต่ละเกม พร้อม emoji และชื่อเกม
class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.title,
    required this.emoji,
    required this.avg,
    required this.total,
    required this.isEmpty,
  });

  final String title;
  final String emoji;
  final double avg;
  final int total;
  final bool isEmpty;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
            ),
            const SizedBox(height: 8),
            if (isEmpty)
              Text(
                tr('history.noData'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      fontSize: 16,
                    ),
              )
            else
              Text(
                '${avg.toStringAsFixed(1)}/$total',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            if (!isEmpty)
              Text(
                tr('history.avgLast5'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
              ),
          ],
        ),
      ),
    );
  }
}

/// แถวแสดงคะแนนเกมแต่ละครั้ง มีชื่อเกม วันที่ และคะแนน
class _GameScoreRow extends StatelessWidget {
  const _GameScoreRow({required this.score});

  final GameScore score;

  /// แปลง gameType เป็นชื่อภาษาไทยพร้อม emoji
  String _gameLabel() {
    switch (score.gameType) {
      case 'sound_match':
        return '🔊 ${tr('history.soundMatch')}';
      case 'sequence':
        return '🔢 ${tr('history.sequence')}';
      default:
        return score.gameType;
    }
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final ratio =
        score.total > 0 ? score.score / score.total : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _gameLabel(),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(score.date),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: 16,
                      ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (ratio >= 0.7
                      ? AppTheme.success
                      : ratio >= 0.4
                          ? AppTheme.warning
                          : AppTheme.error)
                  .withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${score.score}/${score.total}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: ratio >= 0.7
                        ? AppTheme.success
                        : ratio >= 0.4
                            ? AppTheme.warning
                            : AppTheme.error,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ส่วนที่ 3 — แนวโน้มพัฒนาการ
// ═══════════════════════════════════════════════════════════════

/// แสดงแนวโน้มพัฒนาการสมองของผู้ใช้ โดยเปรียบเทียบคะแนนประเมินล่าสุด
/// ถ้ามีข้อมูล 6 ครั้งขึ้นไป จะเปรียบเทียบ 3 ครั้งล่าสุดกับ 3 ครั้งก่อนหน้า
class _TrendSection extends StatelessWidget {
  const _TrendSection({required this.assessments});

  final List<AssessmentResult> assessments;

  @override
  Widget build(BuildContext context) {
    // Count this week's assessments
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final thisWeek = assessments
        .where((a) => a.date.isAfter(weekStart))
        .length;

    // Trend: compare last 3 avg vs previous 3
    final trend = _computeTrend();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          icon: Icons.trending_up_rounded,
          title: tr('history.trend'),
        ),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: assessments.isEmpty
                ? Center(
                    child: Column(
                      children: [
                        Icon(Icons.show_chart_rounded,
                            size: 40,
                            color: AppTheme.textSecondary.withAlpha(100)),
                        const SizedBox(height: 8),
                        Text(
                          tr('history.doAssessmentForTrend'),
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                color: AppTheme.textSecondary,
                                fontSize: 18,
                              ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      // Week summary
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              size: 22, color: AppTheme.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              trp('history.thisWeekCount', {'n': '$thisWeek'}),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(fontSize: 18),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Trend arrow
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: trend.color.withAlpha(15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: trend.color.withAlpha(50)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              trend.arrow,
                              style: TextStyle(
                                fontSize: 32,
                                color: trend.color,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                trend.label,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: trend.color,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 20,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (assessments.length < 3)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            tr('history.needThreeForTrend'),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppTheme.textSecondary,
                                  fontSize: 16,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  /// คำนวณแนวโน้ม: เปรียบเทียบค่าเฉลี่ย 3 ครั้งล่าสุดกับ 3 ครั้งก่อนหน้า
  /// ถ้าดีขึ้น 5% = ลูกศรขึ้น, แย่ลง 5% = ลูกศรลง, อื่น ๆ = คงที่
  _Trend _computeTrend() {
    if (assessments.length < 3) {
      return _Trend(
        arrow: '→',
        label: tr('history.trendNotEnough'),
        color: AppTheme.textSecondary,
      );
    }

    // Recent 3 average
    final recent3 = assessments.take(3).toList();
    final recentAvg = recent3.fold<double>(
            0, (sum, a) => sum + a.totalScore / a.maxScore) /
        recent3.length;

    // If we have 6+, compare to previous 3
    if (assessments.length >= 6) {
      final prev3 = assessments.skip(3).take(3).toList();
      final prevAvg = prev3.fold<double>(
              0, (sum, a) => sum + a.totalScore / a.maxScore) /
          prev3.length;

      final diff = recentAvg - prevAvg;
      if (diff > 0.05) {
        return _Trend(
          arrow: '↑',
          label: tr('history.trendImproved'),
          color: AppTheme.success,
        );
      } else if (diff < -0.05) {
        return _Trend(
          arrow: '↓',
          label: tr('history.trendPracticeMore'),
          color: AppTheme.error,
        );
      } else {
        return _Trend(
          arrow: '→',
          label: tr('history.trendSteady'),
          color: AppTheme.warning,
        );
      }
    }

    // Only 3–5 results, evaluate by absolute score
    if (recentAvg >= 0.7) {
      return _Trend(
        arrow: '↑',
        label: tr('history.trendGoodStart'),
        color: AppTheme.success,
      );
    } else if (recentAvg >= 0.4) {
      return _Trend(
        arrow: '→',
        label: tr('history.trendDeveloping'),
        color: AppTheme.warning,
      );
    } else {
      return _Trend(
        arrow: '↓',
        label: tr('history.trendShouldPractice'),
        color: AppTheme.error,
      );
    }
  }
}

/// โมเดลข้อมูลสำหรับแสดงแนวโน้ม มีลูกศร ข้อความ และสี
class _Trend {
  const _Trend({
    required this.arrow,
    required this.label,
    required this.color,
  });

  final String arrow;
  final String label;
  final Color color;
}

// ═══════════════════════════════════════════════════════════════
// Widget ที่ใช้ร่วมกันในหน้าประวัติ
// ═══════════════════════════════════════════════════════════════

/// หัวข้อของแต่ละส่วน มีไอคอนและชื่อหัวข้อ
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 22),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

/// การ์ดแสดงเมื่อยังไม่มีข้อมูล พร้อมไอคอนและข้อความบอกผู้ใช้
class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message, required this.icon});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Center(
          child: Column(
            children: [
              Icon(icon, size: 44, color: AppTheme.textSecondary.withAlpha(100)),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                      fontSize: 18,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
