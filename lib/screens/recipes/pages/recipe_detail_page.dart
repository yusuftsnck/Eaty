import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../services/api_service.dart';
import '../../../services/customer_profile_service.dart';
import '../../../services/customer_session_service.dart';
import '../../../widgets/app_image.dart';
import '../data/recipe_repository.dart';
import '../models/recipe.dart';
import '../recipes_theme.dart';
import '../widgets/add_to_notebook_sheet.dart';

class RecipeDetailPage extends StatefulWidget {
  const RecipeDetailPage({super.key, required this.recipe});

  final Recipe recipe;

  @override
  State<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  final _api = ApiService();
  final _commentCtrl = TextEditingController();
  final _commentFocus = FocusNode();

  late Recipe _recipe;
  List<RecipeComment> _comments = [];
  bool _loadingComments = true;
  bool _sending = false;
  String? _commentsError;

  @override
  void initState() {
    super.initState();
    _recipe = widget.recipe;
    _fetchComments();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    _commentFocus.dispose();
    super.dispose();
  }

  Future<void> _fetchComments() async {
    final recipeId = _recipe.apiId;
    if (recipeId == null) {
      setState(() => _loadingComments = false);
      return;
    }

    final data = await _api.getRecipeComments(recipeId);
    if (!mounted) return;
    if (data == null) {
      setState(() {
        _loadingComments = false;
        _commentsError = 'Yorumlar yuklenemedi.';
      });
      return;
    }

    final list = data.map(RecipeComment.fromApi).toList();
    setState(() {
      _comments = list;
      _loadingComments = false;
      _commentsError = null;
    });
    _syncCommentCount(list.length);
  }

  Future<void> _sendComment() async {
    if (_sending) return;
    final recipeId = _recipe.apiId;
    if (recipeId == null) {
      _showMessage('Bu tarif icin yorum eklenemiyor.');
      return;
    }

    final text = _commentCtrl.text.trim();
    if (text.isEmpty) {
      _showMessage('Yorum boş olamaz.');
      return;
    }

    final profileName = CustomerProfileService.instance.profile.value?.name
        ?.trim();
    final sessionName = CustomerSessionService.instance.user.value?.displayName
        ?.trim();
    final authorName = (profileName != null && profileName.isNotEmpty)
        ? profileName
        : (sessionName != null && sessionName.isNotEmpty
              ? sessionName
              : 'Kullanici');
    final authorEmail = CustomerSessionService.instance.user.value?.email
        .trim();

    setState(() => _sending = true);
    final created = await _api.addRecipeComment(
      recipeId,
      comment: text,
      authorName: authorName,
      authorEmail: authorEmail,
    );

    if (!mounted) return;
    setState(() => _sending = false);
    if (created == null) {
      _showMessage('Yorum gönderilemedi.');
      return;
    }

    final newComment = RecipeComment.fromApi(created);
    setState(() {
      _comments = [..._comments, newComment];
      _commentCtrl.clear();
    });
    _commentFocus.unfocus();
    _syncCommentCount(_comments.length);
  }

