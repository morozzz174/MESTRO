import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../repositories/order_repository.dart';
import '../../../../repositories/impl/order_repository_impl.dart';
import '../../../../bloc/order_bloc.dart';
import '../../../../bloc/order_event.dart';
import '../../notifications/services/scheduling_service.dart';
import 'calendar_event.dart';
import 'calendar_state.dart';

class CalendarBloc extends Bloc<CalendarEvent, CalendarState> {
  final OrderRepository _repository;

  CalendarBloc({OrderRepository? repository})
    : _repository = repository ?? OrderRepositoryImpl(),
      super(CalendarInitial()) {
    on<CalendarLoadOrders>(_onLoadOrders);
    on<CalendarSelectDay>(_onSelectDay);
    on<CalendarCreateOrder>(_onCreateOrder);
    on<CalendarUpdateOrder>(_onUpdateOrder);
    on<CalendarSyncFromOrderBloc>(_onSyncFromOrderBloc);
  }

  /// Синхронизация с OrderBloc — перезагрузка при любом изменении заявок
  void syncFromOrderBloc(OrderBloc orderBloc) {
    orderBloc.stream.listen((orderState) {
      if (orderState is OrderLoaded || orderState is OrderError) {
        add(CalendarSyncFromOrderBloc());
      }
    });
  }

  Future<void> _onSyncFromOrderBloc(
    CalendarSyncFromOrderBloc event,
    Emitter<CalendarState> emit,
  ) async {
    try {
      final orders = await _repository.getAllOrders();
      final ordersByDay = await _repository.getAllCalendarOrders();

      // Сохраняем выбранный день
      DateTime selectedDay;
      if (state is CalendarLoaded) {
        selectedDay = (state as CalendarLoaded).selectedDay;
      } else {
        final today = DateTime.now();
        selectedDay = DateTime(today.year, today.month, today.day);
      }

      final key = DateTime(
        selectedDay.year,
        selectedDay.month,
        selectedDay.day,
      );
      final dayOrders = ordersByDay[key] ?? [];

      emit(
        CalendarLoaded(
          allOrders: orders,
          ordersByDay: ordersByDay,
          selectedDay: key,
          selectedDayOrders: dayOrders,
        ),
      );
    } catch (e) {
      // Логируем ошибку синхронизации
      debugPrint('[CalendarBloc] Sync error: $e');
    }
  }

  Future<void> _onLoadOrders(
    CalendarLoadOrders event,
    Emitter<CalendarState> emit,
  ) async {
    emit(CalendarLoading());
    try {
      final orders = await _repository.getAllOrders();
      final ordersByDay = await _repository.getAllCalendarOrders();
      final today = DateTime.now();
      final selectedKey = DateTime(today.year, today.month, today.day);

      emit(
        CalendarLoaded(
          allOrders: orders,
          ordersByDay: ordersByDay,
          selectedDay: selectedKey,
          selectedDayOrders: ordersByDay[selectedKey] ?? [],
        ),
      );
    } catch (e) {
      emit(CalendarError('Ошибка загрузки календаря: $e'));
    }
  }

  Future<void> _onSelectDay(
    CalendarSelectDay event,
    Emitter<CalendarState> emit,
  ) async {
    if (state is! CalendarLoaded) return;

    final current = state as CalendarLoaded;
    final key = DateTime(event.day.year, event.day.month, event.day.day);
    final dayOrders = current.ordersByDay[key] ?? [];

    emit(current.copyWith(selectedDay: key, selectedDayOrders: dayOrders));
  }

  Future<void> _onCreateOrder(
    CalendarCreateOrder event,
    Emitter<CalendarState> emit,
  ) async {
    try {
      await _repository.insertOrder(event.order);

      // Планируем уведомления
      if (event.order.appointmentDate != null) {
        final scheduler = AppointmentNotificationScheduler();
        await scheduler.scheduleForAppointment(event.order);
      }

      add(CalendarLoadOrders());
    } catch (e) {
      emit(CalendarError('Ошибка создания заявки: $e'));
    }
  }

  Future<void> _onUpdateOrder(
    CalendarUpdateOrder event,
    Emitter<CalendarState> emit,
  ) async {
    try {
      await _repository.updateOrder(event.order);
      add(CalendarLoadOrders());
    } catch (e) {
      emit(CalendarError('Ошибка обновления заявки: $e'));
    }
  }
}
