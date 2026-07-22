import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/supabase_client.dart';
import '../models/post.dart';

enum FeedFilter { all, myType, myGroup }

/// نتيجة محاولة نشر خاطرة عبر بوابة الفلترة
class CreatePostResult {
  final bool ok;
  final String? rejectionReason;
  final int reward;
  final String? error;

  const CreatePostResult({
    required this.ok,
    this.rejectionReason,
    this.reward = 0,
    this.error,
  });
}

class PostsProvider extends ChangeNotifier {
  List<Post> _posts = [];
  bool _isLoading = false;
  FeedFilter _filter = FeedFilter.all;
  Set<int> _likedIds = {};
  final Map<int, List<PostComment>> _comments = {};

  List<Post> get posts => _posts;
  bool get isLoading => _isLoading;
  FeedFilter get filter => _filter;

  Post? byId(int id) {
    for (final p in _posts) {
      if (p.id == id) return p;
    }
    return null;
  }

  List<PostComment> commentsFor(int postId) => _comments[postId] ?? [];

  Future<void> setFilter(FeedFilter filter, {String? myType}) async {
    _filter = filter;
    await fetchFeed(myType: myType);
  }

  Future<void> fetchFeed({String? myType}) async {
    _isLoading = true;
    notifyListeners();

    try {
      var query = SupabaseHelper.client.from('posts').select();

      if (_filter == FeedFilter.myType && myType != null) {
        query = query.eq('author_personality', myType);
      } else if (_filter == FeedFilter.myGroup && myType != null) {
        query = query.inFilter('author_personality', groupCodes(myType));
      }

      final response =
          await query.order('created_at', ascending: false).limit(50);

      await _fetchMyLikes();
      _posts = (response as List)
          .map((json) =>
              Post.fromJson(json, isLiked: _likedIds.contains(json['id'])))
          .toList();
    } catch (e) {
      debugPrint('Error fetching posts: $e');
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
          .from('post_likes')
          .select('post_id')
          .eq('user_id', user.id);
      _likedIds = (response as List).map((r) => r['post_id'] as int).toSet();
    } catch (e) {
      debugPrint('Error fetching post likes: $e');
    }
  }

  /// جلب خواطر مستخدم بعينه (للبروفايل العام)
  Future<List<Post>> fetchUserPosts(String userId) async {
    try {
      final response = await SupabaseHelper.client
          .from('posts')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(30);
      return (response as List)
          .map((json) =>
              Post.fromJson(json, isLiked: _likedIds.contains(json['id'])))
          .toList();
    } catch (e) {
      debugPrint('Error fetching user posts: $e');
      return [];
    }
  }

  /// النشر عبر بوابة الفلترة الذكية
  Future<CreatePostResult> createPost(String content) async {
    try {
      final res = await SupabaseHelper.client.functions.invoke(
        'create-post',
        body: {'content': content},
      );
      final data = res.data;
      if (data is! Map) {
        return const CreatePostResult(ok: false, error: 'unknown');
      }
      if (data['ok'] == true) {
        await fetchFeed();
        return CreatePostResult(
          ok: true,
          reward: (data['reward'] as num?)?.toInt() ?? 0,
        );
      }
      if (data['error'] == 'rejected') {
        return CreatePostResult(
          ok: false,
          rejectionReason:
              data['reason']?.toString() ?? 'المحتوى مخالف لإرشادات المجتمع',
        );
      }
      return CreatePostResult(ok: false, error: data['error']?.toString());
    } catch (e) {
      debugPrint('Error creating post: $e');
      return const CreatePostResult(ok: false, error: 'network');
    }
  }

  /// إعجاب/إلغاء — يرجع false لو غير مسجل
  Future<bool> toggleLike(int postId) async {
    final user = SupabaseHelper.client.auth.currentUser;
    if (user == null) return false;

    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return true;

    final post = _posts[index];
    final wasLiked = post.isLiked;

    _posts[index] = post.copyWith(
      isLiked: !wasLiked,
      likesCount: wasLiked ? post.likesCount - 1 : post.likesCount + 1,
    );
    if (wasLiked) {
      _likedIds.remove(postId);
    } else {
      _likedIds.add(postId);
    }
    notifyListeners();

    try {
      if (wasLiked) {
        await SupabaseHelper.client
            .from('post_likes')
            .delete()
            .eq('user_id', user.id)
            .eq('post_id', postId);
      } else {
        await SupabaseHelper.client
            .from('post_likes')
            .insert({'user_id': user.id, 'post_id': postId});
      }
    } catch (e) {
      debugPrint('Error toggling post like: $e');
      _posts[index] = post;
      if (wasLiked) {
        _likedIds.add(postId);
      } else {
        _likedIds.remove(postId);
      }
      notifyListeners();
    }
    return true;
  }

