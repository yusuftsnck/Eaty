import 'package:flutter/material.dart';

import 'data/recipe_repository.dart';
import 'pages/recipe_submit_page.dart';
import 'pages/recipes_ai_chef_page.dart';
import 'pages/recipes_feed_page.dart';
import 'pages/recipes_my_page.dart';
import 'pages/recipes_notebooks_page.dart';
import 'recipes_theme.dart';
import 'widgets/add_to_notebook_sheet.dart';
import '../../services/customer_session_service.dart';

class RecipesHomePage extends StatefulWidget {
  const RecipesHomePage({super.key});

  @override
  State<RecipesHomePage> createState() => _RecipesHomePageState();
}

class _RecipesHomePageState extends State<RecipesHomePage> {
  int _tabIndex = 0;
  late final VoidCallback _sessionListener;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _sessionListener = () {
      if (!mounted) return;
      _refreshAll();
    };
    CustomerSessionService.instance.user.addListener(_sessionListener);
    Future.microtask(_refreshAll);
  }

  @override
  void dispose() {
    CustomerSessionService.instance.user.removeListener(_sessionListener);
    super.dispose();
  }

  Future<void> _refreshAll() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    final email = _resolveAuthorEmail();
    try {
      await RecipeRepository.instance.refreshCommunityRecipes(
        viewerEmail: email,
      );
      await RecipeRepository.instance.refreshMyRecipes(
        email,
        viewerEmail: email,
      );
      await RecipeRepository.instance.refreshNotebooks(email);
    } finally {
      _isRefreshing = false;
    }
  }

  void _setTab(int index) {
    if (index == _tabIndex) return;
    setState(() => _tabIndex = index);
  }

  Future<void> _openCreateNotebook() async {
    await showCreateNotebookDialog(context);
  }

  Future<void> _openSubmitRecipe() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RecipeSubmitPage()),
    );
  }

  String _resolveAuthorEmail() {
    final email = CustomerSessionService.instance.user.value?.email;
    if (email != null && email.trim().isNotEmpty) {
      return email.trim();
    }
    return 'guest@eaty.local';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RecipeColors.background,
      body: SafeArea(
        top: false,
        child: IndexedStack(
          index: _tabIndex,
          children: [
            const RecipesFeedPage(),
            RecipesNotebooksPage(onCreateNotebook: _openCreateNotebook),
            RecipesMyPage(onCreateRecipe: _openSubmitRecipe),
            RecipesAiChefPage(onNavigate: _setTab),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: _tabIndex,
        onTap: _setTab,
        selectedItemColor: RecipeColors.primary,
        unselectedItemColor: RecipeColors.textMuted,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_outlined),
            label: 'Tarif Defteri',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_shared_outlined),
            label: 'Tariflerim',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome),
            label: 'AI Sef',
          ),
        ],
      ),
      floatingActionButton: _buildFloatingAction(),
    );
  }

  Widget? _buildFloatingAction() {
    switch (_tabIndex) {
      case 1:
        return FloatingActionButton.extended(
          onPressed: _openCreateNotebook,
          backgroundColor: RecipeColors.secondary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('Yeni Defter'),
        );

      default:
        return null;
    }
  }
}
