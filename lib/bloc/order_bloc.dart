import 'package:flutter_bloc/flutter_bloc.dart';
import '../database/database_helper.dart';
import 'order_event.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final DatabaseHelper _db = DatabaseHelper();

  OrderBloc() : super(OrderInitial()) {
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
      final orders = await _db.getAllOrders();
      emit(OrderLoaded(orders));
    } catch (e) {
      emit(OrderError('Ошибка загрузки заявок: $e'));
    }
  }

  Future<void> _onCreateOrder(
    CreateOrder event,
    Emitter<OrderState> emit,
  ) async {
    try {
      await _db.insertOrder(event.order);
      final orders = await _db.getAllOrders();
      emit(OrderLoaded(orders));
    } catch (e) {
      emit(OrderError('Ошибка создания заявки: $e'));
    }
  }

  Future<void> _onUpdateOrder(
    UpdateOrder event,
    Emitter<OrderState> emit,
  ) async {
    try {
      await _db.updateOrder(event.order);
      final orders = await _db.getAllOrders();
      emit(OrderLoaded(orders));
    } catch (e) {
      emit(OrderError('Ошибка обновления заявки: $e'));
    }
  }

  Future<void> _onDeleteOrder(
    DeleteOrder event,
    Emitter<OrderState> emit,
  ) async {
    try {
      await _db.deleteOrder(event.orderId);
      final orders = await _db.getAllOrders();
      emit(OrderLoaded(orders));
    } catch (e) {
      emit(OrderError('Ошибка удаления заявки: $e'));
    }
  }

  Future<void> _onAddPhoto(AddPhoto event, Emitter<OrderState> emit) async {
    try {
      await _db.insertPhoto(event.photo);
      // Перезагружаем заявки для обновления UI
      final orders = await _db.getAllOrders();
      emit(OrderLoaded(orders));
    } catch (e) {
      emit(OrderError('Ошибка добавления фото: $e'));
    }
  }

  Future<void> _onUpdatePhoto(
    UpdatePhoto event,
    Emitter<OrderState> emit,
  ) async {
    try {
      await _db.updatePhoto(event.photo);
      final orders = await _db.getAllOrders();
      emit(OrderLoaded(orders));
    } catch (e) {
      emit(OrderError('Ошибка обновления фото: $e'));
    }
  }

  Future<void> _onDeletePhoto(
    DeletePhoto event,
    Emitter<OrderState> emit,
  ) async {
    try {
      await _db.deletePhoto(event.photoId);
      final orders = await _db.getAllOrders();
      emit(OrderLoaded(orders));
    } catch (e) {
      emit(OrderError('Ошибка удаления фото: $e'));
    }
  }
}
