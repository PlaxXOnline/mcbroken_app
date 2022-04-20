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
        /* actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              print('such was');
              //BlocProvider.of<HomeBloc>(context).add(DataRequestEvent());
            },
          ),
        ], */
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
                var internetState = context.watch<InternetCubit>().state;
                print(internetState);
                if (internetState is InternetConnected &&
                        internetState.connectionType == ConnectionType.Wifi ||
                    internetState is InternetConnected &&
                        internetState.connectionType == ConnectionType.Mobile) {
                  context.read<HomeBloc>().add(DataRequestEvent());
                  return Flexible(
                    child: Builder(
                      builder: ((context) {
                        final homeState = context.watch<HomeBloc>().state;
                        if (homeState is HomeStateLoaded) {
                          return McDonaldsMap();
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
