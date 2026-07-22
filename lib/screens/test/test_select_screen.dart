import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../providers/test_provider.dart';
import '../../widgets/editorial.dart';

class TestSelectScreen extends StatefulWidget {
  const TestSelectScreen({super.key});

  @override
  State<TestSelectScreen> createState() => _TestSelectScreenState();
}

class _TestSelectScreenState extends State<TestSelectScreen>
    with WidgetsBindingObserver {
  SavedTest? _saved;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSaved();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // تحديث بطاقة الاستئناف عند العودة للتطبيق
    if (state == AppLifecycleState.resumed) _loadSaved();
  }

  Future<void> _loadSaved() async {
    final saved = await context.read<TestProvider>().savedTest();
    if (mounted) setState(() => _saved = saved);
  }

  Future<void> _start(TestType type) async {
    if (_busy) return;
    setState(() => _busy = true);
    await context.read<TestProvider>().startTest(type);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _saved = null;
    });
    context.push('/test').then((_) => _loadSaved());
  }

  Future<void> _resume() async {
    if (_busy) return;
    setState(() => _busy = true);
    final ok = await context.read<TestProvider>().resumeSavedTest();
    if (!mounted) return;
    setState(() => _busy = false);

    if (ok) {
      context.push('/test').then((_) => _loadSaved());
    } else {
      setState(() => _saved = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر استئناف الاختبار — ابدأ اختباراً جديداً')),
      );
    }
  }

  Future<void> _discard() async {
    await context.read<TestProvider>().clearProgress();
    if (mounted) setState(() => _saved = null);
  }

  @override
  Widget build(BuildContext context) {
    final saved = _saved;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            Masthead(
              title: 'الاختبار',
              accent: AppColors.green,
              subtitle: 'اعرف نمطك من بين ستة عشر نمطاً',
            ),
            const SizedBox(height: 24),

            if (saved != null) ...[
              _ResumeCard(
                saved: saved,
                busy: _busy,
                onResume: _resume,
                onDiscard: _discard,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: Container(height: 1, color: AppColors.hairline)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'أو ابدأ من جديد',
                      style: AppType.ui(size: 11, color: AppColors.inkSoft),
                    ),
                  ),
                  Expanded(child: Container(height: 1, color: AppColors.hairline)),
                ],
              ),
              const SizedBox(height: 20),
            ],

            _TestOption(
              number: '01',
              title: 'الاختبار السريع',
              meta: '${arabicDigits(16)} سؤالاً · ${arabicDigits(3)} دقائق',
              note: 'نظرة أولى جيدة على نمط شخصيتك.',
              accent: AppColors.green,
              onTap: () => _start(TestType.quick),
            ),
            const SizedBox(height: 16),
            _TestOption(
              number: '02',
              title: 'الاختبار الكامل',
              meta: '${arabicDigits(48)} سؤالاً · ${arabicDigits(10)} دقائق',
              note: 'النتيجة الأدق والأعمق — نوصي به.',
              accent: AppColors.violet,
              onTap: () => _start(TestType.full),
            ),
            const SizedBox(height: 24),
            Text(
              'لا توجد إجابات صحيحة أو خاطئة. أجب كما أنت فعلاً، لا كما تودّ أن تكون.',
              style: AppType.ui(size: 12, color: AppColors.inkSoft, height: 1.8),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.bookmark_border, size: 13, color: AppColors.inkSoft),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'يمكنك التوقف في أي سؤال والعودة لاحقاً — تقدّمك محفوظ.',
                    style: AppType.ui(size: 11.5, color: AppColors.inkSoft),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// بطاقة استئناف الاختبار المتوقف
class _ResumeCard extends StatelessWidget {
  final SavedTest saved;
  final bool busy;
  final VoidCallback onResume;
  final VoidCallback onDiscard;

  const _ResumeCard({
    required this.saved,
    required this.busy,
    required this.onResume,
    required this.onDiscard,
  });

  @override
  Widget build(BuildContext context) {
    final accent =
        saved.type == TestType.full ? AppColors.violet : AppColors.green;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.ink, width: 1.2),
        boxShadow: [BoxShadow(color: accent, offset: const Offset(-4, 4))],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CategoryTab(label: 'اختبار متوقف', color: accent),
              const Spacer(),
              Text(
                arabicTimeAgo(saved.savedAt),
                style: AppType.ui(size: 10.5, color: AppColors.inkSoft),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            saved.type == TestType.full
                ? 'أكمل اختبارك الكامل'
                : 'أكمل اختبارك السريع',
            style: AppType.display(size: 23, height: 1.35),
          ),
          const SizedBox(height: 4),
          Text(
            'أجبت عن ${arabicDigits(saved.answered)} من ${arabicDigits(saved.total)} سؤالاً',
            style: AppType.ui(size: 12.5, color: AppColors.inkMuted),
          ),
          const SizedBox(height: 12),
          RulerProgress(progress: saved.progress, accent: accent),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: InkButton(
                  label: busy ? 'جارٍ الفتح…' : 'أكمل من حيث توقفت',
                  expanded: true,
                  shadowColor: accent,
                  onTap: busy ? null : onResume,
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: busy ? null : onDiscard,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 12),
                  child: Text(
                    'تجاهل',
                    style: AppType.ui(
                      size: 12.5,
                      weight: FontWeight.w700,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TestOption extends StatelessWidget {
  final String number;
  final String title;
  final String meta;
  final String note;
  final Color accent;
  final VoidCallback onTap;

  const _TestOption({
    required this.number,
    required this.title,
    required this.meta,
    required this.note,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration:
            BoxDecoration(border: Border.all(color: AppColors.hairline)),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  arabicDigits(number),
                  style: AppType.ui(
                    size: 12,
                    weight: FontWeight.w700,
                    color: accent,
                    letterSpacing: 2,
                  ),
                ),
                const Spacer(),
                Text(meta, style: AppType.ui(size: 11, color: AppColors.inkSoft)),
              ],
            ),
            const SizedBox(height: 8),
            Text(title, style: AppType.display(size: 22, height: 1.3)),
            const SizedBox(height: 4),
            Text(note, style: AppType.ui(size: 12.5, color: AppColors.inkMuted)),
            const SizedBox(height: 14),
            InkButton(label: 'ابدأ', shadowColor: accent, onTap: onTap),
          ],
        ),
      ),
    );
  }
}
