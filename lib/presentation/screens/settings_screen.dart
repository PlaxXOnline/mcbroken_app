import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mcbroken/logic/cubits/settings/settings_cubit.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:settings_ui/settings_ui.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    AppLocalizations locale = AppLocalizations.of(context)!;
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

  Widget buildSettingsList(
      BuildContext context, SettingsState state, AppLocalizations locale) {
    final Size size = MediaQuery.of(context).size;

    return BlocBuilder<SettingsCubit, SettingsState>(
      buildWhen: (old, next) => old != next,
      builder: (builderContext, state) {
        return SizedBox(
          child: SettingsList(
            applicationType: ApplicationType.both,
            sections: [
              SettingsSection(
                title: const Text('Informationen'),
                tiles: [
                  SettingsTile(
                    title: const Text('Eismaschinen gesamt:'),
                    value: const Text('100'),
                  ),
                  SettingsTile(
                    title: const Text('Eismaschinen funktionstüchtig:'),
                    value: const Text('30'),
                  ),
                  SettingsTile(
                    title: const Text('Eismaschinen defekt:'),
                    value: const Text('70'),
                  ),
                ],
              ),
              SettingsSection(
                title: const Text('Map'),
                tiles: [
                  SettingsTile.switchTile(
                    initialValue: false,
                    onToggle: (value) {},
                    title: const Text('Eigene Position anzeigen'),
                  ),
                  SettingsTile.switchTile(
                    initialValue: false,
                    onToggle: (value) {},
                    title: const Text('Nur funktionierende anzeigen'),
                  ),
                  SettingsTile.switchTile(
                    initialValue: false,
                    onToggle: (value) {},
                    title: const Text('Nur defekte anzeigen'),
                  ),
                  SettingsTile.switchTile(
                    initialValue: false,
                    onToggle: (value) {},
                    title: const Text('Rotieren erlauben'),
                  ),
                  SettingsTile.switchTile(
                    initialValue: false,
                    onToggle: (value) {},
                    title: const Text('Zoom erlauben'),
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
