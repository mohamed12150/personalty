import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/supabase_client.dart';
import '../data/personality_calculator.dart';
import '../data/questions_data.dart';
import '../models/personality_type.dart';
import '../models/question.dart';

enum TestType { quick, full }

/// اختبار متوقف محفوظ على الجهاز
class SavedTest {
  final TestType type;
  final int answered;
  final int total;
  final DateTime savedAt;

  const SavedTest({
    required this.type,
    required this.answered,
    required this.total,
    required this.savedAt,
  });

  double get progress => total == 0 ? 0 : answered / total;
}

class TestProvider extends ChangeNotifier {
  TestType _testType = TestType.quick;
  List<Question> _questions = [];
  int _currentIndex = 0;
  final Map<int, int> _answers = {}; // questionId → قيمة الإجابة
  bool _isLoadingQuestions = false;
  bool _isSubmitting = false;

  // حالة النتيجة
  String? _resultCode;
  Map<String, int> _percentages = {};
  PersonalityType? _resultType;
  String? _aiAnalysis;
  bool _isAnalysisLoading = false;
  int? _savedResultId;

  TestType get testType => _testType;
  List<Question> get questions => _questions;
  int get currentIndex => _currentIndex;
  bool get isLoadingQuestions => _isLoadingQuestions;
  bool get isSubmitting => _isSubmitting;
  String? get resultCode => _resultCode;

  /// آخر نمط معروف — يبقى محفوظاً محلياً حتى للضيوف وبعد إعادة التشغيل
  String? _persistedCode;
  String? get persistedCode => _persistedCode;

