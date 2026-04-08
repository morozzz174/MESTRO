import '../models/editor_state.dart';

/// Менеджер Undo/Redo для редактора плана
class EditorUndoRedoManager {
  final List<EditorState> _undoStack = [];
  final List<EditorState> _redoStack = [];
  final int _maxHistorySize;

  EditorUndoRedoManager({int maxHistorySize = 50})
    : _maxHistorySize = maxHistorySize;

  /// Сохранить текущее состояние (вызывать перед изменением)
  void push(EditorState state) {
    _undoStack.add(state);
    if (_undoStack.length > _maxHistorySize) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
  }

  /// Откатить последнее изменение
  EditorState? undo(EditorState currentState) {
    if (_undoStack.isEmpty) return null;
    final previous = _undoStack.removeLast();
    _redoStack.add(currentState);
    return previous;
  }

  /// Вернуть отменённое изменение
  EditorState? redo(EditorState currentState) {
    if (_redoStack.isEmpty) return null;
    final next = _redoStack.removeLast();
    _undoStack.add(currentState);
    return next;
  }

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }
}
