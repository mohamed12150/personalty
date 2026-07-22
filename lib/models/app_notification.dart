/// إشعار داخل التطبيق — مطابق لجدول notifications
class AppNotification {
  final int id;
  final String type; // like | comment | support | article | reply
  final String? actorName;
  final int? actorAvatarId;
  final String? actorPersonality;
  final int? postId;
  final int? articleId;
  final int? amount;
  final String? preview;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    this.actorName,
    this.actorAvatarId,
    this.actorPersonality,
    this.postId,
    this.articleId,
    this.amount,
    this.preview,
    this.isRead = false,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as int,
      type: json['type'] ?? 'like',
      actorName: json['actor_name'],
      actorAvatarId: json['actor_avatar_id'],
      actorPersonality: json['actor_personality'],
      postId: json['post_id'],
      articleId: json['article_id'],
      amount: json['amount'],
      preview: json['preview'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        type: type,
        actorName: actorName,
        actorAvatarId: actorAvatarId,
        actorPersonality: actorPersonality,
        postId: postId,
        articleId: articleId,
        amount: amount,
        preview: preview,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );

  /// نص الإشعار كما يظهر للمستخدم
  String get title {
    final who = actorName ?? 'أحدهم';
    switch (type) {
      case 'like':
        return '$who أعجب بما كتبت';
      case 'comment':
        return '$who علّق على خاطرتك';
      case 'support':
        return '$who دعمك بـ$amount ورقة';
      case 'reply':
        return '$who ردّت على تعليقك';
      case 'article':
        return 'مقال جديد يخصّك';
      default:
        return 'إشعار جديد';
    }
  }

  /// الوجهة عند الضغط
  String? get route {
    if (postId != null) return '/post/$postId';
    if (articleId != null) return '/article-detail/$articleId';
    return null;
  }
}
