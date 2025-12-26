import 'package:flutter/material.dart';

import '../../../widgets/app_image.dart';
import '../models/recipe_notebook.dart';
import '../recipes_theme.dart';

class RecipeNotebookCard extends StatelessWidget {
  const RecipeNotebookCard({
    super.key,
    required this.notebook,
    required this.recipeCount,
    this.onTap,
    this.menu,
  });

  final RecipeNotebook notebook;
  final int recipeCount;
  final VoidCallback? onTap;
  final Widget? menu;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                  child: AppImage(
                    source: notebook.coverImage,
                    width: double.infinity,
                    height: 150,
                    fit: BoxFit.cover,
                    placeholder: Container(
                      height: 150,
                      color: RecipeColors.background,
                      alignment: Alignment.center,
                      child: const Icon(Icons.menu_book, size: 36),
                    ),
                  ),
                ),
                if (menu != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: menu!,
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notebook.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: RecipeColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$recipeCount tarif',
                    style: const TextStyle(
                      color: RecipeColors.textMuted,
                      fontSize: 12,
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
