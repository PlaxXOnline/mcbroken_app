part of 'home_bloc.dart';

@immutable
abstract class HomeState {}

class HomeStateInitial extends HomeState {}

class HomeStateLoading extends HomeState {}

class HomeStateLoaded extends HomeState {
  final List<Mcdonalds_model> mcdonalds_data;
  final Position position;
  final bool filtered;
  final bool? showOnlyBroken;
  final DateTime lastUpdated;

  HomeStateLoaded(
    this.mcdonalds_data, 
    this.position, {
    this.filtered = false,
    this.showOnlyBroken,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();
  
  HomeStateLoaded copyWith({
    List<Mcdonalds_model>? mcdonalds_data,
    Position? position,
    bool? filtered,
    bool? showOnlyBroken,
    DateTime? lastUpdated,
  }) {
    return HomeStateLoaded(
      mcdonalds_data ?? this.mcdonalds_data,
      position ?? this.position,
      filtered: filtered ?? this.filtered,
      showOnlyBroken: showOnlyBroken ?? this.showOnlyBroken,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class HomeStateError extends HomeState {
  final String error;
  final bool canRetry;

  HomeStateError(this.error, {this.canRetry = true});
}
