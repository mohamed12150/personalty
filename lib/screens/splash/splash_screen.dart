import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../providers/test_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    context.read<TestProvider>().loadPersisted();
    final prefs = SharedPreferences.getInstance();
    await Future.delayed(const Duration(milliseconds: 1600));
    final seenOnboarding =
        (await prefs).getBool('seen_onboarding') ?? false;
    if (!mounted) return;
    context.go(seenOnboarding ? '/home' : '/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'شخصيتي',
              style: AppType.display(size: 46, weight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            // القاعدة المزدوجة — توقيع المطبعة
            Column(
              children: [
                Container(height: 3, width: 130, color: AppColors.ink),
                const SizedBox(height: 3),
                Container(height: 1, width: 130, color: AppColors.hairline),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'اعرف من أنت.',
              style: AppType.ui(size: 13, color: AppColors.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}
