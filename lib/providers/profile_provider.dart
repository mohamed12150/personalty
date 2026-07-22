import 'package:flutter/material.dart';
import '../models/profile.dart';
import '../core/push_service.dart';
import '../core/supabase_client.dart';

class ProfileProvider extends ChangeNotifier {
  Profile? _profile;
  bool _isLoading = false;

  Profile? get profile => _profile;
  bool get isLoading => _isLoading;

  /// Fetch user profile from Supabase 'profiles' table
  Future<void> fetchProfile(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await SupabaseHelper.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      _profile = Profile.fromJson(response);
      // وسم جهاز المستخدم بنمطه — للإشعارات المستهدفة
      PushService.tagPersonality(_profile?.personalityType);
      // تسجيل آخر ظهور — لفلترة النشطين في لوحة التحكم
      SupabaseHelper.client
          .from('profiles')
          .update({'last_seen': DateTime.now().toUtc().toIso8601String()})
          .eq('id', userId)
          .then((_) {}, onError: (e) => debugPrint('last_seen error: $e'));
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update user's personality type after a test
  Future<void> updatePersonality(String userId, String personality) async {
    try {
      await SupabaseHelper.client
          .from('profiles')
          .update({'personality_type': personality})
          .eq('id', userId);
      
      // Refresh local profile
      await fetchProfile(userId);
    } catch (e) {
      debugPrint("Error updating personality: $e");
    }
  }

  /// حفظ هوية المستخدم: النوع والعمر (مرة واحدة — السيرفر يمنع تغييرهما لاحقاً) والأفاتار
  Future<bool> updateIdentity(
    String userId, {
    String? gender,
    String? ageRange,
    int? avatarId,
  }) async {
    try {
      await SupabaseHelper.client.from('profiles').update({
        'gender': gender,
        'age_range': ageRange,
        'identity_set': true,
      }).eq('id', userId);

      // الأفاتار عبر دالة السيرفر لينتشر على الخواطر والتعليقات القديمة
      if (avatarId != null) {
        await SupabaseHelper.client
            .rpc('set_avatar', params: {'p_avatar_id': avatarId});
      }

      await fetchProfile(userId);
      return true;
    } catch (e) {
      debugPrint('Error updating identity: $e');
      return false;
    }
  }

  /// تغيير الاسم المستعار — ينتشر على كل المحتوى القديم عبر السيرفر
  Future<String?> setUsername(String name) async {
    try {
      final res = await SupabaseHelper.client
          .rpc('set_username', params: {'p_name': name});
      if (res is Map && res['ok'] == true) {
        await refresh();
        return null;
      }
      return (res is Map ? res['error']?.toString() : null) ?? 'unknown';
    } catch (e) {
      debugPrint('Error setting username: $e');
      return 'network';
    }
  }

  /// إعادة تحميل البروفايل (بعد شراء أو مكافأة)
  Future<void> refresh() async {
    final id = _profile?.id;
    if (id != null) await fetchProfile(id);
  }

  void clearProfile() {
    _profile = null;
    notifyListeners();
  }
}
