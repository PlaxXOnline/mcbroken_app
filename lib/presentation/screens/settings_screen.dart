import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mcbroken/constants/enums.dart';
import 'package:mcbroken/logic/blocs/settingsbloc/settings_bloc.dart';
import 'package:mcbroken/logic/cubits/internetcubit/internet_cubit.dart';
import 'package:settings_ui/settings_ui.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: BackButton(
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Hero(
            tag: 'flurry_icon',
            child: Image.asset(
              'assets/flurry_icon.ico',
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          children: [
            Builder(
              builder: (blocContext) {
                var internetState = context.watch<InternetCubit>().state;
                log(internetState.toString());
                if (internetState is InternetConnected &&
                        internetState.connectionType == ConnectionType.wifi ||
                    internetState is InternetConnected &&
                        internetState.connectionType == ConnectionType.mobile) {
                  return Flexible(
                    child: Builder(
                      builder: ((context) {
                        final settingsState =
                            context.watch<SettingsBloc>().state;
                        if (settingsState is SettingsStateLoaded) {
                          return SettingsList(
                            sections: [
                              SettingsSection(
                                title: const Text('General'),
                                tiles: [
                                  SettingsTile.navigation(
                                    leading: const Icon(Icons.language),
                                    title: const Text('Language'),
                                    value: const Text('English'),
                                  ),
                                ],
                              ),
                            ],
                          );
                        } else if (settingsState is SettingsStateError) {
                          return Center(
                            child: Text(settingsState.error),
                          );
                        } else {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                      }),
                    ),
                  );
                } else if (internetState is InternetDisconnected) {
                  return const Text('Keine Internetverbindung.');
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
            /* Divider(
              height: 5,
            ), */
          ],
        ),
      ),

      /* SettingsList(
        sections: [
          SettingsSection(
            title: const Text('General'),
            tiles: [
              SettingsTile.navigation(
                leading: const Icon(Icons.language),
                title: const Text('Language'),
                value: const Text('English'),
              ),
            ],
          ),
        ],
      ), */
    );
  }
}
