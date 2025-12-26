import 'package:flutter/material.dart';

import '../data/recipe_repository.dart';
import '../recipes_theme.dart';
import '../widgets/recipe_list_tile.dart';
import 'recipe_detail_page.dart';
import 'recipe_submit_page.dart';
import '../../../services/customer_session_service.dart';

class RecipesMyPage extends StatelessWidget {
  const RecipesMyPage({super.key, required this.onCreateRecipe});

  final VoidCallback onCreateRecipe;

  @override
  Widget build(BuildContext context) {
    final repo = RecipeRepository.instance;
    final userEmail = _resolveUserEmail();

    return Container(
      color: RecipeColors.background,
      child: Stack(
        children: [
          Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                decoration: const BoxDecoration(
                  gradient: RecipeColors.headerGradient,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SizedBox(height: 6),
                    Text(
                      'Tariflerim',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Paylastığın tarifleri buradan yönet.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  children: [
                    const Text(
                      'Paylaştıklarım',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: RecipeColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    AnimatedBuilder(
                      animation: repo,
                      builder: (context, _) {
                        final recipes = repo.myRecipes;
                        if (recipes.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Henüz tarif paylaşmadın.',
                              style: TextStyle(color: RecipeColors.textMuted),
                            ),
                          );
                        }
                        return Column(
                          children: recipes
                              .map(
                                (recipe) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: RecipeListTile(
                                    recipe: recipe,
                                    badge: recipe.category,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            RecipeDetailPage(recipe: recipe),
                                      ),
                                    ),
                                    trailing: PopupMenuButton<String>(
                                      onSelected: (value) async {
                                        if (value == 'edit') {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => RecipeSubmitPage(
                                                initialRecipe: recipe,
                                              ),
                                            ),
                                          );
                                        }
                                        if (value == 'delete') {
                                          final success = await repo
                                              .deleteRecipe(
                                                recipe,
                                                userEmail: userEmail,
                                              );
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                success
                                                    ? 'Tarif silindi.'
                                                    : 'Tarif silinemedi.',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      itemBuilder: (_) => const [
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Text('Düzenle'),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Sil'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            right: 16,
            bottom: 20,
            child: ElevatedButton.icon(
              onPressed: onCreateRecipe,
              style: ElevatedButton.styleFrom(
                backgroundColor: RecipeColors.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 6,
              ),
              icon: const Icon(Icons.add),
              label: const Text(
                'Tarif Gönder',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _resolveUserEmail() {
    final email = CustomerSessionService.instance.user.value?.email;
    if (email != null && email.trim().isNotEmpty) {
      return email.trim();
    }
    return 'guest@eaty.local';
  }
}
