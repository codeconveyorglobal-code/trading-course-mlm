class CourseMaterial {
  final String id;
  final String title;
  final String type;
  final String? url;
  final int fileSize;
  final String? duration;
  final int order;
  final bool isPreview;

  CourseMaterial({required this.id, required this.title, required this.type, this.url, required this.fileSize, this.duration, required this.order, required this.isPreview});

  factory CourseMaterial.fromJson(Map<String, dynamic> json) {
    return CourseMaterial(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      type: json['type'] ?? 'pdf',
      url: json['url'],
      fileSize: (json['fileSize'] ?? 0).toInt(),
      duration: json['duration'],
      order: (json['order'] ?? 0).toInt(),
      isPreview: json['isPreview'] ?? false,
    );
  }
}

class CourseModel {
  final String id;
  final String title;
  final String slug;
  final String description;
  final String shortDescription;
  final String category;
  final String level;
  final double price;
  final double? discountPrice;
  final String? thumbnail;
  final String? instructorName;
  final List<CourseMaterial> materials;
  final List<String> quizzes;
  final List<String> tags;
  final String language;
  final String? duration;
  final int totalLessons;
  final bool isPublished;
  final bool isFeatured;
  final bool isMLMEligible;
  final int enrolledCount;
  final double rating;
  final List<String> requirements;
  final List<String> whatYouLearn;
  final bool isPurchased;
  final DateTime createdAt;

  CourseModel({
    required this.id,
    required this.title,
    required this.slug,
    required this.description,
    required this.shortDescription,
    required this.category,
    required this.level,
    required this.price,
    this.discountPrice,
    this.thumbnail,
    this.instructorName,
    required this.materials,
    required this.quizzes,
    required this.tags,
    required this.language,
    this.duration,
    required this.totalLessons,
    required this.isPublished,
    required this.isFeatured,
    required this.isMLMEligible,
    required this.enrolledCount,
    required this.rating,
    required this.requirements,
    required this.whatYouLearn,
    required this.isPurchased,
    required this.createdAt,
  });

  double get effectivePrice => discountPrice ?? price;
  bool get hasDiscount => discountPrice != null && discountPrice! < price;

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'] ?? '',
      shortDescription: json['shortDescription'] ?? '',
      category: json['category'] ?? '',
      level: json['level'] ?? 'Beginner',
      price: (json['price'] ?? 0).toDouble(),
      discountPrice: json['discountPrice']?.toDouble(),
      thumbnail: json['thumbnail'],
      instructorName: json['instructorName'] ?? json['instructor']?['name'],
      materials: (json['materials'] as List? ?? []).map((m) => CourseMaterial.fromJson(m)).toList(),
      quizzes: List<String>.from(json['quizzes']?.map((q) => q is String ? q : q['_id'] ?? '') ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      language: json['language'] ?? 'English',
      duration: json['duration'],
      totalLessons: (json['totalLessons'] ?? 0).toInt(),
      isPublished: json['isPublished'] ?? false,
      isFeatured: json['isFeatured'] ?? false,
      isMLMEligible: json['isMLMEligible'] ?? true,
      enrolledCount: (json['enrolledCount'] ?? 0).toInt(),
      rating: (json['rating'] ?? 0).toDouble(),
      requirements: List<String>.from(json['requirements'] ?? []),
      whatYouLearn: List<String>.from(json['whatYouLearn'] ?? []),
      isPurchased: json['isPurchased'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
