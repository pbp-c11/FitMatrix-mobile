import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static const apiBaseUrl =
      String.fromEnvironment('FITMATRIX_API_BASE', defaultValue: 'http://10.0.2.2:8000/api/');
  static const mediaBaseUrl =
      String.fromEnvironment('FITMATRIX_MEDIA_BASE', defaultValue: 'http://10.0.2.2:8000');
}

final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('SharedPreferences not initialized'),
);
