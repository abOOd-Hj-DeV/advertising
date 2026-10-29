import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';

/// Sanctum token + current user, persisted across launches.
class ApiSession {
  ApiSession(this.client, this._prefs) {
    _token = _prefs.getString(_tokenKey);
    if (_token != null) client.token = _token;
  }

  static const _tokenKey = 'api.token';
  static const _userKey = 'api.user';

  final ApiClient client;
  final SharedPreferences _prefs;

  String? _token;
  Map<String, dynamic>? _user;

  bool get isAuthenticated => _token != null;
  Map<String, dynamic>? get user => _user;

  Future<void> _saveToken(String token) async {
    _token = token;
    client.token = token;
    await _prefs.setString(_tokenKey, token);
  }

  Future<void> logout() async {
    try {
      await client.post('/auth/logout');
    } catch (_) {}
    _token = null;
    _user = null;
    client.token = null;
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_userKey);
  }

  /// POST /auth/register → token + user
  Future<Map<String, dynamic>> register(
      {required String email,
      required String password,
      required String displayName}) async {
    final res = await client.post('/auth/register', body: {
      'email': email,
      'password': password,
      'password_confirmation': password,
      'display_name': displayName,
    });
    await _saveToken(res['token'] as String);
    _user = res['user'] as Map<String, dynamic>?;
    return _user ?? {};
  }

  Future<Map<String, dynamic>> login(
      {required String email, required String password}) async {
    final res = await client.post('/auth/login', body: {
      'email': email,
      'password': password,
    });
    await _saveToken(res['token'] as String);
    _user = res['user'] as Map<String, dynamic>?;
    return _user ?? {};
  }

  /// Stores a token+user pair returned by a custom call (register with extra fields).
  Future<void> adopt(Map<String, dynamic> res) async {
    await _saveToken(res['token'] as String);
    _user = res['user'] as Map<String, dynamic>?;
  }

  /// Refreshes the cached user via GET /me; returns null when unauthenticated.
  Future<Map<String, dynamic>?> refreshUser() async {
    if (!isAuthenticated) return null;
    try {
      final res = await client.get('/me');
      _user = res['data'] as Map<String, dynamic>?;
      return _user;
    } on ApiException catch (e) {
      if (e.status == 401) await logout();
      rethrow;
    }
  }
}
