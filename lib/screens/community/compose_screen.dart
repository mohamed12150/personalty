import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../providers/posts_provider.dart';
import '../../widgets/editorial.dart';

/// كتابة خاطرة — تمر على بوابة الفلترة قبل النشر
class ComposeScreen extends StatefulWidget {
  const ComposeScreen({super.key});

  @override
  State<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends State<ComposeScreen> {
  final _controller = TextEditingController();
  bool _publishing = false;
  String? _rejectionReason;

  static const _maxLength = 500;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    final content = _controller.text.trim();
    if (content.isEmpty || _publishing) return;

    setState(() {
      _publishing = true;
      _rejectionReason = null;
    });

    final result = await context.read<PostsProvider>().createPost(content);
    if (!mounted) return;

    if (result.ok) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.reward > 0
                ? 'نُشرت خاطرتك ✓ — وكسبت ${arabicDigits(result.reward)} ورقة على أول خاطرة 🍃'
                : 'نُشرت خاطرتك ✓',
          ),
        ),
      );
    } else {
      setState(() {
        _publishing = false;
        _rejectionReason = result.rejectionReason ??
            (result.error == 'network'
                ? 'تعذّر الاتصال — حاول مجدداً'
                : 'حدث خطأ، حاول مجدداً');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _maxLength - _controller.text.length;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: Icon(Icons.close,
                        size: 20, color: AppColors.ink),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const Spacer(),
                  Text(
                    arabicDigits(remaining),
                    style: AppType.ui(
                      size: 12,
                      weight: FontWeight.w700,
                      color: remaining < 50
                          ? AppColors.orange
                          : AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('خاطرة جديدة', style: AppType.display(size: 26)),
              const SizedBox(height: 4),
              Text(
                'فضفض، احكِ موقفاً، أو شارك ملاحظة — نمطك سيظهر بجانبها',
                style: AppType.ui(size: 12, color: AppColors.inkSoft),
              ),
              const SizedBox(height: 14),
              Container(height: 3, color: AppColors.ink),
              const SizedBox(height: 3),
              const Hairline(),
              const SizedBox(height: 14),
              Expanded(
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  expands: true,
                  maxLength: _maxLength,
                  textAlignVertical: TextAlignVertical.top,
                  style: AppType.display(size: 17, height: 1.9),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'اكتب من قلبك…',
                    hintStyle: AppType.display(
                        size: 17, color: AppColors.inkSoft),
                    border: InputBorder.none,
                    counterText: '',
                  ),
                ),
              ),
              if (_rejectionReason != null) ...[
                Container(
                  decoration: BoxDecoration(
                    border: BorderDirectional(
                      start: BorderSide(color: AppColors.orange, width: 3),
                    ),
                  ),
                  padding: const EdgeInsetsDirectional.only(start: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'لم تُنشر الخاطرة',
                        style: AppType.ui(
                          size: 12.5,
                          weight: FontWeight.w700,
                          color: AppColors.orange,
                        ),
                      ),
                      Text(
                        _rejectionReason!,
                        style: AppType.ui(size: 12, color: AppColors.inkMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              InkButton(
                label: _publishing ? 'يُراجَع ويُنشر…' : 'انشر خاطرتك',
                expanded: true,
                shadowColor: AppColors.green,
                onTap: _controller.text.trim().isEmpty || _publishing
                    ? null
                    : _publish,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
