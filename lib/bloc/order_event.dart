import 'package:equatable/equatable.dart';
import '../models/order.dart';

// ===== Events =====
abstract class OrderEvent extends Equatable {
  const OrderEvent();

  @override
  List<Object?> get props => [];
}

class LoadOrders extends OrderEvent {}

class CreateOrder extends OrderEvent {
  final Order order;
  const CreateOrder(this.order);

  @override
  List<Object?> get props => [order];
}

class UpdateOrder extends OrderEvent {
  final Order order;
  const UpdateOrder(this.order);

  @override
  List<Object?> get props => [order];
}

class DeleteOrder extends OrderEvent {
  final String orderId;
  const DeleteOrder(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class AddPhoto extends OrderEvent {
  final String orderId;
  final PhotoAnnotation photo;
  const AddPhoto(this.orderId, this.photo);

  @override
  List<Object?> get props => [orderId, photo];
}

class UpdatePhoto extends OrderEvent {
  final PhotoAnnotation photo;
  const UpdatePhoto(this.photo);

  @override
  List<Object?> get props => [photo];
}

class DeletePhoto extends OrderEvent {
  final String photoId;
  const DeletePhoto(this.photoId);

  @override
  List<Object?> get props => [photoId];
}

// ===== States =====
abstract class OrderState extends Equatable {
  const OrderState();

  @override
  List<Object?> get props => [];
}

class OrderInitial extends OrderState {}

class OrderLoading extends OrderState {}

class OrderLoaded extends OrderState {
  final List<Order> orders;
  const OrderLoaded(this.orders);

  @override
  List<Object?> get props => [orders];
}

class OrderError extends OrderState {
  final String message;
  const OrderError(this.message);

  @override
  List<Object?> get props => [message];
}
