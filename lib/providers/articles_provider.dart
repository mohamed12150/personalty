import 'package:flutter/material.dart';
import '../core/supabase_client.dart';
import '../models/article.dart';
import '../models/comment.dart';

class ArticlesProvider extends ChangeNotifier {
  List<Article> _articles = [];
  bool _isLoading = false;
  Set<int> _likedIds = {};
  final Map<int, List<Comment>> _comments = {};
  bool _loadedOnce = false;

  List<Article> get articles => _articles;
  bool get isLoading => _isLoading;
  bool get loadedOnce => _loadedOnce;

  Article? byId(int id) {
    for (final a in _articles) {
      if (a.id == id) return a;
    }
    return null;
  }

  List<Comment> commentsFor(int articleId) => _comments[articleId] ?? [];

  /// جلب المقالات: العامة + الخاصة بنمط المستخدم إن وُجد
  Future<void> fetchArticles({String? personalityType}) async {
    _isLoading = true;
    notifyListeners();

    try {
      var query = SupabaseHelper.client.from('articles').select();
      if (personalityType != null && personalityType.isNotEmpty) {
        query = query.or(
          'personality_types.cs.{$personalityType},personality_types.eq.{}',
        );
      }
      final response = await query.order('created_at', ascending: false);

      await _fetchMyLikes();
      _articles = (response as List)
          .map((json) => Article.fromJson(
                json,
                isLiked: _likedIds.contains(json['id']),
              ))
          .toList();
      _loadedOnce = true;
    } catch (e) {
      debugPrint('Error fetching articles: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchMyLikes() async {
    final user = SupabaseHelper.client.auth.currentUser;
    if (user == null) {
      _likedIds = {};
      return;
    }
    try {
      final response = await SupabaseHelper.client
          .from('likes')
          .select('article_id')
          .eq('user_id', user.id);
      _likedIds =
          (response as List).map((r) => r['article_id'] as int).toSet();
    } catch (e) {
      debugPrint('Error fetching likes: $e');
    }
  }

  /// إعجاب/إلغاء إعجاب — يرجع false لو المستخدم غير مسجل
  Future<bool> toggleLike(int articleId) async {
    final user = SupabaseHelper.client.auth.currentUser;
    if (user == null) return false;

    final index = _articles.indexWhere((a) => a.id == articleId);
    if (index == -1) return true;

    final article = _articles[index];
    final wasLiked = article.isLiked;

    // تحديث فوري في الواجهة ثم مزامنة مع القاعدة
    _articles[index] = article.copyWith(
      isLiked: !wasLiked,
      likesCount: wasLiked ? article.likesCount - 1 : article.likesCount + 1,
    );
    if (wasLiked) {
      _likedIds.remove(articleId);
    } else {
      _likedIds.add(articleId);
    }
    notifyListeners();

    try {
      if (wasLiked) {
        await SupabaseHelper.client
            .from('likes')
            .delete()
            .eq('user_id', user.id)
            .eq('article_id', articleId);
      } else {
        await SupabaseHelper.client
            .from('likes')
            .insert({'user_id': user.id, 'article_id': articleId});
      }
    } catch (e) {
      debugPrint('Error toggling like: $e');
      // التراجع عن التحديث المتفائل عند الفشل
      _articles[index] = article;
      if (wasLiked) {
        _likedIds.add(articleId);
      } else {
        _likedIds.remove(articleId);
      }
      notifyListeners();
    }
    return true;
  }

  Future<void> fetchComments(int articleId) async {
    try {
      final response = await SupabaseHelper.client
          .from('comments')
          .select()
          .eq('article_id', articleId)
          .order('created_at', ascending: false);
      _comments[articleId] =
          (response as List).map((c) => Comment.fromJson(c)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching comments: $e');
    }
  }

  /// إضافة تعليق — يرجع false لو المستخدم غير مسجل
  Future<bool> addComment(
    int articleId,
    String content, {
    required String userName,
    String? userPersonality,
    String? nameColor,
  }) async {
    final user = SupabaseHelper.client.auth.currentUser;
    if (user == null) return false;

    try {
      final inserted = await SupabaseHelper.client
          .from('comments')
          .insert({
            'article_id': articleId,
            'user_id': user.id,
            'user_name': userName,
            'user_personality': userPersonality,
            'author_name_color': nameColor,
            'content': content,
          })
          .select()
          .single();

      _comments[articleId] = [
        Comment.fromJson(inserted),
        ...(_comments[articleId] ?? []),
      ];

      final index = _articles.indexWhere((a) => a.id == articleId);
      if (index != -1) {
        _articles[index] = _articles[index].copyWith(
          commentsCount: _articles[index].commentsCount + 1,
        );
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding comment: $e');
    }
    return true;
  }
}
