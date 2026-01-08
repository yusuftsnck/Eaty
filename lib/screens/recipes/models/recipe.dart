class Recipe {
  Recipe({
    required this.id,
    required this.title,
    required this.author,
    required this.authorHandle,
    required this.summary,
    required this.coverImage,
    required this.galleryImages,
    required this.time,
    required this.servings,
    required this.difficulty,
    required this.category,
    required this.story,
    required this.ingredients,
    required this.steps,
    required this.equipment,
    required this.method,
    required this.likes,
    required this.comments,
    required this.saves,
    this.isLiked = false,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String author;
  final String authorHandle;
  final String summary;
  final String coverImage;
  final List<String> galleryImages;
  final String time;
  final String servings;
  final String difficulty;
  final String category;
  final String story;
  final List<String> ingredients;
  final List<String> steps;
  final String equipment;
  final String method;
  final int likes;
  final int comments;
  final int saves;
  final bool isLiked;
  final DateTime createdAt;

  int? get apiId {
    if (!id.startsWith('db_')) return null;
    return int.tryParse(id.replaceFirst('db_', ''));
  }

  static List<String> _stringListFromJson(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return [];
  }

  static String _buildHandle(String? name, String? email) {
    final source = (name == null || name.trim().isEmpty) ? (email ?? '') : name;
    final trimmed = source.trim().toLowerCase();
    if (trimmed.isEmpty) return '@kullanici';
    final handle = trimmed.replaceAll(RegExp(r'\s+'), '');
    return handle.startsWith('@') ? handle : '@$handle';
  }

  static String _buildTime(String? prep, String? cook) {
    final parts = <String>[];
    if (prep != null && prep.trim().isNotEmpty) {
      parts.add(prep.trim());
    }
    if (cook != null && cook.trim().isNotEmpty) {
      parts.add(cook.trim());
    }
    if (parts.isEmpty) return '30 dk';
    if (parts.length == 1) return parts.first;
    return '${parts[0]} + ${parts[1]}';
  }

  factory Recipe.fromApi(Map<String, dynamic> json) {
    final authorName = json['author_name']?.toString().trim();
    final authorEmail = json['author_email']?.toString().trim();
    final prep = json['prep_time']?.toString();
    final cook = json['cook_time']?.toString();
    final gallery = _stringListFromJson(json['gallery_images']);
    final cover = json['cover_image_url']?.toString();
    final summary =
        json['subtitle']?.toString() ??
        json['story']?.toString() ??
        'Topluluktan yeni bir tarif';
    final story = json['story']?.toString() ?? summary;

    DateTime createdAt = DateTime.now();
    final createdRaw = json['created_at'];
    if (createdRaw is String) {
      createdAt = DateTime.tryParse(createdRaw) ?? createdAt;
    }

    return Recipe(
      id: 'db_${json['id']}',
      title: json['title']?.toString() ?? 'Tarif',
      author: authorName?.isNotEmpty == true ? authorName! : 'Kullanici',
      authorHandle: _buildHandle(authorName, authorEmail),
      summary: summary,
      coverImage: cover?.isNotEmpty == true
          ? cover!
          : (gallery.isNotEmpty ? gallery.first : ''),
      galleryImages: gallery,
      time: _buildTime(prep, cook),
      servings: json['servings']?.toString() ?? '2 kişilik',
      difficulty: 'Orta',
      category: json['category']?.toString() ?? 'Tarif',
      story: story,
      ingredients: _stringListFromJson(json['ingredients']),
      steps: _stringListFromJson(json['steps']),
      equipment: json['equipment']?.toString() ?? 'Tencere',
      method: json['method']?.toString() ?? 'Fırın',
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      comments: (json['comments'] as num?)?.toInt() ?? 0,
      saves: (json['saves'] as num?)?.toInt() ?? 0,
      isLiked: json['is_liked'] == true,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toApiCreatePayload({
    required String authorName,
    required String authorEmail,
    String? authorPhotoUrl,
    String? prepTime,
    String? cookTime,
    String? equipment,
    String? method,
  }) {
    return {
      'title': title,
      'subtitle': summary.isNotEmpty ? summary : null,
      'story': story.isNotEmpty ? story : summary,
      'ingredients': ingredients,
      'steps': steps,
      'category': category,
      'servings': servings,
      'prep_time': prepTime ?? time,
      'cook_time': cookTime,
      'equipment': equipment ?? this.equipment,
      'method': method ?? this.method,
      'cover_image_url': coverImage,
      'gallery_images': galleryImages,
      'author_name': authorName,
      'author_email': authorEmail,
      'author_photo_url': authorPhotoUrl,
    };
  }

  Map<String, dynamic> toApiUpdatePayload({
    String? prepTime,
    String? cookTime,
    String? equipment,
    String? method,
  }) {
    return {
      'title': title,
      'subtitle': summary.isNotEmpty ? summary : null,
      'story': story.isNotEmpty ? story : summary,
      'ingredients': ingredients,
      'steps': steps,
      'category': category,
      'servings': servings,
      'prep_time': prepTime ?? time,
      'cook_time': cookTime,
      'equipment': equipment ?? this.equipment,
      'method': method ?? this.method,
      'cover_image_url': coverImage,
      'gallery_images': galleryImages,
    };
  }

  Recipe copyWith({
    String? id,
    String? title,
    String? author,
    String? authorHandle,
    String? summary,
    String? coverImage,
    List<String>? galleryImages,
    String? time,
    String? servings,
    String? difficulty,
    String? category,
    String? story,
    List<String>? ingredients,
    List<String>? steps,
    String? equipment,
    String? method,
    int? likes,
    int? comments,
    int? saves,
    bool? isLiked,
    DateTime? createdAt,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      authorHandle: authorHandle ?? this.authorHandle,
      summary: summary ?? this.summary,
      coverImage: coverImage ?? this.coverImage,
      galleryImages: galleryImages ?? this.galleryImages,
      time: time ?? this.time,
      servings: servings ?? this.servings,
      difficulty: difficulty ?? this.difficulty,
      category: category ?? this.category,
      story: story ?? this.story,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      equipment: equipment ?? this.equipment,
      method: method ?? this.method,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      saves: saves ?? this.saves,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
