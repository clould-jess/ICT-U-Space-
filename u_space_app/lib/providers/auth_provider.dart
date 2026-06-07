import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';

final apiServiceProvider = Provider((ref) => ApiService());

final authStateProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier(ref.read(apiServiceProvider));
});

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final ApiService _apiService;

  AuthNotifier(this._apiService) : super(const AsyncValue.data(null));

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _apiService.login(email, password);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<bool> checkAutoLogin() async {
    try {
      final token = await _apiService.getToken();
      if (token == null || token.isEmpty) return false;
      
      final user = await _apiService.getMe();
      state = AsyncValue.data(user);
      return true;
    } catch (_) {
      // Token invalid or network error
      await _apiService.removeToken();
      return false;
    }
  }

  /// Sign up a new user. Role is auto-detected on the backend from [matricule].
  Future<void> signup(String name, String email, String password, String matricule) async {
    state = const AsyncValue.loading();
    try {
      final user = await _apiService.signup(name, email, password, matricule);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Refresh user profile from the backend (e.g. after profile update).
  Future<void> refreshProfile() async {
    try {
      final user = await _apiService.getMe();
      state = AsyncValue.data(user);
    } catch (_) {
      // silently ignore — stale state is still usable
    }
  }

  Future<void> logout() async {
    await _apiService.removeToken();
    // Clear any locally persisted role overrides from the old flow
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('user_role_'));
    for (final k in keys) {
      await prefs.remove(k);
    }
    state = const AsyncValue.data(null);
  }
}
