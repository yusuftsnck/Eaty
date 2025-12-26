import 'package:flutter/material.dart';

import '../models/recipe.dart';
import '../recipes_theme.dart';

Future<Recipe?> showQuickAddRecipeSheet(BuildContext context) async {
  final formKey = GlobalKey<FormState>();
  final title = TextEditingController();
  final subtitle = TextEditingController();
  final time = TextEditingController(text: '30 dk');
  final servings = TextEditingController(text: '2 kişilik');
  final image = TextEditingController(
    text:
        'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=900&q=80',
  );
  String difficulty = 'Kolay';

  final newRecipe = await showModalBottomSheet<Recipe>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              top: 16,
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Yeni Tarif Ekle',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _InputField(
                      controller: title,
                      label: 'Tarif adi',
                      hint: 'Orn: Fırında Sebzeli Somon',
                      validator: (v) =>
                          v == null || v.isEmpty ? 'İsim gerekli' : null,
                    ),
                    _InputField(
                      controller: subtitle,
                      label: 'Kısa açıkklama',
                      hint: 'Örn: Hafif ve protein dolu',
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _InputField(
                            controller: time,
                            label: 'Süre',
                            hint: '30 dk',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _InputField(
                            controller: servings,
                            label: 'Kişi sayısı',
                            hint: '2 kişilik',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Zorluk',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: ['Kolay', 'Orta', 'Zor']
                          .map(
                            (level) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(level),
                                selected: difficulty == level,
                                onSelected: (_) => setSheetState(() {
                                  difficulty = level;
                                }),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 8),
                    _InputField(
                      controller: image,
                      label: 'Kapak görseli URL',
                      hint: 'https://',
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: RecipeColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          if (!formKey.currentState!.validate()) return;
                          Navigator.pop(
                            ctx,
                            Recipe(
                              id: 'quick_${DateTime.now().microsecondsSinceEpoch}',
                              title: title.text.trim(),
                              author: 'Sen',
                              authorHandle: '@sen',
                              summary: subtitle.text.trim().isEmpty
                                  ? 'Topluluktan yeni bir tarif'
                                  : subtitle.text.trim(),
                              coverImage: image.text.trim(),
                              galleryImages: [image.text.trim()],
                              time: time.text.trim(),
                              servings: servings.text.trim(),
                              difficulty: difficulty,
                              category: 'Topluluk',
                              story: subtitle.text.trim(),
                              ingredients: const [
                                'Malzemeler daha sonra düzenlenebilir.',
                              ],
                              steps: const [
                                'Tarif adımlarını buraya ekleyebilirsin.',
                              ],
                              equipment: 'Tencere',
                              method: 'Fırın',
                              likes: 0,
                              comments: 0,
                              saves: 0,
                              createdAt: DateTime.now(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.save_rounded, size: 18),
                        label: const Text(
                          'Kaydet ve Paylaş',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );

  title.dispose();
  subtitle.dispose();
  time.dispose();
  servings.dispose();
  image.dispose();

  return newRecipe;
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
