part of 'home_bloc.dart';

late final McDonaldsRepository mcDonaldsRepository = McDonaldsRepository();

@immutable
abstract class HomeState {}

class HomeStateInitial extends HomeState {}

class HomeStateLoading extends HomeState {}

class HomeStateLoaded extends HomeState {
  final List<Mcdonalds_model> mcdonalds_data;
  final Position position;

  HomeStateLoaded(this.mcdonalds_data, this.position);
}

class HomeStateError extends HomeState {
  final String error;

  HomeStateError(this.error);
}
