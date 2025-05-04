// filepath: /Users/janikkahle/Documents/Development/Projekte/Mobile/mcbroken_app/lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:mcbroken/constants/bloc_observer.dart';
import 'package:mcbroken/core/di/injection_container.dart';
import 'package:mcbroken/logic/blocs/home/home_bloc.dart';
import 'package:mcbroken/logic/cubits/connectivity/internet_cubit.dart';
import 'package:mcbroken/logic/cubits/settings/settings_cubit.dart';
import 'package:mcbroken/presentation/screens/home_screen.dart';
import 'package:mcbroken/services/background_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Haupteinstiegspunkt der Anwendung
///
/// Diese Funktion initialisiert alle notwendigen Services und startet die Anwendung.
/// Hier werden wichtige Konfigurationen wie Dependency Injection, Benachrichtigungen
/// und Hintergrund-Services eingerichtet, bevor die Flutter-App gestartet wird.
void main() async {
  // BloC-Observer für Debugging registrieren
  Bloc.observer = AppBlocObserver();
  
  // Flutter-Framework initialisieren
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  
  // Native Splash Screen anzeigen während App lädt
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
  // Dependency Injection initialisieren
  await initDependencies();
  
  // Benachrichtigungen initialisieren
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
    FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings initializationSettingsAndroid = 
    AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings initializationSettingsIOS = 
    DarwinInitializationSettings();
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  
  // Hintergrund-Service initialisieren
  await BackgroundDataService.initializeService();
  
  // App starten
  runApp(const MyApp());
}

/// Die Hauptanwendungsklasse
///
/// Diese Klasse ist der Einstiegspunkt der Anwendung und setzt die grundlegende
/// Struktur der Anwendung fest, einschließlich der Theme-Konfiguration und
/// der Registrierung der Blocs und Cubits.
class MyApp extends StatelessWidget {
  /// Erstellt eine neue Instanz der MyApp
  const MyApp({Key? key}) : super(key: key);

  /// Baut die Widget-Hierarchie für die Anwendung auf
  ///
  /// Diese Methode wird vom Flutter-Framework aufgerufen, um die UI zu erstellen.
  /// Die Methode konfiguriert die Hauptkomponenten der App, wie Provider, Themes
  /// und die initiale Route.
  ///
  /// [context] Der BuildContext, der für den Zugriff auf die Widget-Hierarchie verwendet wird
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Alle Blocs und Cubits aus dem serviceLocator beziehen
        BlocProvider<InternetCubit>(
          create: (_) => serviceLocator<InternetCubit>(),
        ),
        BlocProvider<HomeBloc>(
          create: (_) => serviceLocator<HomeBloc>(),
        ),
        BlocProvider<SettingsCubit>(
          create: (_) => serviceLocator<SettingsCubit>(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          primaryColor: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
