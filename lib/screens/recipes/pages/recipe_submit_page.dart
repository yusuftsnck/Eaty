import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/recipe_repository.dart';
import '../models/recipe.dart';
import '../recipes_theme.dart';
import '../widgets/recipe_step_indicator.dart';
import '../../../services/customer_profile_service.dart';
import '../../../services/customer_session_service.dart';

class RecipeSubmitPage extends StatefulWidget {
  const RecipeSubmitPage({super.key, this.initialRecipe});

  final Recipe? initialRecipe;

  @override
  State<RecipeSubmitPage> createState() => _RecipeSubmitPageState();
}

class _RecipeSubmitPageState extends State<RecipeSubmitPage> {
  final PageController _pageController = PageController();
  final ImagePicker _picker = ImagePicker();

  int _currentStep = 0;
  bool _isSubmitting = false;
  late final List<String> _prepTimeOptions;
  late final List<String> _cookTimeOptions;

  final _titleController = TextEditingController();
  final _storyController = TextEditingController();
  final _ingredientsController = TextEditingController();
  late List<TextEditingController> _stepControllers;
  final List<String> _photoUrls = [];

  String _category = 'Ana Yemek';
  String _servings = '2 kişilik';
  String _prepTime = '15 dk';
  String _cookTime = '30 dk';
  String _equipment = 'Tencere';
  String _method = 'Fırın';
  String _difficulty = 'Orta';
  bool _acceptedTerms = false;

  bool get _isEditing => widget.initialRecipe != null;

  @override
  void initState() {
    super.initState();
    _prepTimeOptions = const ['10 dk', '15 dk', '20 dk', '30 dk', '45 dk'];
    _cookTimeOptions = const ['10 dk', '20 dk', '30 dk', '40 dk', '60 dk'];
    final recipe = widget.initialRecipe;
    if (recipe != null) {
      _titleController.text = recipe.title;
      _storyController.text = recipe.story;
      _ingredientsController.text = recipe.ingredients.join('\n');
      _stepControllers = recipe.steps.isNotEmpty
          ? recipe.steps
                .map((step) => TextEditingController(text: step))
                .toList()
          : [TextEditingController()];
      _photoUrls
        ..clear()
        ..addAll(recipe.galleryImages);
      _category = recipe.category;
      _servings = recipe.servings;
      _difficulty = recipe.difficulty;
      _equipment = recipe.equipment;
      _method = recipe.method;
      _applyTimeFromRecipe(recipe.time);
    } else {
      _stepControllers = [TextEditingController(), TextEditingController()];
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _storyController.dispose();
    _ingredientsController.dispose();
    for (final controller in _stepControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _applyTimeFromRecipe(String time) {
    final parts = time.split('+').map((part) => part.trim()).toList();
    if (parts.isNotEmpty) {
      final prep = parts.first;
      _prepTime = _prepTimeOptions.contains(prep)
          ? prep
          : _prepTimeOptions.first;
    }
    if (parts.length > 1) {
      final cook = parts[1];
      _cookTime = _cookTimeOptions.contains(cook)
          ? cook
          : _cookTimeOptions.first;
    } else {
      _cookTime = _cookTimeOptions.first;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_photoUrls.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En fazla 10 fotoğraf ekleyebilirsin.')),
      );
      return;
    }
    final image = await _picker.pickImage(
      source: source,
      maxWidth: 1400,
      imageQuality: 80,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    final dataUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    setState(() => _photoUrls.add(dataUrl));
  }

  void _addStep() {
    setState(() => _stepControllers.add(TextEditingController()));
  }

  void _removeStep() {
    if (_stepControllers.length <= 1) return;
    final controller = _stepControllers.removeLast();
    controller.dispose();
    setState(() {});
  }

  void _removePhoto(int index) {
    if (index < 0 || index >= _photoUrls.length) return;
    setState(() => _photoUrls.removeAt(index));
  }

  void _movePhoto(int index, int direction) {
    final newIndex = index + direction;
    if (newIndex < 0 || newIndex >= _photoUrls.length) return;
    setState(() {
      final temp = _photoUrls[index];
      _photoUrls[index] = _photoUrls[newIndex];
      _photoUrls[newIndex] = temp;
    });
  }

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _nextStep() async {
    if (_isSubmitting) return;
    if (_currentStep == 0) {
      if (_titleController.text.trim().isEmpty ||
          _ingredientsController.text.trim().isEmpty ||
          _stepControllers.every(
            (controller) => controller.text.trim().isEmpty,
          )) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tarif bilgilerini doldur.')),
        );
        return;
      }
    }

    if (_currentStep < 2) {
      _goToStep(_currentStep + 1);
    } else {
      if (!_acceptedTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Koşulları kabul etmelisin.')),
        );
        return;
      }
      await _submitRecipe();
    }
  }

