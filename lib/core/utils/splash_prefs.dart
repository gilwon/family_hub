// lib/core/utils/splash_prefs.dart
// 스플래시 이미지 로컬 경로 저장/조회

import 'package:shared_preferences/shared_preferences.dart';

class SplashPrefs {
  static const _key = 'splash_image_path';

  static Future<String?> getImagePath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  static Future<void> setImagePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, path);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
