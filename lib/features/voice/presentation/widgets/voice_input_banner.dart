import 'package:flutter/material.dart';
import '../../../../services/voice_input_service.dart';

/// Компактная панель голосового ввода — отображается поверх чек-листа
/// Пользователь может прокручивать чек-лист пока идёт распознавание
class VoiceInputBanner extends StatefulWidget {
  final Function(String text) onResult;
  final VoidCallback onClose;

  const VoiceInputBanner({
    super.key,
    required this.onResult,
    required this.onClose,
  });

  @override
  State<VoiceInputBanner> createState() => _VoiceInputBannerState();
}

class _VoiceInputBannerState extends State<VoiceInputBanner>
    with SingleTickerProviderStateMixin {
  final VoiceInputService _voiceService = VoiceInputService();
  bool _isListening = false;
  String _currentText = '';
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _startListening();
  }

  Future<void> _startListening() async {
    final available = await _voiceService.initialize();
    if (!available) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Распознавание речи недоступно'),
            backgroundColor: Colors.red,
          ),
        );
        widget.onClose();
      }
      return;
    }

    setState(() => _isListening = true);

    _voiceService.onResult = (result) {
      if (mounted) {
        setState(() => _currentText = result.recognizedText);
      }
    };

    await _voiceService.startListening();
  }

  Future<void> _stopAndApply() async {
    await _voiceService.stopListening();
    if (_currentText.isNotEmpty) {
      widget.onResult(_currentText);
    }
    widget.onClose();
  }

  @override
  void dispose() {
    _voiceService.cancelListening();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8, left: 8, right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _isListening ? Colors.red.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isListening ? Colors.red : Colors.grey.shade300,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Индикатор записи
              if (_isListening)
                ScaleTransition(
                  scale: _pulseController,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                )
              else
                const Icon(Icons.mic_off, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              // Текст
              Expanded(
                child: Text(
                  _currentText.isEmpty
                      ? 'Говорите...'
                      : _currentText,
                  style: TextStyle(
                    fontSize: 14,
                    color: _currentText.isEmpty
                        ? Colors.grey.shade600
                        : Colors.black87,
                    fontStyle: _currentText.isEmpty
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // Кнопка закрыть
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () {
                  _voiceService.cancelListening();
                  widget.onClose();
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          if (_currentText.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: _stopAndApply,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Применить', style: TextStyle(fontSize: 13)),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.green.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: () {
                    setState(() => _currentText = '');
                    _startListening();
                  },
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Ещё раз', style: TextStyle(fontSize: 13)),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
