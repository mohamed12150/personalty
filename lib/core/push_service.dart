import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

/// إشعارات خارج التطبيق عبر OneSignal.
/// يبقى معطّلاً بأمان حتى يُملأ appId.
class PushService {
  /// App ID من لوحة OneSignal → Keys & IDs
  static const String appId = 'db7f5110-0613-4732-9c69-29aa8da2c55c';

  static bool get enabled => appId.isNotEmpty && !kIsWeb;
  static bool _initialized = false;

  /// يُستدعى مرة عند إقلاع التطبيق
  static Future<void> init() async {
    if (!enabled || _initialized) return;
    _initialized = true;
    try {
      OneSignal.initialize(appId);
      // طلب إذن الإشعارات (أندرويد 13+ يتطلبه)
      OneSignal.Notifications.requestPermission(false);
    } catch (e) {
      debugPrint('PushService init error: $e');
    }
  }

  /// ربط الجهاز بحساب المستخدم — الإرسال يستهدف معرفه مباشرة
  static Future<void> login(String userId) async {
    if (!enabled) return;
    try {
      await OneSignal.login(userId);
    } catch (e) {
      debugPrint('PushService login error: $e');
    }
  }

  static Future<void> logout() async {
    if (!enabled) return;
    try {
      await OneSignal.logout();
    } catch (e) {
      debugPrint('PushService logout error: $e');
    }
  }

  /// وسم الجهاز بنمط صاحبه — يتيح إرسالاً مستهدفاً ("كل الـ INFJ")
  static Future<void> tagPersonality(String? code) async {
    if (!enabled) return;
    try {
      if (code == null || code.isEmpty) {
        await OneSignal.User.removeTag('personality');
      } else {
        await OneSignal.User.addTagWithKey('personality', code);
      }
    } catch (e) {
      debugPrint('PushService tag error: $e');
    }
  }
}
