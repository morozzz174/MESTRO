import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';
import '../repositories/user_repository.dart';
import '../repositories/impl/user_repository_impl.dart';
import '../models/user.dart';
import '../models/order.dart';
import '../services/ucaller_service.dart';
import 'consent_screen.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/work_types/presentation/pages/work_type_selection_screen.dart';

/// Конфигурация uCaller — читается из .env с fallback на значения по умолчанию
final _ucallerServiceId =
    int.tryParse(dotenv.env['UCALLER_SERVICE_ID'] ?? '366080') ?? 366080;
final _ucallerSecretKey =
    dotenv.env['UCALLER_SECRET_KEY'] ?? '2Fgpaau5OeJE7tLJKdSVgLNIhLnvzGzM';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  String? _verifiedPhone;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D1B2A), // глубокий тёмно-синий
              Color(0xFF1B2838), // чуть светлее
              Color(0xFF1A2733),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ===== HERO-СЕКЦИЯ =====
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        // Логотип / Иконка
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00B4D8), Color(0xFF0077B6)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00B4D8).withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.construction_rounded,
                            size: 44,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'MESTRO',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Единый Стандарт Точности Расчёта Объекта',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.5),
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Описание
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: Column(
                            children: [
                              _FeatureRow(
                                icon: Icons.calendar_today_rounded,
                                title: 'Запись клиентов',
                                desc: 'Календарь замеров с напоминаниями',
                              ),
                              const SizedBox(height: 12),
                              _FeatureRow(
                                icon: Icons.checklist_rtl,
                                title: '15 специализаций',
                                desc:
                                    'Окна, двери, кухни, электрика, ИЖС и др.',
                              ),
                              const SizedBox(height: 12),
                              _FeatureRow(
                                icon: Icons.calculate_rounded,
                                title: 'Авто-расчёт стоимости',
                                desc: 'Мгновенный расчёт по вашим замерам',
                              ),
                              const SizedBox(height: 12),
                              _FeatureRow(
                                icon: Icons.architecture_rounded,
                                title: 'Планы и чертежи',
                                desc:
                                    'Планы помещений, фасады, разрезы, спецификации',
                              ),
                              const SizedBox(height: 12),
                              _FeatureRow(
                                icon: Icons.construction_rounded,
                                title: 'Конструктив здания',
                                desc:
                                    'Стены, фундамент, кровля, перекрытия, инженерия',
                              ),
                              const SizedBox(height: 12),
                              _FeatureRow(
                                icon: Icons.camera_enhance_rounded,
                                title: 'Фотофиксация',
                                desc: 'Фото с аннотациями и геотегами',
                              ),
                              const SizedBox(height: 12),
                              _FeatureRow(
                                icon: Icons.mic_rounded,
                                title: 'Голосовой ввод',
                                desc: 'Диктуйте замеры — AI заполнит все поля',
                              ),
                              const SizedBox(height: 12),
                              _FeatureRow(
                                icon: Icons.picture_as_pdf_rounded,
                                title: 'PDF и Excel отчёты',
                                desc: 'Коммерческие предложения и прайс-листы',
                              ),
                              const SizedBox(height: 12),
                              _FeatureRow(
                                icon: Icons.wifi_off_rounded,
                                title: 'Полный офлайн',
                                desc: 'Работает без интернета',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ===== КНОПКА НАЧАТЬ =====
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() => _currentStep = 0);
                              _showRegistration(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00B4D8),
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shadowColor: const Color(
                                0xFF00B4D8,
                              ).withOpacity(0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Начать работу',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Регистрация займёт меньше минуты',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showRegistration(BuildContext context) {
    // Полноэкранный мастер регистрации вместо bottom sheet
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => Scaffold(
          appBar: AppBar(
            title: const Text('Регистрация'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ),
          body: _RegistrationForm(
            currentStep: _currentStep,
            verifiedPhone: _verifiedPhone,
            onStepChanged: (step, phone) {
              setState(() {
                _currentStep = step;
                _verifiedPhone = phone;
              });
            },
            onRegistered: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomePage()),
                (route) => false,
              );
            },
          ),
        ),
      ),
    );
  }
}

