import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'repositories.dart';
import 'session.dart';

/// App store backed by the real API. Active only when `API_BASE` is set;
/// otherwise the app keeps running on the offline DemoStore.
class ApiStore extends ChangeNotifier {
  ApiStore._(this.client, this.session, this.repos);

  final ApiClient client;
  final ApiSession session;
  final ApiRepositories repos;

  static ApiStore? _instance;
  static ApiStore? get instanceOrNull => _instance;
  static bool get enabled => const String.fromEnvironment('API_BASE').isNotEmpty;

  static Future<ApiStore?> boot() async {
    if (!enabled) return null;
    final prefs = await SharedPreferences.getInstance();
    final client = ApiClient();
    final session = ApiSession(client, prefs);
    _instance = ApiStore._(client, session, ApiRepositories(client, session));
    if (session.isAuthenticated) {
      // Revalidate the stored token in the background.
      unawaited(session.refreshUser().then((u) {
        if (u != null) _instance?.notifyListeners();
      }).catchError((_) {}));
    }
    return _instance;
  }

  Map<String, dynamic>? get user => session.user;
  bool get isAuthenticated => session.isAuthenticated;

  Future<void> login(String email, String password) async {
    await session.login(email: email, password: password);
    notifyListeners();
  }

  Future<void> register(String email, String password, String name) async {
    await session.register(
        email: email, password: password, displayName: name);
    notifyListeners();
  }

  Future<void> logout() async {
    await session.logout();
    notifyListeners();
  }
}
