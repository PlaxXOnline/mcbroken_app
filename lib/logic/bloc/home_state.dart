part of 'home_bloc.dart';

@immutable
abstract class HomeState {}

class HomeStateInitial extends HomeState {}

class HomeStateLoading extends HomeState {}

class HomeStateLoaded extends HomeState {}

class HomeStateError extends HomeState {}