// ===== FEATURE ROW =====

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: const Color(0xFF00B4D8).withOpacity(0.15),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF00B4D8)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                desc,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ===== ФОРМА РЕГИСТРАЦИИ =====

class _RegistrationForm extends StatefulWidget {
  final int currentStep;
  final String? verifiedPhone;
  final Function(int step, String? phone) onStepChanged;
  final VoidCallback onRegistered;

  const _RegistrationForm({
    required this.currentStep,
    required this.verifiedPhone,
    required this.onStepChanged,
    required this.onRegistered,
  });

  @override
  State<_RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<_RegistrationForm> {
  late int _currentStep;
  String? _verifiedPhone;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.currentStep;
    _verifiedPhone = widget.verifiedPhone;
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0077B6),
          primary: const Color(0xFF0077B6),
          secondary: const Color(0xFF00B4D8),
        ),
      ),
      child: Stepper(
        currentStep: _currentStep,
        controlsBuilder: (_, _) => const SizedBox.shrink(),
        onStepTapped: (step) {
          if (step >= _currentStep) {
            setState(() => _currentStep = step);
          }
        },
        steps: [
          Step(
            title: const Text('Телефон'),
            content: _PhoneVerificationStep(
              onVerified: (phone) {
                setState(() {
                  _verifiedPhone = phone;
                  _currentStep = 1;
                });
                widget.onStepChanged(1, phone);
              },
            ),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Профиль'),
            content: _ProfileStep(
              verifiedPhone: _verifiedPhone ?? '',
              onRegistered: () {
                setState(() => _currentStep = 2);
                widget.onStepChanged(2, _verifiedPhone);
              },
            ),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Готово'),
            content: _SuccessStep(onDone: widget.onRegistered),
            isActive: _currentStep >= 2,
            state: StepState.indexed,
          ),
        ],
      ),
    );
  }
}

// ===== ШАГ 1: Верификация телефона через звонок uCaller =====

class _PhoneVerificationStep extends StatefulWidget {
  final ValueChanged<String> onVerified;

  const _PhoneVerificationStep({required this.onVerified});

  @override
  State<_PhoneVerificationStep> createState() => _PhoneVerificationStepState();
}

