import 'package:flutter/material.dart';
import '../core/supabase_client.dart';
import '../models/puzzle.dart';

class PuzzleProvider extends ChangeNotifier {
  Puzzle? _puzzle;
  PuzzleAttempt? _myAttempt;
  PuzzleOutcome? _outcome; // نتيجة الحل في هذه الجلسة
  int _streak = 0;
  bool _isLoading = false;
  bool _isAnswering = false;
  String? _error;

  Puzzle? get puzzle => _puzzle;
  PuzzleAttempt? get myAttempt => _myAttempt;
  PuzzleOutcome? get outcome => _outcome;
  int get streak => _streak;
  bool get isLoading => _isLoading;
  bool get isAnswering => _isAnswering;
  String? get error => _error;
  bool get alreadyAnswered => _myAttempt != null || _outcome != null;

  Future<void> fetchToday() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await SupabaseHelper.client
          .from('puzzles_public')
          .select()
          .order('puzzle_date', ascending: false)
          .limit(1);

      final list = response as List;
      _puzzle = list.isEmpty ? null : Puzzle.fromJson(list.first);

      _myAttempt = null;
      _outcome = null;
      if (_puzzle != null &&
          SupabaseHelper.client.auth.currentUser != null) {
        final attemptRes = await SupabaseHelper.client
            .from('puzzle_attempts')
            .select()
            .eq('puzzle_id', _puzzle!.id)
            .maybeSingle();
        if (attemptRes != null) {
          _myAttempt = PuzzleAttempt.fromJson(attemptRes);
        }
        await _computeStreak();
      }
    } catch (e) {
      debugPrint('Error fetching puzzle: $e');
      _error = 'network';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// السلسلة: أيام متتالية بإجابات صحيحة حتى اليوم/أمس
  Future<void> _computeStreak() async {
    try {
      final response = await SupabaseHelper.client
          .from('puzzle_attempts')
          .select('created_at, is_correct')
          .order('created_at', ascending: false)
          .limit(60);

      final days = <DateTime>{};
      for (final row in response as List) {
        if (row['is_correct'] == true) {
          final d = DateTime.parse(row['created_at']).toUtc();
          days.add(DateTime.utc(d.year, d.month, d.day));
        }
      }

      final today = DateTime.now().toUtc();
      var cursor = DateTime.utc(today.year, today.month, today.day);
      var streak = 0;
      // السلسلة تصمد لو لم يُحل لغز اليوم بعد
      if (!days.contains(cursor)) {
        cursor = cursor.subtract(const Duration(days: 1));
      }
      while (days.contains(cursor)) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      }
      _streak = streak;
    } catch (e) {
      debugPrint('Error computing streak: $e');
    }
  }

  /// إرسال الإجابة — التصحيح يحدث في السيرفر حصرياً
  Future<String?> answer(String choice) async {
    final puzzle = _puzzle;
    if (puzzle == null || _isAnswering) return null;

    if (SupabaseHelper.client.auth.currentUser == null) {
      return 'auth';
    }

    _isAnswering = true;
    notifyListeners();

    try {
      final res = await SupabaseHelper.client.rpc(
        'answer_puzzle',
        params: {'p_puzzle_id': puzzle.id, 'p_choice': choice},
      );

      if (res is Map && res['ok'] == true) {
        _outcome = PuzzleOutcome(
          correct: res['correct'] == true,
          correctCode: res['correct_code']?.toString() ?? '',
          reward: (res['reward'] as num?)?.toInt() ?? 0,
        );
        await _computeStreak();
        return null;
      }
      return (res is Map ? res['error']?.toString() : null) ?? 'unknown';
    } catch (e) {
      debugPrint('Error answering puzzle: $e');
      return 'network';
    } finally {
      _isAnswering = false;
      notifyListeners();
    }
  }
}
