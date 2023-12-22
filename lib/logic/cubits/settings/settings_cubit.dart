import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(const SettingsState());

  void togglePositionSwitch(bool value) {
    emit(state.copyWith(showOwnPosition: value));
  }

  void toggleWorkingSwitch(bool value) {
    emit(state.copyWith(showOnlyWorking: value));
  }

  void toggleDefectSwitch(bool value) {
    emit(state.copyWith(showOnlyDefect: value));
  }

  void toggleRotationSwitch(bool value) {
    emit(state.copyWith(allowRotation: value));
  }

  void toggleZoomSwitch(bool value) {
    emit(state.copyWith(allowZoom: value));
  }
}
