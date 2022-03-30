import 'package:bloc/bloc.dart';
import 'package:mcbroken/data/models/mcdonalds_model.dart';
import 'package:mcbroken/data/repository/mcdonalds_repository.dart';
import 'package:mcbroken/logic/cubit/internet_cubit.dart';
import 'package:meta/meta.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final InternetCubit internetCubit;
  late final McDonaldsRepository mcDonaldsRepository;

  HomeBloc(this.internetCubit, this.mcDonaldsRepository)
      : super(HomeStateInitial()) {
    on<DataRequestEvent>((event, emit) async {
      emit(HomeStateLoading());
      try {
        final Mcdonalds_model mcdonaldsData =
            await mcDonaldsRepository.getDatafromMcDonalds();
        emit(HomeStateLoaded(mcdonaldsData));
      } catch (e) {
        emit(HomeStateError(e.toString()));
      }
    });
  }
}
