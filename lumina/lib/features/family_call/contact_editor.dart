import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../shared/storage/user_profile.dart';

/// หน้าเพิ่ม/แก้ไขสมาชิกครอบครัว (ชื่อ + เบอร์ + รูป)
/// ส่งคืน [FamilyContact] ผ่าน Navigator.pop เมื่อกดบันทึก
class ContactEditor extends StatefulWidget {
  const ContactEditor({super.key, this.existing});

  /// ถ้าเป็นการแก้ไข ส่ง contact เดิมเข้ามา (null = เพิ่มใหม่)
  final FamilyContact? existing;

  @override
  State<ContactEditor> createState() => _ContactEditorState();
}

class _ContactEditorState extends State<ContactEditor> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _lineController;
  String? _photoBase64;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _phoneController = TextEditingController(text: widget.existing?.phone ?? '');
    _lineController =
        TextEditingController(text: widget.existing?.lineUserId ?? '');
    _photoBase64 = widget.existing?.photoBase64;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _lineController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 70,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() => _photoBase64 = base64Encode(bytes));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('family.photoPickFailed'))),
        );
      }
    }
  }

  void _save() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('family.namePhoneRequired'))),
      );
      return;
    }
    final line = _lineController.text.trim();
    Navigator.of(context).pop(
      FamilyContact(
        name: name,
        phone: phone,
        photoBase64: _photoBase64,
        lineUserId: line.isEmpty ? null : line,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    Uint8List? photoBytes;
    if (_photoBase64 != null) {
      try {
        photoBytes = base64Decode(_photoBase64!);
      } catch (_) {
        photoBytes = null;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? tr('family.editMember') : tr('family.addMember')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickPhoto,
              child: CircleAvatar(
                radius: 64,
                backgroundColor: AppTheme.primary.withAlpha(30),
                backgroundImage:
                    photoBytes != null ? MemoryImage(photoBytes) : null,
                child: photoBytes == null
                    ? const Icon(Icons.add_a_photo_rounded,
                        size: 40, color: AppTheme.primary)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: _pickPhoto,
              icon: const Icon(Icons.photo_library_rounded),
              label: Text(
                  photoBytes == null ? tr('family.addPhoto') : tr('family.changePhoto')),
            ),
          ),
          const SizedBox(height: 24),
          Text(tr('family.nameLabel'),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            style: const TextStyle(fontSize: 20),
            decoration: InputDecoration(
              hintText: tr('family.nameHint'),
              prefixIcon: const Icon(Icons.person_rounded),
            ),
          ),
          const SizedBox(height: 20),
          Text(tr('family.phoneLabel'),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(fontSize: 20),
            decoration: InputDecoration(
              hintText: tr('family.phoneHint'),
              prefixIcon: const Icon(Icons.phone_rounded),
            ),
          ),
          const SizedBox(height: 20),
          Text(tr('family.lineIdLabel'),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            tr('family.lineIdDesc'),
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _lineController,
            style: const TextStyle(fontSize: 18),
            decoration: InputDecoration(
              hintText: tr('family.lineIdHint'),
              prefixIcon: const Icon(Icons.chat_rounded),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_rounded),
              label: Text(tr('family.save')),
            ),
          ),
        ],
      ),
    );
  }
}
