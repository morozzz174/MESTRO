import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/app_logger.dart';
import '../repositories/order_repository.dart';
import '../repositories/impl/order_repository_impl.dart';
import 'order_event.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final OrderRepository _repository;

  OrderBloc({OrderRepository? repository})
    : _repository = repository ?? OrderRepositoryImpl(),
      super(OrderInitial()) {
    on<LoadOrders>(_onLoadOrders);
    on<CreateOrder>(_onCreateOrder);
    on<UpdateOrder>(_onUpdateOrder);
    on<DeleteOrder>(_onDeleteOrder);
    on<AddPhoto>(_onAddPhoto);
    on<UpdatePhoto>(_onUpdatePhoto);
    on<DeletePhoto>(_onDeletePhoto);
  }

  Future<void> _onLoadOrders(LoadOrders event, Emitter<OrderState> emit) async {
    emit(OrderLoading());
    try {
      final orders = await _repository.getAllOrders();
      emit(OrderLoaded(orders));
    } catch (e, st) {
      AppLogger.error('OrderBloc', 'Ошибка загрузки заявок', e, st);
      emit(OrderError('Ошибка загрузки заявок: $e'));
    }
  }

  Future<void> _onCreateOrder(
    CreateOrder event,
    Emitter<OrderState> emit,
  ) async {
    // Оптимистичное обновление: сразу добавляем в состояние
    if (state is OrderLoaded) {
      final currentOrders = (state as OrderLoaded).orders;
      final updatedOrders = [event.order, ...currentOrders];
      emit(OrderLoaded(updatedOrders));
    }

    try {
      await _repository.insertOrder(event.order);
      // В фоне перезагружаем для синхронизации
      final orders = await _repository.getAllOrders();
      emit(OrderLoaded(orders));
    } catch (e, st) {
      // Откат при ошибке
      AppLogger.error('OrderBloc', 'Ошибка создания заявки', e, st);
      emit(OrderError('Ошибка создания заявки: $e'));
      add(LoadOrders());
    }
  }

  Future<void> _onUpdateOrder(
    UpdateOrder event,
    Emitter<OrderState> emit,
  ) async {
    // Оптимистичное обновление
    if (state is OrderLoaded) {
      final currentOrders = (state as OrderLoaded).orders;
      final updatedOrders = currentOrders
          .map((o) => o.id == event.order.id ? event.order : o)
          .toList();
      emit(OrderLoaded(updatedOrders));
    }

    try {
      await _repository.updateOrder(event.order);
      // В фоне синхронизируем
      final orders = await _repository.getAllOrders();
      emit(OrderLoaded(orders));
    } catch (e, st) {
      AppLogger.error('OrderBloc', 'Ошибка обновления заявки', e, st);
      emit(OrderError('Ошибка обновления заявки: $e'));
      add(LoadOrders());
    }
  }

  Future<void> _onDeleteOrder(
    DeleteOrder event,
    Emitter<OrderState> emit,
  ) async {
    // Оптимистичное удаление
    if (state is OrderLoaded) {
      final currentOrders = (state as OrderLoaded).orders;
      final updatedOrders = currentOrders.where((o) => o.id != event.orderId).toList();
      emit(OrderLoaded(updatedOrders));
    }

    try {
      await _repository.deleteOrder(event.orderId);
      // В фоне синхронизируем
      final orders = await _repository.getAllOrders();
      emit(OrderLoaded(orders));
    } catch (e, st) {
      AppLogger.error('OrderBloc', 'Ошибка удаления заявки', e, st);
      emit(OrderError('Ошибка удаления заявки: $e'));
      add(LoadOrders());
    }
  }

  Future<void> _onAddPhoto(AddPhoto event, Emitter<OrderState> emit) async {
    // Оптимистичное обновление: добавляем фото в заявку
    if (state is OrderLoaded) {
      final currentOrders = (state as OrderLoaded).orders;
      final updatedOrders = currentOrders.map((order) {
        if (order.id == event.orderId) {
          return order.copyWith(photos: [...order.photos, event.photo]);
        }
        return order;
      }).toList();
      emit(OrderLoaded(updatedOrders));
    }

    try {
      await _repository.insertPhoto(event.photo);
      // В фоне синхронизируем
      final orders = await _repository.getAllOrders();
      emit(OrderLoaded(orders));
    } catch (e, st) {
      AppLogger.error('OrderBloc', 'Ошибка добавления фото', e, st);
      emit(OrderError('Ошибка добавления фото: $e'));
      add(LoadOrders());
    }
  }

  Future<void> _onUpdatePhoto(
    UpdatePhoto event,
    Emitter<OrderState> emit,
  ) async {
    // Оптимистичное обновление
    if (state is OrderLoaded) {
      final currentOrders = (state as OrderLoaded).orders;
      final updatedOrders = currentOrders.map((order) {
        final photoIndex = order.photos.indexWhere((p) => p.id == event.photo.id);
        if (photoIndex != -1) {
          final updatedPhotos = [...order.photos];
          updatedPhotos[photoIndex] = event.photo;
          return order.copyWith(photos: updatedPhotos);
        }
        return order;
      }).toList();
      emit(OrderLoaded(updatedOrders));
    }

    try {
      await _repository.updatePhoto(event.photo);
      final orders = await _repository.getAllOrders();
      emit(OrderLoaded(orders));
    } catch (e, st) {
      AppLogger.error('OrderBloc', 'Ошибка обновления фото', e, st);
      emit(OrderError('Ошибка обновления фото: $e'));
      add(LoadOrders());
    }
  }

  Future<void> _onDeletePhoto(
    DeletePhoto event,
    Emitter<OrderState> emit,
  ) async {
    // Оптимистичное удаление
    if (state is OrderLoaded) {
      final currentOrders = (state as OrderLoaded).orders;
      final updatedOrders = currentOrders.map((order) {
        final filteredPhotos = order.photos.where((p) => p.id != event.photoId).toList();
        if (filteredPhotos.length != order.photos.length) {
          return order.copyWith(photos: filteredPhotos);
        }
        return order;
      }).toList();
      emit(OrderLoaded(updatedOrders));
    }

    try {
      await _repository.deletePhoto(event.photoId);
      final orders = await _repository.getAllOrders();
      emit(OrderLoaded(orders));
    } catch (e, st) {
      AppLogger.error('OrderBloc', 'Ошибка удаления фото', e, st);
      emit(OrderError('Ошибка удаления фото: $e'));
      add(LoadOrders());
    }
  }
}
