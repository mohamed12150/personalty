import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../core/supabase_client.dart';
import '../core/theme.dart';
import 'editorial.dart';

/// إعلان منبثق يُدار من لوحة التحكم — يظهر مرة واحدة لكل مستخدم
/// دون أي تحديث للتطبيق (تهنئة عيد، إعلان ميزة، صيانة...)
class Announcement {
  final int id;
  final String title;
  final String body;
  final String emoji;
  final String accent;

  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.emoji,
    required this.accent,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
        id: json['id'] as int,
        title: json['title'] ?? '',
        body: json['body'] ?? '',
        emoji: json['emoji'] ?? '🎉',
        accent: json['accent'] ?? 'violet',
      );
}

/// يفحص الإعلانات النشطة ويعرض أول إعلان لم يره المستخدم بعد
Future<void> maybeShowAnnouncement(BuildContext context) async {
  try {
    final rows = await SupabaseHelper.client
        .from('announcements')
        .select()
        .order('created_at', ascending: false)
        .limit(5);

    final list = (rows as List).map((j) => Announcement.fromJson(j)).toList();
    if (list.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getStringList('seen_announcements') ?? [];

    Announcement? fresh;
    for (final a in list) {
      if (!seen.contains(a.id.toString())) {
        fresh = a;
        break;
      }
    }
    if (fresh == null || !context.mounted) return;

    // تسجيلها كمُشاهدة (مع حد أقصى للقائمة المحفوظة)
    final updated = [...seen, fresh.id.toString()];
    await prefs.setStringList(
      'seen_announcements',
      updated.length > 50 ? updated.sublist(updated.length - 50) : updated,
    );

    if (!context.mounted) return;
    final accent = AppColors.accentByName(fresh.accent);
    final announcement = fresh;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.ink, width: 1.2),
        ),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: accent, offset: const Offset(-4, 4))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(announcement.emoji, style: const TextStyle(fontSize: 40)),
              const SizedBox(height: 12),
              Text(
                announcement.title,
                style: AppType.display(size: 24, height: 1.4),
              ),
              const SizedBox(height: 4),
              Container(height: 4, width: 52, color: accent),
              const SizedBox(height: 12),
              Text(
                announcement.body,
                style: AppType.ui(
                  size: 14,
                  height: 1.9,
                  color: AppColors.inkMuted,
                ),
              ),
              const SizedBox(height: 20),
              InkButton(
                label: 'حسناً',
                expanded: true,
                shadowColor: accent,
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  } catch (e) {
    debugPrint('Error showing announcement: $e');
  }
}
