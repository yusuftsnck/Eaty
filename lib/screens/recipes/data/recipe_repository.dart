import 'package:flutter/material.dart';

import '../../../services/api_service.dart';

import '../models/recipe.dart';
import '../models/recipe_notebook.dart';

class RecipeRepository extends ChangeNotifier {
  RecipeRepository._();

  static final RecipeRepository instance = RecipeRepository._();

  final List<Recipe> _communityRecipes = [];
  final List<Recipe> _myRecipes = [];
  final List<RecipeNotebook> _notebooks = [];
  final ApiService _api = ApiService();
  bool _isSyncing = false;

  List<Recipe> get communityRecipes => List.unmodifiable(_communityRecipes);
  List<Recipe> get myRecipes => List.unmodifiable(_myRecipes);
  List<RecipeNotebook> get notebooks => List.unmodifiable(_notebooks);
  bool get isSyncing => _isSyncing;

  Recipe? findRecipeById(String id) {
    try {
      return _communityRecipes.firstWhere((recipe) => recipe.id == id);
    } catch (_) {
      try {
        return _myRecipes.firstWhere((recipe) => recipe.id == id);
      } catch (_) {
        return null;
      }
    }
  }

  Recipe addRecipe(
    Recipe recipe, {
    bool addToMyRecipes = true,
    bool addToCommunity = true,
  }) {
    if (addToCommunity) {
      _insertOrUpdate(_communityRecipes, recipe);
    }
    if (addToMyRecipes) {
      _insertOrUpdate(_myRecipes, recipe);
    }
    notifyListeners();
    return recipe;
  }

  Future<Recipe?> createRecipeFromPayload(
    Map<String, dynamic> payload, {
    bool addToMyRecipes = true,
  }) async {
    final response = await _api.createRecipe(payload);
    if (response == null) return null;
    final recipe = Recipe.fromApi(response);
    addRecipe(recipe, addToMyRecipes: addToMyRecipes, addToCommunity: true);
    return recipe;
  }

