import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../widgets/editorial.dart';
import '../../widgets/onboarding_art.dart';

/// جولة تعريفية من أربع صفحات بأسلوب المطبعة
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  // getter لا متغيّر ثابت: الألوان تتبع الوضع الليلي
  static List<({Color accent, String kicker, String title, String body})>
      get _pages => [
    (
      accent: AppColors.violet,
      kicker: '٠١ — اختبارك',
      title: 'من أنت؟',
      body:
          'أسئلة مدروسة تطبع تقريراً كاملاً لشخصيتك من بين ستة عشر نمطاً — نقاط قوتك، علاقاتك، ومسارك المهني، مع تحليل ذكي يُكتب لك وحدك.',
    ),
    (
      accent: AppColors.orange,
      kicker: '٠٢ — المجتمع',
      title: 'ناس تشبهك.',
      body:
          'خواطر يكتبها أصحابها ونمط شخصيتهم بجانبها. فلتر «نمطي» يريك ما يكتبه من يفكرون ويشعرون مثلك تماماً.',
    ),
    (
      accent: AppColors.green,
      kicker: '٠٣ — شخصيات حية',
      title: 'يكتبون ويردّون.',
      body:
          'ست عشرة شخصية افتراضية معلنة، كل واحدة تكتب بأسلوب نمطها الحقيقي — علّق على خاطرة نور أو حازم وسيصلك ردّ يشبههما.',
    ),
    (
      accent: AppColors.blue,
      kicker: '٠٤ — العب واكسب',
      title: 'اجمع أوراقك.',
      body:
          'لغز شخصية جديد كل يوم. اجمع الأوراق 🍃 لتلوّن اسمك، تفتح أفاتارات مميزة، وتدعم خواطر أعجبتك.',
    ),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', true);
    if (mounted) context.go('/home');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_page];
    final isLast = _page == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Row(
                children: [
                  Text(
                    'شخصيتي',
                    style: AppType.ui(
                      size: 13,
                      weight: FontWeight.w700,
                      letterSpacing: 1,
                      color: AppColors.inkMuted,
                    ),
                  ),
                  const Spacer(),
                  if (!isLast)
                    GestureDetector(
                      onTap: _finish,
                      child: Text(
                        'تخطَّ',
                        style: AppType.ui(
                          size: 13,
                          weight: FontWeight.w700,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final p = _pages[i];
                  // مقاسات تتكيّف مع الشاشات الصغيرة فلا يفيض المحتوى أبداً
                  final width = MediaQuery.sizeOf(context).width;
                  final titleSize = width < 340 ? 30.0 : (width < 400 ? 34.0 : 40.0);

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OnboardingArt(index: i, accent: p.accent),
                        const SizedBox(height: 22),
                        Text(
                          p.kicker,
                          style: AppType.ui(
                            size: 12,
                            weight: FontWeight.w700,
                            letterSpacing: 2,
                            color: p.accent,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(height: 3, width: 44, color: p.accent),
                        const SizedBox(height: 18),
                        Text(
                          p.title,
                          style: AppType.display(
                            size: titleSize,
                            weight: FontWeight.w700,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          p.body,
                          style: AppType.ui(
                            size: 14.5,
                            color: AppColors.inkMuted,
                            height: 2.0,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      for (var i = 0; i < _pages.length; i++) ...[
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: i == _page ? 22 : 8,
                          height: 8,
                          color: i == _page
                              ? _pages[i].accent
                              : AppColors.hairline,
                        ),
                        const SizedBox(width: 6),
                      ],
                    ],
                  ),
                  const SizedBox(height: 18),
                  InkButton(
                    label: isLast ? 'ابدأ الرحلة' : 'التالي',
                    expanded: true,
                    shadowColor: page.accent,
                    onTap: () {
                      if (isLast) {
                        _finish();
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOut,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
