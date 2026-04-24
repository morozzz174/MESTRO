import '../../../../models/order.dart';
import '../../../../services/voice_input_service.dart';

/// Миксин для обработки голосового ввода в чек-листе
mixin ChecklistVoiceInputMixin {
  Order _applyVoiceInputToOrder(Order order, String text) {
    if (text.isNotEmpty) {
      final currentNotes = order.notes ?? '';
      final newNotes = currentNotes.isEmpty ? text : '$currentNotes; $text';
      return order.copyWith(notes: newNotes);
    }
    return order;
  }

  void _applyVoiceDataToChecklist(
    VoiceExtractedData data,
    void Function(String fieldId, String value) onFieldUpdate,
  ) {
    if (data.windowWidth != null) {
      onFieldUpdate('width', data.windowWidth.toString());
    }
    if (data.windowHeight != null) {
      onFieldUpdate('height', data.windowHeight.toString());
    }
    if (data.area != null) {
      onFieldUpdate('area', data.area.toString());
    }
    if (data.windowCount != null) {
      onFieldUpdate('window_count', data.windowCount.toString());
    }
    if (data.windowType != null) {
      onFieldUpdate('window_type', data.windowType!);
    }
    if (data.hasSill) {
      onFieldUpdate('has_sill', 'true');
    }
    if (data.hasSlopes) {
      onFieldUpdate('has_slopes', 'true');
    }
    if (data.hasMosquitoNet) {
      onFieldUpdate('mosquito_net', 'true');
    }
  }

  String formatVoiceInputResult(VoiceExtractedData data) {
    final parts = <String>[];
    if (data.windowWidth != null) parts.add('Ширина: ${data.windowWidth}');
    if (data.windowHeight != null) parts.add('Высота: ${data.windowHeight}');
    if (data.area != null) parts.add('Площадь: ${data.area}');
    if (data.windowCount != null) parts.add('Кол-во: ${data.windowCount}');
    if (data.windowType != null) parts.add('Тип: ${data.windowType}');
    return parts.join(', ');
  }
}
