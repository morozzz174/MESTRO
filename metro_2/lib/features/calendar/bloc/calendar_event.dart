import 'package:equatable/equatable.dart';
import '../../../../models/order.dart';

abstract class CalendarEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class CalendarLoadOrders extends CalendarEvent {}

class CalendarSelectDay extends CalendarEvent {
  final DateTime day;

  CalendarSelectDay(this.day);

  @override
  List<Object?> get props => [day];
}

class CalendarCreateOrder extends CalendarEvent {
  final Order order;

  CalendarCreateOrder(this.order);

  @override
  List<Object?> get props => [order];
}

class CalendarUpdateOrder extends CalendarEvent {
  final Order order;

  CalendarUpdateOrder(this.order);

  @override
  List<Object?> get props => [order];
}

/// Событие синхронизации — триггерится при изменении OrderBloc
class CalendarSyncFromOrderBloc extends CalendarEvent {}
