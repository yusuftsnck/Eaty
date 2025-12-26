import 'package:flutter/material.dart';

import '../data/recipe_repository.dart';
import '../models/recipe.dart';
import '../recipes_theme.dart';
import '../widgets/add_to_notebook_sheet.dart';
import '../widgets/recipe_feed_card.dart';
import 'recipe_detail_page.dart';
import '../../../services/customer_session_service.dart';

class RecipesFeedPage extends StatefulWidget {
  const RecipesFeedPage({super.key});

  @override
  State<RecipesFeedPage> createState() => _RecipesFeedPageState();
}

class _RecipesFeedPageState extends State<RecipesFeedPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Recipe> _filtered(List<Recipe> recipes) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return recipes;
    return recipes.where((recipe) {
      return recipe.title.toLowerCase().contains(query) ||
          recipe.summary.toLowerCase().contains(query) ||
          recipe.author.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final repo = RecipeRepository.instance;

    return AnimatedBuilder(
      animation: repo,
      builder: (context, _) {
        final recipes = _filtered(repo.communityRecipes);
        final email = CustomerSessionService.instance.user.value?.email;
        return Container(
          color: RecipeColors.background,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 18),
                  decoration: const BoxDecoration(
                    gradient: RecipeColors.headerGradient,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      const Text(
                        'Ana Sayfa',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Topluluktan en taze tarifler.',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Tarif ara',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final recipe = recipes[index];
                    return RecipeFeedCard(
                      recipe: recipe,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RecipeDetailPage(recipe: recipe),
                        ),
                      ),
                      onAddToNotebook: () =>
                          showAddToNotebookSheet(context, recipe),
                      onLike: () async {
                        final userEmail =
                            (email == null || email.trim().isEmpty)
                            ? 'guest@eaty.local'
                            : email.trim();
                        await repo.toggleRecipeLike(recipe, userEmail);
                      },
                    );
                  }, childCount: recipes.length),
                ),
              ),
              if (recipes.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: const [
                        Icon(Icons.search_off, size: 40),
                        SizedBox(height: 12),
                        Text(
                          'Eşlesen tarif bulunamadı.',
                          style: TextStyle(color: RecipeColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        );
      },
    );
  }
}
