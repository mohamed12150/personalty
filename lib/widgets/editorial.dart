import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/theme.dart';

/// خط فاصل رفيع
class Hairline extends StatelessWidget {
  const Hairline({super.key});

  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: AppColors.hairline);
}

/// ترويسة صحيفة: العنوان + قاعدة مزدوجة (سميكة فوق رفيعة)
/// لكل قسم لون توقيع يميّز قاعدته
class Masthead extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Color? accent;

  const Masthead({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppType.display(size: 30, weight: FontWeight.w700, height: 1.3),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: AppType.ui(size: 11, color: AppColors.inkSoft),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: 10),
        Container(height: 3, color: accent ?? AppColors.ink),
        const SizedBox(height: 3),
        const Hairline(),
      ],
    );
  }
}

/// عنوان قسم مرقّم: "٠١ — مقالات تخصّك"
class SectionHead extends StatelessWidget {
  final String number;
  final String title;
  final Color? accent;

  const SectionHead({
    super.key,
    required this.number,
    required this.title,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              arabicDigits(number),
              style: AppType.ui(
                size: 12,
                weight: FontWeight.w700,
                color: accent ?? AppColors.ink,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(width: 8),
            Text('—', style: AppType.ui(size: 12, color: AppColors.inkSoft)),
            const SizedBox(width: 8),
            Text(title, style: AppType.ui(size: 13, weight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 8),
        const Hairline(),
      ],
    );
  }
}

/// زر حبر مصمت بظل إزاحة مطبعي
class InkButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color? shadowColor;
  final bool expanded;

  const InkButton({
    super.key,
    required this.label,
    this.onTap,
    this.shadowColor,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 22),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: shadowColor ?? AppColors.violet,
              offset: const Offset(-3, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppType.ui(
            size: 14,
            weight: FontWeight.w700,
            color: AppColors.paper,
            height: 1.2,
          ),
        ),
      ),
    );
    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// زر بإطار رفيع
class GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool expanded;

  const GhostButton({
    super.key,
    required this.label,
    this.onTap,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 22),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.ink, width: 1.2),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppType.ui(size: 14, weight: FontWeight.w700, height: 1.2),
        ),
      ),
    );
    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// جرس الإشعارات مع عدّاد غير المقروء
class NotificationBell extends StatelessWidget {
  final int unread;
  final VoidCallback onTap;

