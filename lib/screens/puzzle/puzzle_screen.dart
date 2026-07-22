import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/puzzle.dart';
import '../../providers/profile_provider.dart';
import '../../providers/puzzle_provider.dart';
import '../../widgets/editorial.dart';

/// لغز الشخصية اليومي — خمّن النمط واكسب أوراقاً
class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({super.key});

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  String? _choice;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<PuzzleProvider>().fetchToday());
  }

  Future<void> _submit() async {
    final choice = _choice;
    if (choice == null) return;

    final error = await context.read<PuzzleProvider>().answer(choice);
    if (!mounted) return;

    if (error == 'auth') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('سجّل الدخول لتلعب وتكسب الأوراق 🍃'),
          action: SnackBarAction(
            label: 'تسجيل الدخول',
            textColor: AppColors.paper,
            onPressed: () => context.push('/auth'),
          ),
        ),
      );
    } else if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error == 'already_attempted'
              ? 'جربت لغز اليوم بالفعل — عُد غداً'
              : 'حدث خطأ، حاول مجدداً'),
        ),
      );
    } else {
      // نجاح — حدّث رصيد الأوراق في البروفايل
      context.read<ProfileProvider>().refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PuzzleProvider>();
    final puzzle = provider.puzzle;

    return Scaffold(
      body: SafeArea(
        child: provider.isLoading
            ? Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.ink),
                ),
              )
            : puzzle == null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('لا يوجد لغز اليوم بعد.',
                            style: AppType.display(size: 20)),
                        const SizedBox(height: 6),
                        Text('اللغز الجديد يُطبع فجر كل يوم',
                            style: AppType.ui(
                                size: 12, color: AppColors.inkSoft)),
                        const SizedBox(height: 16),
                        GhostButton(label: 'عودة', onTap: () => context.pop()),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
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
                          const Spacer(),
                          if (provider.streak > 0)
                            Text(
                              'سلسلتك: ${arabicDigits(provider.streak)} 🔥',
                              style: AppType.ui(
                                  size: 12.5, weight: FontWeight.w700),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Masthead(
                        title: 'لغز اليوم',
                        accent: AppColors.green,
                        subtitle: arabicDateLine(puzzle.date),
                      ),
                      const SizedBox(height: 20),

                      // المشهد
                      Stack(
                        children: [
                          PositionedDirectional(
                            top: 0,
                            start: 0,
                            child: Text(
                              '؟',
                              style: AppType.display(
                                size: 90,
                                weight: FontWeight.w700,
                                color: AppColors.hairline,
                                height: 1,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: Text(
                              puzzle.scenario,
                              style: AppType.display(size: 18, height: 2.0),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.eco,
                              size: 14, color: AppColors.green),
                          const SizedBox(width: 4),
                          Text(
                            'الإجابة الصحيحة تكسبك ${arabicDigits(puzzle.reward)} ورقة',
                            style: AppType.ui(
                                size: 11.5, color: AppColors.inkMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Hairline(),
                      const SizedBox(height: 8),

                      if (provider.outcome != null)
                        _OutcomeBlock(provider: provider)
                      else if (provider.myAttempt != null)
                        _AttemptedBlock(attempt: provider.myAttempt!)
                      else ...[
                        Text(
                          'من هو؟',
                          style: AppType.ui(
                              size: 13, weight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        for (final option in puzzle.options)
                          _OptionRow(
                            code: option,
                            isSelected: _choice == option,
                            onTap: () => setState(() => _choice = option),
                          ),
                        const SizedBox(height: 20),
                        Opacity(
                          opacity: _choice == null ? 0.35 : 1,
                          child: InkButton(
                            label: provider.isAnswering
                                ? 'يُصحَّح…'
                                : 'هذه إجابتي',
                            expanded: true,
                            shadowColor: AppColors.green,
                            onTap: _choice == null || provider.isAnswering
                                ? null
                                : _submit,
                          ),
                        ),
                      ],
                    ],
                  ),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  final String code;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionRow({
    required this.code,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accentForCode(code);
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.hairline)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 24,
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
              code,
              style: AppType.mono(size: 14, letterSpacing: 2),
            ),
            const SizedBox(width: 10),
            Text(
              typeNameAr(code),
              style: AppType.ui(
                size: 13,
                weight: isSelected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// نتيجة الحل في هذه الجلسة
class _OutcomeBlock extends StatelessWidget {
  final PuzzleProvider provider;

  const _OutcomeBlock({required this.provider});

  @override
  Widget build(BuildContext context) {
    final outcome = provider.outcome!;
    final accent =
        outcome.correct ? AppColors.green : AppColors.orange;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            StampBadge(
              text: outcome.correct
                  ? 'إجابة صحيحة · +${arabicDigits(outcome.reward)} ورقة 🍃'
                  : 'ليست الإجابة الصحيحة',
              color: accent,
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'الإجابة: ${outcome.correctCode} — ${typeNameAr(outcome.correctCode)} ${typeEmoji(outcome.correctCode)}',
          style: AppType.display(size: 19, height: 1.6),
        ),
        const SizedBox(height: 8),
        if (provider.streak > 0)
          Text(
            'سلسلتك الآن: ${arabicDigits(provider.streak)} ${provider.streak > 1 ? 'أيام' : 'يوم'} 🔥',
            style: AppType.ui(size: 13, weight: FontWeight.w700),
          ),
        const SizedBox(height: 4),
        Text(
          'لغز جديد يُطبع فجر كل يوم — عُد غداً',
          style: AppType.ui(size: 12, color: AppColors.inkSoft),
        ),
        const SizedBox(height: 20),
        GhostButton(
          label: 'استكشف نمط ${outcome.correctCode}',
          expanded: true,
          onTap: () =>
              context.push('/personality-detail?code=${outcome.correctCode}'),
        ),
      ],
    );
  }
}

/// سبق حلّه اليوم (من زيارة سابقة)
class _AttemptedBlock extends StatelessWidget {
  final PuzzleAttempt attempt;

  const _AttemptedBlock({required this.attempt});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            StampBadge(
              text: attempt.isCorrect
                  ? 'حللت لغز اليوم ✓'
                  : 'جربت لغز اليوم',
              color:
                  attempt.isCorrect ? AppColors.green : AppColors.inkSoft,
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          attempt.isCorrect
              ? 'أحسنت! إجابتك ${attempt.choice} كانت صحيحة.'
              : 'إجابتك كانت ${attempt.choice} — حظ أوفر في لغز الغد.',
          style: AppType.display(size: 17, height: 1.8),
        ),
        const SizedBox(height: 4),
        Text(
          'لغز جديد يُطبع فجر كل يوم',
          style: AppType.ui(size: 12, color: AppColors.inkSoft),
        ),
      ],
    );
  }
}
