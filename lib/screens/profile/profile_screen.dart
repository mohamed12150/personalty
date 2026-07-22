import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/supabase_client.dart';
import '../../core/theme.dart';
import '../../models/profile.dart';
import '../../models/test_result.dart';
import '../../providers/auth_provider.dart';
import '../../providers/economy_provider.dart';
import '../../providers/posts_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/avatar_view.dart';
import '../../widgets/editorial.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<TestResult> _history = [];
  bool _loadingHistory = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EconomyProvider>().fetchCatalogs();
      _loadHistory();
    });
  }

  Future<void> _loadHistory() async {
    final user = SupabaseHelper.client.auth.currentUser;
    if (user == null) return;
    setState(() => _loadingHistory = true);
    try {
      final response = await SupabaseHelper.client
          .from('test_results')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(20);
      if (mounted) {
        setState(() {
          _history = (response as List)
              .map((r) => TestResult.fromJson(r))
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading history: $e');
    } finally {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  void _openColorsShop() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.paper,
      // يسمح للنافذة بالتمدد والتمرير بدل الفيض على الشاشات القصيرة
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (context) => const _ColorsShopSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = context.watch<ProfileProvider>().profile;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            Masthead(
              title: 'حسابي',
              accent: AppColors.blue,
              trailing: IconButton(
                onPressed: () => context.push('/settings'),
                icon: Icon(Icons.tune, size: 20, color: AppColors.ink),
              ),
            ),
            const SizedBox(height: 24),
            if (!auth.isAuthenticated)
              const _GuestBlock()
            else ...[
              _IdentityBlock(
                profile: profile,
                fallbackName: auth.user?.email?.split('@').first ?? 'مستخدم',
              ),
              const SizedBox(height: 14),
              _WalletBlock(
                leaves: profile?.leaves ?? 0,
                onOpenShop: _openColorsShop,
              ),
              if (profile != null && !profile.identityComplete) ...[
                const SizedBox(height: 14),
                const _CompleteIdentityBlock(),
              ],
              const SizedBox(height: 28),
              const SectionHead(number: '01', title: 'سجلّ اختباراتك'),
              if (_loadingHistory)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                )
              else if (_history.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'لم تُجرِ أي اختبار بعد.',
                    style: AppType.ui(size: 12.5, color: AppColors.inkSoft),
                  ),
                )
              else
                for (final result in _history)
                  InkWell(
                    onTap: () =>
                        context.push('/personality-detail?code=${result.code}'),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppColors.hairline),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                result.code,
                                style: AppType.mono(size: 16, letterSpacing: 3),
                              ),
                              Container(
                                height: 3,
                                width: 52,
                                color: AppColors.accentForCode(result.code),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Text(
                            result.testType == 'full' ? 'كامل' : 'سريع',
                            style: AppType.ui(
                              size: 11,
                              color: AppColors.inkMuted,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            arabicDateLine(result.createdAt),
                            style: AppType.ui(
                              size: 11,
                              color: AppColors.inkSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              const SizedBox(height: 28),
              GhostButton(
                label: 'تسجيل الخروج',
                expanded: true,
                onTap: () async {
                  await context.read<AuthProvider>().signOut();
                  if (context.mounted) context.go('/home');
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GuestBlock extends StatelessWidget {
  const _GuestBlock();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Container(
      decoration: BoxDecoration(border: Border.all(color: AppColors.hairline)),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'أنت تتصفح كضيف.',
            style: AppType.display(size: 24, height: 1.4),
          ),
          const SizedBox(height: 6),
          Text(
            'سجّل الدخول لحفظ نتائجك، والمشاركة في المجتمع، وجمع الأوراق 🍃',
            style: AppType.ui(size: 13, color: AppColors.inkMuted, height: 1.8),
          ),
          const SizedBox(height: 16),
          InkButton(
            label: auth.isLoading
                ? 'جارٍ الدخول…'
                : 'تسجيل الدخول بحساب Google',
            expanded: true,
            onTap: auth.isLoading
                ? null
                : () async {
                    final provider = context.read<AuthProvider>();
                    final ok = await provider.signInWithGoogle();
                    if (!ok && context.mounted && provider.lastError != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'تعذّر الدخول:\n${provider.lastError}',
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                          ),
                          duration: const Duration(seconds: 10),
                        ),
                      );
                    }
                  },
          ),
        ],
      ),
    );
  }
}

class _IdentityBlock extends StatelessWidget {
  final Profile? profile;
  final String fallbackName;

  const _IdentityBlock({required this.profile, required this.fallbackName});

  @override
  Widget build(BuildContext context) {
    final economy = context.watch<EconomyProvider>();
    final personality = profile?.personalityType;
    final accent = AppColors.accentForCode(personality);
    final name = profile?.username ?? fallbackName;
    final nameColor = AppColors.nameColor(profile?.nameColor);
    final avatarPath = economy.avatarPath(profile?.avatarId);

    return Container(
      decoration: BoxDecoration(border: Border.all(color: AppColors.hairline)),
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AvatarView(
            assetPath: avatarPath,
            personality: personality,
            fallbackText: name.isNotEmpty ? name[0] : '•',
            size: 64,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppType.display(
                    size: 21,
                    height: 1.3,
                    color: nameColor,
                  ),
                ),
                const SizedBox(height: 4),
                if (personality != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        personality,
                        style: AppType.mono(size: 16, letterSpacing: 4),
                      ),
                      Container(height: 4, width: 64, color: accent),
                    ],
                  )
                else
                  GestureDetector(
                    onTap: () => context.go('/test-select'),
                    child: Text(
                      'اعمل الاختبار واعرف نمطك ←',
                      style: AppType.ui(
                        size: 12,
                        weight: FontWeight.w700,
                        color: AppColors.violet,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.push('/profile-setup'),
            icon: Icon(
              Icons.edit_outlined,
              size: 18,
              color: AppColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletBlock extends StatelessWidget {
  final int leaves;
  final VoidCallback onOpenShop;

  const _WalletBlock({required this.leaves, required this.onOpenShop});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: AppColors.hairline)),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Icon(Icons.eco, size: 20, color: AppColors.green),
          const SizedBox(width: 8),
          Text(
            '${arabicDigits(leaves)} ورقة',
            style: AppType.ui(size: 15, weight: FontWeight.w700),
          ),
          const Spacer(),
          GhostButton(label: 'متجر الألوان', onTap: onOpenShop),
        ],
      ),
    );
  }
}

class _CompleteIdentityBlock extends StatelessWidget {
  const _CompleteIdentityBlock();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: AppColors.hairline)),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'أكمل هويتك',
                  style: AppType.display(size: 17, height: 1.3),
                ),
                Text(
                  'اختر أفاتارك ليظهر بجانب خواطرك وتعليقاتك',
                  style: AppType.ui(size: 11.5, color: AppColors.inkMuted),
                ),
              ],
            ),
          ),
          InkButton(
            label: 'ابدأ',
            shadowColor: AppColors.green,
            onTap: () => context.push('/profile-setup'),
          ),
        ],
      ),
    );
  }
}

