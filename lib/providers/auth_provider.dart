import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  User? _user;
  String? _lastError;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  User? get user => _user;
  String? get lastError => _lastError;

  AuthProvider() {
    _user = SupabaseHelper.client.auth.currentUser;

    // مزامنة حالة الدخول مع أي تغيير
    SupabaseHelper.client.auth.onAuthStateChange.listen((data) {
      _user = data.session?.user;
      notifyListeners();
    });
  }

  /// تسجيل دخول جوجل الأصلي — قائمة الحسابات تظهر داخل التطبيق
  /// (على الويب فقط نستخدم تحويل المتصفح لأن القائمة الأصلية غير متاحة)
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      if (kIsWeb) {
        final ok = await SupabaseHelper.client.auth.signInWithOAuth(
          OAuthProvider.google,
        );
        _isLoading = false;
        notifyListeners();
        return ok;
      }

      final googleSignIn = GoogleSignIn(
        serverClientId: SupabaseHelper.googleWebClientId,
      );
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // المستخدم أغلق القائمة
        _lastError = 'أُغلقت نافذة الاختيار قبل الإتمام';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        throw const AuthException(
            'no_id_token: لم نستلم رمز الدخول — راجع serverClientId');
      }

      await SupabaseHelper.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: googleAuth.accessToken,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      _lastError = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// حذف الحساب نهائياً — مطلب متاجر التطبيقات
  /// يُحذف حساب المصادقة من السيرفر ويجرّ كل البيانات والمحتوى معه
  Future<bool> deleteAccount() async {
    try {
      await SupabaseHelper.client.rpc('delete_my_account');
      // تنظيف الجلسة محلياً بعد زوال الحساب من السيرفر
      try {
        if (!kIsWeb) await GoogleSignIn().signOut();
      } catch (_) {}
      try {
        await SupabaseHelper.client.auth.signOut();
      } catch (_) {}
      _user = null;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting account: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      if (!kIsWeb) await GoogleSignIn().signOut();
    } catch (e) {
      debugPrint('Error signing out of Google: $e');
    }
    await SupabaseHelper.client.auth.signOut();
    _user = null;
    notifyListeners();
  }
}
