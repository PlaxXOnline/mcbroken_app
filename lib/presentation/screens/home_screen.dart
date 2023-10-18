import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mcbroken/constants/enums.dart';
import 'package:mcbroken/logic/homebloc/home_bloc.dart';
import 'package:mcbroken/logic/cubit/internet_cubit.dart';
import 'package:mcbroken/presentation/widgets/map.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    FlutterNativeSplash.remove();
    final AppLocalizations locale = AppLocalizations.of(context)!;
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
        title: Text(
          locale.appTitle,
          style: GoogleFonts.courgette(),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          children: [
            Builder(
              builder: (blocContext) {
                var internetState = context.watch<InternetCubit>().state;
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
                          return const McDonaldsMap();
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
                  return Text(locale.noConnection);
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
