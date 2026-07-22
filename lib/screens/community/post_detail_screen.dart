import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/supabase_client.dart';
import '../../core/theme.dart';
import '../../providers/economy_provider.dart';
import '../../providers/posts_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/avatar_view.dart';
import '../../widgets/editorial.dart';
import '../../widgets/user_post_card.dart';

/// صفحة الخاطرة: المحتوى + التعليقات (بما فيها ردود الشخصيات الافتراضية)
class PostDetailScreen extends StatefulWidget {
  final int postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentController = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PostsProvider>();
      if (provider.byId(widget.postId) == null) {
        provider.fetchFeed(
          myType: context.read<ProfileProvider>().profile?.personalityType,
        );
      }
      provider.fetchComments(widget.postId);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _deleteComment(int commentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: AppColors.hairline),
        ),
        title: Text('حذف تعليقك؟', style: AppType.display(size: 19)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: AppType.ui(color: AppColors.inkSoft)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('حذف',
                style: AppType.ui(
                    weight: FontWeight.w700, color: AppColors.orange)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await context
        .read<PostsProvider>()
        .deleteComment(widget.postId, commentId);
  }

  Future<void> _send() async {
    final content = _commentController.text.trim();
    if (content.isEmpty || _sending) return;

    final profile = context.read<ProfileProvider>().profile;
    if (profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('سجّل الدخول لتتمكن من التعليق'),
          action: SnackBarAction(
            label: 'تسجيل الدخول',
            textColor: AppColors.paper,
            onPressed: () => context.push('/auth'),
          ),
        ),
      );
      return;
    }

    setState(() => _sending = true);
    await context.read<PostsProvider>().addComment(
          widget.postId,
          content,
          authorName: profile.username ?? 'مستخدم',
          authorPersonality: profile.personalityType,
          authorAvatarId: profile.avatarId,
          authorNameColor: profile.nameColor,
        );
    _commentController.clear();
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PostsProvider>();
    final economy = context.watch<EconomyProvider>();
    final post = provider.byId(widget.postId);
    final comments = provider.commentsFor(widget.postId);

    if (post == null) {
      return Scaffold(
        body: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.ink),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: Icon(Icons.arrow_back,
                            size: 20, color: AppColors.ink),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      Text('الخاطرة',
                          style: AppType.ui(
                              size: 13, weight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  UserPostCard(post: post, clickable: false),
                  const SizedBox(height: 20),
                  SectionHead(
                    number: '01',
                    title:
                        'التعليقات (${arabicDigits(post.commentsCount)})',
                  ),
                  if (post.isAi) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${post.authorName} ترد على التعليقات عادة خلال دقائق 🤖',
                      style: AppType.ui(size: 11, color: AppColors.inkSoft),
                    ),
                  ],
                  const SizedBox(height: 8),
                  if (comments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'كن أول من يعلّق.',
                        style:
                            AppType.ui(size: 12.5, color: AppColors.inkSoft),
                      ),
                    )
                  else
                    for (final comment in comments)
                      Builder(builder: (context) {
                        final myId =
                            SupabaseHelper.client.auth.currentUser?.id;
                        final isMine = comment.userId != null &&
                            comment.userId == myId;
                        void openAuthor() {
                          if (comment.userId == null) return;
                          if (isMine) {
                            context.go('/profile');
                          } else {
                            context.push('/user/${comment.userId}');
                          }
                        }

                        return Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: AppColors.hairline),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: openAuthor,
                              child: AvatarView(
                                assetPath:
                                    economy.avatarPath(comment.authorAvatarId),
                                personality: comment.authorPersonality,
                                fallbackText:
                                    typeEmoji(comment.authorPersonality),
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: GestureDetector(
                                          onTap: openAuthor,
                                          child: Text(
                                            comment.authorName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppType.ui(
                                              size: 12.5,
                                              weight: FontWeight.w700,
                                              color: AppColors.nameColor(
                                                  comment.authorNameColor),
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (comment.authorPersonality !=
                                          null) ...[
                                        const SizedBox(width: 6),
                                        Text(
                                          comment.authorPersonality!,
                                          style: AppType.mono(
                                            size: 9.5,
                                            letterSpacing: 1.5,
                                            color: AppColors.accentForCode(
                                                comment.authorPersonality),
                                          ),
                                        ),
                                      ],
                                      if (comment.isAi) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 4,
                                                  vertical: 1),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: AppColors.inkSoft),
                                          ),
                                          child: Text(
                                            'AI',
                                            style: AppType.mono(
                                              size: 8,
                                              letterSpacing: 1,
                                              color: AppColors.inkMuted,
                                            ),
                                          ),
                                        ),
                                      ],
                                      const Spacer(),
                                      Text(
                                        arabicTimeAgo(comment.createdAt),
                                        style: AppType.ui(
                                            size: 9.5,
                                            color: AppColors.inkSoft),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    comment.content,
                                    style:
                                        AppType.ui(size: 13, height: 1.8),
                                  ),
                                  const SizedBox(height: 6),
                                  if (isMine)
                                    // تعليقي: لا إعجاب لنفسي — عدد الإعجابات
                                    // للعرض فقط، مع إمكانية الحذف
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (comment.likesCount > 0) ...[
                                          Icon(Icons.favorite,
                                              size: 13,
                                              color: AppColors.orange),
                                          const SizedBox(width: 4),
                                          Text(
                                            arabicDigits(comment.likesCount),
                                            style: AppType.ui(
                                              size: 10.5,
                                              weight: FontWeight.w700,
                                              color: AppColors.inkMuted,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                        ],
                                        GestureDetector(
                                          onTap: () => _deleteComment(
                                              comment.id),
                                          behavior: HitTestBehavior.opaque,
                                          child: Text(
                                            'حذف',
                                            style: AppType.ui(
                                              size: 10.5,
                                              weight: FontWeight.w700,
                                              color: AppColors.inkSoft,
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    GestureDetector(
                                      onTap: () async {
                                        final ok = await context
                                            .read<PostsProvider>()
                                            .toggleCommentLike(
                                                widget.postId, comment.id);
                                        if (!ok && context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: const Text(
                                                  'سجّل الدخول لتتمكن من الإعجاب'),
                                              action: SnackBarAction(
                                                label: 'تسجيل الدخول',
                                                textColor: AppColors.paper,
                                                onPressed: () =>
                                                    context.push('/auth'),
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      behavior: HitTestBehavior.opaque,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            comment.isLiked
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            size: 14,
                                            color: comment.isLiked
                                                ? AppColors.orange
                                                : AppColors.inkSoft,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            arabicDigits(comment.likesCount),
                                            style: AppType.ui(
                                              size: 10.5,
                                              weight: FontWeight.w700,
                                              color: comment.isLiked
                                                  ? AppColors.ink
                                                  : AppColors.inkSoft,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        );
                      }),
                ],
              ),
            ),
            // إدخال التعليق
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.hairline)),
                color: AppColors.paper,
              ),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.hairline),
                      ),
                      child: TextField(
                        controller: _commentController,
                        style: AppType.ui(size: 13.5),
                        decoration: InputDecoration(
                          hintText: 'اكتب تعليقك…',
                          hintStyle: AppType.ui(
                              size: 13, color: AppColors.inkSoft),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _send,
                    child: Container(
                      padding: const EdgeInsets.all(11),
                      color: AppColors.ink,
                      child: _sending
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.paper,
                              ),
                            )
                          : Icon(Icons.send,
                              size: 16, color: AppColors.paper),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
