import 'package:flutter/material.dart';
import '../core/supabase_client.dart';
import '../models/catalog_items.dart';

/// نتيجة عملية شراء/دعم من دوال السيرفر
class EconomyResult {
  final bool ok;
  final String? error;
  final int? balance;

  const EconomyResult({required this.ok, this.error, this.balance});

  factory EconomyResult.fromJson(dynamic json) {
    if (json is! Map) return const EconomyResult(ok: false, error: 'unknown');
    return EconomyResult(
      ok: json['ok'] == true,
      error: json['error']?.toString(),
      balance: (json['balance'] as num?)?.toInt(),
    );
  }

  /// رسالة عربية جاهزة للعرض عند الفشل
  String get message {
    switch (error) {
      case 'balance':
        return 'أوراقك لا تكفي 🍃 — اجمع المزيد من اللغز اليومي';
      case 'auth':
        return 'سجّل الدخول أولاً';
      case 'own_post':
        return 'لا يمكنك دعم خاطرتك';
      case 'already_attempted':
        return 'جربت لغز اليوم بالفعل — عُد غداً';
      case 'expired':
        return 'انتهى وقت هذا اللغز';
      default:
        return 'حدث خطأ، حاول مجدداً';
    }
  }
}

class EconomyProvider extends ChangeNotifier {
  List<AvatarItem> _avatars = [];
  List<ColorItem> _colors = [];
  bool _loaded = false;

  List<AvatarItem> get avatars => _avatars;
  List<ColorItem> get colors => _colors;
  bool get loaded => _loaded;

  AvatarItem? avatarById(int? id) {
    if (id == null) return null;
    for (final a in _avatars) {
      if (a.id == id) return a;
    }
    return null;
  }

  String? avatarPath(int? id) => avatarById(id)?.assetPath;

  List<AvatarItem> avatarsOfPack(String pack) =>
      _avatars.where((a) => a.pack == pack).toList();

  Future<void> fetchCatalogs() async {
    if (_loaded) return;
    try {
      final avatarsRes =
          await SupabaseHelper.client.from('avatar_catalog').select().order('id');
      final colorsRes = await SupabaseHelper.client
          .from('color_catalog')
          .select()
          .order('sort_order');
      _avatars =
          (avatarsRes as List).map((j) => AvatarItem.fromJson(j)).toList();
      _colors = (colorsRes as List).map((j) => ColorItem.fromJson(j)).toList();
      _loaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching catalogs: $e');
    }
  }

  Future<EconomyResult> buyColor(String color) async {
    try {
      final res = await SupabaseHelper.client
          .rpc('buy_color', params: {'p_color': color});
      return EconomyResult.fromJson(res);
    } catch (e) {
      debugPrint('buy_color error: $e');
      return const EconomyResult(ok: false, error: 'network');
    }
  }

  Future<EconomyResult> buyAvatar(int avatarId) async {
    try {
      final res = await SupabaseHelper.client
          .rpc('buy_avatar', params: {'p_avatar_id': avatarId});
      return EconomyResult.fromJson(res);
    } catch (e) {
      debugPrint('buy_avatar error: $e');
      return const EconomyResult(ok: false, error: 'network');
    }
  }

  Future<EconomyResult> supportPost(int postId, int leaves) async {
    try {
      final res = await SupabaseHelper.client.rpc(
        'support_post',
        params: {'p_post_id': postId, 'p_leaves': leaves},
      );
      return EconomyResult.fromJson(res);
    } catch (e) {
      debugPrint('support_post error: $e');
      return const EconomyResult(ok: false, error: 'network');
    }
  }
}
