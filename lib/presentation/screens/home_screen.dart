import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mcbroken/constants/enums.dart';
import 'package:mcbroken/logic/cubit/internet_cubit.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('McBroken'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          children: [
            BlocBuilder<InternetCubit, InternetState>(
              builder: (blocContext, state) {
                if (state is InternetConnected &&
                    state.connectionType == ConnectionType.Wifi) {
                  return const Text('Connection: Wifi');
                } else if (state is InternetConnected &&
                    state.connectionType == ConnectionType.Mobile) {
                  return const Text('Connection: Mobile');
                } else if (state is InternetDisconnected) {
                  return const Text('Keine Internetverbindung.');
                }
                return const CircularProgressIndicator();
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
