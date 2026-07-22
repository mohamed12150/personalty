/// سؤال اختبار — مطابق لجدول questions في Supabase
class Question {
  final int id;
  final String text;
  final String axis; // 'EI' | 'NS' | 'TF' | 'JP'
  final int direction; // 1: الموافقة للحرف الأول، -1: سؤال معكوس
  final bool inQuick;
  final int sortOrder;

  /// صياغات بديلة بنفس المعنى والاتجاه تماماً
  final List<String> variants;

  const Question({
    required this.id,
    required this.text,
    required this.axis,
    this.direction = 1,
    this.inQuick = false,
    this.sortOrder = 0,
    this.variants = const [],
  });

  /// الصياغة التي يراها مستخدم معيّن — ثابتة له، ومختلفة بين المستخدمين
  String textForSeed(int seed) {
    if (variants.isEmpty) return text;
    final all = [text, ...variants];
    // مزج البذرة برقم السؤال حتى لا يأخذ المستخدم نفس النسخة في كل الأسئلة
    final index = ((seed ^ (id * 2654435761)) & 0x7fffffff) % all.length;
    return all[index];
  }

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as int,
      text: json['text_ar'] ?? '',
      axis: json['axis'] ?? 'EI',
      direction: (json['direction'] ?? 1) as int,
      inQuick: json['in_quick'] ?? false,
      sortOrder: json['sort_order'] ?? 0,
      variants: List<String>.from(json['variants'] ?? const []),
    );
  }
}

/// خيار إجابة على مقياس ليكرت السباعي
class QuestionOption {
  final String text;
  final int value; // من 3 إلى -3

  const QuestionOption({required this.text, required this.value});

  static const List<QuestionOption> scale = [
    QuestionOption(text: 'أوافق تماماً', value: 3),
    QuestionOption(text: 'أوافق بشكل معتدل', value: 2),
    QuestionOption(text: 'أوافق قليلاً', value: 1),
    QuestionOption(text: 'محايد', value: 0),
    QuestionOption(text: 'أعارض قليلاً', value: -1),
    QuestionOption(text: 'أعارض بشكل معتدل', value: -2),
    QuestionOption(text: 'أعارض تماماً', value: -3),
  ];
}
