import '../models/question.dart';

/// ناتج حساب الشخصية: الكود + نسبة كل طرف
class CalcResult {
  final String code; // INFJ
  final Map<String, int> percentages; // {'E': 28, 'I': 72, ...}

  const CalcResult(this.code, this.percentages);
}

/// خوارزمية MBTI: تجميع درجات كل محور مع مراعاة الأسئلة المعكوسة،
/// ثم استخراج الحرف الغالب والنسبة المئوية لكل طرف.
class PersonalityCalculator {
  static const Map<String, List<String>> _axisLetters = {
    'EI': ['E', 'I'],
    'NS': ['N', 'S'],
    'TF': ['T', 'F'],
    'JP': ['J', 'P'],
  };

  /// answers: questionId → قيمة الإجابة (من -3 إلى 3)
  static CalcResult calculate(List<Question> questions, Map<int, int> answers) {
    final sums = <String, int>{'EI': 0, 'NS': 0, 'TF': 0, 'JP': 0};
    final counts = <String, int>{'EI': 0, 'NS': 0, 'TF': 0, 'JP': 0};

    for (final q in questions) {
      final answer = answers[q.id];
      if (answer == null || !sums.containsKey(q.axis)) continue;
      // الاتجاه يعكس درجة السؤال المعكوس تلقائياً
      sums[q.axis] = sums[q.axis]! + (answer * q.direction);
      counts[q.axis] = counts[q.axis]! + 1;
    }

    final code = StringBuffer();
    final percentages = <String, int>{};

    _axisLetters.forEach((axis, letters) {
      final count = counts[axis]! == 0 ? 1 : counts[axis]!;
      final max = 3 * count; // أقصى مجموع ممكن للمحور
      // تحويل المجموع (-max..max) إلى نسبة (0..100) ناحية الحرف الأول
      final ratio = (sums[axis]! + max) / (2 * max);
      final firstPct = (ratio * 100).round().clamp(0, 100);

      percentages[letters[0]] = firstPct;
      percentages[letters[1]] = 100 - firstPct;
      code.write(firstPct >= 50 ? letters[0] : letters[1]);
    });

    return CalcResult(code.toString(), percentages);
  }
}