  Future<void> loadPersisted() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('last_personality');
    if (saved != null && saved != _persistedCode) {
      _persistedCode = saved;
      notifyListeners();
    }
  }
  Map<String, int> get percentages => _percentages;
  PersonalityType? get resultType => _resultType;
  String? get aiAnalysis => _aiAnalysis;
  bool get isAnalysisLoading => _isAnalysisLoading;

  int get totalQuestions => _questions.length;
  Question get currentQuestion => _questions[_currentIndex];

  /// بذرة ثابتة لكل مستخدم/جهاز — تحدد أي صياغة من الأسئلة يراها
  int _variantSeed = 0;
  int get variantSeed => _variantSeed;

  /// نص السؤال بالصياغة الخاصة بهذا المستخدم
  String questionText(Question q) => q.textForSeed(_variantSeed);

  Future<void> _loadVariantSeed() async {
    final user = SupabaseHelper.client.auth.currentUser;
    if (user != null) {
      _variantSeed = user.id.hashCode & 0x7fffffff;
      return;
    }
    // الضيف: بذرة عشوائية تُحفظ على الجهاز فتبقى نسخته ثابتة
    final prefs = await SharedPreferences.getInstance();
    var seed = prefs.getInt('variant_seed');
    if (seed == null) {
      seed = DateTime.now().microsecondsSinceEpoch & 0x7fffffff;
      await prefs.setInt('variant_seed', seed);
    }
    _variantSeed = seed;
  }
  double get progress =>
      _questions.isEmpty ? 0 : _currentIndex / _questions.length;
  int? get currentAnswer =>
      _questions.isEmpty ? null : _answers[currentQuestion.id];
  bool get isLastQuestion => _currentIndex >= _questions.length - 1;
  bool get allAnswered =>
      _questions.isNotEmpty && _questions.every((q) => _answers.containsKey(q.id));

  void _resetResult() {
    _resultCode = null;
    _percentages = {};
    _resultType = null;
    _aiAnalysis = null;
    _savedResultId = null;
  }

  /// جلب أسئلة النوع المطلوب مع صياغاتها البديلة
  Future<List<Question>> _fetchQuestions(TestType type) async {
    try {
      final query = SupabaseHelper.client.from('questions_with_variants').select();
      final response = type == TestType.quick
          ? await query.eq('in_quick', true).order('sort_order')
          : await query.order('sort_order');
      final list = (response as List).map((q) => Question.fromJson(q)).toList();
      return list.isEmpty ? List.of(QuestionsData.fallback) : list;
    } catch (e) {
      debugPrint('Error fetching questions: $e');
      return List.of(QuestionsData.fallback);
    }
  }

  /// بدء اختبار جديد: تحميل الأسئلة من Supabase حسب النوع
  Future<void> startTest(TestType type) async {
    _testType = type;
    _currentIndex = 0;
    _answers.clear();
    _resetResult();
    _isLoadingQuestions = true;
    notifyListeners();

    await clearProgress();
    await _loadVariantSeed();
    _questions = await _fetchQuestions(type);
    _questions.shuffle();

    _isLoadingQuestions = false;
    notifyListeners();
    // ترتيب الأسئلة يُحفظ من البداية ليمكن الاستئناف بنفسه
    _saveProgress();
  }

  void answer(int value) {
    if (_questions.isEmpty) return;
    _answers[currentQuestion.id] = value;
    _saveProgress();
    notifyListeners();
  }

  void nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      _currentIndex++;
      _saveProgress();
      notifyListeners();
    }
  }

  void previousQuestion() {
    if (_currentIndex > 0) {
      _currentIndex--;
      _saveProgress();
      notifyListeners();
    }
  }

  // ===== حفظ التقدّم واستئنافه =====
  static const _progressKey = 'test_progress';

  /// يُحفظ بعد كل إجابة أو تنقّل — محلياً فيعمل حتى بلا إنترنت وللضيوف
  Future<void> _saveProgress() async {
    if (_questions.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _progressKey,
        jsonEncode({
          'type': _testType.name,
          'ids': _questions.map((q) => q.id).toList(),
          'answers': _answers.map((k, v) => MapEntry(k.toString(), v)),
          'index': _currentIndex,
          'saved_at': DateTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      debugPrint('Error saving test progress: $e');
    }
  }

  Future<void> clearProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_progressKey);
    } catch (e) {
      debugPrint('Error clearing test progress: $e');
    }
  }

  /// معلومات الاختبار المتوقف لعرضها في شاشة الاختيار
  Future<SavedTest?> savedTest() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_progressKey);
      if (raw == null) return null;

      final data = jsonDecode(raw) as Map<String, dynamic>;
      final ids = List<int>.from(data['ids'] ?? const []);
      final answers = Map<String, dynamic>.from(data['answers'] ?? const {});
      if (ids.isEmpty || answers.length >= ids.length) {
        // مكتمل أو تالف — لا فائدة من عرضه
        await prefs.remove(_progressKey);
        return null;
      }

      return SavedTest(
        type: data['type'] == 'full' ? TestType.full : TestType.quick,
        answered: answers.length,
        total: ids.length,
        savedAt: DateTime.tryParse(data['saved_at'] ?? '') ?? DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error reading test progress: $e');
      return null;
    }
  }

  /// استئناف الاختبار المتوقف من حيث انتهى
  Future<bool> resumeSavedTest() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_progressKey);
      if (raw == null) return false;

      final data = jsonDecode(raw) as Map<String, dynamic>;
      final ids = List<int>.from(data['ids'] ?? const []);
      if (ids.isEmpty) return false;
      final type = data['type'] == 'full' ? TestType.full : TestType.quick;

      _testType = type;
      _isLoadingQuestions = true;
      _resetResult();
      notifyListeners();

      await _loadVariantSeed();
      final fetched = await _fetchQuestions(type);

      // ترتيب الأسئلة كما كانت وقت التوقف
      final byId = {for (final q in fetched) q.id: q};
      final ordered = <Question>[];
      for (final id in ids) {
        final q = byId[id];
        if (q != null) ordered.add(q);
      }
      if (ordered.length != ids.length) {
        // تغيّرت الأسئلة منذ الحفظ — نبدأ من جديد
        await clearProgress();
        _isLoadingQuestions = false;
        notifyListeners();
        return false;
      }

      _questions = ordered;
      _answers.clear();
      (data['answers'] as Map).forEach((k, v) {
        final id = int.tryParse(k.toString());
        if (id != null) _answers[id] = (v as num).toInt();
      });
      _currentIndex =
          (data['index'] as num?)?.toInt().clamp(0, _questions.length - 1) ?? 0;

      _isLoadingQuestions = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error resuming test: $e');
      _isLoadingQuestions = false;
      notifyListeners();
      return false;
    }
  }

  /// حساب النتيجة محلياً، جلب وصف النمط، الحفظ، ثم طلب تحليل الذكاء الاصطناعي
  Future<void> submitTest() async {
    if (_isSubmitting) return;
    _isSubmitting = true;
    notifyListeners();

    try {
      final calc = PersonalityCalculator.calculate(_questions, _answers);
      _resultCode = calc.code;
      _percentages = calc.percentages;

      // حفظ محلي — يعمل للضيوف أيضاً ويصمد بعد إغلاق التطبيق
      _persistedCode = calc.code;
      SharedPreferences.getInstance()
          .then((prefs) => prefs.setString('last_personality', calc.code));

      // وصف النمط من قاعدة البيانات
      try {
        final row = await SupabaseHelper.client
            .from('personality_types')
            .select()
            .eq('code', calc.code)
            .single();
        _resultType = PersonalityType.fromJson(row);
      } catch (e) {
        debugPrint('Error fetching personality type: $e');
      }

      // حفظ النتيجة وتحديث البروفايل للمسجلين
      final user = SupabaseHelper.client.auth.currentUser;
      if (user != null) {
        try {
          final inserted = await SupabaseHelper.client
              .from('test_results')
              .insert({
                'user_id': user.id,
                'test_type': _testType.name,
                'code': calc.code,
                'percentages': calc.percentages,
              })
              .select('id')
              .single();
          _savedResultId = inserted['id'] as int?;

          await SupabaseHelper.client.from('profiles').update({
            'personality_type': calc.code,
            'scores': calc.percentages,
            'last_test_date': DateTime.now().toIso8601String(),
          }).eq('id', user.id);
        } catch (e) {
          debugPrint('Error saving result: $e');
        }
      }

      // اكتمل الاختبار — لا داعي لاستئنافه لاحقاً
      await clearProgress();

      // التحليل الشخصي يُحمَّل في الخلفية ولا يعطل عرض النتيجة
      _fetchAnalysis();
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> _fetchAnalysis() async {
    if (_resultCode == null) return;
    _isAnalysisLoading = true;
    notifyListeners();

    try {
      final res = await SupabaseHelper.client.functions.invoke(
        'analyze-result',
        body: {
          'code': _resultCode,
          'percentages': _percentages,
          'test_type': _testType.name,
        },
      );
      final data = res.data;
      final text = (data is Map) ? data['analysis'] as String? : null;
      if (text != null && text.isNotEmpty) {
        _aiAnalysis = text;
        // حفظ التحليل مع النتيجة المخزنة
        if (_savedResultId != null) {
          try {
            await SupabaseHelper.client
                .from('test_results')
                .update({'ai_analysis': text}).eq('id', _savedResultId!);
          } catch (e) {
            debugPrint('Error saving analysis: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching analysis: $e');
    } finally {
      _isAnalysisLoading = false;
      notifyListeners();
    }
  }
}
