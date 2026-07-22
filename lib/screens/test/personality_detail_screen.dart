import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/supabase_client.dart';
import '../../core/theme.dart';
import '../../models/personality_type.dart';
import '../../providers/test_provider.dart';
import '../../widgets/editorial.dart';

/// التقرير الكامل لنمط شخصية — يُفتح من النتيجة أو من البروفايل بكود محدد
class PersonalityDetailScreen extends StatefulWidget {
  final String? code;

  const PersonalityDetailScreen({super.key, this.code});

  @override
  State<PersonalityDetailScreen> createState() =>
      _PersonalityDetailScreenState();
}

class _PersonalityDetailScreenState extends State<PersonalityDetailScreen> {
  PersonalityType? _type;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final fromTest = context.read<TestProvider>().resultType;
    if (fromTest != null &&
        (widget.code == null || widget.code == fromTest.code)) {
      setState(() {
        _type = fromTest;
        _loading = false;
      });
      return;
    }

    if (widget.code == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final row = await SupabaseHelper.client
          .from('personality_types')
          .select()
          .eq('code', widget.code!)
          .single();
      if (mounted) {
        setState(() {
          _type = PersonalityType.fromJson(row);
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading personality type: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.ink,
            ),
          ),
        ),
      );
    }

    final type = _type;
    if (type == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('لم نجد هذا النمط.', style: AppType.display(size: 20)),
              const SizedBox(height: 16),
              GhostButton(label: 'عودة', onTap: () => context.pop()),
            ],
          ),
        ),
      );
    }

    final accent = AppColors.accentByName(type.colorName);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: Icon(Icons.arrow_forward,
                      size: 20, color: AppColors.ink),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const Spacer(),
                Text(
                  type.code,
                  style: AppType.mono(size: 15, letterSpacing: 4),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              type.nameAr,
              style: AppType.display(size: 36, weight: FontWeight.w700, height: 1.25),
            ),
            const SizedBox(height: 4),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  type.groupAr,
                  style: AppType.ui(size: 13.5, weight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Container(height: 5, width: 68, color: accent),
              ],
            ),
            const SizedBox(height: 18),
            const Hairline(),
            const SizedBox(height: 20),

            SectionHead(number: '01', title: 'من هو ${type.nameAr}؟', accent: accent),
            const SizedBox(height: 12),
            Text(
              type.description,
              style: AppType.display(size: 16, height: 1.95),
            ),
            const SizedBox(height: 26),

            SectionHead(number: '02', title: 'نقاط القوة', accent: accent),
            _MarkedList(items: type.strengths, accent: accent),
            const SizedBox(height: 26),

            SectionHead(number: '03', title: 'نقاط الضعف', accent: accent),
            _MarkedList(items: type.weaknesses, accent: AppColors.inkSoft),
            const SizedBox(height: 26),

            SectionHead(number: '04', title: 'في العلاقات', accent: accent),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: BorderDirectional(
                  start: BorderSide(color: accent, width: 3),
                ),
              ),
              padding: const EdgeInsetsDirectional.only(start: 14),
              child: Text(
                type.relationships,
                style: AppType.ui(size: 14, height: 1.9, color: AppColors.inkMuted),
              ),
            ),
            const SizedBox(height: 26),

            SectionHead(number: '05', title: 'مسارات مهنية تناسبك', accent: accent),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final career in type.careers)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.hairline),
                    ),
                    child: Text(career, style: AppType.ui(size: 12.5)),
                  ),
              ],
            ),
            const SizedBox(height: 26),

            SectionHead(number: '06', title: 'مشاهير من نمطك', accent: accent),
            const SizedBox(height: 12),
            Text(
              type.famousPeople.join(' · '),
              style: AppType.display(size: 16, height: 1.8),
            ),
            const SizedBox(height: 32),
            GhostButton(
              label: 'عودة',
              expanded: true,
              onTap: () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarkedList extends StatelessWidget {
  final List<String> items;
  final Color accent;

  const _MarkedList({required this.items, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final item in items)
          Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.hairline)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Row(
              children: [
                Container(width: 7, height: 7, color: accent),
                const SizedBox(width: 12),
                Expanded(child: Text(item, style: AppType.ui(size: 13.5))),
              ],
            ),
          ),
      ],
    );
  }
}
