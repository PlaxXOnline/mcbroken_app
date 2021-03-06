import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mcbroken/data/models/mcdonalds_model.dart';
import 'package:mcbroken/data/repository/mcdonalds_repository.dart';
import 'package:mcbroken/logic/cubit/internet_cubit.dart';
import 'package:meta/meta.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final InternetCubit? internetCubit;
  final McDonaldsRepository mcDonaldsRepository = McDonaldsRepository();
  late StreamSubscription? internetStreamSubscription;
  late final List<Mcdonalds_model> mcDonaldsData;

  HomeBloc({this.internetCubit}) : super(HomeStateInitial()) {
    print("HomeState initializing...");

    on<DataRequestEvent>((event, emit) async {
      emit(HomeStateLoading());
      mcDonaldsData = await mcDonaldsRepository.getDatafromMcDonalds();
      emit(HomeStateLoaded(mcDonaldsData));
      print('HomeState Loaded');
    });
  }
  @override
  Future<void> close() {
    internetStreamSubscription?.cancel();
    return super.close();
  }
}
