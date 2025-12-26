import 'package:flutter/material.dart';

import '../../../widgets/app_image.dart';
import '../models/recipe.dart';
import '../recipes_theme.dart';

class RecipeListTile extends StatelessWidget {
  const RecipeListTile({
    super.key,
    required this.recipe,
    this.onTap,
    this.trailing,
    this.badge,
  });

  final Recipe recipe;
  final VoidCallback? onTap;
  final Widget? trailing;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: RecipeColors.border),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AppImage(
                source: recipe.coverImage,
                width: 96,
                height: 78,
                fit: BoxFit.cover,
                placeholder: Container(
                  width: 96,
                  height: 78,
                  color: RecipeColors.background,
                  alignment: Alignment.center,
                  child: const Icon(Icons.photo, size: 30),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: RecipeColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recipe.author,
                    style: const TextStyle(
                      color: RecipeColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: RecipeColors.background,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            badge!,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: RecipeColors.textMuted,
                            ),
                          ),
                        ),
                      if (badge != null) const SizedBox(width: 8),
                      Text(
                        recipe.time,
                        style: const TextStyle(
                          fontSize: 11,
                          color: RecipeColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
