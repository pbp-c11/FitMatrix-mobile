import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static const _defaultHost = 'https://fadhil-daffa-fitmatrix.pbp.cs.ui.ac.id';

  static const _apiBaseUrlRaw = String.fromEnvironment(
    'FITMATRIX_API_BASE',
    defaultValue: '$_defaultHost/api/',
  );

  static const _mediaBaseUrlRaw = String.fromEnvironment(
    'FITMATRIX_MEDIA_BASE',
    defaultValue: _defaultHost,
  );
  
  static String get apiBaseUrl => _normalizeBaseUrl(_apiBaseUrlRaw);
  static String get mediaBaseUrl => _normalizeBaseUrl(_mediaBaseUrlRaw);

  static String _normalizeBaseUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return url;

    final host = uri.host;

    // `10.0.2.2` only works inside Android emulators; map it for web runs.
    if (kIsWeb && host == '10.0.2.2') {
      return uri.replace(host: '127.0.0.1').toString();
    }

    // `localhost` points at the emulator/device itself on Android.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      if (host == 'localhost' || host == '127.0.0.1') {
        return uri.replace(host: '10.0.2.2').toString();
      }
    }

    return url;
  }
}

final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('SharedPreferences not initialized'),
);
