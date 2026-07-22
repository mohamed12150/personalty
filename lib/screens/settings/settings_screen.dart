import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/editorial.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  /// حذف الحساب: تأكيد مشدد بكتابة كلمة "حذف"
  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: AppColors.hairline),
        ),
        title: Text('حذف الحساب نهائياً؟', style: AppType.display(size: 20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'سيُحذف حسابك وكل نتائجك وخواطرك وتعليقاتك وأوراقك نهائياً، ولا يمكن التراجع.\n\nللتأكيد اكتب: حذف',
              style: AppType.ui(size: 13, height: 1.8),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: AppType.ui(size: 14, weight: FontWeight.w700),
              decoration: InputDecoration(
                hintText: 'حذف',
                hintStyle: AppType.ui(size: 13, color: AppColors.inkSoft),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.hairline),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('تراجع', style: AppType.ui(color: AppColors.inkSoft)),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim() == 'حذف'),
            child: Text(
              'احذف حسابي',
              style: AppType.ui(
                weight: FontWeight.w700,
                color: const Color(0xFFC0392B),
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final ok = await context.read<AuthProvider>().deleteAccount();
    if (!context.mounted) return;
    if (ok) {
      context.go('/home');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حُذف حسابك — نتمنى رؤيتك مجدداً 🤍')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر الحذف — حاول مجدداً')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
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
              ],
            ),
            const SizedBox(height: 8),
            const Masthead(title: 'الإعدادات'),
            const SizedBox(height: 20),

            // وضع العرض
            const SectionHead(number: '01', title: 'المظهر'),
            const SizedBox(height: 12),
            const _ThemeModePicker(),
            const SizedBox(height: 24),

            const SectionHead(number: '02', title: 'الإشعارات'),
            _ToggleRow(
              icon: Icons.volume_up_outlined,
              label: 'صوت الإشعارات',
              note: 'نغمة قصيرة عند وصول تفاعل جديد',
              value: context.watch<NotificationsProvider>().soundEnabled,
              onChanged: (v) =>
                  context.read<NotificationsProvider>().setSoundEnabled(v),
            ),
            const SizedBox(height: 24),

            const SectionHead(number: '03', title: 'الحساب'),
            _SettingsRow(
              icon: Icons.person_outline,
              label: auth.isAuthenticated ? 'تسجيل الخروج' : 'تسجيل الدخول',
              onTap: () async {
                if (auth.isAuthenticated) {
                  await context.read<AuthProvider>().signOut();
                  if (context.mounted) context.go('/home');
                } else {
                  context.push('/auth');
                }
              },
            ),
            _SettingsRow(
              icon: Icons.replay_outlined,
              label: 'إعادة الاختبار',
              onTap: () => context.go('/test-select'),
            ),
            _SettingsRow(
              icon: Icons.explore_outlined,
              label: 'جولة التطبيق',
              onTap: () => context.push('/onboarding'),
            ),
            _SettingsRow(
              icon: Icons.privacy_tip_outlined,
              label: 'سياسة الخصوصية',
              onTap: () => context.push('/privacy'),
            ),
            _SettingsRow(
              icon: Icons.gavel_outlined,
              label: 'شروط الاستخدام',
              onTap: () => context.push('/terms'),
            ),
            _SettingsRow(
              icon: Icons.info_outline,
              label: 'عن التطبيق',
              onTap: () => showAboutDialog(
                context: context,
                applicationName: 'شخصيتي',
                applicationVersion: '1.0.0',
                children: [
                  Text(
                    'تطبيق عربي لاكتشاف نمط شخصيتك من بين ستة عشر نمطاً، بمحتوى يُكتب خصيصاً لك.',
                    style: AppType.ui(size: 13, height: 1.8),
                  ),
                ],
              ),
            ),

            if (auth.isAuthenticated) ...[
              const SizedBox(height: 26),
              const SectionHead(number: '04', title: 'منطقة الخطر'),
              _SettingsRow(
                icon: Icons.delete_forever_outlined,
                label: 'حذف الحساب نهائياً',
                onTap: () => _confirmDeleteAccount(context),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// اختيار وضع العرض: فاتح / داكن / حسب النظام
class _ThemeModePicker extends StatelessWidget {
  const _ThemeModePicker();

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    const options = [
      (mode: ThemeMode.light, label: 'فاتح', icon: Icons.wb_sunny_outlined),
      (mode: ThemeMode.dark, label: 'داكن', icon: Icons.nightlight_outlined),
      (mode: ThemeMode.system, label: 'النظام', icon: Icons.phone_android),
    ];

    return Row(
      children: [
        for (final option in options) ...[
          Expanded(
            child: GestureDetector(
              onTap: () =>
                  context.read<ThemeProvider>().setMode(option.mode),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: themeProvider.mode == option.mode
                      ? AppColors.ink
                      : Colors.transparent,
                  border: Border.all(
                    color: themeProvider.mode == option.mode
                        ? AppColors.ink
                        : AppColors.hairline,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      option.icon,
                      size: 19,
                      color: themeProvider.mode == option.mode
                          ? AppColors.paper
                          : AppColors.inkMuted,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      option.label,
                      style: AppType.ui(
                        size: 11.5,
                        weight: FontWeight.w700,
                        color: themeProvider.mode == option.mode
                            ? AppColors.paper
                            : AppColors.inkMuted,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (option.mode != ThemeMode.system) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

/// صف بمفتاح تشغيل/إيقاف
class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String note;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.note,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.hairline)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 19, color: AppColors.ink),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppType.ui(size: 14, weight: FontWeight.w600)),
                Text(note,
                    style: AppType.ui(size: 11, color: AppColors.inkSoft)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.paper,
            activeTrackColor: AppColors.green,
            inactiveThumbColor: AppColors.paper,
            inactiveTrackColor: AppColors.inkSoft,
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SettingsRow({
    required this.icon,
    required this.label,
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
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Row(
          children: [
            Icon(icon, size: 19, color: AppColors.ink),
            const SizedBox(width: 12),
            Text(label, style: AppType.ui(size: 14, weight: FontWeight.w600)),
            const Spacer(),
            Icon(Icons.arrow_back_ios_new,
                size: 12, color: AppColors.inkSoft),
          ],
        ),
      ),
    );
  }
}
