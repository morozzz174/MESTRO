import '../../database/database_helper.dart';
import '../../models/order.dart';
import '../order_repository.dart';

/// Реализация OrderRepository на основе DatabaseHelper
class OrderRepositoryImpl implements OrderRepository {
  final DatabaseHelper _db = DatabaseHelper();

  @override
  Future<List<Order>> getAllOrders() => _db.getAllOrders();

  @override
  Future<Order?> getOrder(String id) => _db.getOrder(id);

  @override
  Future<void> insertOrder(Order order) => _db.insertOrder(order);

  @override
  Future<void> updateOrder(Order order) => _db.updateOrder(order);

  @override
  Future<void> deleteOrder(String id) => _db.deleteOrder(id);

  @override
  Future<List<Order>> getOrdersByDate(DateTime date) => _db.getOrdersByDate(date);

  @override
  Future<Map<DateTime, List<Order>>> getAllCalendarOrders() => _db.getAllCalendarOrders();

  @override
  Future<List<Order>> getFutureAppointments() => _db.getFutureAppointments();

  @override
  Future<List<Order>> getPastAppointments() => _db.getPastAppointments();

  @override
  Future<List<PhotoAnnotation>> getPhotosForOrder(String orderId) => _db.getPhotosForOrder(orderId);

  @override
  Future<void> insertPhoto(PhotoAnnotation photo) => _db.insertPhoto(photo);

  @override
  Future<void> updatePhoto(PhotoAnnotation photo) => _db.updatePhoto(photo);

  @override
  Future<void> deletePhoto(String id) => _db.deletePhoto(id);
}
