import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config.dart';
import 'models/user.dart';
import 'network.dart';

class AuthState {
  final bool loading;
  final User? user;
  final String? accessToken;
  final String? refreshToken;
  final String? error;

  const AuthState({
    this.loading = false,
    this.user,
    this.accessToken,
    this.refreshToken,
    this.error,
  });

  bool get isAuthenticated =>
      user != null && (accessToken?.isNotEmpty ?? false);

  AuthState copyWith({
    bool? loading,
    User? user,
    String? accessToken,
    String? refreshToken,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      loading: loading ?? this.loading,
      user: user ?? this.user,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthController extends ChangeNotifier {
  AuthController(this._dio, this._prefs);

  final Dio _dio;
  final SharedPreferences _prefs;
  AuthState _state = const AuthState(loading: true);

  AuthState get state => _state;

  Future<void> hydrate() async {
    final storedAccess = _prefs.getString(_kAccess);
    final storedRefresh = _prefs.getString(_kRefresh);
    if (storedAccess != null && storedRefresh != null) {
      _state = _state.copyWith(
        accessToken: storedAccess,
        refreshToken: storedRefresh,
      );
      notifyListeners();
      try {
        final user = await _fetchMe(storedAccess);
        _state = _state.copyWith(user: user, loading: false, clearError: true);
      } on DioException catch (err) {
        final shouldTryRefresh = err.response?.statusCode == 401;
        if (shouldTryRefresh) {
          final refreshed = await refreshTokens();
          if (refreshed != null) {
            final user = await _fetchMe(refreshed);
            _state = _state.copyWith(
              user: user,
              loading: false,
              clearError: true,
            );
          } else {
            await logout();
          }
        } else {
          await logout();
        }
      }
    } else {
      _state = _state.copyWith(loading: false);
    }
    notifyListeners();
  }

  Future<User?> login(String identifier, String password) async {
    _state = _state.copyWith(loading: true, clearError: true);
    notifyListeners();
    return _authenticate(
      identifier: identifier,
      password: password,
      fallbackError: 'Unable to sign in',
    );
  }

  Future<User?> register({
    required String username,
    required String email,
    required String password,
    String? displayName,
  }) async {
    _state = _state.copyWith(loading: true, clearError: true);
    notifyListeners();
    try {
      await _dio.post(
        '${AppConfig.apiBaseUrl}auth/register/',
        data: {
          'username': username,
          'email': email,
          'password': password,
          if (displayName != null && displayName.isNotEmpty)
            'display_name': displayName,
        },
      );
      return await _authenticate(
        identifier: username,
        password: password,
        fallbackError: 'Unable to sign in after registering',
      );
    } on DioException catch (err) {
      _state = _state.copyWith(
        loading: false,
        error: _extractError(err, 'Unable to register'),
      );
      notifyListeners();
      return null;
    } catch (_) {
      _state = _state.copyWith(loading: false, error: 'Unable to register');
      notifyListeners();
      return null;
    }
  }

  Future<String?> refreshTokens() async {
    if (_state.refreshToken == null) return null;
    try {
      final res = await _dio.post(
        '${AppConfig.apiBaseUrl}auth/token/refresh/',
        data: {'refresh': _state.refreshToken},
      );
      final newAccess = res.data['access'] as String?;
      if (newAccess != null) {
        await _prefs.setString(_kAccess, newAccess);
        _state = _state.copyWith(accessToken: newAccess, clearError: true);
        notifyListeners();
      }
      return newAccess;
    } on DioException catch (err) {
      _state = _state.copyWith(error: _extractError(err, 'Session expired'));
      notifyListeners();
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    await _prefs.remove(_kAccess);
    await _prefs.remove(_kRefresh);
    _state = const AuthState(loading: false);
    notifyListeners();
  }

  Future<User> _fetchMe(String accessToken) async {
    final res = await _dio.get(
      '${AppConfig.apiBaseUrl}auth/me/',
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
    );
    return User.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> _persistTokens(String access, String refresh) async {
    await _prefs.setString(_kAccess, access);
    await _prefs.setString(_kRefresh, refresh);
  }

  Future<User?> _authenticate({
    required String identifier,
    required String password,
    required String fallbackError,
  }) async {
    try {
      final tokenRes = await _dio.post(
        '${AppConfig.apiBaseUrl}auth/token/',
        data: {
          'identifier': identifier,
          'username': identifier,
          'password': password,
        },
      );
      final access = tokenRes.data['access'] as String?;
      final refresh = tokenRes.data['refresh'] as String?;
      if (access == null || refresh == null) {
        throw Exception('Invalid credentials');
      }
      await _persistTokens(access, refresh);
      final user = await _fetchMe(access);
      _state = _state.copyWith(
        user: user,
        accessToken: access,
        refreshToken: refresh,
        loading: false,
      );
      notifyListeners();
      return user;
    } on DioException catch (err) {
      _state = _state.copyWith(
        loading: false,
        error: _extractError(err, fallbackError),
      );
      notifyListeners();
      return null;
    } catch (_) {
      _state = _state.copyWith(loading: false, error: fallbackError);
      notifyListeners();
      return null;
    }
  }

  String _extractError(DioException err, String fallback) {
    final data = err.response?.data;
    if (data is Map<String, dynamic>) {
      if (data['detail'] is String) return data['detail'] as String;
      for (final value in data.values) {
        if (value is List && value.isNotEmpty && value.first is String) {
          return value.first as String;
        }
        if (value is String) return value;
      }
    }
    return fallback;
  }
}

const _kAccess = 'fitmatrix_access';
const _kRefresh = 'fitmatrix_refresh';

final authControllerProvider = ChangeNotifierProvider<AuthController>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  final dio = ref.watch(unauthenticatedDioProvider);
  final controller = AuthController(dio, prefs);
  controller.hydrate();
  return controller;
});
