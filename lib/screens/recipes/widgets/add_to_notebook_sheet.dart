import 'package:flutter/material.dart';

import '../data/recipe_repository.dart';
import '../models/recipe.dart';
import '../models/recipe_notebook.dart';
import '../pages/recipe_notebook_form_page.dart';
import '../recipes_theme.dart';
import '../../../services/customer_session_service.dart';

Future<void> showAddToNotebookSheet(BuildContext context, Recipe recipe) async {
  final repo = RecipeRepository.instance;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      return SafeArea(
        child: AnimatedBuilder(
          animation: repo,
          builder: (context, _) {
            final notebooks = repo.notebooks;
            return Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Deftere Ekle',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  if (notebooks.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: RecipeColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: RecipeColors.border),
                      ),
                      child: const Text(
                        'Henüz defterin yok. Yeni bir defter oluştur ve tariflerini kaydet.',
                        style: TextStyle(color: RecipeColors.textMuted),
                      ),
                    ),
                  if (notebooks.isNotEmpty)
                    SizedBox(
                      height: 260,
                      child: ListView.separated(
                        itemCount: notebooks.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 18,
                          color: RecipeColors.border,
                        ),
                        itemBuilder: (context, index) {
                          final notebook = notebooks[index];
                          final selected = notebook.recipeIds.contains(
                            recipe.id,
                          );
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: RecipeColors.secondary,
                              child: Text(
                                notebook.title.isNotEmpty
                                    ? notebook.title[0].toUpperCase()
                                    : 'D',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              notebook.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${notebook.recipeIds.length} tarif',
                              style: const TextStyle(
                                color: RecipeColors.textMuted,
                              ),
                            ),
                            trailing: selected
                                ? const Icon(
                                    Icons.check_circle,
                                    color: RecipeColors.primary,
                                  )
                                : const Icon(Icons.add_circle_outline),
                            onTap: () async {
                              if (selected) return;
                              Recipe? savedRecipe = recipe;
                              if (recipe.apiId == null) {
                                final fallbackEmail = _resolveOwnerEmail();
                                final payload = recipe.toApiCreatePayload(
                                  authorName: recipe.author,
                                  authorEmail: fallbackEmail,
                                );
                                savedRecipe = await repo
                                    .createRecipeFromPayload(payload);
                              }
                              if (savedRecipe == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Tarif kaydedilemedi.'),
                                  ),
                                );
                                return;
                              }
                              final updated = await repo
                                  .addRecipeToNotebookRemote(
                                    savedRecipe,
                                    notebook,
                                  );
                              if (updated == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Deftere ekleme başarısız oldu.',
                                    ),
                                  ),
                                );
                                return;
                              }
                              if (!context.mounted) return;
                              Navigator.pop(sheetContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '"${recipe.title}" deftere eklendi.',
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: RecipeColors.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () async {
                        final created = await showCreateNotebookDialog(context);
                        if (created) {
                          Navigator.pop(sheetContext);
                        }
                      },
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text(
                        'Yeni Defter',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}

Future<bool> showCreateNotebookDialog(
  BuildContext context, {
  RecipeNotebook? notebook,
}) async {
  final created = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => RecipeNotebookFormPage(notebook: notebook),
    ),
  );
  return created ?? false;
}

String _resolveOwnerEmail() {
  final email = CustomerSessionService.instance.user.value?.email;
  if (email != null && email.trim().isNotEmpty) {
    return email.trim();
  }
  return 'guest@eaty.local';
}
