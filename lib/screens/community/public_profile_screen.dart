import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/supabase_client.dart';
import '../../core/theme.dart';
import '../../models/post.dart';
import '../../models/profile.dart';
import '../../providers/economy_provider.dart';
import '../../providers/posts_provider.dart';
import '../../widgets/avatar_view.dart';
import '../../widgets/editorial.dart';
import '../../widgets/user_post_card.dart';

/// البروفايل العام لأي مستخدم في المجتمع
class PublicProfileScreen extends StatefulWidget {
  final String userId;

  const PublicProfileScreen({super.key, required this.userId});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  Profile? _profile;
  List<Post> _posts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // شبكة أمان: لو كان هذا حسابي فالمكان الصحيح هو صفحة حسابي
      if (widget.userId == SupabaseHelper.client.auth.currentUser?.id) {
        context.go('/profile');
        return;
      }
      _load();
    });
  }

  Future<void> _load() async {
    context.read<EconomyProvider>().fetchCatalogs();
    final postsProvider = context.read<PostsProvider>();
    try {
      final profileRes = await SupabaseHelper.client
          .from('profiles')
          .select()
          .eq('id', widget.userId)
          .single();
      final posts = await postsProvider.fetchUserPosts(widget.userId);
      if (mounted) {
        setState(() {
          _profile = Profile.fromJson(profileRes);
          _posts = posts;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading public profile: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
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

    final profile = _profile;
    if (profile == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('لم نجد هذا المستخدم.', style: AppType.display(size: 20)),
              const SizedBox(height: 16),
              GhostButton(label: 'عودة', onTap: () => context.pop()),
            ],
          ),
        ),
      );
    }

    final economy = context.watch<EconomyProvider>();
    final accent = AppColors.accentForCode(profile.personalityType);
    final nameColor = AppColors.nameColor(profile.nameColor);
    final avatarPath = economy.avatarPath(profile.avatarId);
    final totalSupport =
        _posts.fold<int>(0, (sum, p) => sum + p.supportLeaves);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
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
              ],
            ),
            const SizedBox(height: 8),

            // الهوية — الشخصية واقفة بالكامل
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (avatarPath != null)
                  AvatarView(
                    assetPath: avatarPath,
                    personality: profile.personalityType,
                    size: 150,
                    fullBody: true,
                  )
                else
                  AvatarView(
                    personality: profile.personalityType,
                    fallbackText: typeEmoji(profile.personalityType),
                    size: 84,
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.username ?? 'مستخدم',
                        style: AppType.display(
                            size: 26, height: 1.3, color: nameColor),
                      ),
                      const SizedBox(height: 4),
                      if (profile.personalityType != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              profile.personalityType!,
                              style:
                                  AppType.mono(size: 16, letterSpacing: 4),
                            ),
                            Container(height: 4, width: 64, color: accent),
                          ],
                        ),
                      const SizedBox(height: 8),
                      Text(
                        'انضم في ${arabicDateLine(profile.createdAt)}',
                        style:
                            AppType.ui(size: 11, color: AppColors.inkSoft),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // إحصائيات
            Container(
              decoration:
                  BoxDecoration(border: Border.all(color: AppColors.hairline)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          arabicDigits(_posts.length),
                          style:
                              AppType.display(size: 20, weight: FontWeight.w700),
                        ),
                        Text('خاطرة',
                            style: AppType.ui(
                                size: 10.5, color: AppColors.inkSoft)),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 30, color: AppColors.hairline),
                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.eco,
                                size: 14, color: AppColors.green),
                            const SizedBox(width: 4),
                            Text(
                              arabicDigits(totalSupport),
                              style: AppType.display(
                                  size: 20, weight: FontWeight.w700),
                            ),
                          ],
                        ),
                        Text('دعم مستلَم',
                            style: AppType.ui(
                                size: 10.5, color: AppColors.inkSoft)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            SectionHead(number: '01', title: 'خواطر', accent: accent),
            const SizedBox(height: 12),
            if (_posts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Center(
                  child: Text(
                    'لا خواطر منشورة بعد.',
                    style: AppType.ui(size: 12.5, color: AppColors.inkSoft),
                  ),
                ),
              )
            else
              for (final post in _posts) ...[
                UserPostCard(post: post),
                const SizedBox(height: 12),
              ],
          ],
        ),
      ),
    );
  }
}
