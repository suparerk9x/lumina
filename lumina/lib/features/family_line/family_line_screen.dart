import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../shared/services/device_service.dart';
import '../../shared/services/line_service.dart';

/// หน้าเชื่อม LINE ครอบครัว (เฟส 1 — multi-tenant, device JWT)
/// ลูกหลานแอด OA → บอทตอบ userId → กรอกในแอป → รับแจ้งเตือนเฉพาะบ้านนี้
class FamilyLineScreen extends StatefulWidget {
  const FamilyLineScreen({super.key});

  @override
  State<FamilyLineScreen> createState() => _FamilyLineScreenState();
}

class _FamilyLineScreenState extends State<FamilyLineScreen> {
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  List<Map<String, dynamic>> _caregivers = [];
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final list = await DeviceService().listCaregivers();
    if (!mounted) return;
    setState(() {
      _caregivers = list;
      _loading = false;
    });
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _openLine() async {
    try {
      await launchUrl(Uri.parse(LineService().addFriendUrl),
          mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) _snack(tr('family.lineOpenFailed'));
    }
  }

  Future<void> _addCaregiver() async {
    final id = _idController.text.trim();
    if (!id.startsWith('U') || id.length < 20) {
      _snack(tr('family.invalidId'));
      return;
    }
    setState(() => _busy = true);
    final ok =
        await DeviceService().addCaregiver(id, displayName: _nameController.text.trim());
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      _idController.clear();
      _nameController.clear();
      _snack(tr('family.added'));
      _refresh();
    } else {
      _snack(tr('family.addFailed'));
    }
  }

  Future<void> _removeCaregiver(String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(tr('family.removeTitle')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr('common.cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: Text(tr('common.delete')),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await DeviceService().removeCaregiver(userId);
    _refresh();
  }

  Future<void> _createInvite() async {
    setState(() => _busy = true);
    final url = await DeviceService().createInvite();
    if (!mounted) return;
    setState(() => _busy = false);
    if (url == null) {
      _snack(tr('family.inviteNotReady'));
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(tr('family.inviteByLink')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(tr('family.inviteCreated'),
                style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              color: Colors.white,
              child: QrImageView(data: url, size: 170),
            ),
            const SizedBox(height: 12),
            SelectableText(url, style: const TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: url));
              _snack(tr('family.linkCopied'));
            },
            child: Text(tr('family.copyLink')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr('common.close')),
          ),
        ],
      ),
    );
  }

  Future<void> _testAlert() async {
    setState(() => _busy = true);
    final pushed = await DeviceService().alert(
      type: 'test',
      severity: 'info',
      message: tr('family.testAlertMessage'),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (pushed < 0) {
      _snack(tr('family.testAlertFailed'));
    } else if (pushed == 0) {
      _snack(tr('family.testAlertNone'));
    } else {
      _snack(trp('family.testAlertSent', {'n': '$pushed'}));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppTheme.darkPrimary : AppTheme.primary;
    final secondary =
        isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;

    return Scaffold(
      appBar: AppBar(title: Text(tr('family.lineTitle'))),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(tr('family.lineIntro'),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: secondary),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),

          // เชิญด้วยลิงก์ (LIFF) — ง่ายสุด
          SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _busy ? null : _createInvite,
              icon: const Icon(Icons.link_rounded),
              label: Text(tr('family.inviteByLink')),
            ),
          ),
          const SizedBox(height: 20),
          Row(children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(tr('family.orManual'),
                  style: TextStyle(fontSize: 13, color: secondary)),
            ),
            const Expanded(child: Divider()),
          ]),
          const SizedBox(height: 16),

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
                data: LineService().addFriendUrl,
                version: QrVersions.auto,
                size: 200,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(LineService.oaBasicId,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: primary)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _openLine,
              icon: const Icon(Icons.open_in_new_rounded),
              label: Text(tr('family.openLineToAdd')),
            ),
          ),
          const SizedBox(height: 24),

          // กรอก userId เพื่อผูก
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: primary.withAlpha(15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(tr('family.getIdStep'),
                style: TextStyle(fontSize: 15, color: secondary)),
          ),
          const SizedBox(height: 16),
          Text(tr('family.caregiverIdField'),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _idController,
            style: const TextStyle(fontSize: 18),
            decoration: const InputDecoration(
              hintText: 'Uxxxxxxxx…',
              prefixIcon: Icon(Icons.badge_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            style: const TextStyle(fontSize: 18),
            decoration: InputDecoration(
              hintText: tr('family.caregiverNameField'),
              prefixIcon: const Icon(Icons.person_rounded),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _busy ? null : _addCaregiver,
              icon: const Icon(Icons.person_add_rounded),
              label: Text(tr('family.addCaregiver')),
            ),
          ),
          const SizedBox(height: 28),

          // รายชื่อผู้ดูแลที่เชื่อมแล้ว
          Text(tr('family.linkedTitle'),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_caregivers.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(tr('family.noCaregivers'),
                  style: TextStyle(fontSize: 16, color: secondary)),
            )
          else
            ..._caregivers.map((c) {
              final name = (c['displayName'] as String?)?.trim();
              final userId = c['userId'] as String? ?? '';
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(Icons.chat_rounded, color: primary),
                  title: Text(name != null && name.isNotEmpty ? name : userId,
                      style: const TextStyle(fontSize: 17)),
                  subtitle: name != null && name.isNotEmpty
                      ? Text(userId,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12))
                      : null,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: AppTheme.error),
                    onPressed: () => _removeCaregiver(userId),
                  ),
                ),
              );
            }),
          const SizedBox(height: 20),

          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _busy ? null : _testAlert,
              icon: const Icon(Icons.send_rounded),
              label: Text(tr('family.testSend')),
            ),
          ),
        ],
      ),
    );
  }
}
