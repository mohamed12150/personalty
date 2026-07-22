/// بروفايل المستخدم — مطابق لجدول profiles في Supabase
class Profile {
  final String id;
  final String? username;
  final String? avatarUrl;
  final String? personalityType;
  final Map<String, dynamic>? scores;
  final int streak;
  final DateTime? lastTestDate;
  final DateTime createdAt;

  // الهوية والاقتصاد
  final String? gender; // male | female | null (لم يفصح)
  final String? ageRange; // '13-17' .. '45+'
  final int? avatarId;
  final String? nameColor;
  final List<String> unlockedColors;
  final List<int> unlockedAvatars;
  final int leaves;
  final bool identitySet; // النوع والعمر يُحددان مرة واحدة

  const Profile({
    required this.id,
    this.username,
    this.avatarUrl,
    this.personalityType,
    this.scores,
    this.streak = 0,
    this.lastTestDate,
    required this.createdAt,
    this.gender,
    this.ageRange,
    this.avatarId,
    this.nameColor,
    this.unlockedColors = const [],
    this.unlockedAvatars = const [],
    this.leaves = 0,
    this.identitySet = false,
  });

  bool get identityComplete => avatarId != null;

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      username: json['username'],
      avatarUrl: json['avatar_url'],
      personalityType: json['personality_type'],
      scores: json['scores'],
      streak: json['streak'] ?? 0,
      lastTestDate: json['last_test_date'] != null
          ? DateTime.parse(json['last_test_date'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      gender: json['gender'],
      ageRange: json['age_range'],
      avatarId: json['avatar_id'],
      nameColor: json['name_color'],
      unlockedColors: List<String>.from(json['unlocked_colors'] ?? []),
      unlockedAvatars: List<int>.from(json['unlocked_avatars'] ?? []),
      leaves: json['leaves'] ?? 0,
      identitySet: json['identity_set'] ?? false,
    );
  }
}
