// filepath: /Users/janikkahle/Documents/Development/Projekte/Mobile/mcbroken_app/lib/logic/cubits/settings/settings_cubit.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings_state.dart';

/// Cubit zur Verwaltung der Benutzereinstellungen
///
/// Der SettingsCubit ist verantwortlich für das Laden, Speichern und Aktualisieren
/// von Benutzereinstellungen wie Kartendarstellung, Filter und Anzeigeoptionen.
class SettingsCubit extends Cubit<SettingsState> {
  /// Konstanten für die SharedPreferences-Keys
  static const String _keyShowOwnPosition = 'show_own_position';
  static const String _keyShowOnlyWorking = 'show_only_working';
  static const String _keyShowOnlyDefect = 'show_only_defect';
  static const String _keyAllowRotation = 'allow_rotation';
  static const String _keyAllowZoom = 'allow_zoom';
  
  /// Instanz von SharedPreferences für persistente Speicherung
  final SharedPreferences _sharedPreferences;

  /// Erstellt eine neue Instanz des SettingsCubit
  ///
  /// [sharedPreferences] wird für die persistente Speicherung der Einstellungen verwendet.
  /// Die Einstellungen werden beim Start aus SharedPreferences geladen.
  SettingsCubit({required SharedPreferences sharedPreferences}) 
      : _sharedPreferences = sharedPreferences,
        super(SettingsState(
          showOwnPosition: sharedPreferences.getBool(_keyShowOwnPosition) ?? true,
          showOnlyWorking: sharedPreferences.getBool(_keyShowOnlyWorking) ?? false,
          showOnlyDefect: sharedPreferences.getBool(_keyShowOnlyDefect) ?? false,
          allowRotation: sharedPreferences.getBool(_keyAllowRotation) ?? true,
          allowZoom: sharedPreferences.getBool(_keyAllowZoom) ?? true,
        ));

  /// Aktiviert oder deaktiviert die Anzeige der eigenen Position
  ///
  /// [value] gibt an, ob die eigene Position angezeigt werden soll
  Future<void> togglePositionSwitch(bool value) async {
    await _sharedPreferences.setBool(_keyShowOwnPosition, value);
    emit(state.copyWith(showOwnPosition: value));
  }

  /// Aktiviert oder deaktiviert die Anzeige von nur funktionierenden Eismaschinen
  ///
  /// [value] gibt an, ob nur funktionierende Eismaschinen angezeigt werden sollen
  Future<void> toggleWorkingSwitch(bool value) async {
    await _sharedPreferences.setBool(_keyShowOnlyWorking, value);
    emit(state.copyWith(showOnlyWorking: value));
  }

  /// Aktiviert oder deaktiviert die Anzeige von nur defekten Eismaschinen
  ///
  /// [value] gibt an, ob nur defekte Eismaschinen angezeigt werden sollen
  Future<void> toggleDefectSwitch(bool value) async {
    await _sharedPreferences.setBool(_keyShowOnlyDefect, value);
    emit(state.copyWith(showOnlyDefect: value));
  }

  /// Aktiviert oder deaktiviert die Kartenrotation
  ///
  /// [value] gibt an, ob die Karte rotiert werden kann
  Future<void> toggleRotationSwitch(bool value) async {
    await _sharedPreferences.setBool(_keyAllowRotation, value);
    emit(state.copyWith(allowRotation: value));
  }

  /// Aktiviert oder deaktiviert das Zoomen der Karte
  ///
  /// [value] gibt an, ob die Karte gezoomt werden kann
  Future<void> toggleZoomSwitch(bool value) async {
    await _sharedPreferences.setBool(_keyAllowZoom, value);
    emit(state.copyWith(allowZoom: value));
  }
}
