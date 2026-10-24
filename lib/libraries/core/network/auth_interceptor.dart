import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

class AuthInterceptor extends Interceptor {
  final Dio dio;
  final TokenStorage tokenStorage;

  bool _isRefreshing = false;
  final List<RequestOptions> _queue = [];

  AuthInterceptor({required this.dio, required this.tokenStorage});

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = tokenStorage.accessToken;

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final requestOptions = err.requestOptions;

      // kalau lagi refresh → queue request
      if (_isRefreshing) {
        _queue.add(requestOptions);
        return;
      }

      _isRefreshing = true;

      final newToken = await _refreshToken();

      if (newToken != null) {
        await tokenStorage.saveAccessToken(newToken);

        // retry original request
        requestOptions.headers['Authorization'] = 'Bearer $newToken';
        final response = await dio.fetch(requestOptions);

        // retry queued requests
        for (final req in _queue) {
          req.headers['Authorization'] = 'Bearer $newToken';
          dio.fetch(req);
        }

        _queue.clear();
        _isRefreshing = false;

        return handler.resolve(response);
      } else {
        // refresh gagal → logout
        _isRefreshing = false;
        _queue.clear();

        await tokenStorage.clear();

        return handler.next(err);
      }
    }

    return handler.next(err);
  }

  Future<String?> _refreshToken() async {
    try {
      final refreshToken = tokenStorage.refreshToken;

      if (refreshToken == null) return null;

      final response = await dio.post(
        '/auth/refresh',
        data: {"refresh_token": refreshToken},
        options: Options(
          headers: {
            'Authorization': null, // penting!
          },
        ),
      );

      return response.data['access_token'];
    } catch (e) {
      return null;
    }
  }
}
