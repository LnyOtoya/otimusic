// lib/services/storage_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _serverAddressKey = 'server_address';
  static const _usernameKey = 'username';
  static const _passwordKey = 'password';

  // 保存登录信息
  static Future<void> saveLoginInfo(
    String serverAddress,
    String username,
    String password,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_serverAddressKey, serverAddress);
    await prefs.setString(_usernameKey, username);
    await prefs.setString(_passwordKey, password);
  }

  // 获取保存的登录信息
  static Future<Map<String, String>?> getLoginInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final serverAddress = prefs.getString(_serverAddressKey);
    final username = prefs.getString(_usernameKey);
    final password = prefs.getString(_passwordKey);

    if (serverAddress != null && username != null && password != null) {
      return {
        'serverAddress': serverAddress,
        'username': username,
        'password': password,
      };
    }
    return null;
  }

  // 清除登录信息（退出登录）
  static Future<void> clearLoginInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_serverAddressKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_passwordKey);
  }
}
