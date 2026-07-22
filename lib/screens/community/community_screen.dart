import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../providers/articles_provider.dart';
import '../../providers/economy_provider.dart';
import '../../providers/posts_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/test_provider.dart';
import '../../widgets/editorial.dart';
import '../../widgets/post_card.dart';
import '../../widgets/user_post_card.dart';

/// تبويب المجتمع: خواطر الناس والشخصيات + مقالات التطبيق
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  bool _showingPosts = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EconomyProvider>().fetchCatalogs();
      _loadPosts();
      final personality =
          context.read<ProfileProvider>().profile?.personalityType;
      context.read<ArticlesProvider>().fetchArticles(
            personalityType: personality,
          );
    });
  }

  String? get _myType =>
      context.read<ProfileProvider>().profile?.personalityType ??
      context.read<TestProvider>().persistedCode;

  Future<void> _loadPosts() {
    return context.read<PostsProvider>().fetchFeed(myType: _myType);
  }

  Future<void> _setFilter(FeedFilter filter) async {
    final myType = _myType;
    if (filter != FeedFilter.all && myType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('اعمل الاختبار أولاً ليظهر لك محتوى نمطك'),
          action: SnackBarAction(
            label: 'ابدأ',
            textColor: AppColors.paper,
            onPressed: () => context.go('/test-select'),
          ),
        ),
      );
      return;
    }
    await context.read<PostsProvider>().setFilter(filter, myType: myType);
  }

  void _compose() {
    final profile = context.read<ProfileProvider>().profile;
    if (profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('سجّل الدخول لتكتب خاطرتك'),
          action: SnackBarAction(
            label: 'تسجيل الدخول',
            textColor: AppColors.paper,
            onPressed: () => context.push('/auth'),
          ),
        ),
      );
      return;
    }
    context.push('/compose');
  }

  @override
  Widget build(BuildContext context) {
    final postsProvider = context.watch<PostsProvider>();
    final articlesProvider = context.watch<ArticlesProvider>();

    return Scaffold(
      floatingActionButton: _showingPosts
          ? GestureDetector(
              onTap: _compose,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(color: AppColors.orange, offset: Offset(-3, 3)),
                  ],
                ),
                child: Icon(Icons.edit_outlined,
                    color: AppColors.paper, size: 22),
              ),
            )
          : null,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.ink,
          onRefresh: _loadPosts,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
            children: [
              Masthead(
                title: 'المجتمع',
                accent: AppColors.orange,
                subtitle: 'خواطر من كل الأنماط — ومقالات تخصّك',
              ),
              const SizedBox(height: 16),

              // خواطر / مقالات
              Row(
                children: [
                  _MainTab(
                    label: 'خواطر',
                    isActive: _showingPosts,
                    onTap: () => setState(() => _showingPosts = true),
                  ),
                  const SizedBox(width: 8),
                  _MainTab(
                    label: 'مقالات',
                    isActive: !_showingPosts,
                    onTap: () => setState(() => _showingPosts = false),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Hairline(),
              const SizedBox(height: 12),

              if (_showingPosts) ...[
                // فلاتر الفيد
                Row(
                  children: [
                    _FilterChip(
                      label: 'الكل',
                      isActive: postsProvider.filter == FeedFilter.all,
                      onTap: () => _setFilter(FeedFilter.all),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'نمطي',
                      isActive: postsProvider.filter == FeedFilter.myType,
                      onTap: () => _setFilter(FeedFilter.myType),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'مجموعتي',
                      isActive: postsProvider.filter == FeedFilter.myGroup,
                      onTap: () => _setFilter(FeedFilter.myGroup),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (postsProvider.isLoading && postsProvider.posts.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.ink),
                      ),
                    ),
                  )
                else if (postsProvider.posts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Center(
                      child: Text(
                        'لا خواطر هنا بعد — كن أول من يكتب ✍️',
                        style: AppType.ui(size: 13, color: AppColors.inkSoft),
                      ),
                    ),
                  )
                else
                  for (final post in postsProvider.posts) ...[
                    UserPostCard(post: post),
                    const SizedBox(height: 12),
                  ],
              ] else ...[
                if (articlesProvider.isLoading &&
                    articlesProvider.articles.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.ink),
                      ),
                    ),
                  )
                else
                  for (final article in articlesProvider.articles) ...[
                    PostCard(article: article),
                    const SizedBox(height: 12),
                  ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MainTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _MainTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppType.display(
              size: 19,
              weight: FontWeight.w700,
              color: isActive ? AppColors.ink : AppColors.inkSoft,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 3),
          Container(
            height: 3,
            width: 34,
            color: isActive ? AppColors.orange : Colors.transparent,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? AppColors.orange : Colors.transparent,
          border: Border.all(
            color: isActive ? AppColors.orange : AppColors.hairline,
          ),
        ),
        child: Text(
          label,
          style: AppType.ui(
            size: 12,
            weight: FontWeight.w700,
            color: isActive ? AppColors.paper : AppColors.inkMuted,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
