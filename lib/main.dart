import 'package:flutter/material.dart';
// ignore: unnecessary_import
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/constants.dart';
import 'core/push_service.dart';
import 'core/theme.dart';
import 'core/router.dart';
import 'providers/auth_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/articles_provider.dart';
import 'providers/test_provider.dart';
import 'providers/economy_provider.dart';
import 'providers/posts_provider.dart';
import 'providers/notifications_provider.dart';
import 'providers/puzzle_provider.dart';
import 'providers/theme_provider.dart';
import 'core/supabase_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseHelper.initialize();
  await PushService.init();

  // قراءة وضع العرض المحفوظ قبل أول رسم حتى لا تومض الشاشة
  final themeProvider = ThemeProvider();
  await themeProvider.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => ArticlesProvider()),
        ChangeNotifierProvider(create: (_) => TestProvider()),
        ChangeNotifierProvider(create: (_) => EconomyProvider()),
        ChangeNotifierProvider(create: (_) => PostsProvider()),
        ChangeNotifierProvider(create: (_) => PuzzleProvider()),
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),
      ],
      child: const ShakhsiyatiApp(),
    ),
  );
}

class ShakhsiyatiApp extends StatefulWidget {
  const ShakhsiyatiApp({super.key});

  @override
  State<ShakhsiyatiApp> createState() => _ShakhsiyatiAppState();
}

/// مفتاح عام لعرض شرائط التنبيه من أي مكان
final _messengerKey = GlobalKey<ScaffoldMessengerState>();

class _ShakhsiyatiAppState extends State<ShakhsiyatiApp> {
  late GoRouter _router;
  late ThemeProvider _theme;
  late bool _isDark;

  @override
  void initState() {
    super.initState();
    _theme = context.read<ThemeProvider>();
    _isDark = _theme.isDark;
    AppColors.dark = _isDark;
    _router = AppRouter.create();
    _theme.addListener(_onThemeChanged);
  }

  /// عند تبديل الوضع نُعيد إنشاء شجرة التنقل بالكامل فتُبنى كل الشاشات
  /// من جديد بالألوان الجديدة — مع البقاء في نفس الصفحة
  void _onThemeChanged() {
    if (_theme.isDark == _isDark) return;
    _isDark = _theme.isDark;
    AppColors.dark = _isDark;

    String location = '/home';
    try {
      location = _router.routerDelegate.currentConfiguration.uri.toString();
    } catch (_) {
      // في أسوأ الحالات نعود للرئيسية
    }
    if (location.isEmpty || location == '/splash') location = '/home';

    // التبويبات تُفتح مباشرة، وأي شاشة أخرى تُفتح فوق الرئيسية
    // حتى يبقى زر الرجوع سليماً
    const tabs = {'/home', '/test-select', '/community', '/profile'};
    final isTab = tabs.contains(location);

    final old = _router;
    final fresh = AppRouter.create(
      initialLocation: isTab ? location : '/home',
    );
    setState(() => _router = fresh);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isTab) fresh.push(location);
      old.dispose();
    });
  }

  @override
  void dispose() {
    _theme.removeListener(_onThemeChanged);
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // الاشتراك ليُعاد بناء الثيم عند التبديل
    final themeProvider = context.watch<ThemeProvider>();
    AppColors.dark = themeProvider.isDark;

    return MaterialApp.router(
      title: 'شخصيتي',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _messengerKey,
      theme: AppTheme.build(),
      darkTheme: AppTheme.build(),
      themeMode: themeProvider.mode,
      routerConfig: _router,
      builder: (context, child) {
        // متابعة حالة الدخول لجلب البروفايل أو مسحه
        final authUser = context.watch<AuthProvider>().user;
        final profileProvider = context.read<ProfileProvider>();
        if (authUser != null) {
          if (profileProvider.profile == null && !profileProvider.isLoading) {
            Future.microtask(() {
              profileProvider.fetchProfile(authUser.id);
              // ربط الجهاز بالحساب — الإشعارات الخارجية تستهدفه مباشرة
              PushService.login(authUser.id);
            });
          }
        } else if (profileProvider.profile != null) {
          final notifications = context.read<NotificationsProvider>();
          Future.microtask(() {
            profileProvider.clearProfile();
            notifications.clear();
            PushService.logout();
          });
        }

        // أيقونات شريط الحالة تتبع خلفية الوضع الحالي
        // إشعار وصل والتطبيق مفتوح → شريط تنبيه سريع
        final incoming = context.watch<NotificationsProvider>().incoming;
        if (incoming != null) {
          final notifications = context.read<NotificationsProvider>();
          Future.microtask(() {
            notifications.consumeIncoming();
            final messenger = _messengerKey.currentState;
            messenger?.hideCurrentSnackBar();
            messenger?.showSnackBar(
              SnackBar(
                content: Text(incoming.title),
                duration: const Duration(seconds: 4),
                action: incoming.route == null
                    ? null
                    : SnackBarAction(
                        label: 'عرض',
                        textColor: AppColors.paper,
                        onPressed: () => _router.push(incoming.route!),
                      ),
              ),
            );
          });
        }

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: themeProvider.isDark
              ? SystemUiOverlayStyle.light.copyWith(
                  statusBarColor: Colors.transparent,
                  systemNavigationBarColor: AppColors.paper,
                  systemNavigationBarIconBrightness: Brightness.light,
                )
              : SystemUiOverlayStyle.dark.copyWith(
                  statusBarColor: Colors.transparent,
                  systemNavigationBarColor: AppColors.paper,
                  systemNavigationBarIconBrightness: Brightness.dark,
                ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          ),
        );
      },
    );
  }
}
