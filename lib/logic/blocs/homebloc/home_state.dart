part of 'home_bloc.dart';

late final McDonaldsRepository mcDonaldsRepository = McDonaldsRepository();

@immutable
abstract class HomeState {}

class HomeStateInitial extends HomeState {}

class HomeStateLoading extends HomeState {}

class HomeStateLoaded extends HomeState {
  final List<McDonaldsModel> mcDonaldsData;

  HomeStateLoaded(this.mcDonaldsData);
}

class HomeStateError extends HomeState {
  final String error;

  HomeStateError(this.error);
}
