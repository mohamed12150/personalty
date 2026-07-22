/// نتيجة اختبار محفوظة — مطابقة لجدول test_results في Supabase
class TestResult {
  final int id;
  final String testType; // quick | full
  final String code;
  final Map<String, int> percentages;
  final String? aiAnalysis;
  final DateTime createdAt;

  const TestResult({
    required this.id,
    required this.testType,
    required this.code,
    required this.percentages,
    this.aiAnalysis,
    required this.createdAt,
  });

  factory TestResult.fromJson(Map<String, dynamic> json) {
    final raw = json['percentages'];
    final percentages = <String, int>{};
    if (raw is Map) {
      raw.forEach((k, v) {
        percentages[k.toString()] = (v as num).round();
      });
    }
    return TestResult(
      id: json['id'] as int,
      testType: json['test_type'] ?? 'quick',
      code: json['code'] ?? '',
      percentages: percentages,
      aiAnalysis: json['ai_analysis'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
