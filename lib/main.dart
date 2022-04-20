import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mcbroken/logic/bloc/home_bloc.dart';
import 'package:mcbroken/logic/cubit/internet_cubit.dart';
import 'package:mcbroken/presentation/screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MyApp(
      connectivity: Connectivity(),
    ),
  );
}

class MyApp extends StatelessWidget {
  final Connectivity connectivity;

  const MyApp({Key? key, required this.connectivity}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final InternetCubit internetCubit =
        InternetCubit(connectivity: connectivity);
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: internetCubit),
        BlocProvider<HomeBloc>(
          create: (context) => HomeBloc(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'McBroken',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
