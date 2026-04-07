import 'package:flutter_test/flutter_test.dart';
import 'package:metro_2/models/checklist_config.dart';
import 'package:metro_2/utils/condition_evaluator.dart';

void main() {
  group('ConditionEvaluator', () {
    group('isFieldVisible', () {
      test('should return true when field has no condition', () {
        final field = ChecklistField(
          id: 'name',
          type: 'text',
          label: 'Имя',
          required: true,
        );
        final formData = <String, dynamic>{};

        final result = ConditionEvaluator.isFieldVisible(field, formData);

        expect(result, isTrue);
      });

      test('should return true when condition is met (equals)', () {
        final field = ChecklistField(
          id: 'quarter_depth',
          type: 'number',
          label: 'Глубина четверти',
          condition: ChecklistCondition(
            field: 'has_quarter',
            operator: 'equals',
            value: true,
          ),
        );
        final formData = {'has_quarter': true};

        final result = ConditionEvaluator.isFieldVisible(field, formData);

        expect(result, isTrue);
      });

      test('should return false when condition is not met (equals)', () {
        final field = ChecklistField(
          id: 'quarter_depth',
          type: 'number',
          label: 'Глубина четверти',
          condition: ChecklistCondition(
            field: 'has_quarter',
            operator: 'equals',
            value: true,
          ),
        );
        final formData = {'has_quarter': false};

        final result = ConditionEvaluator.isFieldVisible(field, formData);

        expect(result, isFalse);
      });

      test('should return false when required field is missing', () {
        final field = ChecklistField(
          id: 'quarter_depth',
          type: 'number',
          label: 'Глубина четверти',
          condition: ChecklistCondition(
            field: 'has_quarter',
            operator: 'equals',
            value: true,
          ),
        );
        final formData = {'other_field': 'value'};

        final result = ConditionEvaluator.isFieldVisible(field, formData);

        expect(result, isFalse);
      });

      test('should handle not_equals operator', () {
        final field = ChecklistField(
          id: 'detail',
          type: 'text',
          label: 'Детали',
          condition: ChecklistCondition(
            field: 'status',
            operator: 'not_equals',
            value: 'none',
          ),
        );
        final formData = {'status': 'completed'};

        final result = ConditionEvaluator.isFieldVisible(field, formData);

        expect(result, isTrue);
      });

      test('should handle greater_than operator', () {
        final field = ChecklistField(
          id: 'discount',
          type: 'number',
          label: 'Скидка',
          condition: ChecklistCondition(
            field: 'total',
            operator: 'greater_than',
            value: 10000,
          ),
        );
        final formData = {'total': 15000};

        final result = ConditionEvaluator.isFieldVisible(field, formData);

        expect(result, isTrue);
      });

      test('should handle less_than operator', () {
        final field = ChecklistField(
          id: 'small_order_fee',
          type: 'number',
          label: 'Наценка за малый заказ',
          condition: ChecklistCondition(
            field: 'total',
            operator: 'less_than',
            value: 5000,
          ),
        );
        final formData = {'total': 3000};

        final result = ConditionEvaluator.isFieldVisible(field, formData);

        expect(result, isTrue);
      });
    });

    group('validateRequiredFields', () {
      test('should return empty list when all required fields are filled', () {
        final fields = [
          ChecklistField(
            id: 'name',
            type: 'text',
            label: 'Имя',
            required: true,
          ),
          ChecklistField(
            id: 'phone',
            type: 'text',
            label: 'Телефон',
            required: true,
          ),
        ];
        final formData = {
          'name': 'Иван',
          'phone': '+79001234567',
        };

        final errors = ConditionEvaluator.validateRequiredFields(fields, formData);

        expect(errors, isEmpty);
      });

      test('should return error list when required fields are missing', () {
        final fields = [
          ChecklistField(
            id: 'name',
            type: 'text',
            label: 'Имя',
            required: true,
          ),
          ChecklistField(
            id: 'phone',
            type: 'text',
            label: 'Телефон',
            required: true,
          ),
        ];
        final formData = {
          'name': 'Иван',
        };

        final errors = ConditionEvaluator.validateRequiredFields(fields, formData);

        expect(errors, hasLength(1));
        expect(errors, contains('Телефон'));
      });

      test('should not validate hidden required fields', () {
        final fields = [
          ChecklistField(
            id: 'has_quarter',
            type: 'boolean',
            label: 'Есть четверть',
          ),
          ChecklistField(
            id: 'quarter_depth',
            type: 'number',
            label: 'Глубина четверти',
            required: true,
            condition: ChecklistCondition(
              field: 'has_quarter',
              operator: 'equals',
              value: true,
            ),
          ),
        ];
        final formData = {'has_quarter': false};

        final errors = ConditionEvaluator.validateRequiredFields(fields, formData);

        expect(errors, isEmpty);
      });

      test('should validate visible required fields with zero value', () {
        final fields = [
          ChecklistField(
            id: 'width',
            type: 'number',
            label: 'Ширина',
            required: true,
          ),
        ];
        final formData = {'width': 0};

        final errors = ConditionEvaluator.validateRequiredFields(fields, formData);

        expect(errors, hasLength(1));
        expect(errors, contains('Ширина'));
      });

      test('should not validate optional fields', () {
        final fields = [
          ChecklistField(
            id: 'notes',
            type: 'text',
            label: 'Заметки',
            required: false,
          ),
        ];
        final formData = <String, dynamic>{};

        final errors = ConditionEvaluator.validateRequiredFields(fields, formData);

        expect(errors, isEmpty);
      });

      test('should handle empty string as missing value', () {
        final fields = [
          ChecklistField(
            id: 'name',
            type: 'text',
            label: 'Имя',
            required: true,
          ),
        ];
        final formData = {'name': ''};

        final errors = ConditionEvaluator.validateRequiredFields(fields, formData);

        expect(errors, hasLength(1));
      });

      test('should handle multiple missing required fields', () {
        final fields = [
          ChecklistField(
            id: 'name',
            type: 'text',
            label: 'Имя',
            required: true,
          ),
          ChecklistField(
            id: 'phone',
            type: 'text',
            label: 'Телефон',
            required: true,
          ),
          ChecklistField(
            id: 'address',
            type: 'text',
            label: 'Адрес',
            required: true,
          ),
        ];
        final formData = <String, dynamic>{};

        final errors = ConditionEvaluator.validateRequiredFields(fields, formData);

        expect(errors, hasLength(3));
        expect(errors, containsAll(['Имя', 'Телефон', 'Адрес']));
      });
    });

    group('Integration: visibility + validation', () {
      test('should validate only visible required fields', () {
        final fields = [
          ChecklistField(
            id: 'window_type',
            type: 'select',
            label: 'Тип окна',
            required: true,
            options: ['Одностворчатое', 'Двустворчатое', 'Трёхстворчатое'],
          ),
          ChecklistField(
            id: 'sill_width',
            type: 'number',
            label: 'Ширина подоконника',
            required: true,
            condition: ChecklistCondition(
              field: 'has_sill',
              operator: 'equals',
              value: true,
            ),
          ),
        ];
        final formData = {
          'window_type': 'Двустворчатое',
          'has_sill': false,
        };

        final errors = ConditionEvaluator.validateRequiredFields(fields, formData);

        // Только window_type должен быть валидирован (заполнен)
        // sill_width скрыт, поэтому не должен вызывать ошибку
        expect(errors, isEmpty);
      });

      test('should require hidden field when condition is met', () {
        final fields = [
          ChecklistField(
            id: 'has_sill',
            type: 'boolean',
            label: 'Есть подоконник',
          ),
          ChecklistField(
            id: 'sill_width',
            type: 'number',
            label: 'Ширина подоконника',
            required: true,
            condition: ChecklistCondition(
              field: 'has_sill',
              operator: 'equals',
              value: true,
            ),
          ),
        ];
        final formData = {
          'has_sill': true,
        };

        final errors = ConditionEvaluator.validateRequiredFields(fields, formData);

        expect(errors, hasLength(1));
        expect(errors, contains('Ширина подоконника'));
      });
    });
  });
}
