// filepath: /Users/janikkahle/Documents/Development/Projekte/Mobile/mcbroken_app/lib/core/di/injection_container.dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:mcbroken/data/repository/mcdonalds_repository.dart';
import 'package:mcbroken/logic/blocs/home/home_bloc.dart';
import 'package:mcbroken/logic/cubits/connectivity/internet_cubit.dart';
import 'package:mcbroken/logic/cubits/settings/settings_cubit.dart';
import 'package:mcbroken/services/api/api_client.dart';
import 'package:mcbroken/services/api/api_error_handler.dart';
import 'package:mcbroken/services/database/database_service.dart';
import 'package:mcbroken/services/network/network_info.dart';
import 'package:mcbroken/services/preferences/favorites_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Globale GetIt Instanz für die Dependency Injection
final GetIt serviceLocator = GetIt.instance;

/// Initialisiert alle Abhängigkeiten für die Dependency Injection
///
/// Diese Funktion muss vor dem Start der App aufgerufen werden,
/// um alle benötigten Services und Blocs zu registrieren.
Future<void> initDependencies() async {
  // Externe Services
  final sharedPreferences = await SharedPreferences.getInstance();
  serviceLocator.registerSingleton<SharedPreferences>(sharedPreferences);
  serviceLocator.registerLazySingleton<Connectivity>(() => Connectivity());
  serviceLocator.registerLazySingleton<InternetConnectionChecker>(() => InternetConnectionChecker());
  serviceLocator.registerLazySingleton<Dio>(() {
    final dio = Dio();
    dio.options.connectTimeout = const Duration(seconds: 10);
    dio.options.receiveTimeout = const Duration(seconds: 10);
    return dio;
  });

  // Core Services
  serviceLocator.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(
      connectivity: serviceLocator<Connectivity>(),
      connectionChecker: serviceLocator<InternetConnectionChecker>(),
    ),
  );
  serviceLocator.registerLazySingleton<ApiErrorHandler>(() => ApiErrorHandlerImpl());
  serviceLocator.registerLazySingleton<ApiClient>(
    () => ApiClientImpl(
      dio: serviceLocator<Dio>(),
      errorHandler: serviceLocator<ApiErrorHandler>(),
    ),
  );
  serviceLocator.registerLazySingleton<DatabaseService>(() => DatabaseServiceImpl());
  serviceLocator.registerLazySingleton<FavoritesService>(
    () => FavoritesService(
      serviceLocator<SharedPreferences>(),
      serviceLocator<DatabaseService>(),
    ),
  );

  // Repositories
  serviceLocator.registerLazySingleton<McDonaldsRepository>(
    () => McDonaldsRepositoryImpl(
      apiClient: serviceLocator<ApiClient>(),
      databaseService: serviceLocator<DatabaseService>(),
      networkInfo: serviceLocator<NetworkInfo>(),
    ),
  );

  // BLoCs und Cubits
  serviceLocator.registerFactory<HomeBloc>(
    () => HomeBloc(
      repository: serviceLocator<McDonaldsRepository>(),
      favoritesService: serviceLocator<FavoritesService>(),
      internetCubit: serviceLocator<InternetCubit>(),
    ),
  );
  serviceLocator.registerFactory<InternetCubit>(
    () => InternetCubit(connectivity: serviceLocator<Connectivity>()),
  );
  serviceLocator.registerFactory<SettingsCubit>(
    () => SettingsCubit(sharedPreferences: serviceLocator<SharedPreferences>()),
  );
}
