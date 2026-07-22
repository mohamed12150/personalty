import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../providers/articles_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/editorial.dart';

class ArticleDetailScreen extends StatefulWidget {
  final int articleId;

  const ArticleDetailScreen({super.key, required this.articleId});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  final _commentController = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ArticlesProvider>();
      if (provider.byId(widget.articleId) == null) {
        provider.fetchArticles(
          personalityType:
              context.read<ProfileProvider>().profile?.personalityType,
        );
      }
      provider.fetchComments(widget.articleId);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _promptLogin(String message) {
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

  Future<void> _toggleLike() async {
    final ok =
        await context.read<ArticlesProvider>().toggleLike(widget.articleId);
    if (!ok && mounted) {
      _promptLogin('سجّل الدخول لتتمكن من الإعجاب بالمقالات.');
    }
  }

  Future<void> _sendComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty || _sending) return;

    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      _promptLogin('سجّل الدخول لتتمكن من التعليق.');
      return;
    }

    setState(() => _sending = true);
    final profile = context.read<ProfileProvider>().profile;
    final userName = profile?.username ??
        auth.user?.email?.split('@').first ??
        'مستخدم';
    await context.read<ArticlesProvider>().addComment(
          widget.articleId,
          content,
          userName: userName,
          userPersonality: profile?.personalityType,
          nameColor: profile?.nameColor,
        );
    _commentController.clear();
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ArticlesProvider>();
    final article = provider.byId(widget.articleId);

    if (article == null) {
      return Scaffold(
        body: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.ink,
            ),
          ),
        ),
      );
    }

    final comments = provider.commentsFor(widget.articleId);
    final paragraphs = article.content.split('\n\n');

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: Icon(Icons.arrow_forward,
                      size: 20, color: AppColors.ink),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const Spacer(),
                CategoryTab(
                  label: article.category,
                  color: AppColors.categoryColor(article.category),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              article.title,
              style: AppType.display(size: 27, weight: FontWeight.w700, height: 1.5),
            ),
            const SizedBox(height: 8),
            Text(
              '${arabicDateLine(article.createdAt)} · ${arabicDigits(article.readTime)} دقائق قراءة',
              style: AppType.ui(size: 11.5, color: AppColors.inkSoft),
            ),
            const SizedBox(height: 14),
            Container(height: 3, color: AppColors.ink),
            const SizedBox(height: 3),
            const Hairline(),
            const SizedBox(height: 18),
            for (final paragraph in paragraphs) ...[
              Text(
                paragraph,
                style: AppType.ui(size: 14.5, height: 2.0),
              ),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 4),
            const Hairline(),
            const SizedBox(height: 12),

            // الإعجاب والتعليقات
            Row(
              children: [
                GestureDetector(
                  onTap: _toggleLike,
                  child: Row(
                    children: [
                      Icon(
                        article.isLiked
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 20,
                        color: article.isLiked
                            ? AppColors.orange
                            : AppColors.ink,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        arabicDigits(article.likesCount),
                        style: AppType.ui(size: 13, weight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Icon(Icons.mode_comment_outlined,
                    size: 18, color: AppColors.ink),
                const SizedBox(width: 6),
                Text(
                  arabicDigits(article.commentsCount),
                  style: AppType.ui(size: 13, weight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 24),

            SectionHead(number: '01', title: 'التعليقات'),
            const SizedBox(height: 12),
            Row(
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
                        hintStyle:
                            AppType.ui(size: 13, color: AppColors.inkSoft),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendComment,
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
            const SizedBox(height: 16),
            if (comments.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'كن أول من يعلّق.',
                  style: AppType.ui(size: 12.5, color: AppColors.inkSoft),
                ),
              )
            else
              for (final comment in comments)
                Container(
                  decoration: BoxDecoration(
                    border:
                        Border(bottom: BorderSide(color: AppColors.hairline)),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            comment.userName,
                            style: AppType.ui(
                              size: 12.5,
                              weight: FontWeight.w700,
                              color: AppColors.nameColor(comment.nameColor),
                            ),
                          ),
                          if (comment.userPersonality != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              comment.userPersonality!,
                              style: AppType.mono(
                                size: 10.5,
                                letterSpacing: 1.5,
                                color: AppColors.accentForCode(
                                    comment.userPersonality),
                              ),
                            ),
                          ],
                          const Spacer(),
                          Text(
                            arabicDateLine(comment.createdAt),
                            style: AppType.ui(
                                size: 10, color: AppColors.inkSoft),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(comment.content, style: AppType.ui(size: 13.5)),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