  Future<void> _submitRecipe() async {
    setState(() => _isSubmitting = true);
    final ingredients = _ingredientsController.text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    final steps = _stepControllers
        .map((controller) => controller.text.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final coverImage = _photoUrls.isNotEmpty
        ? _photoUrls.first
        : 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=900&q=80';

    final authorEmail = _resolveAuthorEmail();
    final authorName = _resolveAuthorName(authorEmail);

    final recipe = Recipe(
      id: 'user_${DateTime.now().microsecondsSinceEpoch}',
      title: _titleController.text.trim(),
      author: authorName,
      authorHandle: '@sen',
      summary: _storyController.text.trim().isEmpty
          ? 'Topluluğa yeni bir tarif'
          : _storyController.text.trim(),
      coverImage: coverImage,
      galleryImages: _photoUrls.isEmpty ? [coverImage] : [..._photoUrls],
      time: '$_prepTime + $_cookTime',
      servings: _servings,
      difficulty: _difficulty,
      category: _category,
      story: _storyController.text.trim().isEmpty
          ? 'Tarif detaylari tarif sahibinden.'
          : _storyController.text.trim(),
      ingredients: ingredients,
      steps: steps,
      equipment: _equipment,
      method: _method,
      likes: 0,
      comments: 0,
      saves: 0,
      createdAt: DateTime.now(),
    );

    if (_isEditing) {
      final existing = widget.initialRecipe!;
      final updated = recipe.copyWith(
        id: existing.id,
        author: existing.author,
        authorHandle: existing.authorHandle,
        likes: existing.likes,
        comments: existing.comments,
        saves: existing.saves,
        createdAt: existing.createdAt,
      );
      final payload = updated.toApiUpdatePayload(
        prepTime: _prepTime,
        cookTime: _cookTime,
        equipment: _equipment,
        method: _method,
      );
      final result = await RecipeRepository.instance.updateRecipeFromPayload(
        existing,
        payload,
        userEmail: authorEmail,
      );
      if (!mounted) return;
      if (result == null) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Tarif güncellenemedi.')));
        return;
      }
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tarif güncellendi.')));
      return;
    }

    final payload = recipe.toApiCreatePayload(
      authorName: authorName,
      authorEmail: authorEmail,
      prepTime: _prepTime,
      cookTime: _cookTime,
      equipment: _equipment,
      method: _method,
    );

    final created = await RecipeRepository.instance.createRecipeFromPayload(
      payload,
    );
    if (!mounted) return;
    if (created == null) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tarif kaydedilemedi.')));
      return;
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Tarif paylaşıldı.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RecipeColors.background,
      appBar: AppBar(
        backgroundColor: RecipeColors.primary,
        foregroundColor: Colors.white,
        title: Text(_isEditing ? 'Tarif Düzenle' : 'Tarif Gönder'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: RecipeStepIndicator(
              steps: const ['Tarif Bilgisi', 'Tarif Fotoğrafı', 'Kategori'],
              currentIndex: _currentStep,
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildInfoStep(),
                _buildPhotoStep(),
                _buildCategoryStep(),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: RecipeColors.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _isSubmitting
                            ? 'Gönderiliyor...'
                            : _currentStep < 2
                            ? 'Devam Et'
                            : _isEditing
                            ? 'Güncelle'
                            : 'Tarifi Gönder',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoStep() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        _FormSection(
          title: 'Tarif Adı',
          child: TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              hintText: 'Orn: Tereyağlı Pirinç Pilavı',
            ),
          ),
        ),
        _FormSection(
          title: 'Tarif Hikayesi',
          child: TextField(
            controller: _storyController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Tarifin küçük hikayesini yaz.',
            ),
          ),
        ),
        _FormSection(
          title: 'Malzemeler',
          child: TextField(
            controller: _ingredientsController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Her malzemeyi ayrı satıra yazın.',
            ),
          ),
        ),
        _FormSection(
          title: 'Hazırlanış',
          child: Column(
            children: [
              ..._stepControllers.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: RecipeColors.secondary,
                        child: Text(
                          '${entry.key + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: entry.value,
                          decoration: const InputDecoration(
                            hintText: 'Adımı yaz.',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _removeStep,
                      icon: const Icon(Icons.remove),
                      label: const Text('Adım Kaldır'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _addStep,
                      icon: const Icon(Icons.add),
                      label: const Text('Adım Ekle'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildPhotoStep() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Fotoğraf Çek'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Galeriden Seç'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1,
          ),
          itemCount: _photoUrls.length < 6 ? 6 : _photoUrls.length,
          itemBuilder: (context, index) {
            final hasImage = index < _photoUrls.length;
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: RecipeColors.border),
              ),
              child: hasImage
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: _buildPhotoPreview(_photoUrls[index]),
                        ),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: _PhotoAction(
                            icon: Icons.close,
                            onTap: () => _removePhoto(index),
                          ),
                        ),
                        Positioned(
                          bottom: 6,
                          left: 6,
                          child: _PhotoAction(
                            icon: Icons.chevron_left,
                            onTap: () => _movePhoto(index, -1),
                          ),
                        ),
                        Positioned(
                          bottom: 6,
                          right: 6,
                          child: _PhotoAction(
                            icon: Icons.chevron_right,
                            onTap: () => _movePhoto(index, 1),
                          ),
                        ),
                      ],
                    )
                  : const Icon(
                      Icons.photo_outlined,
                      color: RecipeColors.textMuted,
                    ),
            );
          },
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: RecipeColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'İpucu',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: RecipeColors.textDark,
                ),
              ),
              SizedBox(height: 6),
              _BulletText(text: 'En fazla 10 adet fotoğraf ekleyebilirsin.'),
              _BulletText(text: 'Aşama fotoğraflari ilgiyi artırır.'),
              _BulletText(text: 'Oklar ile sıralama yapabilirsin.'),
              _BulletText(text: 'Silmek için X ikonunu kullan.'),
              _BulletText(text: 'Kapak fotoğrafın ilk görsel olur.'),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildCategoryStep() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        _DropdownSection(
          title: 'Kategori',
          value: _category,
          items: const ['Ana Yemek', 'Çorba', 'Meze', 'Tatli', 'Salata'],
          onChanged: (value) => setState(() => _category = value),
        ),
        _DropdownSection(
          title: 'Kaç kişilik',
          value: _servings,
          items: const ['1 kişilik', '2 kişilik', '4 kişilik', '6 kişilik'],
          onChanged: (value) => setState(() => _servings = value),
        ),
        _DropdownSection(
          title: 'Hazırlama süresi',
          value: _prepTime,
          items: _prepTimeOptions,
          onChanged: (value) => setState(() => _prepTime = value),
        ),
        _DropdownSection(
          title: 'Pişme süresi',
          value: _cookTime,
          items: _cookTimeOptions,
          onChanged: (value) => setState(() => _cookTime = value),
        ),
        _DropdownSection(
          title: 'Pişirme gereci',
          value: _equipment,
          items: const ['Tencere', 'Tava', 'Fırın', 'Airfryer', 'Izgara'],
          onChanged: (value) => setState(() => _equipment = value),
        ),
        _DropdownSection(
          title: 'Pişirme yöntemi',
          value: _method,
          items: const ['Fırın', 'Ocak', 'Izgara', 'Buharda'],
          onChanged: (value) => setState(() => _method = value),
        ),
        _DropdownSection(
          title: 'Zorluk',
          value: _difficulty,
          items: const ['Kolay', 'Orta', 'Zor'],
          onChanged: (value) => setState(() => _difficulty = value),
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          value: _acceptedTerms,
          onChanged: (value) => setState(() => _acceptedTerms = value ?? false),
          title: const Text('Tarif Gönderim Koşullarını kabul ediyorum.'),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  String _resolveAuthorEmail() {
    final email = CustomerSessionService.instance.user.value?.email;
    if (email != null && email.trim().isNotEmpty) {
      return email.trim();
    }
    return 'guest@eaty.local';
  }

  String _resolveAuthorName(String authorEmail) {
    final profileName = CustomerProfileService.instance.profile.value?.name;
    if (profileName != null && profileName.trim().isNotEmpty) {
      return profileName.trim();
    }
    if (authorEmail.contains('@')) {
      final base = authorEmail.split('@').first.trim();
      if (base.isNotEmpty) return base;
    }
    return 'Kullanici';
  }

  Widget _buildPhotoPreview(String source) {
    if (source.startsWith('data:image')) {
      return Image.memory(
        base64Decode(source.split(',').last),
        fit: BoxFit.cover,
      );
    }
    return Image.network(
      source,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Center(
        child: Icon(Icons.broken_image, color: RecipeColors.textMuted),
      ),
    );
  }
}

class _PhotoAction extends StatelessWidget {
  const _PhotoAction({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 18, color: Colors.white),
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

class _DropdownSection extends StatelessWidget {
  const _DropdownSection({
    required this.title,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String title;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

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
          DropdownButtonFormField<String>(
            value: value,
            items: items
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              onChanged(value);
            },
            decoration: const InputDecoration(
              filled: true,
              fillColor: RecipeColors.background,
              border: OutlineInputBorder(borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletText extends StatelessWidget {
  const _BulletText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: RecipeColors.secondary)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: RecipeColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
