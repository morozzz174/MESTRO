import 'package:flutter_bloc/flutter_bloc.dart';
import '../utils/checklist_loader.dart';
import 'checklist_event.dart';

class ChecklistBloc extends Bloc<ChecklistEvent, ChecklistState> {
  ChecklistBloc() : super(ChecklistInitial()) {
    on<LoadChecklist>(_onLoadChecklist);
    on<UpdateField>(_onUpdateField);
    on<ResetChecklist>(_onResetChecklist);
  }

  Future<void> _onLoadChecklist(
    LoadChecklist event,
    Emitter<ChecklistState> emit,
  ) async {
    emit(ChecklistLoading());
    try {
      final config = await ChecklistLoader.load(event.workType);
      emit(ChecklistLoaded(config: config));
    } catch (e) {
      emit(ChecklistError('Ошибка загрузки чек-листа: $e'));
    }
  }

  void _onUpdateField(UpdateField event, Emitter<ChecklistState> emit) {
    final currentState = state;
    if (currentState is ChecklistLoaded) {
      final updatedData = Map<String, dynamic>.from(currentState.formData);
      updatedData[event.fieldId] = event.value;
      emit(currentState.copyWith(formData: updatedData));
    }
  }

  void _onResetChecklist(ResetChecklist event, Emitter<ChecklistState> emit) {
    emit(ChecklistInitial());
  }
}
