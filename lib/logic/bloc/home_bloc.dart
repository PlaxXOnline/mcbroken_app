import 'package:bloc/bloc.dart';
import 'package:mcbroken/data/repository/mcdonalds_repository.dart';
import 'package:meta/meta.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  late final McDonaldsRepository mcDonaldsRepository;

  HomeBloc() : super(HomeStateInitial()) {
    on<DataRequestEvent>((event, emit) async {
      emit(HomeStateLoading());
    });
  }
}
