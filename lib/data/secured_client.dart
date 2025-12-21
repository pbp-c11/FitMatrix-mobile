import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_controller.dart';
import 'network.dart';

final dioProvider = Provider<Dio>((ref) {
  final options = ref.watch(baseOptionsProvider);
  final dio = Dio(options);
  final auth = ref.watch(authControllerProvider);

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = auth.state.accessToken;
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final shouldRetry =
            error.response?.statusCode == 401 &&
            auth.state.refreshToken != null &&
            error.requestOptions.extra['retried'] != true;
        if (shouldRetry) {
          final newToken = await auth.refreshTokens();
          if (newToken != null) {
            final requestOptions = error.requestOptions;
            requestOptions.headers['Authorization'] = 'Bearer $newToken';
            requestOptions.extra['retried'] = true;
            try {
              final clonedResponse = await dio.fetch(requestOptions);
              return handler.resolve(clonedResponse);
            } catch (_) {
              // fall through to default handler
            }
          }
        }
        handler.next(error);
      },
    ),
  );
  dio.interceptors.add(LogInterceptor(requestBody: false, responseBody: false));
  return dio;
});
