import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../providers/profile_provider.dart';
import '../../providers/test_provider.dart';

class TestLoadingScreen extends StatefulWidget {
  const TestLoadingScreen({super.key});

  @override
  State<TestLoadingScreen> createState() => _TestLoadingScreenState();
}

class _TestLoadingScreenState extends State<TestLoadingScreen> {
  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    final provider = context.read<TestProvider>();
    final profileProvider = context.read<ProfileProvider>();
    // لحظة قصيرة حتى لا تومض الشاشة
    await Future.wait([
      provider.submitTest(),
      Future.delayed(const Duration(milliseconds: 1400)),
    ]);
    // تحديث البروفايل في الذاكرة حتى تختفي دعوة "ما زلنا لا نعرف من أنت"
    await profileProvider.refresh();
    if (mounted) context.go('/result');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('نحلّل إجاباتك', style: AppType.display(size: 26)),
            const SizedBox(height: 6),
            Text(
              'ثوانٍ ونطبع تقريرك',
              style: AppType.ui(size: 12.5, color: AppColors.inkSoft),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 120,
              child: LinearProgressIndicator(
                minHeight: 2,
                color: AppColors.ink,
                backgroundColor: AppColors.hairline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
