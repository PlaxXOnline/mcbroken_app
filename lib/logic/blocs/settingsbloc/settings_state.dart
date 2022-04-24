part of 'settings_bloc.dart';

@immutable
abstract class SettingsState {}

class SettingsStateInitial extends SettingsState {}

class SettingsStateLoading extends SettingsState {}

class SettingsStateLoaded extends SettingsState {}

class SettingsStateError extends SettingsState {
  final String error;

  SettingsStateError({required this.error});
}
