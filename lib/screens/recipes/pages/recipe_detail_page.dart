import 'package:flutter/material.dart';

import '../../../widgets/app_image.dart';
import '../models/recipe.dart';
import '../recipes_theme.dart';
import '../widgets/add_to_notebook_sheet.dart';

class RecipeDetailPage extends StatelessWidget {
  const RecipeDetailPage({super.key, required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RecipeColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: RecipeColors.primary,
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: AppImage(
                source: recipe.coverImage,
                width: double.infinity,
                height: 280,
                fit: BoxFit.cover,
                placeholder: Container(
                  color: RecipeColors.background,
                  alignment: Alignment.center,
                  child: const Icon(Icons.photo, size: 50),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: RecipeColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        recipe.isLiked ? Icons.favorite : Icons.favorite_border,
                        color: RecipeColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${recipe.likes} Beğeni',
                        style: const TextStyle(
                          color: RecipeColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              showAddToNotebookSheet(context, recipe),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: RecipeColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.bookmark_add_outlined),
                          label: const Text('Deftere Ekle'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SectionTitle(
                    title: '',
                    trailing: Row(
                      children: [
                        _InfoPill(icon: Icons.schedule, label: recipe.time),
                        const SizedBox(width: 6),
                        _InfoPill(
                          icon: Icons.group_outlined,
                          label: recipe.servings,
                        ),
                        const SizedBox(width: 6),
                        _InfoPill(
                          icon: Icons.local_fire_department,
                          label: recipe.difficulty,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _SectionTitle(
                    title: 'Tarif Hikayesi',
                    trailing: Row(
                      children: [
                        const SizedBox(width: 6),
                        _InfoPill(
                          icon: Icons.kitchen_outlined,
                          label: recipe.equipment,
                        ),
                        const SizedBox(width: 6),
                        _InfoPill(
                          icon: Icons.local_dining_outlined,
                          label: recipe.method,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    recipe.story,
                    style: const TextStyle(
                      color: RecipeColors.textMuted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const _SectionTitle(title: 'Malzemeler'),
                  const SizedBox(height: 8),
                  ...recipe.ingredients.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 16,
                            color: RecipeColors.secondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item,
                              style: const TextStyle(
                                color: RecipeColors.textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const _SectionTitle(title: 'Hazırlanışı'),
                  const SizedBox(height: 8),
                  ...recipe.steps.asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: RecipeColors.secondary,
                              shape: BoxShape.circle,
                            ),
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
                            child: Text(
                              entry.value,
                              style: const TextStyle(
                                color: RecipeColors.textDark,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (recipe.galleryImages.length > 1) ...[
                    const SizedBox(height: 18),
                    const _SectionTitle(title: 'Tarif Fotoğrafları'),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 110,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: recipe.galleryImages.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: AppImage(
                              source: recipe.galleryImages[index],
                              width: 140,
                              height: 110,
                              fit: BoxFit.cover,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: RecipeColors.textDark,
          ),
        ),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: RecipeColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RecipeColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: RecipeColors.textMuted),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: RecipeColors.textMuted),
          ),
        ],
      ),
    );
  }
}