  Future<void> fetchComments(int postId) async {
    try {
      final response = await SupabaseHelper.client
          .from('post_comments')
          .select()
          .eq('post_id', postId)
          .order('created_at', ascending: true);

      // إعجاباتي على تعليقات هذه الخاطرة
      var likedIds = <int>{};
      final user = SupabaseHelper.client.auth.currentUser;
      final ids = (response as List).map((c) => c['id'] as int).toList();
      if (user != null && ids.isNotEmpty) {
        final likesRes = await SupabaseHelper.client
            .from('post_comment_likes')
            .select('comment_id')
            .inFilter('comment_id', ids);
        likedIds =
            (likesRes as List).map((r) => r['comment_id'] as int).toSet();
      }

      _comments[postId] = response
          .map((c) =>
              PostComment.fromJson(c, isLiked: likedIds.contains(c['id'])))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching post comments: $e');
    }
  }

  /// إعجاب/إلغاء على تعليق — يرجع false لو غير مسجل
  Future<bool> toggleCommentLike(int postId, int commentId) async {
    final user = SupabaseHelper.client.auth.currentUser;
    if (user == null) return false;

    final list = _comments[postId];
    if (list == null) return true;
    final index = list.indexWhere((c) => c.id == commentId);
    if (index == -1) return true;

    final comment = list[index];
    final wasLiked = comment.isLiked;

    list[index] = comment.copyWith(
      isLiked: !wasLiked,
      likesCount:
          wasLiked ? comment.likesCount - 1 : comment.likesCount + 1,
    );
    notifyListeners();

    try {
      if (wasLiked) {
        await SupabaseHelper.client
            .from('post_comment_likes')
            .delete()
            .eq('user_id', user.id)
            .eq('comment_id', commentId);
      } else {
        await SupabaseHelper.client
            .from('post_comment_likes')
            .insert({'user_id': user.id, 'comment_id': commentId});
      }
    } catch (e) {
      debugPrint('Error toggling comment like: $e');
      list[index] = comment;
      notifyListeners();
    }
    return true;
  }

  /// إضافة تعليق — يرجع false لو غير مسجل
  Future<bool> addComment(
    int postId,
    String content, {
    required String authorName,
    String? authorPersonality,
    int? authorAvatarId,
    String? authorNameColor,
  }) async {
    final user = SupabaseHelper.client.auth.currentUser;
    if (user == null) return false;

    try {
      final inserted = await SupabaseHelper.client
          .from('post_comments')
          .insert({
            'post_id': postId,
            'user_id': user.id,
            'author_name': authorName,
            'author_personality': authorPersonality,
            'author_avatar_id': authorAvatarId,
            'author_name_color': authorNameColor,
            'content': content,
          })
          .select()
          .single();

      _comments[postId] = [
        ...(_comments[postId] ?? []),
        PostComment.fromJson(inserted),
      ];

      final index = _posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        _posts[index] = _posts[index].copyWith(
          commentsCount: _posts[index].commentsCount + 1,
        );
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding post comment: $e');
    }
    return true;
  }

  /// حذف خاطرتي — قاعدة البيانات تسمح بحذف المالك فقط
  Future<bool> deletePost(int postId) async {
    final user = SupabaseHelper.client.auth.currentUser;
    if (user == null) return false;
    try {
      await SupabaseHelper.client
          .from('posts')
          .delete()
          .eq('id', postId)
          .eq('user_id', user.id);
      _posts.removeWhere((p) => p.id == postId);
      _comments.remove(postId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting post: $e');
      return false;
    }
  }

  /// حذف تعليقي — قاعدة البيانات تسمح بحذف المالك فقط
  Future<bool> deleteComment(int postId, int commentId) async {
    final user = SupabaseHelper.client.auth.currentUser;
    if (user == null) return false;
    try {
      await SupabaseHelper.client
          .from('post_comments')
          .delete()
          .eq('id', commentId)
          .eq('user_id', user.id);

      _comments[postId]?.removeWhere((c) => c.id == commentId);
      final index = _posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        _posts[index] = _posts[index].copyWith(
          commentsCount: (_posts[index].commentsCount - 1).clamp(0, 1 << 30),
        );
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting comment: $e');
      return false;
    }
  }

  /// بلاغ عن خاطرة — يرجع false لو غير مسجل
  Future<bool> reportPost(int postId, String? reason) async {
    final user = SupabaseHelper.client.auth.currentUser;
    if (user == null) return false;
    try {
      await SupabaseHelper.client.from('post_reports').insert({
        'post_id': postId,
        'reporter_id': user.id,
        'reason': reason,
      });
    } catch (e) {
      debugPrint('Error reporting post: $e');
    }
    return true;
  }

  /// بعد تغيير الاسم أو اللون أو الأفاتار — يعيد جلب الفيد ليعكس الهوية الجديدة
  Future<void> refreshAfterIdentityChange({String? myType}) =>
      fetchFeed(myType: myType);

  /// تحديث محلي بعد دعم ناجح
  void applySupport(int postId, int leaves) {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      _posts[index] = _posts[index].copyWith(
        supportLeaves: _posts[index].supportLeaves + leaves,
      );
      notifyListeners();
    }
  }
}
