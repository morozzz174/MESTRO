import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../../models/order.dart';

class CreateAppointmentDialog extends StatefulWidget {
  final DateTime selectedDate;
  final List<WorkType> availableWorkTypes;

  const CreateAppointmentDialog({
    super.key,
    required this.selectedDate,
    this.availableWorkTypes = const [],
  });

  @override
  State<CreateAppointmentDialog> createState() =>
      _CreateAppointmentDialogState();

  static Future<Order?> show(
    BuildContext context,
    DateTime selectedDate, {
    List<WorkType> availableWorkTypes = const [],
  }) {
    return showDialog<Order>(
      context: context,
      builder: (_) => CreateAppointmentDialog(
        selectedDate: selectedDate,
        availableWorkTypes: availableWorkTypes.isEmpty
            ? WorkType.values
            : availableWorkTypes,
      ),
    );
  }
}

class _CreateAppointmentDialogState extends State<CreateAppointmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _appointmentDate;
  TimeOfDay _appointmentTime = const TimeOfDay(hour: 10, minute: 0);
  late WorkType _selectedWorkType;
  OrderStatus _selectedStatus = OrderStatus.newOrder;

  @override
  void initState() {
    super.initState();
    _selectedWorkType = widget.availableWorkTypes.isNotEmpty
        ? widget.availableWorkTypes.first
        : WorkType.windows;
    // Установить дату из календаря + время по умолчанию
    _appointmentDate = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      _appointmentTime.hour,
      _appointmentTime.minute,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy', 'ru');

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Новый замер',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const Divider(),

                  // Дата замера
                  InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Дата замера',
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _appointmentDate != null
                            ? '${dateFormat.format(_appointmentDate!)} ${_appointmentTime.format(context)}'
                            : 'Выберите дату',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Имя клиента
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Имя клиента',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) =>
                        v?.trim().isEmpty == true ? 'Введите имя' : null,
                  ),
                  const SizedBox(height: 12),

                  // Телефон клиента
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Телефон клиента',
                      prefixIcon: Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(),
                      hintText: '+7 (999) 123-45-67',
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Адрес
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Адрес',
                      prefixIcon: Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    validator: (v) =>
                        v?.trim().isEmpty == true ? 'Введите адрес' : null,
                  ),
                  const SizedBox(height: 12),

                  // Тип работ
                  DropdownButtonFormField<WorkType>(
                    initialValue: _selectedWorkType,
                    decoration: const InputDecoration(
                      labelText: 'Тип работ',
                      prefixIcon: Icon(Icons.work_outline),
                      border: OutlineInputBorder(),
                    ),
                    items: widget.availableWorkTypes.map((wt) {
                      return DropdownMenuItem(value: wt, child: Text(wt.title));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedWorkType = val);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Статус
                  DropdownButtonFormField<OrderStatus>(
                    initialValue: _selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Статус',
                      prefixIcon: Icon(Icons.flag_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: OrderStatus.values.map((s) {
                      return DropdownMenuItem(value: s, child: Text(s.label));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedStatus = val);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Заметки
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Заметки',
                      prefixIcon: Icon(Icons.note_outlined),
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),

                  // Кнопки
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Отмена'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: _createOrder,
                          icon: const Icon(Icons.check),
                          label: const Text('Создать'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final initialDate = _appointmentDate ?? widget.selectedDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(
        initialDate.year,
        initialDate.month,
        initialDate.day,
      ),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );

    if (picked != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: _appointmentTime,
      );

      if (time != null && mounted) {
        setState(() {
          _appointmentTime = time;
          _appointmentDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _createOrder() {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final order = Order(
      id: const Uuid().v4(),
      clientName: _nameController.text.trim(),
      address: _addressController.text.trim(),
      date: _appointmentDate ?? now,
      status: _selectedStatus,
      workType: _selectedWorkType,
      appointmentDate: _appointmentDate,
      appointmentEnd: _appointmentDate?.add(const Duration(hours: 2)),
      clientPhone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      createdAt: now,
      updatedAt: now,
    );

    Navigator.of(context).pop(order);
  }
}
