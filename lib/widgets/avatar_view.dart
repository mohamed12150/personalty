import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/constants.dart';
import '../core/theme.dart';

/// عرض الأفاتار بأسلوب المطبعة:
/// - صغيراً: قصّة الوجه والكتفين داخل إطار حاد
/// - fullBody: الشخصية واقفة بالكامل (للبروفايل)
/// - بدون أفاتار: إطار بلون مجموعة النمط وأول حرف/رمز
class AvatarView extends StatelessWidget {
  final String? assetPath;
  final String? personality;
  final String fallbackText; // رمز أو حرف يظهر عند غياب الأفاتار
  final double size;
  final bool fullBody;

  const AvatarView({
    super.key,
    this.assetPath,
    this.personality,
    this.fallbackText = '•',
    this.size = 40,
    this.fullBody = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accentForCode(personality);

    if (fullBody && assetPath != null) {
      return SvgPicture.asset(assetPath!, height: size);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.antiAlias,
      child: assetPath != null
          ? SvgPicture.asset(
              assetPath!,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            )
          : Center(
              child: Text(
                fallbackText,
                style: AppType.ui(
                  size: size * 0.42,
                  weight: FontWeight.w700,
                  color: accent,
                  height: 1.2,
                ),
              ),
            ),
    );
  }
}
