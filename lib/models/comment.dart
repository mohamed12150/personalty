/// تعليق — مطابق لجدول comments في Supabase
class Comment {
  final int id;
  final int articleId;
  final String userId;
  final String userName;
  final String? userPersonality;
  final String? nameColor;
  final String content;
  final DateTime createdAt;

  const Comment({
    required this.id,
    required this.articleId,
    required this.userId,
    required this.userName,
    this.userPersonality,
    this.nameColor,
    required this.content,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as int,
      articleId: json['article_id'] as int,
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? 'مستخدم',
      userPersonality: json['user_personality'],
      nameColor: json['author_name_color'],
      content: json['content'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
