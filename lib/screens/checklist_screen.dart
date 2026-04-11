import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../database/database_helper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../features/profile/presentation/widgets/ai_agent_button.dart';
import '../models/checklist_config.dart';
import '../utils/checklist_loader.dart';
import '../bloc/order_bloc.dart';
import '../bloc/order_event.dart';
import '../bloc/checklist_bloc.dart';
import '../bloc/checklist_event.dart';
import '../models/order.dart';
import '../utils/app_design.dart';
import '../utils/condition_evaluator.dart';
import '../utils/location_helper.dart';
import '../services/voice_input_service.dart';
import '../features/voice/presentation/widgets/voice_input_button.dart';
import '../features/checklists_list/presentation/widgets/checklist_client_info.dart';
import '../features/checklists_list/presentation/widgets/checklist_field_widget.dart';
import '../features/checklists_list/presentation/widgets/checklist_photos_section.dart';
import '../features/checklists_list/presentation/managers/checklist_actions_manager.dart';
import '../features/floor_plan/presentation/pages/floor_plan_page.dart';
import '../features/floor_plan/models/floor_plan_models.dart';
import '../features/home/presentation/pages/order_payments_screen.dart';

class ChecklistScreen extends StatefulWidget {
  final Order order;

  const ChecklistScreen({super.key, required this.order});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  late Order _order;
  final _formKey = GlobalKey<FormState>();
  late ChecklistActionsManager _actionsManager;
  final _photosSectionKey = GlobalKey<ChecklistPhotosSectionState>();

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _actionsManager = ChecklistActionsManager(context: context, order: _order);
    // Загружаем чек-лист и передаём существующие данные для восстановления
    context.read<ChecklistBloc>().add(
      LoadChecklist(
        _order.workType.checklistFile,
        initialData: _order.checklistData,
      ),
    );
  }

  /// Перезагрузить фото после добавления/удаления
  void _refreshPhotos() {
    _photosSectionKey.currentState?.loadPhotos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
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
        onFloorPlan: _showFloorPlan,
        onPayments: _showPayments,
        estimatedCost: _order.estimatedCost,
        paidAmount: _order.paidAmount,
      ),
      floatingActionButton: _buildFloatingButtons(),
    );
  }

  Widget _buildFloatingButtons() {
    return Stack(
      children: [
        // Основная кнопка — Фото
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            onPressed: _takePhoto,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Фото'),
            backgroundColor: AppDesign.accentTeal,
            foregroundColor: Colors.white,
          ),
        ),
        // AI-агент
        Positioned(
          bottom: 90,
          right: 16,
          child: FutureBuilder<ChecklistConfig>(
            future: ChecklistLoader.load(_order.workType.checklistFile),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              return AIAgentButton(
                order: _order,
                checklistConfig: snapshot.data!,
              );
            },
          ),
        ),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(AppDesign.appBarHeight),
      child: Container(
        decoration: BoxDecoration(
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
    );
  }

  Widget _buildForm(BuildContext context, ChecklistLoaded state) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppDesign.spacing16),
        children: [
          // Информация о клиенте
          ChecklistClientInfo(
            order: _order,
            onOrderChanged: (updatedOrder) {
              setState(() => _order = updatedOrder);
            },
          ),
          const SizedBox(height: AppDesign.spacing16),
          AppDesign.separator(),
          const SizedBox(height: AppDesign.spacing8),

          // Поля чек-листа
          ...state.config.fields
              .where(
                (field) =>
                    ConditionEvaluator.isFieldVisible(field, state.formData),
              )
              .map((field) => _buildField(field, state)),

          const SizedBox(height: AppDesign.spacing16),
          AppDesign.separator(),
          const SizedBox(height: AppDesign.spacing8),

          // Фото заявки
          ChecklistPhotosSection(
            key: _photosSectionKey,
            orderId: _order.id,
            onTakePhoto: _takePhoto,
            onViewPhoto: _viewPhoto,
            onDeletePhoto: _deletePhoto,
          ),
          const SizedBox(height: AppDesign.spacing16),
        ],
      ),
    );
  }

  Widget _buildField(ChecklistField field, ChecklistLoaded state) {
    final value = state.formData[field.id];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ChecklistFieldWidget(
        field: field,
        value: value,
        onChanged: (val) {
          context.read<ChecklistBloc>().add(UpdateField(field.id, val));
        },
      ),
    );
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile == null || !mounted) return;

    // Копируем файл в постоянную директорию приложения
    final appDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory('${appDir.path}/photos');
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }

    final fileName = '${const Uuid().v4()}.jpg';
    final permanentPath = '${photosDir.path}/$fileName';
    final savedImage = await File(pickedFile.path).copy(permanentPath);

    final position = await LocationHelper.getCurrentPosition();
    if (!mounted) return;

    final state = context.read<ChecklistBloc>().state;
    if (state is! ChecklistLoaded) return;

    final fieldId = await _showFieldSelector(state.config.fields);
    if (!mounted) return;

    final photo = PhotoAnnotation(
      id: const Uuid().v4(),
      orderId: _order.id,
      filePath: savedImage.path,
      annotatedPath: savedImage.path,
      checklistFieldId: fieldId,
      latitude: position?.latitude,
      longitude: position?.longitude,
      timestamp: DateTime.now(),
    );

    if (!mounted) return;
    context.read<OrderBloc>().add(AddPhoto(_order.id, photo));
    // Обновляем список фото из БД
    Future.delayed(const Duration(milliseconds: 300), _refreshPhotos);
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
    if (!await File(path).exists() || !mounted) return;

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

  Future<void> _showVoiceInput() async {
    await VoiceInputDialog.show(
      context,
      onResult: (text) {
        _applyVoiceInput(text);
      },
    );
  }

  void _applyVoiceInput(String text) {
    final service = VoiceInputService();
    final data = service.extractData(text);

    if (!data.hasData) {
      if (!mounted) return;
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
      setState(() => _order = _order.copyWith(notes: newNotes));
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
    if (!mounted) return;
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
      // Обновляем список фото из БД
      Future.delayed(const Duration(milliseconds: 300), _refreshPhotos);
    }
  }

  Future<void> _saveOrder() async {
    final state = context.read<ChecklistBloc>().state;
    if (state is! ChecklistLoaded) return;

    // Обновляем order в actionsManager
    _actionsManager.order = _order;
    final success = await _actionsManager.saveOrder();
    if (success && mounted) {
      setState(() => _order = _actionsManager.order);
    }
  }

  /// Открыть редактор Floor Plan
  Future<void> _showFloorPlan() async {
    final state = context.read<ChecklistBloc>().state;
    if (state is ChecklistLoaded) {
      _order = _order.copyWith(
        checklistData: state.formData,
        updatedAt: DateTime.now(),
      );
    }
    if (mounted) {
      final updatedPlan = await Navigator.of(context).push<FloorPlan?>(
        MaterialPageRoute(builder: (_) => FloorPlanPage(order: _order)),
      );
      // После возврата обновляем order из БД (план уже сохранён)
      final db = DatabaseHelper();
      final updatedOrder = await db.getOrder(_order.id);
      if (updatedOrder != null && mounted) {
        setState(() => _order = updatedOrder);
      }
    }
  }

  /// Открыть экран платежей
  Future<void> _showPayments() async {
    // Сохраняем текущие данные чек-листа
    final state = context.read<ChecklistBloc>().state;
    if (state is ChecklistLoaded) {
      _order = _order.copyWith(
        checklistData: state.formData,
        updatedAt: DateTime.now(),
      );
    }

    // Загружаем актуальный order из БД
    final db = DatabaseHelper();
    final updatedOrder = await db.getOrder(_order.id);
    if (updatedOrder != null && mounted) {
      setState(() => _order = updatedOrder);

      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => OrderPaymentsScreen(order: _order)),
      );

      // После возврата обновляем order
      final refreshedOrder = await db.getOrder(_order.id);
      if (refreshedOrder != null && mounted) {
        setState(() => _order = refreshedOrder);
      }
    }
  }

  Future<void> _calculateCost() async {
    final state = context.read<ChecklistBloc>().state;
    if (state is! ChecklistLoaded) return;

    _actionsManager.order = _order;
    final cost = await _actionsManager.calculateCost(state.config);
    if (cost != null && mounted) {
      setState(() => _order = _actionsManager.order);
    }
  }

  Future<void> _generatePdf() async {
    _actionsManager.order = _order;
    await _actionsManager.generatePdf();
    if (mounted) {
      setState(() => _order = _actionsManager.order);
    }
  }
}