class _PhoneVerificationStepState extends State<_PhoneVerificationStep> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  bool _isLoading = false;
  bool _codeSent = false;
  String? _errorMessage;
  int? _ucallerId;
  int _remainingTime = 0;
  Timer? _timer;

  final _ucaller = UCallerService(
    serviceId: _ucallerServiceId,
    secretKey: _ucallerSecretKey,
  );

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Введите номер телефона для верификации',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          enabled: !_codeSent,
          decoration: InputDecoration(
            labelText: 'Номер телефона',
            hintText: '+7 (999) 123-45-67',
            prefixIcon: const Icon(Icons.phone_outlined),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF0077B6).withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                size: 18,
                color: Color(0xFF0077B6),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Тест: 79000000001 — всегда успешный звонок',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF0077B6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (_codeSent) ...[
          TextField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: 'Код из звонка',
              hintText: 'Введите код, который продиктует оператор',
              prefixIcon: Icon(Icons.pin_outlined),
              counterText: '',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Вам поступит входящий звонок. Оператор продиктует код — введите его выше.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _remainingTime > 0 ? null : _requestCall,
                  icon: const Icon(Icons.phone_callback),
                  label: _remainingTime > 0
                      ? Text('Повтор через $_remainingTimeс')
                      : const Text('Повторный звонок'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ),

        ElevatedButton.icon(
          onPressed: _isLoading
              ? null
              : (_codeSent ? _verifyCode : _requestCall),
          icon: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(_codeSent ? Icons.check : Icons.phone),
          label: Text(_codeSent ? 'Подтвердить код' : 'Получить звонок'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ],
    );
  }

  /// Запрос звонка от uCaller
  Future<void> _requestCall() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _errorMessage = 'Введите номер телефона');
      return;
    }

    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) {
      setState(() => _errorMessage = 'Введите корректный номер телефона');
      return;
    }

    // Нормализуем номер: убираем 8 в начале, добавляем 7
    String normalizedPhone = digits;
    if (normalizedPhone.startsWith('8') && normalizedPhone.length == 11) {
      normalizedPhone = '7' + normalizedPhone.substring(1);
    }
    if (!normalizedPhone.startsWith('7')) {
      normalizedPhone = '7$normalizedPhone';
    }

    debugPrint('[Registration] Phone: $phone → normalized: $normalizedPhone');

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _ucaller.initCall(phone: normalizedPhone);

      if (!mounted) return;

      if (result.status && !result.hasError) {
        setState(() {
          _codeSent = true;
          _ucallerId = result.ucallerId;
          _remainingTime = 60;
          _errorMessage = null;
        });

        _startTimer();

        // Запускаем опрос статуса звонка
        _pollCallStatus();
      } else if (!result.status) {
        // Ошибка запроса
        final errorMsg = result.error ?? 'Ошибка запроса звонка';
        debugPrint('[Registration] initCall failed: $errorMsg');

        String userMessage;
        if (errorMsg.contains('баланс') || errorMsg.contains('средств')) {
          userMessage = 'Недостаточно средств на балансе сервиса';
        } else if (errorMsg.contains('заблокирован') ||
            errorMsg.contains('block')) {
          userMessage = 'Сервис авторизации временно недоступен';
        } else if (errorMsg.contains('дозвониться') ||
            errorMsg.contains('абонент')) {
          userMessage =
              'Не удалось дозвониться. Проверьте номер или попробуйте позже.\n\n'
              'Совет: для проверки используйте тестовый номер 79000000001';
        } else {
          userMessage = 'Ошибка: $errorMsg';
        }

        setState(() => _errorMessage = userMessage);
      } else {
        // status=true но есть error (uCaller иногда шлёт код в error) — игнорируем
        debugPrint('[Registration] initCall OK (ignoring non-error message)');
        setState(() {
          _codeSent = true;
          _ucallerId = result.ucallerId;
          _remainingTime = 60;
          _errorMessage = null;
        });

        _startTimer();
        _pollCallStatus();
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('[Registration] Exception: $e');
      setState(() {
        _errorMessage = 'Ошибка: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Опрос статуса звонка каждые 5 секунд
  Future<void> _pollCallStatus() async {
    if (_ucallerId == null) return;

    for (int i = 0; i < 24; i++) {
      // максимум 2 минуты опроса
      await Future.delayed(const Duration(seconds: 5));
      if (!mounted) return;

      try {
        final info = await _ucaller.getInfo(_ucallerId!);
        if (info.isCallSuccessful) {
          // Звонок успешен — код доступен на сервере, пользователь его услышит
          debugPrint('[uCaller] Call successful, ucallerId: $_ucallerId');
        } else if (info.callStatus == 0) {
          // Звонок провален
          debugPrint('[uCaller] Call failed, ucallerId: $_ucallerId');
          if (mounted) {
            setState(() {
              _errorMessage =
                  'Звонок не выполнен. Проверьте номер или попробуйте тестовый: 79000000001';
            });
          }
          break;
        }
      } catch (_) {
        // Игнорируем ошибки опроса
      }
    }
  }

  /// Проверка введённого кода
  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _errorMessage = 'Введите код из звонка');
      return;
    }

    if (_ucallerId == null) {
      setState(() => _errorMessage = 'Сначала запросите звонок');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final info = await _ucaller.getInfo(_ucallerId!);

      if (!mounted) return;

      if (!info.isCallSuccessful) {
        setState(() {
          _errorMessage =
              'Звонок ещё не завершён. Дождитесь звонка или запросите повторный.';
        });
        return;
      }

      final expectedCode = info.code?.toString() ?? '';
      debugPrint(
        '[Registration] User entered: "$code", expected: "$expectedCode"',
      );
      if (code != expectedCode) {
        setState(() {
          _errorMessage = 'Неверный код. Проверьте и попробуйте снова.';
        });
        return;
      }

      // Код верный — сохраняем телефон и переходим далее
      widget.onVerified(_phoneController.text.trim());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Ошибка проверки: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingTime > 0) {
        setState(() => _remainingTime--);
      } else {
        timer.cancel();
      }
    });
  }
}

// ===== ШАГ 2: ФИО + согласие =====

