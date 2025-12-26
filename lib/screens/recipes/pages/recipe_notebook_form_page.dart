import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/recipe_repository.dart';
import '../models/recipe_notebook.dart';
import '../recipes_theme.dart';
import '../../../services/customer_profile_service.dart';
import '../../../services/customer_session_service.dart';
import '../../../widgets/app_image.dart';

class RecipeNotebookFormPage extends StatefulWidget {
  const RecipeNotebookFormPage({super.key, this.notebook});

  final RecipeNotebook? notebook;

  @override
  State<RecipeNotebookFormPage> createState() => _RecipeNotebookFormPageState();
}

class _RecipeNotebookFormPageState extends State<RecipeNotebookFormPage> {
  static const String _defaultCoverUrl =
      'https://images.unsplash.com/photo-1493770348161-369560ae357d?auto=format&fit=crop&w=900&q=80';

  late final TextEditingController _titleController;
  String? _coverImage;
  bool _isSaving = false;
  bool _isPicking = false;

  bool get _isEditing => widget.notebook != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.notebook?.title ?? '',
    );
    final existing = widget.notebook?.coverImage;
    if (existing != null && existing.trim().isNotEmpty) {
      _coverImage = existing.trim();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: source,
        maxWidth: 1000,
        imageQuality: 70,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      final dataUrl = await compute(_encodeImageToDataUrl, bytes);
      if (!mounted) return;
      setState(() => _coverImage = dataUrl);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Fotoğraf seçilemedi.')));
    } finally {
      if (!mounted) return;
      setState(() => _isPicking = false);
    }
  }

  Future<void> _saveNotebook() async {
    if (_isSaving) return;
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Defter adı gerekli.')));
      return;
    }
    setState(() => _isSaving = true);
    final repo = RecipeRepository.instance;
    final cover = (_coverImage != null && _coverImage!.trim().isNotEmpty)
        ? _coverImage!.trim()
        : _defaultCoverUrl;

    if (_isEditing) {
      final notebook = widget.notebook!;
      final updated = await repo.updateNotebookFromPayload(notebook, {
        'title': title,
        'cover_image_url': cover,
      });
      if (!mounted) return;
      setState(() => _isSaving = false);
      if (updated == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Defter güncellenemedi.')));
        return;
      }
      Navigator.pop(context, true);
      return;
    }

    final ownerEmail = _resolveOwnerEmail();
    final ownerName = _resolveOwnerName(ownerEmail);
    final payload = RecipeNotebook(
      id: 'temp',
      title: title,
      coverImage: cover,
      recipeIds: const [],
      owner: ownerName,
      ownerEmail: ownerEmail,
      createdAt: DateTime.now(),
    ).toApiCreatePayload(ownerName: ownerName, ownerEmail: ownerEmail);
    final created = await repo.createNotebookFromPayload(payload);
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (created == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Defter oluşturulamadı.')));
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RecipeColors.background,
      appBar: AppBar(
        backgroundColor: RecipeColors.primary,
        foregroundColor: Colors.white,
        title: Text(_isEditing ? 'Defteri Düzenle' : 'Yeni Defter'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _FormSection(
            title: 'Defter adı',
            child: TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Orn: Tatlı tarifleri',
              ),
            ),
          ),
          _FormSection(
            title: 'Kapak fotoğrafı',
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isPicking
                            ? null
                            : () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Kamera'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isPicking
                            ? null
                            : () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Galeri'),
                      ),
                    ),
                  ],
                ),
                if (_isPicking) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(),
                ],
                const SizedBox(height: 12),
                _coverImage == null || _coverImage!.trim().isEmpty
                    ? Container(
                        height: 160,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: RecipeColors.border),
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.photo_outlined,
                              color: RecipeColors.textMuted,
                              size: 36,
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Kapak fotoğrafı seçilmedi',
                              style: TextStyle(color: RecipeColors.textMuted),
                            ),
                          ],
                        ),
                      )
                    : AppImage(
                        source: _coverImage,
                        width: double.infinity,
                        height: 160,
                        borderRadius: BorderRadius.circular(14),
                      ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveNotebook,
            style: ElevatedButton.styleFrom(
              backgroundColor: RecipeColors.secondary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              _isSaving
                  ? 'Kaydediliyor...'
                  : _isEditing
                  ? 'Kaydet'
                  : 'Oluştur',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RecipeColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: RecipeColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

String _encodeImageToDataUrl(List<int> bytes) {
  return 'data:image/jpeg;base64,${base64Encode(bytes)}';
}

String _resolveOwnerEmail() {
  final email = CustomerSessionService.instance.user.value?.email;
  if (email != null && email.trim().isNotEmpty) {
    return email.trim();
  }
  return 'guest@eaty.local';
}

String _resolveOwnerName(String ownerEmail) {
  final profileName = CustomerProfileService.instance.profile.value?.name;
  if (profileName != null && profileName.trim().isNotEmpty) {
    return profileName.trim();
  }
  if (ownerEmail.contains('@')) {
    final base = ownerEmail.split('@').first.trim();
    if (base.isNotEmpty) return base;
  }
  return 'Kullanici';
}