  Future<void> refreshCommunityRecipes({String? viewerEmail}) async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      final data = await _api.getRecipes(viewerEmail: viewerEmail);
      final remote = data
          .whereType<Map<String, dynamic>>()
          .map(Recipe.fromApi)
          .toList();
      _communityRecipes
        ..clear()
        ..addAll(remote);
      notifyListeners();
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> refreshMyRecipes(
    String? authorEmail, {
    String? viewerEmail,
  }) async {
    if (authorEmail == null || authorEmail.trim().isEmpty) return;
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      final data = await _api.getRecipes(
        authorEmail: authorEmail,
        viewerEmail: viewerEmail,
      );
      final remote = data
          .whereType<Map<String, dynamic>>()
          .map(Recipe.fromApi)
          .toList();
      _myRecipes
        ..clear()
        ..addAll(remote);
      notifyListeners();
    } finally {
      _isSyncing = false;
    }
  }

  Future<RecipeNotebook?> createNotebookFromPayload(
    Map<String, dynamic> payload,
  ) async {
    final response = await _api.createRecipeNotebook(payload);
    if (response == null) return null;
    final notebook = RecipeNotebook.fromApi(response);
    _insertOrUpdateNotebook(notebook);
    notifyListeners();
    return notebook;
  }

  Future<RecipeNotebook?> updateNotebookFromPayload(
    RecipeNotebook notebook,
    Map<String, dynamic> payload,
  ) async {
    final notebookId = notebook.apiId;
    if (notebookId == null) return null;
    final response = await _api.updateRecipeNotebook(notebookId, payload);
    if (response == null) return null;
    final updated = RecipeNotebook.fromApi(response);
    _insertOrUpdateNotebook(updated);
    notifyListeners();
    return updated;
  }

  Future<bool> deleteNotebook(RecipeNotebook notebook) async {
    final notebookId = notebook.apiId;
    if (notebookId == null) {
      _notebooks.removeWhere((item) => item.id == notebook.id);
      notifyListeners();
      return true;
    }
    final success = await _api.deleteRecipeNotebook(notebookId);
    if (success) {
      _notebooks.removeWhere((item) => item.id == notebook.id);
      notifyListeners();
    }
    return success;
  }

  Future<void> refreshNotebooks(String? ownerEmail) async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      final data = await _api.getRecipeNotebooks(ownerEmail: ownerEmail);
      final remote = data
          .whereType<Map<String, dynamic>>()
          .map(RecipeNotebook.fromApi)
          .toList();
      _notebooks
        ..clear()
        ..addAll(remote);
      notifyListeners();
    } finally {
      _isSyncing = false;
    }
  }

  Future<RecipeNotebook?> addRecipeToNotebookRemote(
    Recipe recipe,
    RecipeNotebook notebook,
  ) async {
    final recipeId = recipe.apiId;
    final notebookId = notebook.apiId;
    if (recipeId == null || notebookId == null) return null;
    final response = await _api.addRecipeToNotebook(notebookId, recipeId);
    if (response == null) return null;
    final updated = RecipeNotebook.fromApi(response);
    _insertOrUpdateNotebook(updated);
    notifyListeners();
    return updated;
  }

  Future<RecipeNotebook?> removeRecipeFromNotebookRemote(
    Recipe recipe,
    RecipeNotebook notebook,
  ) async {
    final recipeId = recipe.apiId;
    final notebookId = notebook.apiId;
    if (recipeId == null || notebookId == null) return null;
    final response = await _api.removeRecipeFromNotebook(notebookId, recipeId);
    if (response == null) return null;
    final updated = RecipeNotebook.fromApi(response);
    _insertOrUpdateNotebook(updated);
    notifyListeners();
    return updated;
  }

  Future<Recipe?> updateRecipeFromPayload(
    Recipe recipe,
    Map<String, dynamic> payload, {
    String? userEmail,
  }
  ) async {
    final recipeId = recipe.apiId;
    if (recipeId == null) return null;
    final response = await _api.updateRecipe(
      recipeId,
      payload,
      userEmail: userEmail,
    );
    if (response == null) return null;
    final updated = Recipe.fromApi(response);
    _insertOrUpdate(_communityRecipes, updated);
    _insertOrUpdate(_myRecipes, updated);
    notifyListeners();
    return updated;
  }

  Future<bool> deleteRecipe(Recipe recipe, {String? userEmail}) async {
    final recipeId = recipe.apiId;
    if (recipeId == null) {
      _communityRecipes.removeWhere((item) => item.id == recipe.id);
      _myRecipes.removeWhere((item) => item.id == recipe.id);
      _removeRecipeFromNotebooks(recipe.id);
      notifyListeners();
      return true;
    }
    final success = await _api.deleteRecipe(
      recipeId,
      userEmail: userEmail,
    );
    if (success) {
      _communityRecipes.removeWhere((item) => item.id == recipe.id);
      _myRecipes.removeWhere((item) => item.id == recipe.id);
      _removeRecipeFromNotebooks(recipe.id);
      notifyListeners();
    }
    return success;
  }

  Future<Recipe?> toggleRecipeLike(Recipe recipe, String userEmail) async {
    final recipeId = recipe.apiId;
    if (recipeId == null) return null;
    final response = await _api.toggleRecipeLike(recipeId, userEmail);
    if (response == null) return null;
    final likes = (response['likes'] as num?)?.toInt() ?? recipe.likes;
    final liked = response['liked'] == true;
    final updated = recipe.copyWith(likes: likes, isLiked: liked);
    _insertOrUpdate(_communityRecipes, updated);
    _insertOrUpdate(_myRecipes, updated);
    notifyListeners();
    return updated;
  }

  void addRecipeToNotebook(String recipeId, String notebookId) {
    final index = _notebooks.indexWhere((notebook) => notebook.id == notebookId);
    if (index == -1) return;
    final notebook = _notebooks[index];
    if (notebook.recipeIds.contains(recipeId)) return;
    final updated = notebook.copyWith(
      recipeIds: [...notebook.recipeIds, recipeId],
    );
    _notebooks[index] = updated;
    notifyListeners();
  }

  void removeRecipeFromNotebook(String recipeId, String notebookId) {
    final index = _notebooks.indexWhere((notebook) => notebook.id == notebookId);
    if (index == -1) return;
    final notebook = _notebooks[index];
    if (!notebook.recipeIds.contains(recipeId)) return;
    final updated = notebook.copyWith(
      recipeIds: notebook.recipeIds.where((id) => id != recipeId).toList(),
    );
    _notebooks[index] = updated;
    notifyListeners();
  }

  bool isRecipeInNotebook(String recipeId, String notebookId) {
    final notebook = _notebooks.firstWhere(
      (entry) => entry.id == notebookId,
      orElse: () => RecipeNotebook(
        id: '',
        title: '',
        coverImage: '',
        recipeIds: const [],
        owner: '',
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      ),
    );
    return notebook.recipeIds.contains(recipeId);
  }

  void _insertOrUpdate(List<Recipe> target, Recipe recipe) {
    final index = target.indexWhere((item) => item.id == recipe.id);
    if (index == -1) {
      target.insert(0, recipe);
    } else {
      target[index] = recipe;
    }
  }

  void _insertOrUpdateNotebook(RecipeNotebook notebook) {
    final index = _notebooks.indexWhere((item) => item.id == notebook.id);
    if (index == -1) {
      _notebooks.insert(0, notebook);
    } else {
      _notebooks[index] = notebook;
    }
  }

  void _removeRecipeFromNotebooks(String recipeId) {
    for (var i = 0; i < _notebooks.length; i += 1) {
      final notebook = _notebooks[i];
      if (!notebook.recipeIds.contains(recipeId)) continue;
      _notebooks[i] = notebook.copyWith(
        recipeIds: notebook.recipeIds.where((id) => id != recipeId).toList(),
      );
    }
  }

}
