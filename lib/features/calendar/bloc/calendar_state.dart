import 'package:equatable/equatable.dart';
import '../../../../models/order.dart';

abstract class CalendarState extends Equatable {
  @override
  List<Object?> get props => [];
}

class CalendarInitial extends CalendarState {}

class CalendarLoading extends CalendarState {}

class CalendarLoaded extends CalendarState {
  final List<Order> allOrders;
  final Map<DateTime, List<Order>> ordersByDay;
  final DateTime selectedDay;
  final List<Order> selectedDayOrders;

  CalendarLoaded({
    required this.allOrders,
    required this.ordersByDay,
    required this.selectedDay,
    required this.selectedDayOrders,
  });

  CalendarLoaded copyWith({
    List<Order>? allOrders,
    Map<DateTime, List<Order>>? ordersByDay,
    DateTime? selectedDay,
    List<Order>? selectedDayOrders,
  }) {
    return CalendarLoaded(
      allOrders: allOrders ?? this.allOrders,
      ordersByDay: ordersByDay ?? this.ordersByDay,
      selectedDay: selectedDay ?? this.selectedDay,
      selectedDayOrders: selectedDayOrders ?? this.selectedDayOrders,
    );
  }

  @override
  List<Object?> get props => [allOrders, ordersByDay, selectedDay, selectedDayOrders];
}

class CalendarError extends CalendarState {
  final String message;

  CalendarError(this.message);

  @override
  List<Object?> get props => [message];
}
