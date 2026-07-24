import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsHelper {
  static const String _keyServerUrl = 'print_server_url';
  static const String _keyAppId = 'print_app_id';
  static const String _keyAppToken = 'print_app_token';
  static const String _keyEnabled = 'print_enabled';

  Future<void> savePrintConfig({
    required String serverUrl,
    required String appId,
    required String appToken,
    required bool enabled,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyServerUrl, serverUrl);
    await prefs.setString(_keyAppId, appId);
    await prefs.setString(_keyAppToken, appToken);
    await prefs.setBool(_keyEnabled, enabled);
  }

  Future<Map<String, dynamic>> getPrintConfig() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'serverUrl': prefs.getString(_keyServerUrl) ?? '',
      'appId': prefs.getString(_keyAppId) ?? '',
      'appToken': prefs.getString(_keyAppToken) ?? '',
      'enabled': prefs.getBool(_keyEnabled) ?? false,
    };
  }
}
