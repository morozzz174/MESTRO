import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../bloc/order_bloc.dart';
import '../bloc/order_event.dart';
import '../bloc/checklist_bloc.dart';
import '../bloc/checklist_event.dart';
import '../models/order.dart';
import '../models/checklist_config.dart';
import '../utils/app_design.dart';
import '../utils/condition_evaluator.dart';
import '../utils/cost_calculator.dart';
import '../utils/pdf_generator.dart';
import '../utils/location_helper.dart';
import '../services/voice_input_service.dart';
import '../features/voice/presentation/widgets/voice_input_button.dart';
import 'photo_annotation_screen.dart';

class ChecklistScreen extends StatefulWidget {
  final Order order;

  const ChecklistScreen({super.key, required this.order});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  late Order _order;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    // Загружаем чек-лист
    context.read<ChecklistBloc>().add(
      LoadChecklist(_order.workType.checklistFile),
    );
  }

  @override
  void dispose() {
    // Не вызываем ResetChecklist если виджет уже размонтирован
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(AppDesign.appBarHeight),
        child: Container(
          decoration: const BoxDecoration(
            gradient: AppDesign.appBarGradient,
            boxShadow: AppDesign.appBarShadow,
          ),
          child: AppBar(
            title: Text('Чек-лист: ${_order.workType.title}'),
            actions: [
              IconButton(
                icon: const Icon(Icons.mic_none),
                onPressed: _showVoiceInput,
                tooltip: 'Голосовой ввод',
              ),
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: _saveOrder,
                tooltip: 'Сохранить',
              ),
            ],
          ),
        ),
      ),
      body: BlocBuilder<ChecklistBloc, ChecklistState>(
        builder: (context, state) {
          if (state is ChecklistLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ChecklistLoaded) {
            return _buildForm(context, state);
          }

          if (state is ChecklistError) {
            return Center(child: Text('Ошибка: ${state.message}'));
          }

          return const SizedBox.shrink();
        },
      ),
      bottomNavigationBar: _BottomActions(
        onCalculate: _calculateCost,
        onGeneratePdf: _generatePdf,
      ),
    );
  }

  Widget _buildForm(BuildContext context, ChecklistLoaded state) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppDesign.spacing16),
        children: [
          // Информация о клиенте
          _buildClientInfoSection(),
          const SizedBox(height: AppDesign.spacing16),
          AppDesign.separator(),
          const SizedBox(height: AppDesign.spacing8),

          // Поля чек-листа
          ...state.config.fields
              .where(
                (field) =>
                    ConditionEvaluator.isFieldVisible(field, state.formData),
              )
              .map((field) => _buildField(context, field, state)),

          const SizedBox(height: AppDesign.spacing16),
          AppDesign.separator(),
          const SizedBox(height: AppDesign.spacing8),

          // Фото заявки
          _buildPhotosSection(),
          const SizedBox(height: 80), // место для FAB
        ],
      ),
    );
  }

  Widget _buildClientInfoSection() {
    return Container(
      decoration: AppDesign.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(AppDesign.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Информация о клиенте',
              style: AppDesign.subtitleStyle,
            ),
            const SizedBox(height: AppDesign.spacing12),
            TextFormField(
              initialValue: _order.clientName.isEmpty ? null : _order.clientName,
              decoration: const InputDecoration(
                labelText: 'Имя клиента',
                prefixIcon: Icon(Icons.person),
              ),
              onChanged: (value) {
                _order = _order.copyWith(clientName: value);
              },
            ),
            const SizedBox(height: AppDesign.spacing12),
            TextFormField(
              initialValue: _order.address.isEmpty ? null : _order.address,
              decoration: const InputDecoration(
                labelText: 'Адрес',
                prefixIcon: Icon(Icons.location_on),
              ),
              maxLines: 2,
              onChanged: (value) {
                _order = _order.copyWith(address: value);
              },
            ),
            const SizedBox(height: AppDesign.spacing12),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _order.date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  setState(() {
                    _order = _order.copyWith(date: date);
                  });
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Дата замера',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(DateFormat('dd.MM.yyyy', 'ru').format(_order.date)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    BuildContext context,
    ChecklistField field,
    ChecklistLoaded state,
  ) {
    final value = state.formData[field.id];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _FieldWidget(
        field: field,
        value: value,
        onChanged: (val) {
          context.read<ChecklistBloc>().add(UpdateField(field.id, val));
        },
      ),
    );
  }

  Widget _buildPhotosSection() {
    return Container(
      decoration: AppDesign.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(AppDesign.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Фотофиксация',
                  style: AppDesign.subtitleStyle,
                ),
                ElevatedButton.icon(
                  onPressed: _takePhoto,
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: const Text('Добавить фото'),
                  style: AppDesign.accentButtonStyle,
                ),
              ],
            ),
            const SizedBox(height: AppDesign.spacing12),
            BlocBuilder<OrderBloc, OrderState>(
              builder: (context, state) {
                if (state is OrderLoaded) {
                  final order = state.orders.firstWhere(
                    (o) => o.id == _order.id,
                    orElse: () => _order,
                  );
                  if (order.photos.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppDesign.spacing24),
                        child: Text(
                          'Нет фото. Нажмите кнопку выше.',
                          style: AppDesign.captionStyle,
                        ),
                      ),
                    );
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: AppDesign.spacing8,
                      mainAxisSpacing: AppDesign.spacing8,
                    ),
                    itemCount: order.photos.length,
                    itemBuilder: (context, index) {
                      final photo = order.photos[index];
                      return GestureDetector(
                        onTap: () => _viewPhoto(photo),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(AppDesign.radiusListItem),
                              child: Image.file(
                                File(photo.annotatedPath ?? photo.filePath),
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppDesign.statusCancelled.withOpacity(0.9),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  onPressed: () => _deletePhoto(photo),
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile == null || !mounted) return;

    // Получаем геолокацию
    final position = await LocationHelper.getCurrentPosition();

    if (!mounted) return;

    // Показываем выбор пункта чек-листа
    final state = context.read<ChecklistBloc>().state;
    if (state is! ChecklistLoaded) return;

    final fieldId = await _showFieldSelector(state.config.fields);

    if (!mounted) return;

    final photo = PhotoAnnotation(
      id: const Uuid().v4(),
      orderId: _order.id,
      filePath: pickedFile.path,
      checklistFieldId: fieldId,
      latitude: position?.latitude,
      longitude: position?.longitude,
      timestamp: DateTime.now(),
    );

    // Открываем экран аннотаций
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PhotoAnnotationScreen(photo: photo)),
    );

    if (!mounted) return;

    if (result != null && result is PhotoAnnotation) {
      context.read<OrderBloc>().add(AddPhoto(_order.id, result));
    } else {
      // Всё равно сохраняем без аннотаций
      context.read<OrderBloc>().add(AddPhoto(_order.id, photo));
    }
  }

  Future<String?> _showFieldSelector(List<ChecklistField> fields) async {
    return showDialog<String>(
      context: context,
      builder: (context) {
        String? selectedField;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Привязать к пункту'),
              content: DropdownButtonFormField<String>(
                initialValue: selectedField,
                decoration: const InputDecoration(labelText: 'Пункт чек-листа'),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Не привязывать'),
                  ),
                  ...fields.map(
                    (f) => DropdownMenuItem<String>(
                      value: f.id,
                      child: Text(f.label),
                    ),
                  ),
                ],
                onChanged: (val) => setState(() => selectedField = val),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(selectedField),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _viewPhoto(PhotoAnnotation photo) async {
    final path = photo.annotatedPath ?? photo.filePath;
    if (await File(path).exists() && mounted) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.file(File(path)),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    if (photo.checklistFieldId != null)
                      Text('Пункт: ${photo.checklistFieldId}'),
                    Text(
                      'Дата: ${DateFormat('dd.MM.yyyy HH:mm', 'ru').format(photo.timestamp)}',
                    ),
                    if (photo.latitude != null)
                      Text(
                        'Координаты: ${photo.latitude!.toStringAsFixed(6)}, ${photo.longitude!.toStringAsFixed(6)}',
                      ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Закрыть'),
              ),
            ],
          ),
        ),
      );
    }
  }

  /// Показать диалог голосового ввода
  Future<void> _showVoiceInput() async {
    await VoiceInputDialog.show(
      context,
      onResult: (text) {
        _applyVoiceInput(text);
      },
    );
  }

  /// Применить данные из голосового ввода к полям формы
  void _applyVoiceInput(String text) {
    final service = VoiceInputService();
    final data = service.extractData(text);

    if (!data.hasData) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Не удалось распознать параметры. Текст: "$text"'),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Обновляем поля Order
    if (data.notes != null && data.notes!.isNotEmpty) {
      final currentNotes = _order.notes ?? '';
      final newNotes = currentNotes.isEmpty
          ? data.notes!
          : '$currentNotes; ${data.notes}';
      _order = _order.copyWith(notes: newNotes);
    }

    // Обновляем поля чек-листа через BLoC
    final bloc = context.read<ChecklistBloc>();
    if (data.windowWidth != null) {
      bloc.add(UpdateField('width', data.windowWidth.toString()));
    }
    if (data.windowHeight != null) {
      bloc.add(UpdateField('height', data.windowHeight.toString()));
    }
    if (data.area != null) {
      bloc.add(UpdateField('area', data.area.toString()));
    }
    if (data.windowCount != null) {
      bloc.add(UpdateField('window_count', data.windowCount.toString()));
    }
    if (data.windowType != null) {
      bloc.add(UpdateField('window_type', data.windowType));
    }
    if (data.hasSill) {
      bloc.add(UpdateField('has_sill', 'true'));
    }
    if (data.hasSlopes) {
      bloc.add(UpdateField('has_slopes', 'true'));
    }
    if (data.hasMosquitoNet) {
      bloc.add(UpdateField('mosquito_net', 'true'));
    }

    // Уведомление пользователя
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Данные заполнены'),
              ],
            ),
            if (data.toString().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                data.toString(),
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ],
        ),
        backgroundColor: Colors.green.shade700,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _deletePhoto(PhotoAnnotation photo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить фото?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.read<OrderBloc>().add(DeletePhoto(photo.id));
    }
  }

  Future<void> _saveOrder() async {
    // Валидация
    final state = context.read<ChecklistBloc>().state;
    if (state is ChecklistLoaded) {
      final errors = ConditionEvaluator.validateRequiredFields(
        state.config.fields,
        state.formData,
      );
      if (errors.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Заполните обязательные поля: ${errors.join(', ')}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Сохраняем данные чек-листа в заявку
      _order = _order.copyWith(
        checklistData: Map<String, dynamic>.from(state.formData),
        updatedAt: DateTime.now(),
      );
    }

    if (_order.clientName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите имя клиента'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    context.read<OrderBloc>().add(UpdateOrder(_order));

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Заявка сохранена')));
  }

  Future<void> _calculateCost() async {
    final state = context.read<ChecklistBloc>().state;
    if (state is! ChecklistLoaded) return;

    final cost = CostCalculator.calculate(_order, state.config);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Расчёт стоимости'),
        content: Text(
          'Предварительная стоимость работ:\n\n'
          '${NumberFormat.currency(locale: 'ru_RU', symbol: '₽', decimalDigits: 0).format(cost)}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Применить'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      _order = _order.copyWith(estimatedCost: cost, updatedAt: DateTime.now());
      context.read<OrderBloc>().add(UpdateOrder(_order));
    }
  }

  Future<void> _generatePdf() async {
    // Сначала сохраняем текущее состояние
    final state = context.read<ChecklistBloc>().state;
    if (state is ChecklistLoaded) {
      _order = _order.copyWith(
        checklistData: state.formData,
        updatedAt: DateTime.now(),
      );
    }

    // Загружаем актуальные фото
    final orderBlocState = context.read<OrderBloc>().state;
    if (orderBlocState is OrderLoaded) {
      final freshOrder = orderBlocState.orders.firstWhere(
        (o) => o.id == _order.id,
        orElse: () => _order,
      );
      _order = _order.copyWith(photos: freshOrder.photos);
    }

    if (!mounted) return;

    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Генерация PDF...')));

      final file = await PdfGenerator.generateProposal(_order);

      if (!mounted) return;

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'Коммерческое предложение',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка генерации PDF: $e')));
    }
  }
}

