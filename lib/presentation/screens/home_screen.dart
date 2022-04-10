import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mcbroken/constants/enums.dart';
import 'package:mcbroken/logic/bloc/home_bloc.dart';
import 'package:mcbroken/logic/cubit/internet_cubit.dart';
import 'package:mcbroken/presentation/widgets/map.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              print('such was');
              //BlocProvider.of<HomeBloc>(context).add(DataRequestEvent());
            },
          ),
        ],
        leading: Image.asset(
          'assets/flurry_icon.ico',
        ),
        title: const Text('McBroken'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          children: [
            Builder(
              builder: (blocContext) {
                var state = context.watch<InternetCubit>().state;
                print(state);
                if (state is InternetConnected &&
                        state.connectionType == ConnectionType.Wifi ||
                    state is InternetConnected &&
                        state.connectionType == ConnectionType.Mobile) {
                  context.read<HomeBloc>().add(DataRequestEvent());
                  return Flexible(
                    child: Builder(
                      builder: ((context) {
                        final homeBloc = context.watch<HomeBloc>().state;
                        if (homeBloc is HomeStateLoaded) {
                          return McDonaldsMap(
                            mcdonalds_data: homeBloc.mcdonalds_data,
                          );
                        } else if (homeBloc is HomeStateError) {
                          return Center(
                            child: Text(homeBloc.error),
                          );
                        } else {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                      }),
                    ),
                  );
                } else if (state is InternetDisconnected) {
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
