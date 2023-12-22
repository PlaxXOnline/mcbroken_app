part of 'settings_cubit.dart';

class SettingsState extends Equatable {
  const SettingsState({
    this.showOwnPosition = false,
    this.showOnlyWorking = false,
    this.showOnlyDefect = false,
    this.allowRotation = false,
    this.allowZoom = false,
  });

  final bool showOwnPosition;
  final bool showOnlyWorking;
  final bool showOnlyDefect;
  final bool allowRotation;
  final bool allowZoom;

  SettingsState copyWith({
    bool? showOwnPosition,
    bool? showOnlyWorking,
    bool? showOnlyDefect,
    bool? allowRotation,
    bool? allowZoom,
  }) {
    return SettingsState(
      showOwnPosition: showOwnPosition ?? this.showOwnPosition,
      showOnlyWorking: showOnlyWorking ?? this.showOnlyWorking,
      showOnlyDefect: showOnlyDefect ?? this.showOnlyDefect,
      allowRotation: allowRotation ?? this.allowRotation,
      allowZoom: allowZoom ?? this.allowZoom,
    );
  }

  @override
  List<Object> get props => [
        showOwnPosition,
        showOnlyWorking,
        showOnlyDefect,
        allowRotation,
        allowZoom
      ];
}
