import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/auth_screen.dart';
import '../screens/test/test_select_screen.dart';
import '../screens/test/test_screen.dart';
import '../screens/test/test_loading_screen.dart';
import '../screens/test/result_screen.dart';
import '../screens/test/personality_detail_screen.dart';
import '../screens/articles/article_detail_screen.dart';
import '../screens/community/community_screen.dart';
import '../screens/community/compose_screen.dart';
import '../screens/community/post_detail_screen.dart';
import '../screens/community/public_profile_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/profile_setup_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/puzzle/puzzle_screen.dart';
import '../screens/legal/legal_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../core/legal_texts.dart';
import '../widgets/bottom_nav.dart';

/// انتقال موحّد: الصفحة ترتفع قليلاً مع تلاشٍ — إحساس ورقة تُوضع فوق أخرى
CustomTransitionPage<T> _paperPage<T>(GoRouterState state, Widget child) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 190),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.035),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// انتقال بلا حركة — للشاشات الجذرية
CustomTransitionPage<T> _instantPage<T>(GoRouterState state, Widget child) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
    transitionsBuilder: (_, __, ___, child) => child,
  );
}

class AppRouter {
  /// يُنشأ من جديد عند تبديل وضع العرض ليضمن إعادة بناء كل الشاشات
  /// بالألوان الجديدة، مع البقاء في نفس المكان
  static GoRouter create({String initialLocation = '/splash'}) => GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) =>
            _instantPage(state, const SplashScreen()),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) =>
            _paperPage(state, const OnboardingScreen()),
      ),
      GoRoute(
        path: '/auth',
        pageBuilder: (context, state) => _paperPage(state, const AuthScreen()),
      ),

      // التبويبات الأربعة — كل تبويب يحتفظ بحالته
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                pageBuilder: (context, state) =>
                    _instantPage(state, const HomeScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/test-select',
                pageBuilder: (context, state) =>
                    _instantPage(state, const TestSelectScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/community',
                pageBuilder: (context, state) =>
                    _instantPage(state, const CommunityScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                pageBuilder: (context, state) =>
                    _instantPage(state, const ProfileScreen()),
              ),
            ],
          ),
        ],
      ),

      // شاشات تُفتح فوق كل شيء
      GoRoute(
        path: '/test',
        pageBuilder: (context, state) => _paperPage(state, const TestScreen()),
      ),
      GoRoute(
        path: '/loading',
        pageBuilder: (context, state) =>
            _paperPage(state, const TestLoadingScreen()),
      ),
      GoRoute(
        path: '/result',
        pageBuilder: (context, state) =>
            _paperPage(state, const ResultScreen()),
      ),
      GoRoute(
        path: '/personality-detail',
        pageBuilder: (context, state) => _paperPage(
          state,
          PersonalityDetailScreen(code: state.uri.queryParameters['code']),
        ),
      ),
      GoRoute(
        path: '/puzzle',
        pageBuilder: (context, state) =>
            _paperPage(state, const PuzzleScreen()),
      ),
      GoRoute(
        path: '/notifications',
        pageBuilder: (context, state) =>
            _paperPage(state, const NotificationsScreen()),
      ),
      GoRoute(
        path: '/compose',
        pageBuilder: (context, state) =>
            _paperPage(state, const ComposeScreen()),
      ),
      GoRoute(
        path: '/post/:id',
        pageBuilder: (context, state) => _paperPage(
          state,
          PostDetailScreen(
            postId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
          ),
        ),
      ),
      GoRoute(
        path: '/user/:id',
        pageBuilder: (context, state) => _paperPage(
          state,
          PublicProfileScreen(userId: state.pathParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/article-detail/:id',
        pageBuilder: (context, state) => _paperPage(
          state,
          ArticleDetailScreen(
            articleId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
          ),
        ),
      ),
      GoRoute(
        path: '/profile-setup',
        pageBuilder: (context, state) =>
            _paperPage(state, const ProfileSetupScreen()),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) =>
            _paperPage(state, const SettingsScreen()),
      ),
      GoRoute(
        path: '/privacy',
        pageBuilder: (context, state) => _paperPage(
          state,
          const LegalScreen(
            title: LegalTexts.privacyTitle,
            content: LegalTexts.privacy,
          ),
        ),
      ),
      GoRoute(
        path: '/terms',
        pageBuilder: (context, state) => _paperPage(
          state,
          const LegalScreen(
            title: LegalTexts.termsTitle,
            content: LegalTexts.terms,
          ),
        ),
      ),
    ],
  );
}

