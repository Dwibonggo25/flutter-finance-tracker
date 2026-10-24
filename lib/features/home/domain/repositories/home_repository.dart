import '../entities/weather_entity.dart';

abstract class HomeRepository {
  Future<WeatherEntity> getWeather();
}
