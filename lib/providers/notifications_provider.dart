import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../models/app_notification.dart';

class NotificationsProvider extends ChangeNotifier {
  List<AppNotification> _items = [];
  bool _isLoading = false;
  bool _soundEnabled = true;
  RealtimeChannel? _channel;
  final _player = AudioPlayer();

  /// آخر إشعار وصل أثناء فتح التطبيق — لعرض شريط تنبيه سريع
  AppNotification? _incoming;

  List<AppNotification> get items => _items;
  bool get isLoading => _isLoading;
  bool get soundEnabled => _soundEnabled;
  int get unreadCount => _items.where((n) => !n.isRead).length;
  AppNotification? get incoming => _incoming;

  NotificationsProvider() {
    _loadSoundPref();
  }

  Future<void> _loadSoundPref() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _soundEnabled = prefs.getBool('notify_sound') ?? true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading sound pref: $e');
    }
  }

  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notify_sound', value);
    } catch (e) {
      debugPrint('Error saving sound pref: $e');
    }
    if (value) playSound(); // معاينة فورية عند التفعيل
  }

  /// نغمة قصيرة + اهتزاز خفيف
  Future<void> playSound() async {
    if (!_soundEnabled) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/notify.wav'), volume: 0.7);
      HapticFeedback.lightImpact();
    } catch (e) {
      debugPrint('Error playing notification sound: $e');
    }
  }

  void consumeIncoming() => _incoming = null;

  Future<void> fetch() async {
    final user = SupabaseHelper.client.auth.currentUser;
    if (user == null) {
      if (_items.isNotEmpty) {
        _items = [];
        notifyListeners();
      }
      return;
    }

    _subscribe(user.id);

    _isLoading = true;
    notifyListeners();

    try {
      final response = await SupabaseHelper.client
          .from('notifications')
          .select()
          .order('created_at', ascending: false)
          .limit(50);
      _items = (response as List)
          .map((n) => AppNotification.fromJson(n))
          .toList();
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// الاستماع اللحظي: أي إشعار جديد يظهر ويُسمع فوراً دون تحديث
  void _subscribe(String userId) {
    if (_channel != null) return;
    try {
      _channel = SupabaseHelper.client
          .channel('notifications:$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'notifications',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: userId,
            ),
            callback: (payload) {
              try {
                final item = AppNotification.fromJson(payload.newRecord);
                if (_items.any((n) => n.id == item.id)) return;
                _items = [item, ..._items];
                _incoming = item;
                notifyListeners();
                playSound();
              } catch (e) {
                debugPrint('Error handling realtime notification: $e');
              }
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('Error subscribing to notifications: $e');
    }
  }

  Future<void> _unsubscribe() async {
    final channel = _channel;
    _channel = null;
    if (channel != null) {
      try {
        await SupabaseHelper.client.removeChannel(channel);
      } catch (e) {
        debugPrint('Error removing channel: $e');
      }
    }
  }

  /// تعليم الكل كمقروء — يُستدعى عند فتح صفحة الإشعارات
  Future<void> markAllRead() async {
    if (unreadCount == 0) return;
    _items = _items.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();

    try {
      await SupabaseHelper.client.rpc('mark_notifications_read');
    } catch (e) {
      debugPrint('Error marking notifications read: $e');
    }
  }

  void clear() {
    _items = [];
    _incoming = null;
    _unsubscribe();
    notifyListeners();
  }

  @override
  void dispose() {
    _unsubscribe();
    _player.dispose();
    super.dispose();
  }
}
