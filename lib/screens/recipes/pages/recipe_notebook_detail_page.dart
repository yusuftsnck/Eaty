import 'package:flutter/material.dart';

import '../data/recipe_repository.dart';
import '../models/recipe.dart';
import '../models/recipe_notebook.dart';
import '../recipes_theme.dart';
import '../widgets/recipe_list_tile.dart';
import 'recipe_detail_page.dart';

class RecipeNotebookDetailPage extends StatefulWidget {
  const RecipeNotebookDetailPage({super.key, required this.notebook});

  final RecipeNotebook notebook;

  @override
  State<RecipeNotebookDetailPage> createState() =>
      _RecipeNotebookDetailPageState();
}

class _RecipeNotebookDetailPageState extends State<RecipeNotebookDetailPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Recipe> _filteredRecipes(
    RecipeRepository repo,
    RecipeNotebook notebook,
  ) {
    final query = _searchController.text.trim().toLowerCase();
    final recipes = notebook.recipeIds
        .map(repo.findRecipeById)
        .whereType<Recipe>()
        .toList();
    if (query.isEmpty) return recipes;
    return recipes
        .where((recipe) => recipe.title.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final repo = RecipeRepository.instance;

    final notebook = repo.notebooks.firstWhere(
      (entry) => entry.id == widget.notebook.id,
      orElse: () => widget.notebook,
    );

    return Scaffold(
      backgroundColor: RecipeColors.background,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                12,
                12 + MediaQuery.of(context).padding.top,
                12,
                16,
              ),
              decoration: const BoxDecoration(
                gradient: RecipeColors.headerGradient,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notebook.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          notebook.owner,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Arama yap',
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: const BoxDecoration(
                      color: RecipeColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.search, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: AnimatedBuilder(
                animation: repo,
                builder: (context, _) {
                  final recipes = _filteredRecipes(repo, notebook);
                  if (recipes.isEmpty) {
                    return const Center(
                      child: Text(
                        'Bu defterde tarif yok.',
                        style: TextStyle(color: RecipeColors.textMuted),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    itemCount: recipes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final recipe = recipes[index];
                      return RecipeListTile(
                        recipe: recipe,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RecipeDetailPage(recipe: recipe),
                          ),
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'remove') {
                              repo.removeRecipeFromNotebookRemote(
                                recipe,
                                notebook,
                              );
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'remove',
                              child: Text('Defterden çıkar'),
                            ),
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
      ),
    );
  }
}
