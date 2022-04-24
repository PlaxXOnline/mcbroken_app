part of 'home_bloc.dart';

late final McDonaldsRepository mcDonaldsRepository = McDonaldsRepository();

@immutable
abstract class HomeState {}

class HomeStateInitial extends HomeState {}

class HomeStateLoading extends HomeState {}

class HomeStateLoaded extends HomeState {
  final List<Mcdonalds_model> mcdonalds_data;

  HomeStateLoaded(this.mcdonalds_data);
}

class HomeStateError extends HomeState {
  final String error;

  HomeStateError(this.error);
}
