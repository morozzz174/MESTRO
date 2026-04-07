import '../models/order.dart';

/// Абстрактный репозиторий для работы с заявками
/// Отделяет бизнес-логику от прямого доступа к БД
abstract class OrderRepository {
  // ===== Заявки =====

  Future<List<Order>> getAllOrders();

  Future<Order?> getOrder(String id);

  Future<void> insertOrder(Order order);

  Future<void> updateOrder(Order order);

  Future<void> deleteOrder(String id);

  Future<List<Order>> getOrdersByDate(DateTime date);

  Future<Map<DateTime, List<Order>>> getAllCalendarOrders();

  Future<List<Order>> getFutureAppointments();

  Future<List<Order>> getPastAppointments();

  // ===== Фото =====

  Future<List<PhotoAnnotation>> getPhotosForOrder(String orderId);

  Future<void> insertPhoto(PhotoAnnotation photo);

  Future<void> updatePhoto(PhotoAnnotation photo);

  Future<void> deletePhoto(String id);
}
