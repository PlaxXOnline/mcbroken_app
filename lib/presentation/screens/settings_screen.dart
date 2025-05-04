// filepath: /Users/janikkahle/Documents/Development/Projekte/Mobile/mcbroken_app/lib/presentation/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mcbroken/data/models/mcdonalds_location.dart';
import 'package:mcbroken/logic/blocs/home/home_bloc.dart';
import 'package:mcbroken/logic/cubits/settings/settings_cubit.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:settings_ui/settings_ui.dart';

/// Einstellungsbildschirm der Anwendung
///
/// Zeigt Statistiken über die verfügbaren McDonald's-Standorte und ermöglicht
/// die Konfiguration verschiedener App-Einstellungen.
class SettingsScreen extends StatelessWidget {
  /// Erstellt einen neuen SettingsScreen
  ///
  /// [key] ist ein optionaler Schlüssel zur Identifikation dieses Widgets
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Lokalisierungsobjekt für übersetzte Texte
    final AppLocalizations locale = AppLocalizations.of(context)!;
    
    return BlocBuilder<SettingsCubit, SettingsState>(
      buildWhen: (old, next) => old != next,
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              locale.settingsTitle,
              style: GoogleFonts.courgette(),
            ),
          ),
          body: buildSettingsList(context, state, locale),
        );
      },
    );
  }

  /// Erstellt die Einstellungsliste mit Statistikdaten und Konfigurationsoptionen
  ///
  /// [context] ist der aktuelle BuildContext für Zugriff auf Theme und andere Widget-Informationen
  /// [state] ist der aktuelle Zustand des SettingsCubit
  /// [locale] ist das Lokalisierungsobjekt für übersetzte Texte
  /// 
  /// Gibt ein Widget zurück, das die Einstellungsliste darstellt
  Widget buildSettingsList(
      BuildContext context, SettingsState state, AppLocalizations locale) {
    final Size size = MediaQuery.of(context).size;
    
    // Statistikdaten über McDonald's-Standorte abrufen
    List<McDonaldsLocation> allLocations = [];
    List<McDonaldsLocation> workingList = [];
    List<McDonaldsLocation> notWorkingList = [];
    
    // Daten aus dem aktuellen HomeBloc-Zustand extrahieren
    final homeState = context.watch<HomeBloc>().state;
    if (homeState is HomeStateLoaded) {
      allLocations = homeState.mcdonalds_data;
      workingList = allLocations.where((location) => !location.properties.isBroken).toList();
      notWorkingList = allLocations.where((location) => location.properties.isBroken).toList();
    } else if (homeState is HomeStateNoLocation) {
      allLocations = homeState.mcdonalds_data;
      workingList = allLocations.where((location) => !location.properties.isBroken).toList();
      notWorkingList = allLocations.where((location) => location.properties.isBroken).toList();
    } else if (homeState is HomeStateOffline) {
      allLocations = homeState.locations;
      workingList = allLocations.where((location) => !location.properties.isBroken).toList();
      notWorkingList = allLocations.where((location) => location.properties.isBroken).toList();
    }

    return BlocBuilder<SettingsCubit, SettingsState>(
      buildWhen: (old, next) => old != next,
      builder: (builderContext, state) {
        return SizedBox(
          child: SettingsList(
            applicationType: ApplicationType.both,
            sections: [
              // Informationsbereich mit Statistiken
              SettingsSection(
                title: Text(locale.information),
                tiles: [
                  SettingsTile(
                    title: Text(locale.iceMachineTotal),
                    value: Text(allLocations.length.toString()),
                  ),
                  SettingsTile(
                    title: Text(locale.iceMachineWorking),
                    value: Text(workingList.length.toString()),
                  ),
                  SettingsTile(
                    title: Text(locale.iceMachineDefect),
                    value: Text(notWorkingList.length.toString()),
                  ),
                ],
              ),
              // Karteneinstellungen
              SettingsSection(
                title: Text(locale.map),
                tiles: [
                  // Einstellung: Eigene Position anzeigen
                  SettingsTile.switchTile(
                    initialValue: state.showOwnPosition,
                    onToggle: (value) => context
                        .read<SettingsCubit>()
                        .togglePositionSwitch(value),
                    title: Text(locale.showOwnPosition),
                  ),
                  // Einstellung: Nur funktionierende Eismaschinen anzeigen
                  SettingsTile.switchTile(
                    initialValue: state.showOnlyWorking,
                    onToggle: (value) => context
                        .read<SettingsCubit>()
                        .toggleWorkingSwitch(value),
                    title: Text(locale.showOnlyWorking),
                  ),
                  // Einstellung: Nur defekte Eismaschinen anzeigen
                  SettingsTile.switchTile(
                    initialValue: state.showOnlyDefect,
                    onToggle: (value) =>
                        context.read<SettingsCubit>().toggleDefectSwitch(value),
                    title: Text(locale.showOnlyDefect),
                  ),
                  // Einstellung: Kartenrotation erlauben
                  SettingsTile.switchTile(
                    initialValue: state.allowRotation,
                    onToggle: (value) => context
                        .read<SettingsCubit>()
                        .toggleRotationSwitch(value),
                    title: Text(locale.allowRotation),
                  ),
                  // Einstellung: Kartenzoom erlauben
                  SettingsTile.switchTile(
                    initialValue: state.allowZoom,
                    onToggle: (value) =>
                        context.read<SettingsCubit>().toggleZoomSwitch(value),
                    title: Text(locale.allowZoom),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }
}
