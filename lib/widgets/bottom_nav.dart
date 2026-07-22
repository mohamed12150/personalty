import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants.dart';
import '../core/theme.dart';

/// الهيكل الرئيسي: يحتفظ بحالة كل تبويب (موضع التمرير والمحتوى)
/// فالتنقل بين التبويبات فوري بلا إعادة تحميل.
class AppShell extends StatelessWidget {
  final StatefulNavigationShell shell;

  const AppShell({super.key, required this.shell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: _NavBar(
        currentIndex: shell.currentIndex,
        onTap: (index) => shell.goBranch(
          index,
          // النقر على التبويب النشط يعيدك لأعلى فرعه
          initialLocation: index == shell.currentIndex,
        ),
      ),
    );
  }
}

/// شريط تنقل عائم بأسلوب المطبعة:
/// بطاقة ورقية بحد رفيع وظل إزاحة، والعنصر النشط بلوك مصمت بلون قسمه
class _NavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _NavBar({required this.currentIndex, required this.onTap});

  static List<({IconData icon, IconData activeIcon, String label, Color accent})>
      get _items => [
            (
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: 'الرئيسية',
              accent: AppColors.violet,
            ),
            (
              icon: Icons.assignment_outlined,
              activeIcon: Icons.assignment,
              label: 'الاختبار',
              accent: AppColors.green,
            ),
            (
              icon: Icons.forum_outlined,
              activeIcon: Icons.forum_rounded,
              label: 'المجتمع',
              accent: AppColors.orange,
            ),
            (
              icon: Icons.person_outline,
              activeIcon: Icons.person_rounded,
              label: 'أنا',
              accent: AppColors.blue,
            ),
          ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.paper,
          border: Border.all(color: AppColors.ink, width: 1.2),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.14),
              offset: const Offset(-3, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (var i = 0; i < _items.length; i++)
              _NavItem(
                item: _items[i],
                isSelected: currentIndex == i,
                onTap: () => onTap(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final ({IconData icon, IconData activeIcon, String label, Color accent}) item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 7),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: isSelected ? item.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? item.activeIcon : item.icon,
                size: 20,
                color: isSelected
                    ? AppColors.onColor(item.accent)
                    : AppColors.inkSoft,
              ),
              const SizedBox(height: 3),
              Text(
                item.label,
                maxLines: 1,
                style: AppType.ui(
                  size: 9.5,
                  weight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.onColor(item.accent)
                      : AppColors.inkSoft,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
