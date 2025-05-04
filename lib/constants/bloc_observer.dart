import 'package:bloc/bloc.dart';
import 'package:logger/logger.dart';

class AppBlocObserver extends BlocObserver {
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    super.onEvent(bloc, event);
    _logEvent(event);
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    _logError(error, stackTrace);
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    _logChange(change);
  }

  @override
  void onTransition(
    Bloc<dynamic, dynamic> bloc,
    Transition<dynamic, dynamic> transition,
  ) {
    super.onTransition(bloc, transition);
    _logTransition(transition);
  }

  void _logEvent(Object? event) {
    _logger.i("Event: $event");
  }

  void _logError(Object error, StackTrace stackTrace) {
    _logger.e("Error", error: error, stackTrace: stackTrace);
  }

  void _logChange(Change<dynamic> change) {
    _logger.d("Change - Current State: ${change.currentState}, Next State: ${change.nextState}");
  }

  void _logTransition(Transition<dynamic, dynamic> transition) {
    _logger.t(
        "Transition - Event: ${transition.event}, Current State: ${transition.currentState}, Next State: ${transition.nextState}");
  }
}