  void _syncCommentCount(int count) {
    if (_recipe.comments == count) return;
    final updated = _recipe.copyWith(comments: count);
    _recipe = updated;
    RecipeRepository.instance.addRecipe(updated);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatCommentDate(DateTime date) {
    return DateFormat('dd.MM.yyyy HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final recipe = _recipe;
    final canSend = !_sending && _commentCtrl.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: RecipeColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: RecipeColors.primary,
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: AppImage(
                source: recipe.coverImage,
                width: double.infinity,
                height: 280,
                fit: BoxFit.cover,
                placeholder: Container(
                  color: RecipeColors.background,
                  alignment: Alignment.center,
                  child: const Icon(Icons.photo, size: 50),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: RecipeColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        recipe.isLiked ? Icons.favorite : Icons.favorite_border,
                        color: RecipeColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${recipe.likes} Beğeni',
                        style: const TextStyle(
                          color: RecipeColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              showAddToNotebookSheet(context, recipe),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: RecipeColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.bookmark_add_outlined),
                          label: const Text('Deftere Ekle'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SectionTitle(
                    title: '',
                    trailing: Row(
                      children: [
                        _InfoPill(icon: Icons.schedule, label: recipe.time),
                        const SizedBox(width: 6),
                        _InfoPill(
                          icon: Icons.group_outlined,
                          label: recipe.servings,
                        ),
                        const SizedBox(width: 6),
                        _InfoPill(
                          icon: Icons.local_fire_department,
                          label: recipe.difficulty,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _SectionTitle(
                    title: 'Tarif Hikayesi',
                    trailing: Row(
                      children: [
                        const SizedBox(width: 6),
                        _InfoPill(
                          icon: Icons.kitchen_outlined,
                          label: recipe.equipment,
                        ),
                        const SizedBox(width: 6),
                        _InfoPill(
                          icon: Icons.local_dining_outlined,
                          label: recipe.method,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    recipe.story,
                    style: const TextStyle(
                      color: RecipeColors.textMuted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const _SectionTitle(title: 'Malzemeler'),
                  const SizedBox(height: 8),
                  ...recipe.ingredients.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 16,
                            color: RecipeColors.secondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item,
                              style: const TextStyle(
                                color: RecipeColors.textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const _SectionTitle(title: 'Hazırlanışı'),
                  const SizedBox(height: 8),
                  ...recipe.steps.asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: RecipeColors.secondary,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${entry.key + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: const TextStyle(
                                color: RecipeColors.textDark,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (recipe.galleryImages.length > 1) ...[
                    const SizedBox(height: 18),
                    const _SectionTitle(title: 'Tarifin Fotoğrafları'),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 110,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: recipe.galleryImages.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: AppImage(
                              source: recipe.galleryImages[index],
                              width: 140,
                              height: 110,
                              fit: BoxFit.cover,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: RecipeColors.background,
                          shape: BoxShape.circle,
                          border: Border.all(color: RecipeColors.border),
                        ),
                        child: const Icon(
                          Icons.chat_bubble_outline,
                          size: 18,
                          color: RecipeColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Yorumlar',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: RecipeColors.textDark,
                        ),
                      ),
                      const Spacer(),
                      if (!_loadingComments)
                        Text(
                          _comments.length.toString(),
                          style: const TextStyle(
                            color: RecipeColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (_loadingComments)
                    const Center(child: CircularProgressIndicator()),
                  if (!_loadingComments && _commentsError != null)
                    Text(
                      _commentsError!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  if (!_loadingComments &&
                      _commentsError == null &&
                      _comments.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 24,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: RecipeColors.border),
                      ),
                      child: Column(
                        children: const [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: RecipeColors.primary,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'İlk yorumu sen yap',
                            style: TextStyle(
                              color: RecipeColors.textMuted,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (!_loadingComments && _comments.isNotEmpty)
                    Column(
                      children: _comments
                          .map(
                            (comment) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _CommentCard(
                                comment: comment,
                                dateText: _formatCommentDate(comment.createdAt),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            12 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: RecipeColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentCtrl,
                    focusNode: _commentFocus,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Yorumunuzu yazınız',
                      border: InputBorder.none,
                    ),
                    minLines: 1,
                    maxLines: 3,
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 44,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: canSend ? _sendComment : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RecipeColors.primary,
                      foregroundColor: Colors.white,
                      shape: const CircleBorder(),
                      padding: EdgeInsets.zero,
                    ),
                    child: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RecipeComment {
  final String authorName;
  final String comment;
  final DateTime createdAt;

  const RecipeComment({
    required this.authorName,
    required this.comment,
    required this.createdAt,
  });

  factory RecipeComment.fromApi(Map<String, dynamic> json) {
    final name = json['author_name']?.toString().trim();
    final comment = json['comment']?.toString().trim() ?? '';
    DateTime createdAt = DateTime.now();
    final createdRaw = json['created_at'];
    if (createdRaw is String) {
      createdAt = DateTime.tryParse(createdRaw) ?? createdAt;
    }
    return RecipeComment(
      authorName: (name == null || name.isEmpty) ? 'Kullanici' : name,
      comment: comment,
      createdAt: createdAt,
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({required this.comment, required this.dateText});

  final RecipeComment comment;
  final String dateText;

  @override
  Widget build(BuildContext context) {
    final initial = comment.authorName.isNotEmpty ? comment.authorName[0] : 'U';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RecipeColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: RecipeColors.secondary,
                child: Text(
                  initial.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.authorName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: RecipeColors.textDark,
                      ),
                    ),
                    Text(
                      dateText,
                      style: const TextStyle(
                        fontSize: 11,
                        color: RecipeColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            comment.comment,
            style: const TextStyle(color: RecipeColors.textDark, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: RecipeColors.textDark,
          ),
        ),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: RecipeColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RecipeColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: RecipeColors.textMuted),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: RecipeColors.textMuted),
          ),
        ],
      ),
    );
  }
}
