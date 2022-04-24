part of 'settings_bloc.dart';

@immutable
abstract class SettingsEvent {}

class LanguageChanged extends SettingsEvent {
  final String language;

  LanguageChanged({required this.language});
}
