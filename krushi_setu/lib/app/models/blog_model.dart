class BlogModel {
  final String id;
  final String title;
  final String slug;
  final String summary;
  final String content;
  final String? coverImage;
  final String category;
  final String? categoryLabel;
  final List<String> tags;
  final List<String> targetCrops;
  final String? author;
  final String status;
  final int viewsCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  BlogModel({
    required this.id,
    required this.title,
    required this.slug,
    required this.summary,
    required this.content,
    this.coverImage,
    required this.category,
    this.categoryLabel,
    required this.tags,
    required this.targetCrops,
    this.author,
    required this.status,
    required this.viewsCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BlogModel.fromJson(Map<String, dynamic> json) {
    return BlogModel(
      id: json['id'] ?? json['_id'] ?? '',
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      summary: json['summary'] ?? '',
      content: json['content'] ?? '',
      coverImage: json['cover_image'] ?? json['coverUrl'],
      category: json['category'] ?? 'general',
      categoryLabel: json['category_label'] ?? json['categoryLabel'],
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      targetCrops: (json['target_crops'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      author: json['author'],
      status: json['status'] ?? 'published',
      viewsCount: json['views_count'] ?? json['totalViews'] ?? 0,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'slug': slug,
      'summary': summary,
      'content': content,
      'cover_image': coverImage,
      'category': category,
      'category_label': categoryLabel,
      'tags': tags,
      'target_crops': targetCrops,
      'author': author,
      'status': status,
      'views_count': viewsCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get displayCategory {
    if (categoryLabel != null && categoryLabel!.isNotEmpty) {
      return categoryLabel!;
    }
    switch (category) {
      case 'scheme':
        return 'Govt Scheme';
      case 'pest':
        return 'Pest Alert';
      case 'weather':
        return 'Weather Alert';
      case 'soil':
        return 'Soil Health';
      case 'farming_tips':
        return 'Farming Tip';
      default:
        return 'General Advisory';
    }
  }
}
