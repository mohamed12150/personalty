import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/editorial.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // عند نجاح الدخول نعود للرئيسية تلقائياً
    if (auth.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/home');
      });
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () =>
                        context.canPop() ? context.pop() : context.go('/home'),
                    icon: Icon(Icons.close,
                        size: 20, color: AppColors.ink),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                'احفظ تقريرك.',
                style: AppType.display(size: 40, weight: FontWeight.w700, height: 1.3),
              ),
              const SizedBox(height: 12),
              Text(
                'بحساب واحد تحتفظ بنتائجك وتتابع تغيّر شخصيتك مع الوقت.',
                style: AppType.ui(size: 14, color: AppColors.inkMuted, height: 1.9),
              ),
              const SizedBox(height: 24),
              for (final entry in const [
                ('01', 'نتائجك محفوظة، وتاريخ كامل لاختباراتك'),
                ('02', 'الإعجاب والتعليق باسمك ونمط شخصيتك'),
                ('03', 'محتوى يُنتقى لنمطك أنت تحديداً'),
              ])
                Container(
                  decoration: BoxDecoration(
                    border:
                        Border(bottom: BorderSide(color: AppColors.hairline)),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Text(
                        arabicDigits(entry.$1),
                        style: AppType.ui(
                          size: 11,
                          weight: FontWeight.w700,
                          color: AppColors.violet,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(entry.$2, style: AppType.ui(size: 13.5)),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              InkButton(
                label: auth.isLoading
                    ? 'جارٍ الدخول…'
                    : 'المتابعة بحساب Google',
                expanded: true,
                shadowColor: AppColors.violet,
                onTap: auth.isLoading
                    ? null
                    : () async {
                        final provider = context.read<AuthProvider>();
                        final ok = await provider.signInWithGoogle();
                        if (!ok &&
                            context.mounted &&
                            provider.lastError != null) {
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
              const SizedBox(height: 12),
              GhostButton(
                label: 'المتابعة كضيف',
                expanded: true,
                onTap: () => context.go('/home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