/// متجر ألوان الاسم
class _ColorsShopSheet extends StatefulWidget {
  const _ColorsShopSheet();

  @override
  State<_ColorsShopSheet> createState() => _ColorsShopSheetState();
}

class _ColorsShopSheetState extends State<_ColorsShopSheet> {
  bool _busy = false;

  Future<void> _buy(String color) async {
    if (_busy) return;
    setState(() => _busy = true);
    final result = await context.read<EconomyProvider>().buyColor(color);
    if (!mounted) return;
    if (result.ok) {
      final profileProvider = context.read<ProfileProvider>();
      await profileProvider.refresh();
      // اللون الجديد يظهر فوراً على خواطري وتعليقاتي القديمة
      if (mounted) {
        context.read<PostsProvider>().refreshAfterIdentityChange(
          myType: profileProvider.profile?.personalityType,
        );
      }
    }
    if (mounted) {
      setState(() => _busy = false);
      if (!result.ok) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final economy = context.watch<EconomyProvider>();
    final profile = context.watch<ProfileProvider>().profile;

    return SafeArea(
      // حد أقصى 85% من الشاشة مع تمرير داخلي — لا فيض مهما صغرت الشاشة
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('متجر ألوان الاسم', style: AppType.display(size: 21)),
                  const Spacer(),
                  Icon(Icons.eco, size: 16, color: AppColors.green),
                  const SizedBox(width: 4),
                  Text(
                    arabicDigits(profile?.leaves ?? 0),
                    style: AppType.ui(size: 13.5, weight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'اسمك بلونك في كل المجتمع',
                style: AppType.ui(size: 12, color: AppColors.inkSoft),
              ),
              const SizedBox(height: 12),
              const Hairline(),
              for (final item in economy.colors)
                Builder(
                  builder: (context) {
                    final owned =
                        profile?.unlockedColors.contains(item.color) ?? false;
                    final active = profile?.nameColor == item.color;
                    return Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppColors.hairline),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            color: AppColors.nameColor(item.color),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            AppColors.nameColorLabel(item.color),
                            style: AppType.ui(
                              size: 14,
                              weight: FontWeight.w700,
                              color: AppColors.nameColor(item.color),
                            ),
                          ),
                          const Spacer(),
                          if (active)
                            Text(
                              'مستخدم ✓',
                              style: AppType.ui(
                                size: 12,
                                weight: FontWeight.w700,
                              ),
                            )
                          else
                            GestureDetector(
                              onTap: () => _buy(item.color),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: owned
                                      ? Colors.transparent
                                      : AppColors.ink,
                                  border: Border.all(color: AppColors.ink),
                                ),
                                child: Text(
                                  owned
                                      ? 'استخدام'
                                      : '${arabicDigits(item.price)} 🍃',
                                  style: AppType.ui(
                                    size: 11.5,
                                    weight: FontWeight.w700,
                                    color: owned
                                        ? AppColors.ink
                                        : AppColors.paper,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