// ===== Виджет для поля формы =====
class _FieldWidget extends StatelessWidget {
  final ChecklistField field;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  const _FieldWidget({
    required this.field,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    switch (field.type) {
      case 'text':
        return TextFormField(
          initialValue: value?.toString(),
          decoration: InputDecoration(
            labelText: field.label,
            hintText: field.hint,
            border: const OutlineInputBorder(),
          ),
          onChanged: onChanged,
        );

      case 'number':
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

      case 'select':
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

      case 'boolean':
        return SwitchListTile(
          title: Text(field.label),
          value: value == true,
          onChanged: (val) => onChanged(val),
          contentPadding: EdgeInsets.zero,
        );

      case 'date':
        return InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: value is DateTime
                  ? value as DateTime
                  : DateTime.now(),
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

      default:
        return Text('Неизвестный тип поля: ${field.type}');
    }
  }
}

// ===== Нижняя панель действий =====
class _BottomActions extends StatelessWidget {
  final VoidCallback onCalculate;
  final VoidCallback onGeneratePdf;

  const _BottomActions({
    required this.onCalculate,
    required this.onGeneratePdf,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDesign.spacing16),
      decoration: BoxDecoration(
        color: AppDesign.cardBackground,
        boxShadow: [
          BoxShadow(
            color: AppDesign.deepSteelBlue.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onCalculate,
              icon: const Icon(Icons.calculate, size: 18),
              label: const Text('Рассчитать'),
            ),
          ),
          const SizedBox(width: AppDesign.spacing12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onGeneratePdf,
              icon: const Icon(Icons.picture_as_pdf, size: 18),
              label: const Text('PDF'),
              style: AppDesign.accentButtonStyle,
            ),
          ),
        ],
      ),
    );
  }
}
