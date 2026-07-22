import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../providers/articles_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/test_provider.dart';
import '../../widgets/announcement_dialog.dart';
import '../../widgets/editorial.dart';
import '../../widgets/post_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
      // إعلانات لوحة التحكم — تظهر بعد استقرار الشاشة
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) maybeShowAnnouncement(context);
      });
    });
  }

  Future<void> _load() {
    final personality =
        context.read<ProfileProvider>().profile?.personalityType ??
            context.read<TestProvider>().persistedCode;
    context.read<NotificationsProvider>().fetch();
    return context
        .read<ArticlesProvider>()
        .fetchArticles(personalityType: personality);
  }

  @override
  Widget build(BuildContext context) {
    final articlesProvider = context.watch<ArticlesProvider>();
    // نمط المستخدم: من بروفايله، أو من آخر نتيجة محفوظة محلياً (تعمل للضيوف)
    final personality =
        context.watch<ProfileProvider>().profile?.personalityType ??
            context.watch<TestProvider>().persistedCode;
    final accent = AppColors.accentForCode(personality);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.ink,
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            children: [
              Masthead(
                title: 'شخصيتي',
                accent: AppColors.violet,
                subtitle: arabicDateLine(DateTime.now()),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    NotificationBell(
                      unread: context
                          .watch<NotificationsProvider>()
                          .unreadCount,
                      onTap: () => context.push('/notifications'),
                    ),
                    IconButton(
                      onPressed: () => context.push('/settings'),
                      icon: Icon(Icons.tune, size: 20, color: AppColors.ink),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (personality == null)
                const _LeadStartTest()
              else
                _LeadIdentity(code: personality, accent: accent),
              const SizedBox(height: 14),
              const _PuzzleBlock(),
              const SizedBox(height: 28),
              SectionHead(
                number: '01',
                title:
                    personality == null ? 'منشورات مختارة' : 'منشورات تخصّك',
                accent: accent,
              ),
              const SizedBox(height: 14),
              if (articlesProvider.isLoading && articlesProvider.articles.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                )
              else if (articlesProvider.articles.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    'لا توجد مقالات بعد — عُد لاحقاً.',
                    style: AppType.ui(size: 13, color: AppColors.inkSoft),
                  ),
                )
              else ...[
                for (var i = 0;
                    i < articlesProvider.articles.take(8).length;
                    i++) ...[
                  PostCard(
                    article: articlesProvider.articles[i],
                    featured: i == 0,
                  ),
                  const SizedBox(height: 14),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// مدخل لغز اليوم
class _PuzzleBlock extends StatelessWidget {
  const _PuzzleBlock();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/puzzle'),
      child: Container(
        decoration:
            BoxDecoration(border: Border.all(color: AppColors.hairline)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Text(
              '؟',
              style: AppType.display(
                size: 34,
                weight: FontWeight.w700,
                color: AppColors.green,
                height: 1,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('لغز الشخصية اليومي',
                      style: AppType.display(size: 17, height: 1.3)),
                  Text(
                    'خمّن النمط من المشهد واكسب ${arabicDigits(25)} ورقة',
                    style: AppType.ui(size: 11.5, color: AppColors.inkMuted),
                  ),
                ],
              ),
            ),
            InkButton(
              label: 'العب',
              shadowColor: AppColors.green,
              onTap: () => context.push('/puzzle'),
            ),
          ],
        ),
      ),
    );
  }
}

/// كتلة الافتتاحية عندما لم يُجرِ المستخدم الاختبار بعد
class _LeadStartTest extends StatelessWidget {
  const _LeadStartTest();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: AppColors.hairline)),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [CategoryTab(label: 'ابدأ من هنا', color: AppColors.violet)],
          ),
          const SizedBox(height: 12),
          Text(
            'ما زلنا لا نعرف من أنت.',
            style: AppType.display(size: 24, height: 1.4),
          ),
          const SizedBox(height: 4),
          Text(
            'ستة عشر سؤالاً تفصلك عن تقرير يشبهك.',
            style: AppType.ui(size: 13, color: AppColors.inkMuted),
          ),
          const SizedBox(height: 16),
          InkButton(
            label: 'ابدأ الاختبار',
            shadowColor: AppColors.violet,
            onTap: () => context.go('/test-select'),
          ),
        ],
      ),
    );
  }
}

/// كتلة هوية المستخدم بعد إجراء الاختبار
class _LeadIdentity extends StatelessWidget {
  final String code;
  final Color accent;

  const _LeadIdentity({required this.code, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: AppColors.hairline)),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'نمطك الحالي',
                  style: AppType.ui(size: 11, color: AppColors.inkSoft),
                ),
                const SizedBox(height: 4),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      code,
                      style: AppType.mono(size: 26, letterSpacing: 5),
                    ),
                    Container(height: 5, width: 92, color: accent),
                  ],
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => context.push('/personality-detail?code=$code'),
                  child: Text(
                    'اقرأ تقريرك الكامل ←',
                    style: AppType.ui(
                      size: 12.5,
                      weight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          GhostButton(
            label: 'أعد الاختبار',
            onTap: () => context.go('/test-select'),
          ),
        ],
      ),
    );
  }
}
