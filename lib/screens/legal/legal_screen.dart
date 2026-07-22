import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../widgets/editorial.dart';

/// عرض سياسة الخصوصية أو شروط الاستخدام بأسلوب المطبعة
class LegalScreen extends StatelessWidget {
  final String title;
  final String content;

  const LegalScreen({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    final sections = content.trim().split('\n\n');

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: Icon(Icons.arrow_back,
                      size: 20, color: AppColors.ink),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Masthead(title: title, accent: AppColors.blue),
            const SizedBox(height: 20),
            for (final section in sections) ...[
              Builder(builder: (context) {
                final isHeading = RegExp(r'^[٠-٩0-9]+\s*—').hasMatch(section);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Text(
                    section,
                    style: isHeading
                        ? AppType.ui(size: 13.5, height: 1.9)
                        : AppType.ui(
                            size: 13,
                            height: 1.9,
                            color: AppColors.inkMuted,
                          ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
