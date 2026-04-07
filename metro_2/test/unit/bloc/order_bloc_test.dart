import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:metro_2/bloc/order_bloc.dart';
import 'package:metro_2/bloc/order_event.dart';
import 'package:metro_2/models/order.dart';
import '../../mocks/mock_order_repository.dart';

void main() {
  group('OrderBloc', () {
    late OrderBloc orderBloc;
    late MockOrderRepository mockRepo;
    late Order testOrder;
    late PhotoAnnotation testPhoto;

    setUp(() {
      mockRepo = MockOrderRepository();
      orderBloc = OrderBloc(repository: mockRepo);

      testOrder = Order(
        id: 'test-order-1',
        clientName: 'Иван Петров',
        address: 'ул. Тестовая, д. 1',
        date: DateTime(2026, 4, 7),
        workType: WorkType.windows,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      testPhoto = PhotoAnnotation(
        id: 'test-photo-1',
        orderId: testOrder.id,
        filePath: '/path/to/photo.jpg',
        annotatedPath: '/path/to/photo_annotated.jpg',
        timestamp: DateTime.now(),
      );
    });

    tearDown(() {
      orderBloc.close();
      mockRepo.reset();
    });

    group('LoadOrders', () {
      test('should emit OrderLoading then OrderLoaded on success', () async {
        mockRepo.insertOrder(testOrder);
        final expectedStates = <OrderState>[];

        orderBloc.stream.listen((state) => expectedStates.add(state));

        orderBloc.add(LoadOrders());
        await Future<void>.delayed(Duration.zero);

        expect(expectedStates, [
          isA<OrderLoading>(),
          isA<OrderLoaded>().having(
            (s) => (s as OrderLoaded).orders,
            'orders',
            [testOrder],
          ),
        ]);
      });

      test('should emit OrderError on database failure', () async {
        mockRepo.shouldThrow = true;
        final expectedStates = <OrderState>[];

        orderBloc.stream.listen((state) => expectedStates.add(state));

        orderBloc.add(LoadOrders());
        await Future<void>.delayed(Duration.zero);

        expect(expectedStates, [
          isA<OrderLoading>(),
          isA<OrderError>(),
        ]);
      });
    });

    group('CreateOrder', () {
      test('should emit optimistic update then sync from DB', () async {
        final expectedStates = <OrderState>[];
        orderBloc.add(LoadOrders());
        await Future<void>.delayed(Duration.zero);

        orderBloc.stream.listen((state) => expectedStates.add(state));

        orderBloc.add(CreateOrder(testOrder));
        await Future<void>.delayed(Duration.zero);

        // Оптимистичное обновление
        expect(expectedStates.last, isA<OrderLoaded>());
        final loadedState = expectedStates.last as OrderLoaded;
        expect(loadedState.orders, contains(testOrder));
      });

      test('should rollback on database failure', () async {
        // Сначала загружаем заказы
        orderBloc.add(LoadOrders());
        await Future<void>.delayed(Duration.zero);

        // Ломаем репозиторий
        mockRepo.shouldThrow = true;
        mockRepo.errorMessage = 'Insert failed';

        final expectedStates = <OrderState>[];
        orderBloc.stream.listen((state) => expectedStates.add(state));

        orderBloc.add(CreateOrder(testOrder));
        await Future<void>.delayed(Duration.zero);

        // Должен быть error + reload
        expect(
          expectedStates.any((s) => s is OrderError),
          isTrue,
          reason: 'Should emit OrderError on failure',
        );
      });
    });

    group('UpdateOrder', () {
      test('should update order optimistically', () async {
        // Загружаем начальные данные
        mockRepo.insertOrder(testOrder);
        orderBloc.add(LoadOrders());
        await Future<void>.delayed(Duration.zero);

        final updatedOrder = testOrder.copyWith(clientName: 'Обновлённое имя');
        final expectedStates = <OrderState>[];
        orderBloc.stream.listen((state) => expectedStates.add(state));

        orderBloc.add(UpdateOrder(updatedOrder));
        await Future<void>.delayed(Duration.zero);

        final loadedState = expectedStates.last as OrderLoaded;
        final foundOrder = loadedState.orders.firstWhere(
          (o) => o.id == testOrder.id,
        );
        expect(foundOrder.clientName, 'Обновлённое имя');
      });

      test('should handle update of non-existent order', () async {
        orderBloc.add(LoadOrders());
        await Future<void>.delayed(Duration.zero);

        final nonExistentOrder = Order(
          id: 'non-existent',
          clientName: 'Test',
          address: 'Test',
          date: DateTime.now(),
          workType: WorkType.windows,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final expectedStates = <OrderState>[];
        orderBloc.stream.listen((state) => expectedStates.add(state));

        orderBloc.add(UpdateOrder(nonExistentOrder));
        await Future<void>.delayed(Duration.zero);

        // Не должно быть ошибок, просто синхронизация
        expect(expectedStates.last, isA<OrderLoaded>());
      });
    });

    group('DeleteOrder', () {
      test('should remove order optimistically', () async {
        mockRepo.insertOrder(testOrder);
        orderBloc.add(LoadOrders());
        await Future<void>.delayed(Duration.zero);

        final expectedStates = <OrderState>[];
        orderBloc.stream.listen((state) => expectedStates.add(state));

        orderBloc.add(DeleteOrder(testOrder.id));
        await Future<void>.delayed(Duration.zero);

        final loadedState = expectedStates.last as OrderLoaded;
        expect(
          loadedState.orders.any((o) => o.id == testOrder.id),
          isFalse,
        );
      });

      test('should handle delete failure with rollback', () async {
        mockRepo.insertOrder(testOrder);
        orderBloc.add(LoadOrders());
        await Future<void>.delayed(Duration.zero);

        mockRepo.shouldThrow = true;
        mockRepo.errorMessage = 'Delete failed';

        final expectedStates = <OrderState>[];
        orderBloc.stream.listen((state) => expectedStates.add(state));

        orderBloc.add(DeleteOrder(testOrder.id));
        await Future<void>.delayed(Duration.zero);

        expect(
          expectedStates.any((s) => s is OrderError),
          isTrue,
        );
      });
    });

    group('Photo operations', () {
      test('should handle photo addition without errors', () async {
        mockRepo.insertOrder(testOrder);
        orderBloc.add(LoadOrders());
        await Future<void>.delayed(Duration.zero);

        final expectedStates = <OrderState>[];
        orderBloc.stream.listen((state) => expectedStates.add(state));

        orderBloc.add(AddPhoto(testOrder.id, testPhoto));
        await Future<void>.delayed(Duration.zero);

        // Проверяем что не было ошибки
        expect(
          expectedStates.any((s) => s is OrderError),
          isFalse,
        );
      });

      test('should handle photo deletion without errors', () async {
        orderBloc.add(LoadOrders());
        await Future<void>.delayed(Duration.zero);

        final expectedStates = <OrderState>[];
        orderBloc.stream.listen((state) => expectedStates.add(state));

        orderBloc.add(DeletePhoto(testPhoto.id));
        await Future<void>.delayed(Duration.zero);

        expect(
          expectedStates.any((s) => s is OrderError),
          isFalse,
        );
      });

      test('should handle photo update without errors', () async {
        orderBloc.add(LoadOrders());
        await Future<void>.delayed(Duration.zero);

        final updatedPhoto = PhotoAnnotation(
          id: testPhoto.id,
          orderId: testPhoto.orderId,
          filePath: testPhoto.filePath,
          annotatedPath: testPhoto.annotatedPath,
          checklistFieldId: 'width',
          timestamp: testPhoto.timestamp,
        );

        final expectedStates = <OrderState>[];
        orderBloc.stream.listen((state) => expectedStates.add(state));

        orderBloc.add(UpdatePhoto(updatedPhoto));
        await Future<void>.delayed(Duration.zero);

        expect(
          expectedStates.any((s) => s is OrderError),
          isFalse,
        );
      });
    });

    group('OrderLoaded state equality', () {
      test('should emit different state when orders change', () async {
        mockRepo.insertOrder(testOrder);
        orderBloc.add(LoadOrders());
        await Future<void>.delayed(Duration.zero);

        final states = <OrderState>[];
        orderBloc.stream.listen((state) => states.add(state));

        // Добавляем второй заказ
        final order2 = Order(
          id: 'test-order-2',
          clientName: 'Пётр Иванов',
          address: 'ул. Вторая, д. 2',
          date: DateTime.now(),
          workType: WorkType.doors,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        mockRepo.insertOrder(order2);

        orderBloc.add(LoadOrders());
        await Future<void>.delayed(Duration.zero);

        expect(states.whereType<OrderLoaded>().length, greaterThan(0));
      });
    });
  });
}
