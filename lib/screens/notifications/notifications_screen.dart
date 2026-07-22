import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/app_notification.dart';
import '../../providers/auth_provider.dart';
import '../../providers/economy_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../widgets/avatar_view.dart';
import '../../widgets/editorial.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<NotificationsProvider>();
      context.read<EconomyProvider>().fetchCatalogs();
      await provider.fetch();
      // تُقرأ بمجرد فتح الصفحة
      if (mounted) provider.markAllRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationsProvider>();
    final isGuest = !context.watch<AuthProvider>().isAuthenticated;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.ink,
          onRefresh: () => context.read<NotificationsProvider>().fetch(),
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
              Masthead(
                title: 'الإشعارات',
                accent: AppColors.violet,
                subtitle: 'ما فاتك من تفاعل ومحتوى',
              ),
              const SizedBox(height: 16),

              if (isGuest)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 50),
                  child: Column(
                    children: [
                      Text('سجّل الدخول لتصلك إشعاراتك.',
                          style: AppType.display(size: 19)),
                      const SizedBox(height: 14),
                      InkButton(
                        label: 'تسجيل الدخول',
                        onTap: () => context.push('/auth'),
                      ),
                    ],
                  ),
                )
              else if (provider.isLoading && provider.items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.ink),
                    ),
                  ),
                )
              else if (provider.items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.notifications_none,
                            size: 30, color: AppColors.inkSoft),
                        const SizedBox(height: 10),
                        Text(
                          'لا إشعارات بعد.',
                          style:
                              AppType.ui(size: 13, color: AppColors.inkSoft),
                        ),
                      ],
                    ),
                  ),
                )
              else
                for (final item in provider.items)
                  _NotificationRow(item: item),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  final AppNotification item;

  const _NotificationRow({required this.item});

  IconData get _icon => switch (item.type) {
        'like' => Icons.favorite,
        'comment' => Icons.mode_comment,
        'support' => Icons.eco,
        'reply' => Icons.smart_toy_outlined,
        _ => Icons.article_outlined,
      };

  Color get _color => switch (item.type) {
        'like' => AppColors.orange,
        'comment' => AppColors.blue,
        'support' => AppColors.green,
        'reply' => AppColors.violet,
        _ => AppColors.ink,
      };

  @override
  Widget build(BuildContext context) {
    final economy = context.watch<EconomyProvider>();
    final route = item.route;

    return InkWell(
      onTap: route == null ? null : () => context.push(route),
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.hairline)),
          // خلفية خفيفة للإشعار غير المقروء
          color: item.isRead
              ? Colors.transparent
              : _color.withValues(alpha: 0.06),
        ),
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.type == 'article')
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.hairline),
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Icon(_icon, size: 17, color: AppColors.inkMuted),
              )
            else
              AvatarView(
                assetPath: economy.avatarPath(item.actorAvatarId),
                personality: item.actorPersonality,
                fallbackText: typeEmoji(item.actorPersonality),
                size: 36,
              ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_icon, size: 13, color: _color),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.ui(
                            size: 13,
                            weight: item.isRead
                                ? FontWeight.w500
                                : FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        arabicTimeAgo(item.createdAt),
                        style:
                            AppType.ui(size: 9.5, color: AppColors.inkSoft),
                      ),
                    ],
                  ),
                  if (item.preview != null && item.preview!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      item.preview!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.ui(
                        size: 12,
                        color: AppColors.inkMuted,
                        height: 1.7,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
