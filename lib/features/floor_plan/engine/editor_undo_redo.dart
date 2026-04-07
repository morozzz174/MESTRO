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

  /// Отменить действие
  EditorState? undo(EditorState currentState) {
    if (_undoStack.isEmpty) return null;
    _redoStack.add(currentState);
    final previous = _undoStack.removeLast();
    return previous;
  }

  /// Повторить отменённое действие
  EditorState? redo(EditorState currentState) {
    if (_redoStack.isEmpty) return null;
    _undoStack.add(currentState);
    final next = _redoStack.removeLast();
    return next;
  }

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  /// Очистить историю
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }
}
