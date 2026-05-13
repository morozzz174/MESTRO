import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
import '../repositories/user_repository.dart';
import '../repositories/impl/user_repository_impl.dart';
import '../models/user.dart';
import '../models/order.dart';
import '../services/loginbot_service.dart';
import '../utils/app_design.dart';
import 'consent_screen.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/work_types/presentation/pages/work_type_selection_screen.dart';

const _defaultLoginBotToken = 'd0ac07f0-ef42-4d11-87d7-f6fee1680086';
final _loginBotToken = dotenv.env['LOGINBOT_TOKEN'] ?? _defaultLoginBotToken;

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
    final screenHeight = MediaQuery.of(context).size.height;
    final isLargeScreen = screenHeight > 700;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppDesign.primaryLight.withOpacity(0.15),
              AppDesign.backgroundDark,
              AppDesign.surfaceDark,
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: isLargeScreen
                ? _buildCenteredLayout()
                : _buildScrollableLayout(),
          ),
        ),
      ),
    );
  }

  Widget _buildCenteredLayout() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(child: SingleChildScrollView(child: _buildContent())),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollableLayout() {
    return SingleChildScrollView(child: _buildContent());
  }

  Widget _buildContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ===== HERO-СЕКЦИЯ =====
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: AppDesign.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppDesign.primaryLight.withOpacity(0.3),
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: const Column(
                  children: [
                    _FeatureRow(
                      icon: Icons.calendar_today_rounded,
                      title: 'Запись клиентов',
                      desc: 'Календарь замеров с напоминаниями',
                    ),
                    SizedBox(height: 12),
                    _FeatureRow(
                      icon: Icons.checklist_rtl,
                      title: '15 специализаций',
                      desc: 'Окна, двери, кухни, электрика, ИЖС и др.',
                    ),
                    SizedBox(height: 12),
                    _FeatureRow(
                      icon: Icons.calculate_rounded,
                      title: 'Авто-расчёт стоимости',
                      desc: 'Мгновенный расчёт по вашим замерам',
                    ),
                    SizedBox(height: 12),
                    _FeatureRow(
                      icon: Icons.architecture_rounded,
                      title: 'Планы и чертежи',
                      desc: 'Планы помещений, фасады, разрезы, спецификации',
                    ),
                    SizedBox(height: 12),
                    _FeatureRow(
                      icon: Icons.construction_rounded,
                      title: 'Конструктив здания',
                      desc: 'Стены, фундамент, кровля, перекрытия, инженерия',
                    ),
                    SizedBox(height: 12),
                    _FeatureRow(
                      icon: Icons.camera_enhance_rounded,
                      title: 'Фотофиксация',
                      desc: 'Фото с аннотациями и геотегами',
                    ),
                    SizedBox(height: 12),
                    _FeatureRow(
                      icon: Icons.mic_rounded,
                      title: 'Голосовой ввод',
                      desc: 'Диктуйте замеры — AI заполнит все поля',
                    ),
                    SizedBox(height: 12),
                    _FeatureRow(
                      icon: Icons.picture_as_pdf_rounded,
                      title: 'PDF и Excel отчёты',
                      desc: 'Коммерческие предложения и прайс-листы',
                    ),
                    SizedBox(height: 12),
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
                    shadowColor: const Color(0xFF00B4D8).withOpacity(0.4),
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

// ===== ШАГ 1: Верификация телефона через LoginBot =====

class _PhoneVerificationStep extends StatefulWidget {
  final ValueChanged<String> onVerified;

  const _PhoneVerificationStep({required this.onVerified});

  @override
  State<_PhoneVerificationStep> createState() => _PhoneVerificationStepState();
}

class _PhoneVerificationStepState extends State<_PhoneVerificationStep> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _waitingCall = false;
  String? _errorMessage;
  String? _requestId;
  String? _callToPhone;
  Timer? _pollTimer;

  final _loginBot = LoginBotService(apiToken: _loginBotToken);

  @override
  void dispose() {
    _phoneController.dispose();
    _pollTimer?.cancel();
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
          enabled: !_waitingCall,
          decoration: InputDecoration(
            labelText: 'Номер телефона',
            hintText: '+7 (999) 123-45-67',
            prefixIcon: const Icon(Icons.phone_outlined),
          ),
        ),
        const SizedBox(height: 16),

        if (_waitingCall && _callToPhone != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0077B6).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF0077B6).withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const Icon(Icons.phone_callback, size: 40, color: Color(0xFF0077B6)),
                const SizedBox(height: 12),
                const Text(
                  'Позвоните на этот номер:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  _callToPhone!,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: Color(0xFF0077B6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Звонок будет сброшен — это нормально.\nВы ни за что не платите.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _callServiceNumber,
                    icon: const Icon(Icons.dialpad),
                    label: const Text('Позвонить'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ),

        if (!_waitingCall)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0077B6).withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 18, color: Color(0xFF0077B6)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'После нажатия "Продолжить" вам нужно будет\nпозвонить на указанный номер',
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
          ),

        if (!_waitingCall)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _requestAuth,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.phone),
              label: const Text('Продолжить'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ),
      ],
    );
  }

  String _normalizePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('8') && digits.length == 11) {
      return '7${digits.substring(1)}';
    }
    if (!digits.startsWith('7')) {
      return '7$digits';
    }
    return digits;
  }

  Future<void> _requestAuth() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _errorMessage = 'Введите номер телефона');
      return;
    }

    final normalizedPhone = _normalizePhone(phone);
    if (normalizedPhone.length < 11) {
      setState(() => _errorMessage = 'Введите корректный номер телефона');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _loginBot.requestAuth(normalizedPhone);
      if (!mounted) return;

      if (!result.success) {
        setState(() {
          _errorMessage = result.error ?? 'Ошибка запроса авторизации';
        });
        return;
      }

      if (result.requestId == null || result.callToPhone == null) {
        setState(() {
          _errorMessage = 'Не удалось получить номер для звонка';
        });
        return;
      }

      setState(() {
        _waitingCall = true;
        _requestId = result.requestId;
        _callToPhone = result.callToPhone;
        _errorMessage = null;
      });

      _startPolling();
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Ошибка: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    int attempts = 0;

    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted || _requestId == null) {
        timer.cancel();
        return;
      }

      attempts++;
      if (attempts > 60) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _errorMessage = 'Время ожидания истекло. Попробуйте снова.';
            _waitingCall = false;
            _callToPhone = null;
          });
        }
        return;
      }

      try {
        final status = await _loginBot.checkStatus(_requestId!);
        if (!mounted) return;

        if (status.isAccepted) {
          timer.cancel();
          widget.onVerified(_phoneController.text.trim());
        } else if (status.isRejected || status.isCancelled) {
          timer.cancel();
          setState(() {
            _errorMessage = 'Звонок не получен. Попробуйте снова.';
            _waitingCall = false;
            _callToPhone = null;
          });
        }
      } catch (_) {}
    });
  }

  Future<void> _callServiceNumber() async {
    if (_callToPhone == null) return;
    final uri = Uri.parse('tel:${_callToPhone!.replaceAll(RegExp(r'\D'), '')}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      setState(() => _errorMessage = 'Не удалось открыть звонилку');
    }
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
