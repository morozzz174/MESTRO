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
import '../services/ai_premium_agent.dart';
import '../services/subscription_service.dart';
import '../features/voice/presentation/widgets/voice_input_banner.dart';
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
  final _subscriptionService = SubscriptionService();
  bool _showVoiceBanner = false;

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
      body: Stack(
        children: [
          BlocBuilder<ChecklistBloc, ChecklistState>(
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
          // Компактный баннер голосового ввода
          if (_showVoiceBanner)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: VoiceInputBanner(
                onResult: (text) {
                  setState(() => _showVoiceBanner = false);
                  _applyVoiceInput(text);
                },
                onClose: () => setState(() => _showVoiceBanner = false),
              ),
            ),
        ],
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
            backgroundColor: Theme.of(context).colorScheme.secondary,
            foregroundColor: Theme.of(context).colorScheme.onSecondary,
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
        padding: EdgeInsets.all(AppDesign.spacing4),
        children: [
          // Информация о клиенте
          ChecklistClientInfo(
            order: _order,
            onOrderChanged: (updatedOrder) {
              setState(() => _order = updatedOrder);
            },
          ),
          SizedBox(height: AppDesign.spacing4),
          AppDesign.separator(),
          SizedBox(height: AppDesign.spacing2),

          // Поля чек-листа
          ...state.config.fields
              .where(
                (field) =>
                    ConditionEvaluator.isFieldVisible(field, state.formData),
              )
              .map((field) => _buildField(field, state)),

          SizedBox(height: AppDesign.spacing4),
          AppDesign.separator(),
          SizedBox(height: AppDesign.spacing2),

          // Фото заявки
          ChecklistPhotosSection(
            key: _photosSectionKey,
            orderId: _order.id,
            onTakePhoto: _takePhoto,
            onViewPhoto: _viewPhoto,
            onDeletePhoto: _deletePhoto,
          ),
          SizedBox(height: AppDesign.spacing4),
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

  void _showVoiceInput() {
    setState(() => _showVoiceBanner = true);
  }

  void _applyVoiceInput(String text) async {
    final voiceService = VoiceInputService();
    final premiumAgent = AIPremiumAgent();

    // Извлекаем структурированные данные для типа работ
    final voiceData = voiceService.extractDataForWorkType(
      text,
      _order.workType.checklistFile,
    );

    // Применяем данные через AI-агент (Premium функция)
    final result = premiumAgent.applyVoiceDataToOrder(_order, voiceData);
    final appliedOrder = result['order'] as Order;
    final appliedFields = result['appliedFields'] as List<String>;

    // Генерируем заметки через AI (Premium функция)
    final generatedNotes = premiumAgent.generateSurveyorNotes(
      text,
      appliedOrder,
    );

    // Формируем итоговые заметки
    String finalNotes = appliedOrder.notes ?? '';
    if (generatedNotes.isNotEmpty) {
      finalNotes = finalNotes.isEmpty
          ? generatedNotes
          : '$finalNotes\n$generatedNotes';
    }

    setState(() {
      _order = appliedOrder.copyWith(notes: finalNotes);
    });

    // Обновляем поля чек-листа через BLoC
    final bloc = context.read<ChecklistBloc>();
    for (final field in appliedFields) {
      if (voiceData.containsKey(field)) {
        final value = voiceData[field];
        if (value is bool) {
          bloc.add(UpdateField(field, value.toString()));
        } else {
          bloc.add(UpdateField(field, value.toString()));
        }
      }
    }

    if (!mounted) return;

    // Формируем сообщение о применённых данных
    final data = voiceService.extractData(text);
    String message = 'Данные заполнены';
    if (appliedFields.isNotEmpty) {
      message = 'Заполнено ${appliedFields.length} полей';
    } else if (data.hasData) {
      message = 'Данные заполнены';
    } else {
      message = 'Добавлены заметки';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green.shade300,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(message),
              ],
            ),
            if (appliedFields.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                appliedFields.take(5).join(', ') +
                    (appliedFields.length > 5 ? '...' : ''),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade300),
              ),
            ],
            if (generatedNotes.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '✓ Заметки сгенерированы AI',
                style: TextStyle(fontSize: 11, color: Colors.amber.shade300),
              ),
            ],
          ],
        ),
        backgroundColor: Colors.green.shade800,
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
    // AI-валидация КП для Premium пользователей
    final isPremium = await _subscriptionService.isPremiumActive();
    if (isPremium && mounted) {
      try {
        final config = await ChecklistLoader.load(
          _order.workType.checklistFile,
        );
        final agent = AIPremiumAgent();
        final report = agent.validateCommercialProposal(_order, config);

        if (report.errorCount > 0 || report.warningCount > 0) {
          final proceed = await _showAIValidationDialog(report);
          if (!proceed) return;
        }
      } catch (e) {
        debugPrint('[ChecklistScreen] AI validation skipped: $e');
      }
    }

    _actionsManager.order = _order;
    await _actionsManager.generatePdf();
    if (mounted) {
      setState(() => _order = _actionsManager.order);
    }
  }

  Future<bool> _showAIValidationDialog(AIValidationReport report) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  report.errorCount > 0 ? Icons.warning : Icons.info_outline,
                  color: report.errorCount > 0 ? Colors.orange : Colors.blue,
                ),
                const SizedBox(width: 8),
                const Text('AI-проверка КП'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Заполненность: ${report.completenessScore.toStringAsFixed(0)}%',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: report.completenessScore / 100,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation(
                            report.completenessScore > 70
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (report.errorCount > 0) ...[
                    Text(
                      '⚠️ Ошибки (${report.errorCount}):',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...report.issues
                        .where((i) => i.type == AIIssueType.error)
                        .take(3)
                        .map(
                          (i) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '• ${i.message}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                  ],
                  if (report.warningCount > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      '⚠️ Предупреждения (${report.warningCount}):',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...report.issues
                        .where((i) => i.type == AIIssueType.warning)
                        .take(3)
                        .map(
                          (i) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '• ${i.message}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    report.summary,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Всё равно отправить'),
              ),
            ],
          ),
        ) ??
        false;
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
      padding: EdgeInsets.all(AppDesign.spacing4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
                    color: hasPayments ? const Color(0xFF10B981) : null,
                  ),
                  label: Text(
                    hasPayments ? 'Оплаты' : 'Оплаты',
                    style: hasPayments
                        ? const TextStyle(color: Color(0xFF10B981))
                        : null,
                  ),
                ),
              ),
              SizedBox(width: AppDesign.spacing2),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onFloorPlan,
                  icon: const Icon(Icons.design_services, size: 18),
                  label: const Text('План'),
                ),
              ),
            ],
          ),
          SizedBox(height: AppDesign.spacing2),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCalculate,
                  icon: const Icon(Icons.calculate, size: 18),
                  label: const Text('Расчёт'),
                ),
              ),
              SizedBox(width: AppDesign.spacing2),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onGeneratePdf,
                  icon: const Icon(Icons.picture_as_pdf, size: 18),
                  label: const Text('PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Theme.of(context).colorScheme.onSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
