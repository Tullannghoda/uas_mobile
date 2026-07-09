import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class LocalStorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('LocalStorageService belum diinisialisasi');
    }
    return _prefs!;
  }

  // ─── TOKEN ─────────────────────────────
  static Future<void> saveToken(String token) async =>
      await prefs.setString(AppConstants.keyToken, token);

  static String? getToken() =>
      prefs.getString(AppConstants.keyToken);

  static Future<void> clearToken() async =>
      await prefs.remove(AppConstants.keyToken);

  // ─── USER ──────────────────────────────
  static Future<void> saveUser({
    required String id,
    required String name,
    required String email,
    required String role,
    String? phone,
    String? department,
  }) async {
    await prefs.setString(AppConstants.keyUserId, id);
    await prefs.setString(AppConstants.keyUserName, name);
    await prefs.setString(AppConstants.keyUserEmail, email);
    await prefs.setString(AppConstants.keyUserRole, role);
    if (phone != null) await prefs.setString('user_phone', phone);
    if (department != null) await prefs.setString('user_department', department);
  }

  static String? getUserId() =>
      prefs.getString(AppConstants.keyUserId);

  static String? getUserName() =>
      prefs.getString(AppConstants.keyUserName);

  static String? getUserEmail() =>
      prefs.getString(AppConstants.keyUserEmail);

  static String? getUserRole() =>
      prefs.getString(AppConstants.keyUserRole);

  static String? getUserPhone() =>
      prefs.getString('user_phone');

  static String? getUserDepartment() =>
      prefs.getString('user_department');

  // ─── THEME ─────────────────────────────
  static Future<void> saveThemeMode(bool isDark) async =>
      await prefs.setBool(AppConstants.keyThemeMode, isDark);

  static bool isDarkMode() =>
      prefs.getBool(AppConstants.keyThemeMode) ?? false;

  // ─── CLEAR ─────────────────────────────
  static Future<void> clearAll() async =>
      await prefs.clear();

  static bool isLoggedIn() =>
      getToken() != null;
}