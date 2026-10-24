import '../../../../libraries/core/network/app_client.dart';
import '../models/weather_model.dart';

class HomeRemoteDatasource {
  final ApiClient apiClient;

  HomeRemoteDatasource(this.apiClient);

  Future<WeatherModel> getWeather() async {
    const apiKey = String.fromEnvironment('OPENWEATHER_API_KEY');

    if (apiKey.isEmpty) {
      throw StateError('OPENWEATHER_API_KEY is not configured');
    }

    final response = await apiClient.dio.get(
      '/weather',
      queryParameters: {'q': 'Jakarta', 'appid': apiKey, 'units': 'metric'},
    );

    return WeatherModel.fromJson(response.data);
  }
}
