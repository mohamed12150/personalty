/// خاطرة — مطابقة لجدول posts في Supabase
class Post {
  final int id;
  final String? userId;
  final int? personaId;
  final String authorName;
  final String? authorPersonality;
  final int? authorAvatarId;
  final String? authorNameColor;
  final bool isAi;
  final String content;
  final int likesCount;
  final int commentsCount;
  final int supportLeaves;
  final bool isLiked; // حالة محلية للمستخدم الحالي
  final DateTime createdAt;

  const Post({
    required this.id,
    this.userId,
    this.personaId,
    required this.authorName,
    this.authorPersonality,
    this.authorAvatarId,
    this.authorNameColor,
    this.isAi = false,
    required this.content,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.supportLeaves = 0,
    this.isLiked = false,
    required this.createdAt,
  });

  factory Post.fromJson(Map<String, dynamic> json, {bool isLiked = false}) {
    return Post(
      id: json['id'] as int,
      userId: json['user_id'],
      personaId: json['persona_id'],
      authorName: json['author_name'] ?? 'مستخدم',
      authorPersonality: json['author_personality'],
      authorAvatarId: json['author_avatar_id'],
      authorNameColor: json['author_name_color'],
      isAi: json['is_ai'] ?? false,
      content: json['content'] ?? '',
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      supportLeaves: json['support_leaves'] ?? 0,
      isLiked: isLiked,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Post copyWith({
    int? likesCount,
    int? commentsCount,
    int? supportLeaves,
    bool? isLiked,
  }) {
    return Post(
      id: id,
      userId: userId,
      personaId: personaId,
      authorName: authorName,
      authorPersonality: authorPersonality,
      authorAvatarId: authorAvatarId,
      authorNameColor: authorNameColor,
      isAi: isAi,
      content: content,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      supportLeaves: supportLeaves ?? this.supportLeaves,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt,
    );
  }
}

/// تعليق على خاطرة — مطابق لجدول post_comments
class PostComment {
  final int id;
  final int postId;
  final String? userId;
  final int? personaId;
  final String authorName;
  final String? authorPersonality;
  final int? authorAvatarId;
  final String? authorNameColor;
  final bool isAi;
  final String content;
  final int likesCount;
  final bool isLiked; // حالة محلية للمستخدم الحالي
  final DateTime createdAt;

  const PostComment({
    required this.id,
    required this.postId,
    this.userId,
    this.personaId,
    required this.authorName,
    this.authorPersonality,
    this.authorAvatarId,
    this.authorNameColor,
    this.isAi = false,
    required this.content,
    this.likesCount = 0,
    this.isLiked = false,
    required this.createdAt,
  });

  factory PostComment.fromJson(Map<String, dynamic> json,
      {bool isLiked = false}) {
    return PostComment(
      id: json['id'] as int,
      postId: json['post_id'] as int,
      userId: json['user_id'],
      personaId: json['persona_id'],
      authorName: json['author_name'] ?? 'مستخدم',
      authorPersonality: json['author_personality'],
      authorAvatarId: json['author_avatar_id'],
      authorNameColor: json['author_name_color'],
      isAi: json['is_ai'] ?? false,
      content: json['content'] ?? '',
      likesCount: json['likes_count'] ?? 0,
      isLiked: isLiked,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  PostComment copyWith({int? likesCount, bool? isLiked}) {
    return PostComment(
      id: id,
      postId: postId,
      userId: userId,
      personaId: personaId,
      authorName: authorName,
      authorPersonality: authorPersonality,
      authorAvatarId: authorAvatarId,
      authorNameColor: authorNameColor,
      isAi: isAi,
      content: content,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt,
    );
  }
}
