/// لغز اليوم — من العرض العام puzzles_public (بدون الإجابة الصحيحة)
class Puzzle {
  final int id;
  final DateTime date;
  final String scenario;
  final List<String> options;
  final int reward;

  const Puzzle({
    required this.id,
    required this.date,
    required this.scenario,
    required this.options,
    required this.reward,
  });

  factory Puzzle.fromJson(Map<String, dynamic> json) {
    return Puzzle(
      id: json['id'] as int,
      date: DateTime.parse(json['puzzle_date']),
      scenario: json['scenario'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      reward: json['reward'] ?? 25,
    );
  }
}

/// محاولة المستخدم المسجلة على لغز
class PuzzleAttempt {
  final String choice;
  final bool isCorrect;
  final DateTime createdAt;

  const PuzzleAttempt({
    required this.choice,
    required this.isCorrect,
    required this.createdAt,
  });

  factory PuzzleAttempt.fromJson(Map<String, dynamic> json) {
    return PuzzleAttempt(
      choice: json['choice'] ?? '',
      isCorrect: json['is_correct'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

/// نتيجة الإجابة القادمة من السيرفر لحظة الحل
class PuzzleOutcome {
  final bool correct;
  final String correctCode;
  final int reward;

  const PuzzleOutcome({
    required this.correct,
    required this.correctCode,
    required this.reward,
  });
}
