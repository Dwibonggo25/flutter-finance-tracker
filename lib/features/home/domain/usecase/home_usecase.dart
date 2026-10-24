import '../entities/weather_entity.dart';
import '../repositories/home_repository.dart';

class HomeUsecase {
  final HomeRepository repository;

  HomeUsecase(this.repository);

  Future<WeatherEntity> call() {
    return repository.getWeather();
  }
}