  const NotificationBell({
    super.key,
    required this.unread,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(Icons.notifications_none, size: 21, color: AppColors.ink),
            if (unread > 0)
              PositionedDirectional(
                top: -3,
                end: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  constraints: const BoxConstraints(minWidth: 15),
                  decoration: BoxDecoration(
                    color: AppColors.orange,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: AppColors.paper, width: 1.2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    unread > 9 ? '٩+' : arabicDigits(unread),
                    style: AppType.ui(
                      size: 8.5,
                      weight: FontWeight.w700,
                      color: AppColors.onColor(AppColors.orange),
                      height: 1.4,
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

/// وسم تصنيف مصمت صغير
class CategoryTab extends StatelessWidget {
  final String label;
  final Color color;

  const CategoryTab({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
      color: color,
      child: Text(
        label,
        style: AppType.ui(
          size: 10.5,
          weight: FontWeight.w700,
          // يتباين مع الخلفية تلقائياً في الوضعين
          color: AppColors.onColor(color),
          height: 1.4,
        ),
      ),
    );
  }
}

/// شريط تقدم على هيئة مسطرة مطبعية بعلامات قياس ومعيّن حبر
class RulerProgress extends StatelessWidget {
  final double progress; // 0..1
  final Color? accent;

  const RulerProgress({super.key, required this.progress, this.accent});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      width: double.infinity,
      child: CustomPaint(
        painter: _RulerPainter(
          progress: progress.clamp(0, 1),
          accent: accent ?? AppColors.green,
        ),
      ),
    );
  }
}

class _RulerPainter extends CustomPainter {
  final double progress;
  final Color accent;

  _RulerPainter({required this.progress, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final baseY = size.height - 5;
    final base = Paint()
      ..color = AppColors.hairline
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, baseY), Offset(size.width, baseY), base);

    // علامات القياس: صغيرة كل جزء، كبيرة كل ست علامات
    const ticks = 24;
    final tick = Paint()
      ..color = AppColors.inkSoft
      ..strokeWidth = 1;
    for (var i = 0; i <= ticks; i++) {
      final x = size.width * i / ticks;
      final h = i % 6 == 0 ? 8.0 : 4.0;
      canvas.drawLine(Offset(x, baseY - h), Offset(x, baseY), tick);
    }

    // الجزء المقطوع — يبدأ من اليمين (RTL)
    final fill = Paint()
      ..color = accent
      ..strokeWidth = 2.5;
    final fillStart = size.width;
    final fillEnd = size.width * (1 - progress);
    canvas.drawLine(Offset(fillStart, baseY), Offset(fillEnd, baseY), fill);

    // معيّن الموضع الحالي
    final diamond = Paint()..color = AppColors.ink;
    canvas.save();
    canvas.translate(fillEnd, baseY);
    canvas.rotate(math.pi / 4);
    canvas.drawRect(const Rect.fromLTWH(-4, -4, 8, 8), diamond);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RulerPainter old) =>
      old.progress != progress || old.accent != accent;
}

/// صف محور النتيجة: الطرف الغالب + مسطرة النسبة + الطرف الآخر
class AxisRow extends StatelessWidget {
  final String axisTitle; // الطاقة
  final String winLabel; // انطوائي
  final String loseLabel; // منفتح
  final int winPct;
  final Color accent;

  const AxisRow({
    super.key,
    required this.axisTitle,
    required this.winLabel,
    required this.loseLabel,
    required this.winPct,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              winLabel,
              style: AppType.ui(size: 13.5, weight: FontWeight.w700),
            ),
            const SizedBox(width: 6),
            Text(
              '${arabicDigits(winPct)}٪',
              style: AppType.ui(
                size: 13.5,
                weight: FontWeight.w700,
                color: accent,
                letterSpacing: 1.5,
              ),
            ),
            const Spacer(),
            Text(
              loseLabel,
              style: AppType.ui(size: 12, color: AppColors.inkSoft),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 12,
          child: CustomPaint(
            painter: _AxisTrackPainter(pct: winPct / 100, accent: accent),
            size: const Size(double.infinity, 12),
          ),
        ),
        const SizedBox(height: 2),
        Text(axisTitle, style: AppType.ui(size: 10, color: AppColors.inkSoft)),
      ],
    );
  }
}

class _AxisTrackPainter extends CustomPainter {
  final double pct;
  final Color accent;

  _AxisTrackPainter({required this.pct, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final base = Paint()
      ..color = AppColors.hairline
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), base);

    final tick = Paint()
      ..color = AppColors.hairline
      ..strokeWidth = 1;
    for (var i = 0; i <= 10; i++) {
      final x = size.width * i / 10;
      canvas.drawLine(Offset(x, y - 3), Offset(x, y + 3), tick);
    }

    // التعبئة من اليمين ناحية الطرف الغالب
    final fill = Paint()
      ..color = accent
      ..strokeWidth = 4;
    canvas.drawLine(
      Offset(size.width, y),
      Offset(size.width * (1 - pct), y),
      fill,
    );
  }

  @override
  bool shouldRepaint(_AxisTrackPainter old) =>
      old.pct != pct || old.accent != accent;
}

/// ختم بريدي مائل بإطار متقطع
class StampBadge extends StatelessWidget {
  final String text;
  final Color color;
  final double angleDegrees;

  const StampBadge({
    super.key,
    required this.text,
    required this.color,
    this.angleDegrees = -6,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angleDegrees * math.pi / 180,
      child: CustomPaint(
        painter: _DashedBorderPainter(color: color),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            text,
            style: AppType.ui(size: 11.5, weight: FontWeight.w700, color: color, height: 1.4),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;

  _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    const dash = 5.0;
    const gap = 3.5;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Offset.zero & size,
        const Radius.circular(4),
      ));

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, math.min(distance + dash, metric.length)),
          paint,
        );
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color;
}
