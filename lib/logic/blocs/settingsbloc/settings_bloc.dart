import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc() : super(SettingsInitial()) {
    on<SettingsEvent>((event, emit) {
      // TODO: implement event handler
    });

    on<LanguageChanged>(_onLanguageChanged);
  }

  FutureOr<void> _onLanguageChanged(event, emit) async {
    emit(SettingsLoading());
    emit(SettingsLoaded());
  }
}
