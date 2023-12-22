import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mcbroken/data/models/mcdonalds_model.dart';
import 'package:mcbroken/logic/blocs/home/home_bloc.dart';
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
    final HomeBloc homeBloc = context.read<HomeBloc>();

    final List<Mcdonalds_model> workingList = homeBloc.mcDonaldsData
        .where((element) => element.properties.is_broken == false)
        .toList();
    final List<Mcdonalds_model> notWorkingList = homeBloc.mcDonaldsData
        .where((element) => element.properties.is_broken == true)
        .toList();

    return BlocBuilder<SettingsCubit, SettingsState>(
      buildWhen: (old, next) => old != next,
      builder: (builderContext, state) {
        return SizedBox(
          child: SettingsList(
            applicationType: ApplicationType.both,
            sections: [
              SettingsSection(
                title: Text(locale.information),
                tiles: [
                  SettingsTile(
                    title: Text(locale.iceMachineTotal),
                    value: Text(homeBloc.mcDonaldsData.length.toString()),
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
              SettingsSection(
                title: Text(locale.map),
                tiles: [
                  SettingsTile.switchTile(
                    initialValue: state.showOwnPosition,
                    onToggle: (value) => context
                        .read<SettingsCubit>()
                        .togglePositionSwitch(value),
                    title: Text(locale.showOwnPosition),
                  ),
                  SettingsTile.switchTile(
                    initialValue: state.showOnlyWorking,
                    onToggle: (value) => context
                        .read<SettingsCubit>()
                        .toggleWorkingSwitch(value),
                    title: Text(locale.showOnlyWorking),
                  ),
                  SettingsTile.switchTile(
                    initialValue: state.showOnlyDefect,
                    onToggle: (value) =>
                        context.read<SettingsCubit>().toggleDefectSwitch(value),
                    title: Text(locale.showOnlyDefect),
                  ),
                  SettingsTile.switchTile(
                    initialValue: state.allowRotation,
                    onToggle: (value) => context
                        .read<SettingsCubit>()
                        .toggleRotationSwitch(value),
                    title: Text(locale.allowRotation),
                  ),
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
