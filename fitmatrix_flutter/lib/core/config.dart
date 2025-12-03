import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static const _apiBaseEnv = String.fromEnvironment(
    'FITMATRIX_API_BASE',
    defaultValue: '',
  );
  static const _mediaBaseEnv = String.fromEnvironment(
    'FITMATRIX_MEDIA_BASE',
    defaultValue: '',
  );
  static const _hostEnv = String.fromEnvironment(
    'FITMATRIX_HOST',
    defaultValue: '',
  );
  static const _portEnv = String.fromEnvironment(
    'FITMATRIX_PORT',
    defaultValue: '',
  );

  static String get apiBaseUrl {
    if (_apiBaseEnv.isNotEmpty) {
      return _ensureTrailingSlash(_apiBaseEnv);
    }
    final host = _platformHost();
    return '$host/api/';
  }

  static String get mediaBaseUrl {
    if (_mediaBaseEnv.isNotEmpty) {
      return _mediaBaseEnv.endsWith('/')
          ? _mediaBaseEnv.substring(0, _mediaBaseEnv.length - 1)
          : _mediaBaseEnv;
    }
    return _platformHost();
  }

  static String _platformHost() {
    final port = _portEnv.isNotEmpty ? _portEnv : '9000';
    final host = _hostEnv.isNotEmpty
        ? _hostEnv
        : switch (defaultTargetPlatform) {
            TargetPlatform.android when !kIsWeb => '10.0.2.2',
            _ => '127.0.0.1',
          };
    final base = host.startsWith('http') ? host : 'http://$host';
    return '$base:$port';
  }

  static String _ensureTrailingSlash(String value) {
    return value.endsWith('/') ? value : '$value/';
  }
}

final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('SharedPreferences not initialized'),
);
