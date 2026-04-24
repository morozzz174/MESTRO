import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/checklist_config.dart';

/// Виджет для отображения поля чек-листа в зависимости от типа
class ChecklistFieldWidget extends StatelessWidget {
  final ChecklistField field;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  const ChecklistFieldWidget({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    switch (field.type) {
      case 'text':
        return _buildTextField();

      case 'number':
        return _buildNumberField();

      case 'select':
        return _buildSelectField();

      case 'boolean':
        return _buildSwitchField();

      case 'date':
        return _buildDateField(context);

      default:
        return Text('Неизвестный тип поля: ${field.type}');
    }
  }

  Widget _buildTextField() {
    return TextFormField(
      initialValue: value?.toString(),
      decoration: InputDecoration(
        labelText: field.label,
        hintText: field.hint,
        border: const OutlineInputBorder(),
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildNumberField() {
    return TextFormField(
      initialValue: value?.toString() ?? '',
      decoration: InputDecoration(
        labelText: field.label,
        hintText: field.hint,
        border: const OutlineInputBorder(),
        suffixText: field.hint,
      ),
      keyboardType: TextInputType.number,
      onChanged: (val) {
        final numValue = double.tryParse(val);
        if (numValue != null) onChanged(numValue);
      },
    );
  }

  Widget _buildSelectField() {
    return DropdownButtonFormField<String>(
      initialValue: value?.toString(),
      decoration: InputDecoration(
        labelText: field.label,
        border: const OutlineInputBorder(),
      ),
      items: (field.options ?? [])
          .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
          .toList(),
      onChanged: (val) => onChanged(val),
    );
  }

  Widget _buildSwitchField() {
    return SwitchListTile(
      title: Text(field.label),
      value: value == true,
      onChanged: (val) => onChanged(val),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildDateField(BuildContext context) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value is DateTime ? value as DateTime : DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (date != null) onChanged(date);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: field.label,
          border: const OutlineInputBorder(),
        ),
        child: Text(
          value is DateTime
              ? DateFormat('dd.MM.yyyy', 'ru').format(value)
              : 'Выберите дату',
        ),
      ),
    );
  }
}
