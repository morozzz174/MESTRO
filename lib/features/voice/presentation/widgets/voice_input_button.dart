import 'package:flutter/material.dart';
import '../../../../services/voice_input_service.dart';

/// Компонент голосового ввода
/// Показывает кнопку микрофона, при нажатии — диалог распознавания речи
class VoiceInputButton extends StatefulWidget {
  /// Callback с распознанным текстом (финальным)
  final Function(String text) onVoiceResult;

  /// Подсказка для пользователя
  final String? hint;

  const VoiceInputButton({super.key, required this.onVoiceResult, this.hint});

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton>
    with SingleTickerProviderStateMixin {
  final VoiceInputService _voiceService = VoiceInputService();
  bool _isInitialized = false;
  bool _isListening = false;
  String _currentText = '';
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _initVoice();
  }

  Future<void> _initVoice() async {
    final available = await _voiceService.initialize();
    if (mounted) {
      setState(() => _isInitialized = available);
    }
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      // Остановить — финальный результат
      print('[VoiceInputButton] Останавливаем запись');
      await _voiceService.stopListening();
      if (mounted && _currentText.isNotEmpty) {
        print('[VoiceInputButton] Возвращаем результат: $_currentText');
        widget.onVoiceResult(_currentText);
      }
      setState(() {
        _isListening = false;
        _currentText = '';
      });
    } else {
      // Начать распознавание
      print('[VoiceInputButton] Начинаем запись');
      setState(() {
        _isListening = true;
        _currentText = '';
      });

      _voiceService.onResult = (result) {
        if (mounted) {
          print('[VoiceInputButton] Обновление текста: ${result.recognizedText}');
          setState(() => _currentText = result.recognizedText);
        }
      };

      final started = await _voiceService.startListening();
      if (!started && mounted) {
        print('[VoiceInputButton] Не удалось начать запись');
        setState(() => _isListening = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Не удалось начать запись. Проверьте микрофон и распознавание речи.',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          ),
        );
      } else if (started) {
        print('[VoiceInputButton] Запись начата успешно');
      }
    }
  }

  @override
  void dispose() {
    _voiceService.cancelListening();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: FloatingActionButton(
        onPressed: _isInitialized ? _toggleListening : null,
        backgroundColor: _isListening
            ? Colors.red
            : Theme.of(context).colorScheme.primary,
        child: _isListening
            ? ScaleTransition(
                scale: _scaleAnimation,
                child: const Icon(Icons.mic, color: Colors.white),
              )
            : const Icon(Icons.mic_none, color: Colors.white),
        tooltip: _isListening ? 'Нажмите для остановки' : 'Голосовой ввод',
      ),
    );
  }
}

/// Модальный диалог голосового ввода с визуализацией
class VoiceInputDialog extends StatefulWidget {
  final Function(String text) onResult;

  const VoiceInputDialog({super.key, required this.onResult});

  static Future<void> show(
    BuildContext context, {
    required Function(String) onResult,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => VoiceInputDialog(onResult: onResult),
    );
  }

  @override
  State<VoiceInputDialog> createState() => _VoiceInputDialogState();
}

class _VoiceInputDialogState extends State<VoiceInputDialog>
    with SingleTickerProviderStateMixin {
  final VoiceInputService _voiceService = VoiceInputService();
  bool _isListening = false;
  String _currentText = '';
  VoiceExtractedData? _extractedData;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _startListening();
  }

  Future<void> _startListening() async {
    print('[VoiceInputDialog] Начинаем инициализацию...');
    final available = await _voiceService.initialize();
    if (!available) {
      print('[VoiceInputDialog] Инициализация не удалась');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Распознавание речи недоступно. '
              'Проверьте наличие Google Speech Services на устройстве.',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    print('[VoiceInputDialog] Запускаем запись...');
    setState(() => _isListening = true);

    _voiceService.onResult = (result) {
      print('[VoiceInputDialog] Получен результат: ${result.recognizedText}');
      if (mounted) {
        setState(() {
          _currentText = result.recognizedText;
          _extractedData = _voiceService.extractData(_currentText);
        });
      }
    };

    final started = await _voiceService.startListening();
    if (!started && mounted) {
      print('[VoiceInputDialog] Не удалось начать запись');
      setState(() => _isListening = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Не удалось начать запись. '
            'Проверьте разрешение на использование микрофона '
            'и наличие распознавания речи на устройстве.',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    } else {
      print('[VoiceInputDialog] Запись начата успешно');
    }
  }

  Future<void> _stopAndApply() async {
    await _voiceService.stopListening();
    if (mounted && _currentText.isNotEmpty) {
      widget.onResult(_currentText);
      Navigator.of(context).pop();
    }
  }

  Future<void> _cancel() async {
    await _voiceService.cancelListening();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _voiceService.cancelListening();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Заголовок
            const Text(
              'Голосовой ввод',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Надиктуйте размеры и параметры',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 24),

            // Анимация микрофона
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Container(
                  width: 100 * _animationController.value + 40,
                  height: 100 * _animationController.value + 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.withOpacity(
                      0.1 + 0.15 * _animationController.value,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_off,
                      size: 48,
                      color: _isListening ? Colors.red : Colors.grey,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Распознанный текст
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 60),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: _currentText.isEmpty
                  ? Text(
                      'Говорите...',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  : Text(_currentText, style: const TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 16),

            // Извлечённые данные
            if (_extractedData != null && _extractedData!.hasData)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Распознанные данные:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _extractedData.toString(),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            if (_extractedData != null && _extractedData!.hasData)
              const SizedBox(height: 16),

            // Кнопки
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _cancel,
                    icon: const Icon(Icons.close),
                    label: const Text('Отмена'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _currentText.isNotEmpty ? _stopAndApply : null,
                    icon: const Icon(Icons.check),
                    label: const Text('Применить'),
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
