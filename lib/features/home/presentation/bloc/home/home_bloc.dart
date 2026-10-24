import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/usecase/home_usecase.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final HomeUsecase usecase;

  HomeBloc(this.usecase) : super(HomeInitial()) {
    on<GetWeatherEvent>(_onGetWeather);
  }

  Future<void> _onGetWeather(
    GetWeatherEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(HomeLoading());

    try {
      final result = await usecase();
      emit(HomeLoaded(result));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }
}
