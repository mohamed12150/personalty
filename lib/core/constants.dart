import 'package:flutter/material.dart';

/// لوحة الألوان التحريرية — ورق وحبر ولون واحد واثق لكل مجموعة.
/// في الوضع الليلي ينقلب الورق حبراً والحبر ورقاً، وتُضاء ألوان المجموعات قليلاً
/// لتبقى مقروءة على الخلفية الداكنة.
class AppColors {
  /// يضبطه ThemeController قبل كل بناء للواجهة
  static bool dark = false;

  // الأساس — ورق وحبر
  static Color get paper =>
      dark ? const Color(0xFF16161F) : const Color(0xFFF5F2ED);
  static Color get paperDark =>
      dark ? const Color(0xFF101017) : const Color(0xFFE9E4DB);
  static Color get card =>
      dark ? const Color(0xFF1E1E2A) : const Color(0xFFFBF9F5);
  static Color get ink =>
      dark ? const Color(0xFFEDE9E1) : const Color(0xFF1C1C2E);
  static Color get inkMuted =>
      dark ? const Color(0xB3EDE9E1) : const Color(0xB31C1C2E); // 70%
  static Color get inkSoft =>
      dark ? const Color(0x80EDE9E1) : const Color(0x731C1C2E); // ~48%
  static Color get hairline =>
      dark ? const Color(0x2EEDE9E1) : const Color(0x261C1C2E); // ~18%
  static const Color white = Color(0xFFFFFFFF);

  // لون كل مجموعة أنماط
  static Color get violet =>
      dark ? const Color(0xFF8B6BF0) : const Color(0xFF6C3CE1); // المحللون
  static Color get green =>
      dark ? const Color(0xFF45C489) : const Color(0xFF2E9E6B); // الدبلوماسيون
  static Color get blue =>
      dark ? const Color(0xFF5A93F5) : const Color(0xFF2F6DE0); // الحماة
  static Color get orange =>
      dark ? const Color(0xFFF2A052) : const Color(0xFFE8862E); // المستكشفون

  /// لون النص المناسب فوق خلفية ملوّنة — يختار تلقائياً حسب إضاءة الخلفية
  /// (مهم في الوضع الليلي حيث ينقلب الحبر إلى لون فاتح)
  static Color onColor(Color background) =>
      background.computeLuminance() > 0.45
          ? const Color(0xFF16161F)
          : white;

  /// اللون من اسمه المخزن في قاعدة البيانات
  static Color accentByName(String? name) {
    switch (name) {
      case 'purple':
      case 'violet':
        return violet;
      case 'green':
        return green;
      case 'blue':
        return blue;
      case 'orange':
        return orange;
      default:
        return violet;
    }
  }

  /// اللون من كود النمط نفسه (INFJ → أخضر الدبلوماسيين)
  static Color accentForCode(String? code) {
    if (code == null || code.length < 4) return violet;
    if (code[1] == 'N') return code[2] == 'T' ? violet : green;
    return code[3] == 'J' ? blue : orange;
  }

  /// ألوان أسماء المستخدمين القابلة للشراء بالأوراق
  static Color nameColor(String? name) {
    switch (name) {
      case 'blue':
        return blue;
      case 'green':
        return green;
      case 'orange':
        return orange;
      case 'violet':
        return violet;
      case 'pink':
        return const Color(0xFFD6467E);
      case 'gold':
        return const Color(0xFFB8860B);
      default:
        return ink;
    }
  }

  /// الاسم العربي للون
  static String nameColorLabel(String name) {
    switch (name) {
      case 'blue':
        return 'الأزرق';
      case 'green':
        return 'الأخضر';
      case 'orange':
        return 'البرتقالي';
      case 'violet':
        return 'البنفسجي';
      case 'pink':
        return 'الوردي';
      case 'gold':
        return 'الذهبي';
      default:
        return name;
    }
  }

  /// لون تصنيف المقال
  static Color categoryColor(String category) {
    switch (category) {
      case 'علاقات':
        return orange;
      case 'مهنة':
        return blue;
      case 'نمو':
        return green;
      case 'شخصية':
        return violet;
      default:
        return ink;
    }
  }
}

/// تحويل الأرقام إلى أرقام هندية للعرض (48 → ٤٨)
String arabicDigits(Object value) {
  const west = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const east = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  var s = value.toString();
  for (var i = 0; i < west.length; i++) {
    s = s.replaceAll(west[i], east[i]);
  }
  return s;
}

/// رمز كل نمط — نفس الرموز المخزنة في قاعدة البيانات
String typeEmoji(String? code) {
  const map = {
    'INTJ': '🧠', 'INTP': '🔬', 'ENTJ': '👑', 'ENTP': '💡',
    'INFJ': '🌙', 'INFP': '🌱', 'ENFJ': '✨', 'ENFP': '🎨',
    'ISTJ': '📋', 'ISFJ': '🛡️', 'ESTJ': '🏛️', 'ESFJ': '🤝',
    'ISTP': '🔧', 'ISFP': '🎭', 'ESTP': '⚡', 'ESFP': '🎉',
  };
  return map[code] ?? '•';
}

/// الاسم العربي لكل نمط — نفس أسماء قاعدة البيانات
String typeNameAr(String? code) {
  const map = {
    'INTJ': 'المخطط الاستراتيجي', 'INTP': 'المفكر',
    'ENTJ': 'القائد', 'ENTP': 'المناظر',
    'INFJ': 'المحامي', 'INFP': 'الوسيط',
    'ENFJ': 'الملهم', 'ENFP': 'المتحمس',
    'ISTJ': 'المدقق', 'ISFJ': 'المدافع',
    'ESTJ': 'التنفيذي', 'ESFJ': 'القنصل',
    'ISTP': 'الحرفي', 'ISFP': 'المغامر',
    'ESTP': 'المقدام', 'ESFP': 'المسلي',
  };
  return map[code] ?? '';
}

/// أنماط نفس المجموعة (INFJ → كل الدبلوماسيين)
List<String> groupCodes(String code) {
  if (code.length < 4) return [code];
  if (code[1] == 'N') {
    return code[2] == 'T'
        ? ['INTJ', 'INTP', 'ENTJ', 'ENTP']
        : ['INFJ', 'INFP', 'ENFJ', 'ENFP'];
  }
  return code[3] == 'J'
      ? ['ISTJ', 'ISFJ', 'ESTJ', 'ESFJ']
      : ['ISTP', 'ISFP', 'ESTP', 'ESFP'];
}

/// "منذ ٥ دقائق" — وقت نسبي بالعربي
String arabicTimeAgo(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'الآن';
  if (diff.inMinutes < 60) return 'منذ ${arabicDigits(diff.inMinutes)} د';
  if (diff.inHours < 24) return 'منذ ${arabicDigits(diff.inHours)} س';
  if (diff.inDays < 7) return 'منذ ${arabicDigits(diff.inDays)} يوم';
  return arabicDateLine(time);
}

/// سطر التاريخ بالعربي: "الأحد ٢٠ يوليو"
String arabicDateLine(DateTime d) {
  const days = [
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];
  const months = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];
  return '${days[d.weekday - 1]} ${arabicDigits(d.day)} ${months[d.month - 1]}';
}
