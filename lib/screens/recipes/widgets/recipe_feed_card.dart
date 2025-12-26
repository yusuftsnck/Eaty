import 'package:flutter/material.dart';

import '../../../widgets/app_image.dart';
import '../models/recipe.dart';
import '../recipes_theme.dart';

class RecipeFeedCard extends StatelessWidget {
  const RecipeFeedCard({
    super.key,
    required this.recipe,
    this.onTap,
    this.onAddToNotebook,
    this.onShare,
    this.onLike,
  });

  final Recipe recipe;
  final VoidCallback? onTap;
  final VoidCallback? onAddToNotebook;
  final VoidCallback? onShare;
  final VoidCallback? onLike;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: Stack(
                children: [
                  AppImage(
                    source: recipe.coverImage,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    placeholder: Container(
                      color: RecipeColors.background,
                      height: 200,
                      alignment: Alignment.center,
                      child: const Icon(Icons.photo, size: 40),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        recipe.category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: RecipeColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: RecipeColors.secondary,
                        child: Text(
                          recipe.author.isNotEmpty
                              ? recipe.author[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          recipe.author,
                          style: const TextStyle(
                            fontSize: 13,
                            color: RecipeColors.textMuted,
                          ),
                        ),
                      ),
                      if (onAddToNotebook != null)
                        IconButton(
                          onPressed: onAddToNotebook,
                          icon: const Icon(Icons.bookmark_add_outlined),
                          color: RecipeColors.primary,
                          tooltip: 'Deftere ekle',
                        ),
                      if (onShare != null)
                        IconButton(
                          onPressed: onShare,
                          icon: const Icon(Icons.ios_share),
                          color: RecipeColors.textMuted,
                          tooltip: 'Paylaş',
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _StatChip(
                        icon: recipe.isLiked
                            ? Icons.favorite
                            : Icons.favorite_border,
                        label: recipe.likes.toString(),
                        active: recipe.isLiked,
                        onTap: onLike,
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        icon: Icons.mode_comment_outlined,
                        label: recipe.comments.toString(),
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        icon: Icons.bookmark_border,
                        label: recipe.saves.toString(),
                      ),
                      const Spacer(),
                      Text(
                        recipe.time,
                        style: const TextStyle(
                          color: RecipeColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
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

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: RecipeColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: active ? RecipeColors.primary : RecipeColors.textMuted,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: active ? RecipeColors.primary : RecipeColors.textMuted,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: content,
    );
  }
}
