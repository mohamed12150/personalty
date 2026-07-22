import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/catalog_items.dart';
import '../../providers/auth_provider.dart';
import '../../providers/economy_provider.dart';
import '../../providers/posts_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/avatar_view.dart';
import '../../widgets/editorial.dart';

/// إعداد الهوية: النوع، الفئة العمرية، واختيار الأفاتار
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  String _gender = 'none'; // male | female | none
  String? _ageRange;
  int? _avatarId;
  String _packTab = 'man';
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  static const _ageRanges = ['13-17', '18-24', '25-34', '35-44', '45+'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EconomyProvider>().fetchCatalogs();
      final profile = context.read<ProfileProvider>().profile;
      if (profile != null) {
        setState(() {
          _nameController.text = profile.username ?? '';
          _gender = profile.gender ?? 'none';
          _ageRange = profile.ageRange;
          _avatarId = profile.avatarId;
          if (profile.gender == 'female') _packTab = 'girl';
        });
      }
    });
  }

  String get _visiblePack {
    if (_gender == 'male') return 'man';
    if (_gender == 'female') return 'girl';
    return _packTab;
  }

  Future<void> _onAvatarTap(AvatarItem item) async {
    final profile = context.read<ProfileProvider>().profile;
    final owned =
        !item.isPremium || (profile?.unlockedAvatars.contains(item.id) ?? false);

    if (owned) {
      setState(() => _avatarId = item.id);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: AppColors.hairline),
        ),
        title: Text('أفاتار مميز', style: AppType.display(size: 20)),
        content: Text(
          'فتح هذا الأفاتار يكلف ${arabicDigits(item.price)} ورقة 🍃\nرصيدك الحالي: ${arabicDigits(profile?.leaves ?? 0)} ورقة',
          style: AppType.ui(size: 13.5, height: 1.8),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: AppType.ui(color: AppColors.inkSoft)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'افتحه',
              style: AppType.ui(weight: FontWeight.w700, color: AppColors.green),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final result = await context.read<EconomyProvider>().buyAvatar(item.id);
    if (!mounted) return;
    if (result.ok) {
      await context.read<ProfileProvider>().refresh();
      if (mounted) setState(() => _avatarId = item.id);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.message)));
    }
  }

  Future<void> _save() async {
    final auth = context.read<AuthProvider>();
    final userId = auth.user?.id;
    if (userId == null || _avatarId == null || _saving) return;

    setState(() => _saving = true);
    final profileProvider = context.read<ProfileProvider>();

    // الاسم المستعار — ينتشر على المحتوى القديم من السيرفر
    final newName = _nameController.text.trim();
    final currentName = profileProvider.profile?.username ?? '';
    if (newName.isNotEmpty && newName != currentName) {
      final nameError = await profileProvider.setUsername(newName);
      if (nameError != null) {
        if (mounted) {
          setState(() => _saving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(nameError == 'invalid_name'
                  ? 'الاسم يجب أن يكون بين حرفين و٢٠ حرفاً'
                  : 'تعذّر حفظ الاسم — حاول مجدداً'),
            ),
          );
        }
        return;
      }
    }

    final ok = await profileProvider.updateIdentity(
      userId,
      gender: _gender == 'none' ? null : _gender,
      ageRange: _ageRange,
      avatarId: _avatarId,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      // تحديث الفيد ليظهر الاسم والأفاتار الجديدان على المحتوى القديم
      context.read<PostsProvider>().refreshAfterIdentityChange(
            myType: profileProvider.profile?.personalityType,
          );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر الحفظ — حاول مجدداً')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAuthenticated) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('سجّل الدخول أولاً لإعداد هويتك.',
                    style: AppType.display(size: 20)),
                const SizedBox(height: 16),
                InkButton(label: 'تسجيل الدخول', onTap: () => context.push('/auth')),
              ],
            ),
          ),
        ),
      );
    }

    final economy = context.watch<EconomyProvider>();
    final profile = context.watch<ProfileProvider>().profile;
    final packAvatars = economy.avatarsOfPack(_visiblePack);

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
                Row(
                  children: [
                    Icon(Icons.eco, size: 16, color: AppColors.green),
                    const SizedBox(width: 4),
                    Text(
                      arabicDigits(profile?.leaves ?? 0),
                      style: AppType.ui(size: 13, weight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Masthead(
              title: 'عرّفنا بنفسك',
              accent: AppColors.blue,
              subtitle: 'اسمك وأفاتارك يتغيران وقتما تشاء',
            ),
            const SizedBox(height: 24),

            const SectionHead(number: '01', title: 'اسمك المستعار'),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.hairline),
              ),
              child: TextField(
                controller: _nameController,
                maxLength: 20,
                style: AppType.ui(size: 14.5, weight: FontWeight.w700),
                decoration: InputDecoration(
                  hintText: 'اسم يعبّر عنك…',
                  hintStyle: AppType.ui(size: 13.5, color: AppColors.inkSoft),
                  border: InputBorder.none,
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 11),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.shield_outlined,
                    size: 13, color: AppColors.inkSoft),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'لا تستخدم اسمك الحقيقي — المجتمع هنا بالأسماء المستعارة أأمن وأمتع',
                    style: AppType.ui(size: 11, color: AppColors.inkSoft),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            const SectionHead(number: '02', title: 'أنت…'),
            if (profile?.identitySet ?? false)
              _LockedValueRow(
                value: profile?.gender == 'male'
                    ? 'ذكر'
                    : profile?.gender == 'female'
                        ? 'أنثى'
                        : 'لم تفصح',
              )
            else ...[
              _ChoiceRow(
                label: 'ذكر',
                isSelected: _gender == 'male',
                onTap: () => setState(() => _gender = 'male'),
              ),
              _ChoiceRow(
                label: 'أنثى',
                isSelected: _gender == 'female',
                onTap: () => setState(() {
                  _gender = 'female';
                  _packTab = 'girl';
                }),
              ),
              _ChoiceRow(
                label: 'أفضّل عدم الإفصاح',
                isSelected: _gender == 'none',
                onTap: () => setState(() => _gender = 'none'),
              ),
              const SizedBox(height: 6),
              Text(
                'يُحدَّد مرة واحدة ولا يمكن تغييره لاحقاً',
                style: AppType.ui(size: 10.5, color: AppColors.inkSoft),
              ),
            ],
            const SizedBox(height: 24),

            const SectionHead(number: '03', title: 'فئتك العمرية'),
            if (profile?.identitySet ?? false)
              _LockedValueRow(
                value: profile?.ageRange != null
                    ? arabicDigits(profile!.ageRange!).replaceAll('-', ' – ')
                    : 'لم تفصح',
              )
            else ...[
              for (final range in _ageRanges)
                _ChoiceRow(
                  label: arabicDigits(range).replaceAll('-', ' – '),
                  isSelected: _ageRange == range,
                  onTap: () => setState(() => _ageRange = range),
                ),
              _ChoiceRow(
                label: 'أفضّل عدم الإفصاح',
                isSelected: _ageRange == null,
                onTap: () => setState(() => _ageRange = null),
              ),
              const SizedBox(height: 6),
              Text(
                'تُحدَّد مرة واحدة ولا يمكن تغييرها لاحقاً',
                style: AppType.ui(size: 10.5, color: AppColors.inkSoft),
              ),
            ],
            const SizedBox(height: 24),

            const SectionHead(number: '04', title: 'اختر أفاتارك'),
            const SizedBox(height: 12),
            if (_gender == 'none')
              Row(
                children: [
                  _PackTab(
                    label: 'شباب',
                    isActive: _packTab == 'man',
                    onTap: () => setState(() => _packTab = 'man'),
                  ),
                  const SizedBox(width: 8),
                  _PackTab(
                    label: 'بنات',
                    isActive: _packTab == 'girl',
                    onTap: () => setState(() => _packTab = 'girl'),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            if (!economy.loaded)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.ink),
                  ),
                ),
              )
            else
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.78,
                children: [
                  for (final item in packAvatars)
                    _AvatarTile(
                      item: item,
                      isSelected: _avatarId == item.id,
                      isOwned: !item.isPremium ||
                          (profile?.unlockedAvatars.contains(item.id) ?? false),
                      onTap: () => _onAvatarTap(item),
                    ),
                ],
              ),
            const SizedBox(height: 28),
            Opacity(
              opacity: _avatarId == null ? 0.35 : 1,
              child: InkButton(
                label: _saving ? 'جارٍ الحفظ…' : 'حفظ هويتي',
                expanded: true,
                shadowColor: AppColors.green,
                onTap: _avatarId == null || _saving ? null : _save,
              ),
            ),
            if (_avatarId == null) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'اختر أفاتاراً أولاً',
                  style: AppType.ui(size: 11.5, color: AppColors.inkSoft),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// قيمة مقفولة بعد أول حفظ
