/// وصف نمط شخصية — مطابق لجدول personality_types في Supabase
class PersonalityType {
  final String code; // INFJ
  final String nameAr; // المحامي
  final String groupAr; // الدبلوماسيون
  final String emoji;
  final String colorName; // purple | green | blue | orange
  final String snippet;
  final String description;
  final List<String> strengths;
  final List<String> weaknesses;
  final String relationships;
  final List<String> careers;
  final List<String> famousPeople;

  const PersonalityType({
    required this.code,
    required this.nameAr,
    required this.groupAr,
    required this.emoji,
    required this.colorName,
    required this.snippet,
    required this.description,
    required this.strengths,
    required this.weaknesses,
    required this.relationships,
    required this.careers,
    required this.famousPeople,
  });

  factory PersonalityType.fromJson(Map<String, dynamic> json) {
    return PersonalityType(
      code: json['code'] ?? '',
      nameAr: json['name_ar'] ?? '',
      groupAr: json['group_ar'] ?? '',
      emoji: json['emoji'] ?? '',
      colorName: json['color'] ?? 'violet',
      snippet: json['snippet'] ?? '',
      description: json['description'] ?? '',
      strengths: List<String>.from(json['strengths'] ?? []),
      weaknesses: List<String>.from(json['weaknesses'] ?? []),
      relationships: json['relationships'] ?? '',
      careers: List<String>.from(json['careers'] ?? []),
      famousPeople: List<String>.from(json['famous_people'] ?? []),
    );
  }
}
