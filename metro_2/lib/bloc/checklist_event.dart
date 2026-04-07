import 'package:equatable/equatable.dart';
import '../models/checklist_config.dart';

// ===== Events =====
abstract class ChecklistEvent extends Equatable {
  const ChecklistEvent();

  @override
  List<Object?> get props => [];
}

class LoadChecklist extends ChecklistEvent {
  final String workType;
  const LoadChecklist(this.workType);

  @override
  List<Object?> get props => [workType];
}

class UpdateField extends ChecklistEvent {
  final String fieldId;
  final dynamic value;
  const UpdateField(this.fieldId, this.value);

  @override
  List<Object?> get props => [fieldId, value];
}

class ResetChecklist extends ChecklistEvent {}

// ===== States =====
abstract class ChecklistState extends Equatable {
  const ChecklistState();

  @override
  List<Object?> get props => [];
}

class ChecklistInitial extends ChecklistState {}

class ChecklistLoading extends ChecklistState {}

class ChecklistLoaded extends ChecklistState {
  final ChecklistConfig config;
  final Map<String, dynamic> formData;

  const ChecklistLoaded({required this.config, this.formData = const {}});

  ChecklistLoaded copyWith({
    ChecklistConfig? config,
    Map<String, dynamic>? formData,
  }) {
    return ChecklistLoaded(
      config: config ?? this.config,
      formData: formData ?? this.formData,
    );
  }

  @override
  List<Object?> get props => [config, formData];
}

class ChecklistError extends ChecklistState {
  final String message;
  const ChecklistError(this.message);

  @override
  List<Object?> get props => [message];
}
