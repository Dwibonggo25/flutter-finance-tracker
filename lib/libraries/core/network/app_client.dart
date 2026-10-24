import 'package:dio/dio.dart';
import '../storage/token_storage.dart';
import 'auth_interceptor.dart';

class ApiClient {
  final Dio dio;

  ApiClient(TokenStorage tokenStorage)
    : dio = Dio(
        BaseOptions(baseUrl: "https://api.openweathermap.org/data/2.5"),
      ) {
    dio.interceptors.add(AuthInterceptor(dio: dio, tokenStorage: tokenStorage));
  }
}
