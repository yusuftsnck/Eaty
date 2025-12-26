class RecipeNotebook {
  RecipeNotebook({
    required this.id,
    required this.title,
    required this.coverImage,
    required this.recipeIds,
    required this.owner,
    this.ownerEmail,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String coverImage;
  final List<String> recipeIds;
  final String owner;
  final String? ownerEmail;
  final DateTime createdAt;

  int? get apiId {
    if (!id.startsWith('db_')) return null;
    return int.tryParse(id.replaceFirst('db_', ''));
  }

  factory RecipeNotebook.fromApi(Map<String, dynamic> json) {
    final rawIds = json['recipe_ids'];
    final ids = <String>[];
    if (rawIds is List) {
      for (final entry in rawIds) {
        if (entry == null) continue;
        ids.add('db_${entry.toString()}');
      }
    }
    DateTime createdAt = DateTime.now();
    final createdRaw = json['created_at'];
    if (createdRaw is String) {
      createdAt = DateTime.tryParse(createdRaw) ?? createdAt;
    }
    return RecipeNotebook(
      id: 'db_${json['id']}',
      title: json['title']?.toString() ?? 'Defter',
      coverImage: json['cover_image_url']?.toString() ?? '',
      recipeIds: ids,
      owner: json['owner_name']?.toString() ?? 'Kullanici',
      ownerEmail: json['owner_email']?.toString(),
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toApiCreatePayload({
    required String ownerName,
    required String ownerEmail,
  }) {
    return {
      'title': title,
      'cover_image_url': coverImage,
      'owner_name': ownerName,
      'owner_email': ownerEmail,
    };
  }

  RecipeNotebook copyWith({
    String? id,
    String? title,
    String? coverImage,
    List<String>? recipeIds,
    String? owner,
    String? ownerEmail,
    DateTime? createdAt,
  }) {
    return RecipeNotebook(
      id: id ?? this.id,
      title: title ?? this.title,
      coverImage: coverImage ?? this.coverImage,
      recipeIds: recipeIds ?? this.recipeIds,
      owner: owner ?? this.owner,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