class _ProfileStep extends StatefulWidget {
  final String verifiedPhone;
  final VoidCallback onRegistered;

  const _ProfileStep({required this.verifiedPhone, required this.onRegistered});

  @override
  State<_ProfileStep> createState() => _ProfileStepState();
}

class _ProfileStepState extends State<_ProfileStep> {
  final _nameController = TextEditingController();
  bool _consentAccepted = false;
  bool _isLoading = false;
  List<String> _selectedWorkTypes = [];
  final UserRepository _userRepository = UserRepositoryImpl();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'ФИО',
            hintText: 'Иванов Иван Иванович',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: TextEditingController(text: widget.verifiedPhone),
          keyboardType: TextInputType.phone,
          readOnly: true,
          decoration: const InputDecoration(
            labelText: 'Телефон (верифицирован)',
            prefixIcon: Icon(Icons.phone_outlined),
            suffixIcon: Icon(Icons.check_circle, color: Color(0xFF00B4D8)),
          ),
        ),
        const SizedBox(height: 24),

        // Чекбокс согласия
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: _consentAccepted,
                onChanged: (val) {
                  setState(() => _consentAccepted = val ?? false);
                },
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    color: Color(0xFF1B2838),
                    fontSize: 14,
                  ),
                  children: [
                    const TextSpan(text: 'Я принимаю условия '),
                    TextSpan(
                      text: 'Согласия на обработку персональных данных',
                      style: const TextStyle(
                        color: Color(0xFF0077B6),
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w600,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ConsentScreen(),
                            ),
                          );
                        },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Выбор ниш
        OutlinedButton.icon(
          onPressed: _selectWorkTypes,
          icon: const Icon(Icons.work_outline),
          label: Text(
            _selectedWorkTypes.isEmpty
                ? 'Выберите ниши (минимум 1)'
                : 'Ниши: ${_selectedWorkTypes.length} выбрано',
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            foregroundColor: _selectedWorkTypes.isEmpty
                ? Colors.redAccent
                : const Color(0xFF00B4D8),
          ),
        ),
        if (_selectedWorkTypes.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _selectedWorkTypes.map((type) {
              final wt = WorkType.values.firstWhere(
                (e) => e.checklistFile == type,
                orElse: () => WorkType.windows,
              );
              return Chip(
                label: Text(wt.title, style: const TextStyle(fontSize: 12)),
                backgroundColor: const Color(0xFF00B4D8).withOpacity(0.12),
                side: const BorderSide(color: Color(0xFF00B4D8)),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            }).toList(),
          ),
        ],

        const SizedBox(height: 24),

        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else
          ElevatedButton.icon(
            onPressed: _selectedWorkTypes.isEmpty ? null : _register,
            icon: const Icon(Icons.person_add),
            label: const Text('Завершить регистрацию'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
      ],
    );
  }

  Future<void> _selectWorkTypes() async {
    final result = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(
        builder: (_) =>
            WorkTypeSelectionScreen(initialSelection: _selectedWorkTypes),
      ),
    );
    if (result != null && mounted) {
      setState(() => _selectedWorkTypes = result);
    }
  }

  Future<void> _register() async {
    final fullName = _nameController.text.trim();
    if (fullName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите ФИО'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedWorkTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите хотя бы одну нишу'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_consentAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Необходимо принять согласие на обработку персональных данных',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = User(
        id: const Uuid().v4(),
        phone: widget.verifiedPhone,
        fullName: fullName,
        consentDate: DateTime.now(),
        consentVersion: User.currentConsentVersion,
        selectedWorkTypes: _selectedWorkTypes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _userRepository.insertUser(user);

      if (!mounted) return;
      widget.onRegistered();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка регистрации: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

// ===== ШАГ 3: Успех =====

class _SuccessStep extends StatelessWidget {
  final VoidCallback onDone;

  const _SuccessStep({required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.check_circle, size: 64, color: Color(0xFF00B4D8)),
        const SizedBox(height: 16),
        const Text(
          'Регистрация завершена!',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          'Теперь вы можете создавать заявки и проводить замеры.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: onDone,
          icon: const Icon(Icons.arrow_forward),
          label: const Text('Перейти к заявкам'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ],
    );
  }
}
