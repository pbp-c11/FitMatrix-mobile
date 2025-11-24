import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config.dart';

final baseOptionsProvider = Provider<BaseOptions>((ref) {
  return BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json'},
  );
});

final unauthenticatedDioProvider = Provider<Dio>((ref) {
  final options = ref.watch(baseOptionsProvider);
  return Dio(options);
});