// ===== Нижняя панель действий =====
class _BottomActions extends StatelessWidget {
  final VoidCallback onCalculate;
  final VoidCallback onGeneratePdf;
  final VoidCallback onFloorPlan;
  final VoidCallback onPayments;
  final double? estimatedCost;
  final double? paidAmount;

  const _BottomActions({
    required this.onCalculate,
    required this.onGeneratePdf,
    required this.onFloorPlan,
    required this.onPayments,
    this.estimatedCost,
    this.paidAmount,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: '₽',
      decimalDigits: 0,
    );

    final estimated = estimatedCost ?? 0;
    final paid = paidAmount ?? 0;
    final hasPayments = paid > 0;

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Финансовая сводка (если есть стоимость)
          if (estimated > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Стоимость: ${currencyFormat.format(estimated)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (hasPayments)
                  Text(
                    'Оплачено: ${currencyFormat.format(paid)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          // Кнопки — 2 строки по 2
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPayments,
                  icon: Icon(
                    hasPayments ? Icons.payment : Icons.payment_outlined,
                    size: 18,
                    color: hasPayments ? Colors.green : null,
                  ),
                  label: Text(
                    hasPayments ? 'Оплаты' : 'Оплаты',
                    style: hasPayments
                        ? const TextStyle(color: Colors.green)
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: AppDesign.spacing8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onFloorPlan,
                  icon: const Icon(Icons.design_services, size: 18),
                  label: const Text('План'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDesign.spacing8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCalculate,
                  icon: const Icon(Icons.calculate, size: 18),
                  label: const Text('Расчёт'),
                ),
              ),
              const SizedBox(width: AppDesign.spacing8),
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
        ],
      ),
    );
  }
}