class _LockedValueRow extends StatelessWidget {
  final String value;

  const _LockedValueRow({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.hairline)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(Icons.lock_outline, size: 14, color: AppColors.inkSoft),
          const SizedBox(width: 12),
          Text(value, style: AppType.ui(size: 14, weight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChoiceRow({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.hairline)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.green : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.green : AppColors.inkSoft,
                  width: 1.4,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: AppType.ui(
                size: 14,
                weight: isSelected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _PackTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.ink : Colors.transparent,
          border: Border.all(
            color: isActive ? AppColors.ink : AppColors.hairline,
          ),
        ),
        child: Text(
          label,
          style: AppType.ui(
            size: 12.5,
            weight: FontWeight.w700,
            color: isActive ? AppColors.paper : AppColors.inkMuted,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _AvatarTile extends StatelessWidget {
  final AvatarItem item;
  final bool isSelected;
  final bool isOwned;
  final VoidCallback onTap;

  const _AvatarTile({
    required this.item,
    required this.isSelected,
    required this.isOwned,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected ? AppColors.green : AppColors.hairline,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  clipBehavior: Clip.antiAlias,
                  width: double.infinity,
                  child: Opacity(
                    opacity: isOwned ? 1 : 0.45,
                    child: AvatarView(
                      assetPath: item.assetPath,
                      size: 72,
                    ),
                  ),
                ),
                if (!isOwned)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Icon(Icons.lock_outline,
                        size: 14, color: AppColors.ink),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          if (!isOwned)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.eco, size: 10, color: AppColors.green),
                const SizedBox(width: 2),
                Text(
                  arabicDigits(item.price),
                  style: AppType.ui(size: 10, weight: FontWeight.w700),
                ),
              ],
            )
          else
            const SizedBox(height: 12),
        ],
      ),
    );
  }
}
