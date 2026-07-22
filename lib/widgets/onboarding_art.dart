import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/constants.dart';
import '../core/theme.dart';

/// رسوم الجولة التعريفية — مبنية من عناصر التطبيق نفسها:
/// بطاقات ورقية بحدود رفيعة، مساطر، وأفاتارات حقيقية من داخل التطبيق.
class OnboardingArt extends StatelessWidget {
  final int index;
  final Color accent;

  const OnboardingArt({super.key, required this.index, required this.accent});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 208,
      child: switch (index) {
        0 => _ReportArt(accent: accent),
        1 => _CommunityArt(accent: accent),
        2 => _PersonasArt(accent: accent),
        _ => _LeavesArt(accent: accent),
      },
    );
  }
}

/// خط نص وهمي — شريط رمادي يمثل السطر دون كتابة نص حقيقي
class _TextBar extends StatelessWidget {
  final double width;
  final Color? color;

  const _TextBar({required this.width, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 5,
      margin: const EdgeInsets.only(bottom: 6),
      color: color ?? AppColors.hairline,
    );
  }
}

/// ٠١ — تقرير الشخصية: بطاقة خلفية مائلة + بطاقة التقرير بالمونوجرام والمساطر
class _ReportArt extends StatelessWidget {
  final Color accent;

  const _ReportArt({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 250,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ورقة خلفية مائلة تعطي إحساس الكوم
            Transform.rotate(
              angle: -5 * math.pi / 180,
              child: Container(
                width: 210,
                height: 180,
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  border: Border.all(color: AppColors.hairline),
                ),
              ),
            ),
            Container(
              width: 220,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.paper,
                border: Border.all(color: AppColors.ink, width: 1.2),
                boxShadow: [
                  BoxShadow(color: accent, offset: const Offset(-4, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // مونوجرام الحروف ٢×٢
                      Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _LetterCell(letter: 'I'),
                              _LetterCell(letter: 'N'),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _LetterCell(letter: 'F', filled: true, accent: accent),
                              _LetterCell(letter: 'J'),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 2),
                            Text('المحامي',
                                style: AppType.display(size: 19, height: 1.2)),
                            const SizedBox(height: 5),
                            Container(height: 4, width: 54, color: accent),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(height: 1, color: AppColors.hairline),
                  const SizedBox(height: 12),
                  // مساطر النسب
                  _MiniRuler(pct: 0.72, accent: accent),
                  const SizedBox(height: 9),
                  _MiniRuler(pct: 0.81, accent: accent),
                  const SizedBox(height: 9),
                  _MiniRuler(pct: 0.55, accent: accent),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LetterCell extends StatelessWidget {
  final String letter;
  final bool filled;
  final Color? accent;

  const _LetterCell({required this.letter, this.filled = false, this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: filled ? accent : Colors.transparent,
        border: Border.all(color: AppColors.hairline),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: AppType.mono(
          size: 14,
          letterSpacing: 0,
          color: filled && accent != null
              ? AppColors.onColor(accent!)
              : AppColors.ink,
        ),
      ),
    );
  }
}

/// مسطرة نسبة مصغّرة بعلامات قياس
class _MiniRuler extends StatelessWidget {
  final double pct;
  final Color accent;

  const _MiniRuler({required this.pct, required this.accent});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 8,
      child: CustomPaint(
        size: const Size(double.infinity, 8),
        painter: _MiniRulerPainter(pct: pct, accent: accent),
      ),
    );
  }
}

class _MiniRulerPainter extends CustomPainter {
  final double pct;
  final Color accent;

  _MiniRulerPainter({required this.pct, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final base = Paint()
      ..color = AppColors.hairline
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), base);
    for (var i = 0; i <= 8; i++) {
      final x = size.width * i / 8;
      canvas.drawLine(Offset(x, y - 2.5), Offset(x, y + 2.5), base);
    }
    final fill = Paint()
      ..color = accent
      ..strokeWidth = 3.5;
    // التعبئة من اليمين (اتجاه القراءة العربي)
    canvas.drawLine(
      Offset(size.width, y),
      Offset(size.width * (1 - pct), y),
      fill,
    );
  }

  @override
  bool shouldRepaint(_MiniRulerPainter old) =>
      old.pct != pct || old.accent != accent;
}

/// ٠٢ — المجتمع: صف أفاتارات واقفة على خط أرضية بأكواد أنماطها
class _CommunityArt extends StatelessWidget {
  final Color accent;

  const _CommunityArt({required this.accent});

