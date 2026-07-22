import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/question.dart';
import '../../providers/test_provider.dart';
import '../../widgets/editorial.dart';

class TestScreen extends StatelessWidget {
  const TestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TestProvider>();

    if (provider.isLoadingQuestions) {
      return Scaffold(
        body: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.ink,
            ),
          ),
        ),
      );
    }

    if (provider.questions.isEmpty) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('تعذّر تحميل الأسئلة.', style: AppType.display(size: 20)),
                const SizedBox(height: 16),
                GhostButton(label: 'عودة', onTap: () => context.pop()),
              ],
            ),
          ),
        ),
      );
    }

    final question = provider.currentQuestion;
    final selected = provider.currentAnswer;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: Icon(Icons.close, size: 20, color: AppColors.ink),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const Spacer(),
                  Text(
                    '${arabicDigits(provider.currentIndex + 1)} / ${arabicDigits(provider.totalQuestions)}',
                    style: AppType.ui(
                      size: 13,
                      weight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              RulerProgress(
                progress: provider.progress,
                accent: AppColors.green,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // رقم السؤال الشبحي خلف النص — لمسة المطبعة
                      Stack(
                        children: [
                          PositionedDirectional(
                            top: 0,
                            start: 0,
                            child: Text(
                              arabicDigits(provider.currentIndex + 1),
                              style: AppType.display(
                                size: 84,
                                weight: FontWeight.w700,
                                color: AppColors.hairline,
                                height: 1,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 44),
                            child: Text(
                              // الصياغة الخاصة بهذا المستخدم
                              provider.questionText(question),
                              style: AppType.display(size: 22, height: 1.85),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Hairline(),
                      for (final option in QuestionOption.scale)
                        _OptionRow(
                          option: option,
                          isSelected: selected == option.value,
                          accent: AppColors.green,
                          onTap: () =>
                              context.read<TestProvider>().answer(option.value),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (provider.currentIndex > 0)
                    GestureDetector(
                      onTap: () =>
                          context.read<TestProvider>().previousQuestion(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 12),
                        child: Text(
                          'السابق',
                          style: AppType.ui(
                            size: 13.5,
                            weight: FontWeight.w700,
                            color: AppColors.inkMuted,
                          ),
                        ),
                      ),
                    ),
                  const Spacer(),
                  Opacity(
                    opacity: selected == null ? 0.35 : 1,
                    child: InkButton(
                      label: provider.isLastQuestion ? 'اطبع تقريري' : 'التالي',
                      shadowColor: AppColors.green,
                      onTap: selected == null
                          ? null
                          : () {
                              final p = context.read<TestProvider>();
                              if (p.isLastQuestion) {
                                context.pushReplacement('/loading');
                              } else {
                                p.nextQuestion();
                              }
                            },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  final QuestionOption option;
  final bool isSelected;
  final Color accent;
  final VoidCallback onTap;

  const _OptionRow({
    required this.option,
    required this.isSelected,
    required this.accent,
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
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            // شريط التحديد على حافة البداية
            Container(
              width: 4,
              height: 22,
              color: isSelected ? accent : Colors.transparent,
            ),
            const SizedBox(width: 10),
            Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                color: isSelected ? accent : Colors.transparent,
                border: Border.all(
                  color: isSelected ? accent : AppColors.inkSoft,
                  width: 1.4,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              option.text,
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
