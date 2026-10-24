import '../../domain/entities/weather_entity.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_data_source.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDatasource remote;

  HomeRepositoryImpl(this.remote);

  @override
  Future<WeatherEntity> getWeather() async {
    return await remote.getWeather();
  }
}
