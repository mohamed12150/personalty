import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseHelper {
  static const String url = 'https://zamhprqbqglboskklrfi.supabase.co';
  static const String anonKey = 'sb_publishable_It2GrZ9pUOlcg8SH04w96g_PLLk6iGN';

  /// معرف عميل الويب (Web Client ID) من Google Cloud Console —
  /// مطلوب لتسجيل الدخول الأصلي داخل التطبيق
  static const String googleWebClientId =
      '504974804977-ja07qtmuincqf869p316ocnjrsvgr9qb.apps.googleusercontent.com';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
