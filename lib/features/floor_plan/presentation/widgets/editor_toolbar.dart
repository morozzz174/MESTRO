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
  final VoidCallback onAddDoor;
  final VoidCallback onAddWindow;
  final VoidCallback onAddRadiator;
  final VoidCallback onAddPlumbing;
  final VoidCallback onAddElectrical;
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
    required this.onAddDoor,
    required this.onAddWindow,
    required this.onAddRadiator,
    required this.onAddPlumbing,
    required this.onAddElectrical,
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
                  label: const Text('Редактор'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isEditing ? AppDesign.accentTeal : null,
                    foregroundColor: isEditing ? Colors.white : null,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
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
                  const SizedBox(width: 8),
                  // Кнопки добавления элементов с горизонтальной прокруткой
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _ElementButton(
                            icon: Icons.meeting_room,
                            label: 'Комната',
                            color: Colors.blue,
                            onPressed: onAddRoom,
                          ),
                          const SizedBox(width: 4),
                          _ElementButton(
                            icon: Icons.door_front_door,
                            label: 'Дверь',
                            color: Colors.brown,
                            onPressed: onAddDoor,
                          ),
                          const SizedBox(width: 4),
                          _ElementButton(
                            icon: Icons.window,
                            label: 'Окно',
                            color: Colors.cyan,
                            onPressed: onAddWindow,
                          ),
                          const SizedBox(width: 4),
                          _ElementButton(
                            icon: Icons.thermostat,
                            label: 'Радиатор',
                            color: Colors.red,
                            onPressed: onAddRadiator,
                          ),
                          const SizedBox(width: 4),
                          _ElementButton(
                            icon: Icons.plumbing,
                            label: 'Сантехника',
                            color: Colors.teal,
                            onPressed: onAddPlumbing,
                          ),
                          const SizedBox(width: 4),
                          _ElementButton(
                            icon: Icons.electrical_services,
                            label: 'Электрика',
                            color: Colors.amber,
                            onPressed: onAddElectrical,
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: onReset,
                            icon: const Icon(Icons.refresh),
                            tooltip: 'Сбросить',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                // Валидация
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isValid
                        ? Colors.green.shade50
                        : Colors.orange.shade50,
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

/// Кнопка добавления элемента
class _ElementButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ElementButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: color),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
      ),
    );
  }
}

/// Диалог добавления комнаты
Future<RoomState?> showAddRoomDialog(
  BuildContext context,
  EditorState state,
) async {
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
          onPressed: selectedType != null
              ? () => Navigator.of(ctx).pop(selectedType)
              : null,
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

/// Диалог добавления двери
Future<DoorState?> showAddDoorDialog(BuildContext context) async {
  String selectedType = 'internal';

  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        title: const Text('Добавить дверь'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRadio(
              'internal',
              'Межкомнатная',
              setDialogState,
              selectedType,
            ),
            _buildRadio('entrance', 'Входная', setDialogState, selectedType),
            _buildRadio('balcony', 'Балконная', setDialogState, selectedType),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Добавить'),
          ),
        ],
      ),
    ),
  );

  if (result != true) return null;

  return DoorState(
    id: const Uuid().v4(),
    x: 2.0, // Дефолтная позиция
    y: 2.0,
    width: selectedType == 'entrance' ? 0.9 : 0.8,
    type: selectedType,
  );
}

/// Диалог добавления окна
Future<WindowState?> showAddWindowDialog(BuildContext context) async {
  String selectedType = 'standard';

  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        title: const Text('Добавить окно'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRadio('standard', 'Обычное', setDialogState, selectedType),
            _buildRadio('balcony', 'Балконное', setDialogState, selectedType),
            _buildRadio(
              'french',
              'Французское (в пол)',
              setDialogState,
              selectedType,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Добавить'),
          ),
        ],
      ),
    ),
  );

  if (result != true) return null;

  return WindowState(
    id: const Uuid().v4(),
    x: 2.0,
    y: 2.0,
    width: 1.2,
    type: selectedType,
  );
}

/// Диалог добавления радиатора
Future<RadiatorState?> showAddRadiatorDialog(BuildContext context) async {
  String selectedType = 'panel';

  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        title: const Text('Добавить радиатор'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRadio('panel', 'Панельный', setDialogState, selectedType),
            _buildRadio(
              'sectional',
              'Секционный',
              setDialogState,
              selectedType,
            ),
            _buildRadio('convector', 'Конвектор', setDialogState, selectedType),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Добавить'),
          ),
        ],
      ),
    ),
  );

  if (result != true) return null;

  return RadiatorState(
    id: const Uuid().v4(),
    x: 2.0,
    y: 2.0,
    length: 1.0,
    type: selectedType,
  );
}

/// Диалог добавления сантехники
Future<PlumbingFixtureState?> showAddPlumbingDialog(
  BuildContext context,
) async {
  String selectedType = 'sink';

  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        title: const Text('Добавить сантехнику'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRadioWithIcon(
              'sink',
              'Раковина',
              '🚰',
              setDialogState,
              selectedType,
            ),
            _buildRadioWithIcon(
              'toilet',
              'Унитаз',
              '🚽',
              setDialogState,
              selectedType,
            ),
            _buildRadioWithIcon(
              'bathtub',
              'Ванна',
              '🛁',
              setDialogState,
              selectedType,
            ),
            _buildRadioWithIcon(
              'shower',
              'Душ',
              '🚿',
              setDialogState,
              selectedType,
            ),
            _buildRadioWithIcon(
              'washingMachine',
              'Стиральная машина',
              '🧺',
              setDialogState,
              selectedType,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Добавить'),
          ),
        ],
      ),
    ),
  );

  if (result != true) return null;

  return PlumbingFixtureState(
    id: const Uuid().v4(),
    x: 2.0,
    y: 2.0,
    type: selectedType,
  );
}

/// Диалог добавления электрики
Future<ElectricalPointState?> showAddElectricalDialog(
  BuildContext context,
) async {
  String selectedType = 'socket';

  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        title: const Text('Добавить электрику'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRadioWithIcon(
              'socket',
              'Розетка',
              '🔌',
              setDialogState,
              selectedType,
            ),
            _buildRadioWithIcon(
              'switch',
              'Выключатель',
              '💡',
              setDialogState,
              selectedType,
            ),
            _buildRadioWithIcon(
              'lightPoint',
              'Точка освещения',
              '💡',
              setDialogState,
              selectedType,
            ),
            _buildRadioWithIcon(
              'internetSocket',
              'Интернет/ТВ',
              '🌐',
              setDialogState,
              selectedType,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Добавить'),
          ),
        ],
      ),
    ),
  );

  if (result != true) return null;

  return ElectricalPointState(
    id: const Uuid().v4(),
    x: 2.0,
    y: 2.0,
    type: selectedType,
  );
}

/// Радио кнопка
Widget _buildRadio(
  String value,
  String label,
  Function(void Function()) setState,
  String groupValue,
) {
  return RadioListTile<String>(
    title: Text(label),
    value: value,
    groupValue: groupValue,
    onChanged: (val) {
      setState(() {});
    },
    contentPadding: EdgeInsets.zero,
  );
}

/// Радио кнопка с иконкой
Widget _buildRadioWithIcon(
  String value,
  String label,
  String icon,
  Function(void Function()) setState,
  String groupValue,
) {
  return RadioListTile<String>(
    title: Text('$icon $label'),
    value: value,
    groupValue: groupValue,
    onChanged: (val) {
      setState(() {});
    },
    contentPadding: EdgeInsets.zero,
  );
}
