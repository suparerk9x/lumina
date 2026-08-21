import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../shared/services/scam_detector.dart';

/// หน้าตรวจข้อความหลอกลวง (ข้อ 3)
/// วางข้อความที่น่าสงสัย → ตรวจด้วย rule-based ไทย → แสดงระดับความเสี่ยง + เหตุผล
class ScamCheckScreen extends StatefulWidget {
  const ScamCheckScreen({super.key});

  @override
  State<ScamCheckScreen> createState() => _ScamCheckScreenState();
}

class _ScamCheckScreenState extends State<ScamCheckScreen> {
  final _controller = TextEditingController();
  ScamResult? _result;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text ?? '';
    if (text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('scam.clipboardEmpty'))),
        );
      }
      return;
    }
    setState(() {
      _controller.text = text;
      _result = null;
    });
  }

  void _check() {
    FocusScope.of(context).unfocus();
    setState(() => _result = ScamDetector().analyze(_controller.text));
  }

  void _clear() {
    setState(() {
      _controller.clear();
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary =
        isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;

    return Scaffold(
      appBar: AppBar(title: Text(tr('scam.title'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            tr('scam.intro'),
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: secondary),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            maxLines: 6,
            style: const TextStyle(fontSize: 18),
            decoration: InputDecoration(
              hintText: tr('scam.inputHint'),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _paste,
                    icon: const Icon(Icons.content_paste_rounded),
                    label: Text(tr('scam.paste')),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _check,
                    icon: const Icon(Icons.shield_rounded),
                    label: Text(tr('scam.check')),
                  ),
                ),
              ),
            ],
          ),
          if (_result != null) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: _clear, child: Text(tr('scam.clear'))),
            const SizedBox(height: 8),
            _ResultCard(result: _result!),
          ],
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final ScamResult result;

  Color get _color => switch (result.risk) {
        ScamRisk.high => AppTheme.error,
        ScamRisk.medium => AppTheme.warning,
        ScamRisk.low => AppTheme.success,
      };

  IconData get _icon => switch (result.risk) {
        ScamRisk.high => Icons.dangerous_rounded,
        ScamRisk.medium => Icons.warning_amber_rounded,
        ScamRisk.low => Icons.verified_user_rounded,
      };

  @override
  Widget build(BuildContext context) {
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _color.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_icon, color: _color, size: 32),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr('scam.riskLabel'),
                          style: Theme.of(context).textTheme.bodyMedium),
                      Text(
                        result.risk.label,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _color.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                result.risk.advice,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600, color: _color),
              ),
            ),
            if (result.reasons.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(tr('scam.detected'),
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...result.reasons.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('•  ', style: TextStyle(fontSize: 18)),
                      Expanded(
                        child: Text(r, style: const TextStyle(fontSize: 17)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
