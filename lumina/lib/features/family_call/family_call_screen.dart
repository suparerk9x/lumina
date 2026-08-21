import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../shared/storage/user_profile.dart';
import '../profile/profile_provider.dart';
import 'contact_editor.dart';

/// หน้าโทรหาครอบครัว (ข้อ 2)
/// แสดงรูปสมาชิกครอบครัวเป็นการ์ดใหญ่ กดแล้วโทรออกทันที
/// จัดการรายชื่อ (เพิ่ม/แก้/ลบ) ได้จากปุ่มด้านบน
class FamilyCallScreen extends ConsumerWidget {
  const FamilyCallScreen({super.key});

  Future<void> _call(BuildContext context, String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    try {
      final ok = await launchUrl(uri);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('family.callFailed'))),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('family.callNotSupported'))),
        );
      }
    }
  }

  Future<void> _addContact(BuildContext context, WidgetRef ref) async {
    final contact = await Navigator.of(context).push<FamilyContact>(
      MaterialPageRoute(builder: (_) => const ContactEditor()),
    );
    if (contact != null) {
      await ref.read(profileProvider.notifier).addContact(contact);
    }
  }

  Future<void> _editContact(
      BuildContext context, WidgetRef ref, int index) async {
    final current = ref.read(profileProvider).contacts[index];
    final contact = await Navigator.of(context).push<FamilyContact>(
      MaterialPageRoute(builder: (_) => ContactEditor(existing: current)),
    );
    if (contact != null) {
      await ref.read(profileProvider.notifier).updateContact(index, contact);
    }
  }

  Future<void> _deleteContact(
      BuildContext context, WidgetRef ref, int index, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(tr('family.deleteTitle')),
        content: Text(trp('family.deleteConfirm', {'name': name})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('family.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: Text(tr('family.delete')),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(profileProvider.notifier).removeContact(index);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contacts = ref.watch(profileProvider).contacts;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('family.callTitle')),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            tooltip: tr('family.addMember'),
            onPressed: () => _addContact(context, ref),
          ),
        ],
      ),
      body: contacts.isEmpty
          ? _EmptyState(onAdd: () => _addContact(context, ref))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.82,
              ),
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                final c = contacts[index];
                return _ContactCard(
                  contact: c,
                  onCall: () => _call(context, c.phone),
                  onEdit: () => _editContact(context, ref, index),
                  onDelete: () =>
                      _deleteContact(context, ref, index, c.name),
                );
              },
            ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.contact,
    required this.onCall,
    required this.onEdit,
    required this.onDelete,
  });

  final FamilyContact contact;
  final VoidCallback onCall;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Uint8List? photoBytes;
    if (contact.photoBase64 != null) {
      try {
        photoBytes = base64Decode(contact.photoBase64!);
      } catch (_) {
        photoBytes = null;
      }
    }

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onCall,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.textSecondary),
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'edit', child: Text(tr('family.edit'))),
                    PopupMenuItem(
                        value: 'delete', child: Text(tr('family.delete'))),
                  ],
                ),
              ),
              CircleAvatar(
                radius: 44,
                backgroundColor: AppTheme.primary.withAlpha(30),
                backgroundImage:
                    photoBytes != null ? MemoryImage(photoBytes) : null,
                child: photoBytes == null
                    ? Text(
                        contact.name.isNotEmpty ? contact.name[0] : '?',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 10),
              Text(
                contact.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: onCall,
                  icon: const Icon(Icons.phone_rounded, size: 20),
                  label: Text(tr('family.call')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups_rounded,
                size: 80,
                color: (isDark ? AppTheme.darkPrimary : AppTheme.primary)
                    .withAlpha(120)),
            const SizedBox(height: 24),
            Text(
              tr('family.emptyTitle'),
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              tr('family.emptyBody'),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.person_add_rounded),
                label: Text(tr('family.addFirstMember')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
