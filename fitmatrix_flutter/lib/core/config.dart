import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'FITMATRIX_API_BASE',
    defaultValue: kIsWeb ? 'http://127.0.0.1:8001/api/' : 'http://10.0.2.2:8001/api/',
  );
  static const mediaBaseUrl = String.fromEnvironment(
    'FITMATRIX_MEDIA_BASE',
    defaultValue: kIsWeb ? 'http://127.0.0.1:8001' : 'http://10.0.2.2:8001',
  );
}

final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('SharedPreferences not initialized'),
);
