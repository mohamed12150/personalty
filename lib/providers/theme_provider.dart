import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

/// يدير وضع العرض (فاتح / داكن / حسب النظام) ويحفظ الاختيار على الجهاز
class ThemeProvider extends ChangeNotifier with WidgetsBindingObserver {
  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  ThemeProvider() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// يستدعيه النظام عند تبديل وضع الجهاز بين النهار والليل
  @override
  void didChangePlatformBrightness() {
    if (_mode == ThemeMode.system) {
      AppColors.dark = isDark;
      notifyListeners();
    }
  }

  /// هل الواجهة داكنة فعلياً الآن؟
  bool get isDark {
    if (_mode == ThemeMode.system) {
      return PlatformDispatcher.instance.platformBrightness == Brightness.dark;
    }
    return _mode == ThemeMode.dark;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('theme_mode');
    _mode = switch (saved) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    AppColors.dark = isDark;
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    AppColors.dark = isDark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.name);
  }
}
