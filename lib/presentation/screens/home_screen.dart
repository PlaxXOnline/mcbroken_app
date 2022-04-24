import 'dart:developer';

import 'package:anim_search_bar/anim_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mcbroken/constants/enums.dart';
import 'package:mcbroken/logic/blocs/homebloc/home_bloc.dart';
import 'package:mcbroken/logic/cubits/internetcubit/internet_cubit.dart';
import 'package:mcbroken/presentation/screens/settings_screen.dart';
import 'package:mcbroken/presentation/widgets/map.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.settings_rounded),
          ),
        ],
        leading: Hero(
          tag: 'flurry_icon',
          child: Image.asset(
            'assets/flurry_icon.ico',
          ),
        ),
        title: const Text('McBroken'),
        centerTitle: true,
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
                  context.read<HomeBloc>().add(DataRequestEvent());
                  return Flexible(
                    child: Builder(
                      builder: ((context) {
                        final homeState = context.watch<HomeBloc>().state;
                        if (homeState is HomeStateLoaded) {
                          return SafeArea(
                            bottom: false,
                            child: Stack(
                              children: [
                                const McDonaldsMap(),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    right: 10.0,
                                    left: 10.0,
                                  ),
                                  child: AnimSearchBar(
                                    color: Theme.of(context).primaryColor,
                                    style: const TextStyle(
                                      color: Colors.white,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.search_rounded,
                                      color: Colors.white,
                                    ),
                                    rtl: true,
                                    width: size.width,
                                    textController:
                                        homeState.textEditingController,
                                    onSuffixTap: () {},
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else if (homeState is HomeStateError) {
                          return Center(
                            child: Text(homeState.error),
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
    );
  }
}
