import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/test_provider.dart';
import '../../widgets/editorial.dart';

/// شاشة النتيجة — تقرير الشخصية المطبوع
class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  static const _axes = [
    (title: 'الطاقة', first: 'E', firstLabel: 'منفتح', second: 'I', secondLabel: 'انطوائي'),
    (title: 'العقل', first: 'N', firstLabel: 'حدسي', second: 'S', secondLabel: 'حسّي'),
    (title: 'الطبيعة', first: 'T', firstLabel: 'منطقي', second: 'F', secondLabel: 'عاطفي'),
    (title: 'التكتيك', first: 'J', firstLabel: 'منظّم', second: 'P', secondLabel: 'مرن'),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TestProvider>();
    final code = provider.resultCode;

    if (code == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('لا توجد نتيجة بعد.', style: AppType.display(size: 22)),
              const SizedBox(height: 16),
              InkButton(
                label: 'ابدأ الاختبار',
                onTap: () => context.go('/test-select'),
              ),
            ],
          ),
        ),
      );
    }

    final type = provider.resultType;
    final accent = type != null
        ? AppColors.accentByName(type.colorName)
        : AppColors.accentForCode(code);
    final isGuest = !context.watch<AuthProvider>().isAuthenticated;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Row(
              children: [
                Text(
                  'تقريرك — ${provider.testType == TestType.full ? 'الاختبار الكامل' : 'الاختبار السريع'}',
                  style: AppType.ui(
                    size: 11,
                    weight: FontWeight.w700,
                    color: AppColors.inkSoft,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => context.go('/home'),
                  icon: Icon(Icons.close, size: 20, color: AppColors.ink),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Hairline(),
            const SizedBox(height: 20),

            // الهوية: الاسم + المونوجرام
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type?.nameAr ?? code,
                        style: AppType.display(
                          size: 38,
                          weight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (type != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              type.groupAr,
                              style: AppType.ui(
                                size: 13.5,
                                weight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(height: 5, width: 68, color: accent),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _Monogram(code: code, accent: accent),
              ],
            ),
            if (type != null) ...[
              const SizedBox(height: 14),
              Text(
                type.snippet,
                style: AppType.ui(size: 13.5, color: AppColors.inkMuted, height: 1.8),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  StampBadge(
                    text: 'من مجموعة ${type.groupAr}',
                    color: accent,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            const Hairline(),
            const SizedBox(height: 20),

            // المقاييس
            SectionHead(number: '01', title: 'مقاييسك', accent: accent),
            const SizedBox(height: 18),
            for (final axis in _axes) ...[
              Builder(builder: (context) {
                final firstPct = provider.percentages[axis.first] ?? 50;
                final firstWins = firstPct >= 50;
                return AxisRow(
                  axisTitle: axis.title,
                  winLabel: firstWins ? axis.firstLabel : axis.secondLabel,
                  loseLabel: firstWins ? axis.secondLabel : axis.firstLabel,
                  winPct: firstWins ? firstPct : 100 - firstPct,
                  accent: accent,
                );
              }),
              const SizedBox(height: 18),
            ],

            if (type != null && type.strengths.isNotEmpty) ...[
              const SizedBox(height: 6),
              SectionHead(number: '02', title: 'نقاط قوّتك', accent: accent),
              const SizedBox(height: 4),
              for (final strength in type.strengths.take(4))
                Container(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.hairline)),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  child: Row(
                    children: [
                      Container(width: 7, height: 7, color: accent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(strength, style: AppType.ui(size: 13.5)),
                      ),
                    ],
                  ),
                ),
            ],

            const SizedBox(height: 24),

            // التحليل المخصص — اقتباس تحريري
            Container(
              decoration: BoxDecoration(
                border: BorderDirectional(
                  start: BorderSide(color: accent, width: 3),
                ),
              ),
              padding: const EdgeInsetsDirectional.only(start: 14, top: 2, bottom: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.format_quote, size: 16, color: accent),
                      const SizedBox(width: 6),
                      Text(
                        'تحليل مخصّص لنتيجتك',
                        style: AppType.ui(
                          size: 11,
                          weight: FontWeight.w700,
                          letterSpacing: 1,
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (provider.aiAnalysis != null)
                    Text(
                      provider.aiAnalysis!,
                      style: AppType.display(size: 15.5, height: 1.95),
                    )
                  else if (provider.isAnalysisLoading)
                    Row(
                      children: [
                        Text(
                          'يُكتَب تحليلك الآن…',
                          style: AppType.display(
                            size: 15,
                            color: AppColors.inkSoft,
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      'التحليل غير متاح حالياً — تقريرك الكامل بالأسفل.',
                      style: AppType.ui(size: 12.5, color: AppColors.inkSoft),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: InkButton(
                    label: 'استكشف شخصيتك',
                    shadowColor: accent,
                    onTap: () => context.push('/personality-detail'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: isGuest
                      ? GhostButton(
                          label: 'سجّل لحفظها',
                          onTap: () => context.push('/auth'),
                        )
                      : GhostButton(
                          label: 'الرئيسية',
                          onTap: () => context.go('/home'),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// مونوجرام حروف النمط ٢×٢ بأسلوب حروف المطبعة
class _Monogram extends StatelessWidget {
  final String code;
  final Color accent;

  const _Monogram({required this.code, required this.accent});

  @override
  Widget build(BuildContext context) {
    final letters = code.split('');
    if (letters.length < 4) return const SizedBox.shrink();

    Widget cell(String letter, {bool accented = false}) => Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.hairline),
            color: accented ? accent : Colors.transparent,
          ),
          alignment: Alignment.center,
          child: Text(
            letter,
            style: AppType.mono(
              size: 19,
              letterSpacing: 0,
              color: accented ? AppColors.onColor(accent) : AppColors.ink,
            ),
          ),
        );

    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [cell(letters[0]), cell(letters[1])],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [cell(letters[2], accented: true), cell(letters[3])],
        ),
      ],
    );
  }
}
