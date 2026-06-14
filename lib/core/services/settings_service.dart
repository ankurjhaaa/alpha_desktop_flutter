import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class SettingsService {
  static const String _settingsKey = 'app_global_settings';

  static Future<void> fetchAndCacheSettings() async {
    try {
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/settings'));
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        // Save the raw JSON string
        await prefs.setString(_settingsKey, response.body);
      }
    } catch (e) {
      // Silently fail if network is down, will use cached or fallback values
    }
  }

  static Future<Map<String, dynamic>> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final String? settingsStr = prefs.getString(_settingsKey);
    
    if (settingsStr != null) {
      try {
        return jsonDecode(settingsStr);
      } catch (e) {
        return {};
      }
    }
    return {};
  }

  static Future<String?> getSetting(String key) async {
    final settings = await getSettings();
    return settings[key]?.toString();
  }
}
