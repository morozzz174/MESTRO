import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'dart:math' as math;
import '../../../../utils/app_design.dart';
import '../../models/editor_state.dart';
import '../../engine/editor_undo_redo.dart';
import '../../engine/floor_plan_validator.dart';

/// Панель инструментов редактора
class EditorToolbar extends StatelessWidget {
  final bool isEditing;
  final bool canUndo;
  final bool canRedo;
  final bool isValid;
  final ValidationResult validation;
  final VoidCallback onToggleEdit;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onAddRoom;
  final VoidCallback onReset;

  const EditorToolbar({
    super.key,
    required this.isEditing,
    required this.canUndo,
    required this.canRedo,
    required this.isValid,
    required this.validation,
    required this.onToggleEdit,
    required this.onUndo,
    required this.onRedo,
    required this.onAddRoom,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppDesign.cardBackground,
        boxShadow: [
          BoxShadow(
            color: AppDesign.deepSteelBlue.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Режим редактирования
                ElevatedButton.icon(
                  onPressed: onToggleEdit,
                  icon: Icon(isEditing ? Icons.visibility : Icons.edit),
                  label: Text(isEditing ? 'Готово' : 'Редактор'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isEditing ? AppDesign.accentTeal : null,
                    foregroundColor: isEditing ? Colors.white : null,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(width: 8),
                // Undo/Redo
                if (isEditing) ...[
                  IconButton(
                    onPressed: canUndo ? onUndo : null,
                    icon: const Icon(Icons.undo),
                    tooltip: 'Отменить',
                  ),
                  IconButton(
                    onPressed: canRedo ? onRedo : null,
                    icon: const Icon(Icons.redo),
                    tooltip: 'Повторить',
                  ),
                  const SizedBox(width: 4),
                  // Добавить комнату
                  ElevatedButton.icon(
                    onPressed: onAddRoom,
                    icon: const Icon(Icons.add_box, size: 18),
                    label: const Text('Комната'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Сбросить
                  IconButton(
                    onPressed: onReset,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Сбросить',
                  ),
                ],
                const Spacer(),
                // Валидация
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isValid ? Colors.green.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isValid ? Colors.green : Colors.orange,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isValid ? Icons.check_circle : Icons.warning_amber,
                        size: 16,
                        color: isValid ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isValid ? 'OK' : '${validation.errors.length} ошибок',
                        style: TextStyle(
                          fontSize: 12,
                          color: isValid ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Диалог добавления комнаты
Future<RoomState?> showAddRoomDialog(BuildContext context, EditorState state) async {
  final types = [
    ('kitchen', 'Кухня', '🍳'),
    ('livingRoom', 'Гостиная', '🛋️'),
    ('bedroom', 'Спальня', '🛏️'),
    ('childrenRoom', 'Детская', '🧸'),
    ('bathroom', 'Ванная', '🚿'),
    ('toilet', 'Туалет', '🚽'),
    ('office', 'Кабинет', '💼'),
    ('storage', 'Кладовая', '📦'),
    ('balcony', 'Балкон', '🌿'),
  ];

  String? selectedType;

  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Добавить комнату'),
      content: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: types.map((t) {
          final isSelected = selectedType == t.$1;
          return ChoiceChip(
            label: Text('${t.$2} ${t.$3}'),
            selected: isSelected,
            onSelected: (val) {
              selectedType = val ? t.$1 : null;
              (ctx as Element).markNeedsBuild();
            },
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: selectedType != null ? () => Navigator.of(ctx).pop(selectedType) : null,
          child: const Text('Добавить'),
        ),
      ],
    ),
  );

  if (selectedType == null) return null;

  // Позиция: свободное место
  double x = 0, y = 0;
  final minArea = FloorPlanValidator.minAreas[selectedType] ?? 8.0;
  final width = math.sqrt(minArea).clamp(1.5, state.totalWidth - x);
  final height = (minArea / width).clamp(1.5, state.totalHeight - y);

  return RoomState(
    id: const Uuid().v4(),
    type: selectedType!,
    x: x,
    y: y,
    width: width,
    height: height,
  );
}
