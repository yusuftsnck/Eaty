import 'package:flutter/material.dart';

import '../data/recipe_repository.dart';
import '../recipes_theme.dart';
import '../widgets/add_to_notebook_sheet.dart';
import '../widgets/recipe_notebook_card.dart';
import 'recipe_notebook_detail_page.dart';

class RecipesNotebooksPage extends StatelessWidget {
  const RecipesNotebooksPage({super.key, required this.onCreateNotebook});

  final VoidCallback onCreateNotebook;

  @override
  Widget build(BuildContext context) {
    final repo = RecipeRepository.instance;

    return Container(
      color: RecipeColors.background,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            decoration: const BoxDecoration(
              gradient: RecipeColors.headerGradient,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SizedBox(height: 6),
                Text(
                  'Tarif Defterleri',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Tariflerini defterlere ayır, sonra kolayca bul.',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: AnimatedBuilder(
              animation: repo,
              builder: (context, _) {
                final notebooks = repo.notebooks;
                if (notebooks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'İlk defterini oluşturmak için aşağidaki butona tıkla!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: RecipeColors.textMuted),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                  itemCount: notebooks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final notebook = notebooks[index];
                    return RecipeNotebookCard(
                      notebook: notebook,
                      recipeCount: notebook.recipeIds.length,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              RecipeNotebookDetailPage(notebook: notebook),
                        ),
                      ),
                      menu: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        onSelected: (value) async {
                          if (value == 'edit') {
                            await showCreateNotebookDialog(
                              context,
                              notebook: notebook,
                            );
                          }
                          if (value == 'delete') {
                            final success = await repo.deleteNotebook(notebook);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? 'Defter silindi.'
                                      : 'Defter silinemedi.',
                                ),
                              ),
                            );
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                          PopupMenuItem(value: 'delete', child: Text('Sil')),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
