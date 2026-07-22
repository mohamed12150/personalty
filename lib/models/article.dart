/// مقال — مطابق لجدول articles في Supabase
class Article {
  final int id;
  final String title;
  final String content;
  final String category;
  final String emoji;
  final List<String> personalityTypes; // فارغة = مقال عام للجميع
  final int readTime;
  final int likesCount;
  final int commentsCount;
  final bool isLiked; // حالة محلية للمستخدم الحالي
  final DateTime createdAt;

  const Article({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    this.emoji = '',
    required this.personalityTypes,
    required this.readTime,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLiked = false,
    required this.createdAt,
  });

  bool get isGeneral => personalityTypes.isEmpty;

  factory Article.fromJson(Map<String, dynamic> json, {bool isLiked = false}) {
    return Article(
      id: json['id'] as int,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      category: json['category'] ?? 'عام',
      emoji: json['emoji'] ?? '',
      personalityTypes: List<String>.from(json['personality_types'] ?? []),
      readTime: json['read_time'] ?? 4,
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      isLiked: isLiked,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Article copyWith({int? likesCount, int? commentsCount, bool? isLiked}) {
    return Article(
      id: id,
      title: title,
      content: content,
      category: category,
      emoji: emoji,
      personalityTypes: personalityTypes,
      readTime: readTime,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt,
    );
  }
}
