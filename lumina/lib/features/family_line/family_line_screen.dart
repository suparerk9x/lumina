import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme.dart';
import '../../shared/services/line_service.dart';

/// หน้าเชื่อม LINE ครอบครัว (เฟส 0 — broadcast)
/// ให้ลูกหลานสแกน QR แอด OA เป็นเพื่อน แล้วจะได้รับแจ้งเตือนเมื่อผู้สูงอายุมีอาการง่วง
class FamilyLineScreen extends StatelessWidget {
  const FamilyLineScreen({super.key});

  Future<void> _openLine(BuildContext context) async {
    final uri = Uri.parse(LineService().addFriendUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เปิด LINE ไม่สำเร็จ')),
        );
      }
    }
  }

  Future<void> _testBroadcast(BuildContext context) async {
    final ok = await LineService()
        .broadcast('ทดสอบแจ้งเตือนจาก Demenish AI — ถ้าเห็นข้อความนี้แปลว่าพร้อมแล้ว');
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'ส่งข้อความทดสอบแล้ว — เช็ก LINE ของคนที่แอด OA'
            : 'ยังส่งไม่ได้ (แอปนี้ยังไม่ได้ตั้งค่า LINE — ต้อง build ด้วย --dart-define)'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppTheme.darkPrimary : AppTheme.primary;
    final secondary =
        isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    final line = LineService();

    return Scaffold(
      appBar: AppBar(title: const Text('แจ้งครอบครัวผ่าน LINE')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'ให้ลูกหลานสแกน QR นี้เพื่อรับแจ้งเตือน\nเมื่อผู้สูงอายุมีอาการง่วง/เหนื่อยล้า',
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: secondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // QR แอด OA
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primary.withAlpha(60), width: 2),
              ),
              child: QrImageView(
                data: line.addFriendUrl,
                version: QrVersions.auto,
                size: 220,
                gapless: false,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              LineService.oaBasicId,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primary,
              ),
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () => _openLine(context),
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('เปิด LINE เพื่อแอด'),
            ),
          ),
          const SizedBox(height: 28),

          // ขั้นตอน
          _StepCard(
            steps: const [
              'ลูกหลานเปิดแอป LINE บนมือถือตัวเอง',
              'สแกน QR นี้ (หรือกดปุ่มเปิด LINE) แล้วแอด "Demenish-AI" เป็นเพื่อน',
              'เปิดฟีเจอร์ "ตรวจจับอาการง่วง" ในหน้าตั้งค่า',
              'เมื่อแอปพบอาการง่วง ทุกคนที่แอดจะได้รับแจ้งเตือนใน LINE',
            ],
          ),
          const SizedBox(height: 24),

          if (line.isConfigured)
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => _testBroadcast(context),
                icon: const Icon(Icons.send_rounded),
                label: const Text('ทดสอบส่งแจ้งเตือน'),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.warning.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'แอปนี้ยังไม่ได้ตั้งค่าเชื่อม LINE — ต้อง build ด้วย '
                '--dart-define (ดู docs/backend) จึงจะส่งแจ้งเตือนจริงได้',
                style: TextStyle(fontSize: 14, color: secondary),
              ),
            ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.steps});

  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).brightness == Brightness.dark
        ? AppTheme.darkPrimary
        : AppTheme.primary;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < steps.length; i++)
              Padding(
                padding: EdgeInsets.only(bottom: i == steps.length - 1 ? 0 : 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration:
                          BoxDecoration(color: primary, shape: BoxShape.circle),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(steps[i],
                            style: const TextStyle(fontSize: 17)),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
