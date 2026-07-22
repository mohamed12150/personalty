import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../models/article.dart';
import '../providers/articles_provider.dart';
import 'editorial.dart';

/// منشور بروح الجريدة: إطار حاد، عنوان أميري، مقتطف أربعة أسطر،
/// وشريط تفاعل يعمل من الفيد مباشرة
class PostCard extends StatelessWidget {
  final Article article;
  final bool featured;

  const PostCard({super.key, required this.article, this.featured = false});

  Future<void> _toggleLike(BuildContext context) async {
    final ok = await context.read<ArticlesProvider>().toggleLike(article.id);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('سجّل الدخول لتتمكن من الإعجاب بالمنشورات.'),
          action: SnackBarAction(
            label: 'تسجيل الدخول',
            textColor: AppColors.paper,
            onPressed: () => context.push('/auth'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.categoryColor(article.category);

    return GestureDetector(
      onTap: () => context.push('/article-detail/${article.id}'),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: featured ? AppColors.ink : AppColors.hairline,
            width: featured ? 1.2 : 1,
          ),
          boxShadow: featured
              ? [BoxShadow(color: accent, offset: const Offset(-4, 4))]
              : null,
          color: AppColors.paper,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CategoryTab(label: article.category, color: accent),
                if (featured) ...[
                  const SizedBox(width: 6),
                  CategoryTab(label: 'جديد', color: AppColors.ink),
                ],
                if (!article.isGeneral &&
                    article.personalityTypes.length == 1) ...[
                  const SizedBox(width: 8),
                  Text(
                    article.personalityTypes.first,
                    style: AppType.mono(
                      size: 10.5,
                      letterSpacing: 1.5,
                      color: AppColors.accentForCode(
                          article.personalityTypes.first),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  arabicDateLine(article.createdAt),
                  style: AppType.ui(size: 10, color: AppColors.inkSoft),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              article.title,
              style: AppType.display(
                size: featured ? 22 : 18,
                height: 1.5,
                weight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            // مقتطف أربعة أسطر فقط
            Text(
              article.content,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: AppType.ui(
                size: 13,
                height: 1.9,
                color: AppColors.inkMuted,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'اقرأ المزيد ←',
              style: AppType.ui(
                size: 12,
                weight: FontWeight.w700,
                color: accent,
              ),
            ),
            const SizedBox(height: 12),
            const Hairline(),
            const SizedBox(height: 10),
            Row(
              children: [
                GestureDetector(
                  onTap: () => _toggleLike(context),
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      Icon(
                        article.isLiked
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 18,
                        color:
                            article.isLiked ? AppColors.orange : AppColors.ink,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        arabicDigits(article.likesCount),
                        style: AppType.ui(size: 12, weight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                Icon(Icons.mode_comment_outlined,
                    size: 16, color: AppColors.ink),
                const SizedBox(width: 5),
                Text(
                  arabicDigits(article.commentsCount),
                  style: AppType.ui(size: 12, weight: FontWeight.w700),
                ),
                const Spacer(),
                Text(
                  '${arabicDigits(article.readTime)} دقائق قراءة',
                  style: AppType.ui(size: 10.5, color: AppColors.inkSoft),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