  // getter لا متغيّر ثابت: الألوان تتبع الوضع الحالي
  static List<({String asset, String code, Color color})> get _people => [
        (
          asset: 'assets/avatar_girl/gee_me_002.svg',
          code: 'ENFP',
          color: AppColors.green
        ),
        (
          asset: 'assets/avatar_man/gee_me_003.svg',
          code: 'INTJ',
          color: AppColors.violet
        ),
        (
          asset: 'assets/avatar_girl/gee_me_011.svg',
          code: 'ISFJ',
          color: AppColors.blue
        ),
        (
          asset: 'assets/avatar_man/gee_me_005.svg',
          code: 'ESTP',
          color: AppColors.orange
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < _people.length; i++)
              Padding(
                // ارتفاعات متفاوتة تكسر الرتابة
                padding: EdgeInsets.only(bottom: i.isEven ? 0 : 10),
                child: SvgPicture.asset(
                  _people[i].asset,
                  height: i.isEven ? 132 : 120,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Container(height: 1.5, color: AppColors.ink),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (final person in _people)
              Text(
                person.code,
                style: AppType.mono(
                  size: 9.5,
                  letterSpacing: 1,
                  color: person.color,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// ٠٣ — الشخصيات: تعليق مستخدم يليه ردّ شخصية بشارة AI
class _PersonasArt extends StatelessWidget {
  final Color accent;

  const _PersonasArt({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SvgPicture.asset('assets/avatar_girl/gee_me_009.svg', height: 150),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // تعليق المستخدم
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration:
                      BoxDecoration(border: Border.all(color: AppColors.hairline)),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _TextBar(width: 92),
                      _TextBar(width: 64),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // ردّ الشخصية الافتراضية
                Container(
                  padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 10, 10),
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    border: Border.all(color: AppColors.hairline),
                    borderRadius: BorderRadius.zero,
                  ),
                  foregroundDecoration: BoxDecoration(
                    border: BorderDirectional(
                      start: BorderSide(color: accent, width: 3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text('نور',
                              style: AppType.ui(
                                  size: 11, weight: FontWeight.w700)),
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration:
                                BoxDecoration(border: Border.all(color: accent)),
                            child: Text(
                              'AI',
                              style: AppType.mono(
                                  size: 7.5, letterSpacing: 1, color: accent),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const _TextBar(width: 100),
                      const _TextBar(width: 80),
                      const _TextBar(width: 52),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ٠٤ — الأوراق: بطاقة اللغز مع أوراق متطايرة وختم المكافأة
class _LeavesArt extends StatelessWidget {
  final Color accent;

  const _LeavesArt({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 260,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // بطاقة اللغز
            Container(
              width: 172,
              height: 168,
              decoration: BoxDecoration(
                color: AppColors.paper,
                border: Border.all(color: AppColors.ink, width: 1.2),
                boxShadow: [
                  BoxShadow(color: accent, offset: const Offset(-4, 4)),
                ],
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '؟',
                    style: AppType.display(
                      size: 60,
                      weight: FontWeight.w700,
                      color: AppColors.hairline,
                      height: 1,
                    ),
                  ),
                  const Spacer(),
                  const _TextBar(width: 110),
                  const _TextBar(width: 84),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration:
                            BoxDecoration(border: Border.all(color: AppColors.inkSoft)),
                      ),
                      const SizedBox(width: 6),
                      const _TextBar(width: 42),
                    ],
                  ),
                  Row(
                    children: [
                      Container(width: 12, height: 12, color: AppColors.green),
                      const SizedBox(width: 6),
                      _TextBar(width: 56, color: AppColors.inkSoft),
                    ],
                  ),
                ],
              ),
            ),
            // أوراق المكافأة متطايرة حول البطاقة
            PositionedDirectional(
              top: 6,
              end: 2,
              child: _LeafToken(size: 40, angle: -14),
            ),
            const PositionedDirectional(
              bottom: 26,
              start: 0,
              child: _LeafToken(size: 32, angle: 12),
            ),
            PositionedDirectional(
              bottom: 0,
              end: 22,
              child: Transform.rotate(
                angle: -7 * math.pi / 180,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    border: Border.all(color: AppColors.green, width: 1.2),
                  ),
                  child: Text(
                    '+${arabicDigits(25)} ورقة',
                    style: AppType.ui(
                      size: 11,
                      weight: FontWeight.w700,
                      color: AppColors.green,
                      height: 1.3,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// رمز الورقة — دائرة بحد رفيع بداخلها ورقة
class _LeafToken extends StatelessWidget {
  final double size;
  final double angle;

  const _LeafToken({required this.size, required this.angle});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle * math.pi / 180,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.paper,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.green, width: 1.4),
        ),
        child: Icon(Icons.eco, size: size * 0.5, color: AppColors.green),
      ),
    );
  }
}
