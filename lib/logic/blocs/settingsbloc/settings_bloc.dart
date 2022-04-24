import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc() : super(SettingsStateInitial()) {
    emit(SettingsStateLoaded());
    on<LanguageChanged>(_onLanguageChanged);
  }

  FutureOr<void> _onLanguageChanged(event, emit) async {
    //emit(SettingsStateLoading());
    emit(SettingsStateLoaded());
  }
}
