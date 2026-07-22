import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../core/supabase_client.dart';
import '../core/theme.dart';
import '../models/post.dart';
import '../providers/economy_provider.dart';
import '../providers/posts_provider.dart';
import '../providers/profile_provider.dart';
import 'avatar_view.dart';
import 'editorial.dart';

/// كارت خاطرة بروح الجريدة: هوية الكاتب + المحتوى + شريط تفاعل كامل
class UserPostCard extends StatelessWidget {
  final Post post;
  final bool clickable; // فتح صفحة الخاطرة عند الضغط

  const UserPostCard({super.key, required this.post, this.clickable = true});

  /// هل هذه خاطرتي أنا؟
  bool get _isMine =>
      post.userId != null &&
      post.userId == SupabaseHelper.client.auth.currentUser?.id;

  /// فتح صفحة صاحب الخاطرة — لو كانت خاطرتي فبروفايلي الشخصي
  void _openAuthor(BuildContext context) {
    if (post.userId == null) return; // شخصية افتراضية بلا بروفايل
    if (_isMine) {
      context.go('/profile');
    } else {
      context.push('/user/${post.userId}');
    }
  }

  void _promptLogin(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: 'تسجيل الدخول',
          textColor: AppColors.paper,
          onPressed: () => context.push('/auth'),
        ),
      ),
    );
  }

  Future<void> _toggleLike(BuildContext context) async {
    final ok = await context.read<PostsProvider>().toggleLike(post.id);
    if (!ok && context.mounted) {
      _promptLogin(context, 'سجّل الدخول لتتمكن من الإعجاب.');
    }
  }

  void _openSupport(BuildContext context) {
    final profile = context.read<ProfileProvider>().profile;
    if (profile == null) {
      _promptLogin(context, 'سجّل الدخول لتدعم الخواطر بالأوراق 🍃');
      return;
    }
    if (post.isAi) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('الشخصيات الافتراضية لا تحتاج دعماً 😄 ادعم خواطر الناس')),
      );
      return;
    }
    if (post.userId == profile.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكنك دعم خاطرتك')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (sheetContext) => _SupportSheet(post: post),
    );
  }

  Future<void> _deleteMine(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: AppColors.hairline),
        ),
        title: Text('حذف خاطرتك؟', style: AppType.display(size: 19)),
        content: Text(
          'ستختفي الخاطرة وتعليقاتها نهائياً.',
          style: AppType.ui(size: 13, height: 1.8),
        ),
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
    if (confirmed != true || !context.mounted) return;

    final ok = await context.read<PostsProvider>().deletePost(post.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'حُذفت خاطرتك' : 'تعذّر الحذف — حاول مجدداً'),
      ),
    );
  }

  Future<void> _report(BuildContext context) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: AppColors.hairline),
        ),
        title: Text('الإبلاغ عن الخاطرة', style: AppType.display(size: 19)),
        content: TextField(
          controller: reasonController,
          style: AppType.ui(size: 13),
          decoration: InputDecoration(
            hintText: 'سبب البلاغ (اختياري)',
            hintStyle: AppType.ui(size: 12.5, color: AppColors.inkSoft),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.hairline),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: AppType.ui(color: AppColors.inkSoft)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('إبلاغ',
                style: AppType.ui(
                    weight: FontWeight.w700, color: AppColors.orange)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final ok = await context
        .read<PostsProvider>()
        .reportPost(post.id, reasonController.text.trim());
    if (!context.mounted) return;
    if (!ok) {
      _promptLogin(context, 'سجّل الدخول لإرسال البلاغات.');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('وصلنا بلاغك — شكراً لحرصك على المجتمع 🤍')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final economy = context.watch<EconomyProvider>();
    final accent = AppColors.accentForCode(post.authorPersonality);
    final nameColor = AppColors.nameColor(post.authorNameColor);

    return GestureDetector(
      onTap: clickable ? () => context.push('/post/${post.id}') : null,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.hairline),
          color: AppColors.paper,
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => _openAuthor(context),
                  child: AvatarView(
                    assetPath: economy.avatarPath(post.authorAvatarId),
                    personality: post.authorPersonality,
                    fallbackText: typeEmoji(post.authorPersonality),
                    size: 38,
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
                              onTap: () => _openAuthor(context),
                              child: Text(
                                post.authorName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppType.ui(
                                  size: 13.5,
                                  weight: FontWeight.w700,
                                  color: nameColor,
                                ),
                              ),
                            ),
                          ),
                          if (post.isAi) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.inkSoft),
                              ),
                              child: Text(
                                'AI',
                                style: AppType.mono(
                                  size: 8.5,
                                  letterSpacing: 1,
                                  color: AppColors.inkMuted,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (post.authorPersonality != null)
                        Text(
                          post.authorPersonality!,
                          style: AppType.mono(
                            size: 10,
                            letterSpacing: 2,
                            color: accent,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  arabicTimeAgo(post.createdAt),
                  style: AppType.ui(size: 10, color: AppColors.inkSoft),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  // محتواي: حذف — محتوى غيري: إبلاغ
                  onTap: () =>
                      _isMine ? _deleteMine(context) : _report(context),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      _isMine ? Icons.delete_outline : Icons.more_horiz,
                      size: 16,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              post.content,
              style: AppType.ui(size: 14, height: 1.9),
            ),
            const SizedBox(height: 12),
            const Hairline(),
            const SizedBox(height: 8),
            Row(
              children: [
                GestureDetector(
                  onTap: () => _toggleLike(context),
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      Icon(
                        post.isLiked
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 17,
                        color:
                            post.isLiked ? AppColors.orange : AppColors.ink,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        arabicDigits(post.likesCount),
                        style: AppType.ui(size: 11.5, weight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: clickable
                      ? () => context.push('/post/${post.id}')
                      : null,
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      Icon(Icons.mode_comment_outlined,
                          size: 15, color: AppColors.ink),
                      const SizedBox(width: 4),
                      Text(
                        arabicDigits(post.commentsCount),
                        style: AppType.ui(size: 11.5, weight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () => _openSupport(context),
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      Icon(Icons.eco_outlined,
                          size: 16, color: AppColors.green),
                      const SizedBox(width: 4),
                      Text(
                        arabicDigits(post.supportLeaves),
                        style: AppType.ui(
                          size: 11.5,
                          weight: FontWeight.w700,
                          color: AppColors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// اختيار مبلغ الدعم 🍃
class _SupportSheet extends StatefulWidget {
  final Post post;

  const _SupportSheet({required this.post});

  @override
  State<_SupportSheet> createState() => _SupportSheetState();
}

class _SupportSheetState extends State<_SupportSheet> {
  bool _busy = false;

  Future<void> _support(int leaves) async {
    if (_busy) return;
    setState(() => _busy = true);

    final result =
        await context.read<EconomyProvider>().supportPost(widget.post.id, leaves);
    if (!mounted) return;

    if (result.ok) {
      context.read<PostsProvider>().applySupport(widget.post.id, leaves);
      await context.read<ProfileProvider>().refresh();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'دعمت ${widget.post.authorName} بـ${arabicDigits(leaves)} ورقة 🍃'),
          ),
        );
      }
    } else {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final balance =
        context.watch<ProfileProvider>().profile?.leaves ?? 0;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ادعم ${widget.post.authorName} 🍃',
                style: AppType.display(size: 20)),
            const SizedBox(height: 4),
            Text(
              'الأوراق تصل لصاحب الخاطرة مباشرة — رصيدك: ${arabicDigits(balance)}',
              style: AppType.ui(size: 12, color: AppColors.inkSoft),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                for (final amount in const [10, 25, 50]) ...[
                  Expanded(
                    child: GestureDetector(
                      onTap: _busy ? null : () => _support(amount),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.green, width: 1.2),
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            Text(
                              arabicDigits(amount),
                              style: AppType.ui(
                                size: 18,
                                weight: FontWeight.w700,
                                color: AppColors.green,
                              ),
                            ),
                            Text('ورقة',
                                style: AppType.ui(
                                    size: 10, color: AppColors.inkSoft)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (amount != 50) const SizedBox(width: 10),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
