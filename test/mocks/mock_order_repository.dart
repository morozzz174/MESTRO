import 'package:metro_2/models/order.dart';
import 'package:metro_2/repositories/order_repository.dart';

/// Mock репозитория для тестирования OrderBloc
class MockOrderRepository implements OrderRepository {
  final List<Order> _orders = [];
  final List<PhotoAnnotation> _photos = [];

  int getAllOrdersCallCount = 0;
  bool shouldThrow = false;
  String? errorMessage;

  void reset() {
    _orders.clear();
    _photos.clear();
    getAllOrdersCallCount = 0;
    shouldThrow = false;
    errorMessage = null;
  }

  @override
  Future<List<Order>> getAllOrders() async {
    if (shouldThrow) {
      throw Exception(errorMessage ?? 'Database error');
    }
    getAllOrdersCallCount++;
    // Обогащаем заказы фотографиями
    return _orders.map((order) {
      final orderPhotos = _photos.where((p) => p.orderId == order.id).toList();
      return order.copyWith(photos: orderPhotos);
    }).toList();
  }

  @override
  Future<Order?> getOrder(String id) async {
    if (shouldThrow) throw Exception(errorMessage ?? 'Database error');
    try {
      return _orders.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> insertOrder(Order order) async {
    if (shouldThrow) throw Exception(errorMessage ?? 'Database error');
    _orders.add(order);
  }

  @override
  Future<void> updateOrder(Order order) async {
    if (shouldThrow) throw Exception(errorMessage ?? 'Database error');
    final index = _orders.indexWhere((o) => o.id == order.id);
    if (index != -1) {
      _orders[index] = order;
    }
  }

  @override
  Future<void> deleteOrder(String id) async {
    if (shouldThrow) throw Exception(errorMessage ?? 'Database error');
    _orders.removeWhere((o) => o.id == id);
  }

  @override
  Future<List<Order>> getOrdersByDate(DateTime date) async {
    if (shouldThrow) throw Exception(errorMessage ?? 'Database error');
    return [];
  }

  @override
  Future<Map<DateTime, List<Order>>> getAllCalendarOrders() async {
    if (shouldThrow) throw Exception(errorMessage ?? 'Database error');
    return {};
  }

  @override
  Future<List<Order>> getFutureAppointments() async {
    if (shouldThrow) throw Exception(errorMessage ?? 'Database error');
    return [];
  }

  @override
  Future<List<Order>> getPastAppointments() async {
    if (shouldThrow) throw Exception(errorMessage ?? 'Database error');
    return [];
  }

  @override
  Future<List<PhotoAnnotation>> getPhotosForOrder(String orderId) async {
    if (shouldThrow) throw Exception(errorMessage ?? 'Database error');
    return _photos.where((p) => p.orderId == orderId).toList();
  }

  @override
  Future<void> insertPhoto(PhotoAnnotation photo) async {
    if (shouldThrow) throw Exception(errorMessage ?? 'Database error');
    _photos.add(photo);
  }

  @override
  Future<void> updatePhoto(PhotoAnnotation photo) async {
    if (shouldThrow) throw Exception(errorMessage ?? 'Database error');
    final index = _photos.indexWhere((p) => p.id == photo.id);
    if (index != -1) {
      _photos[index] = photo;
    }
  }

  @override
  Future<void> deletePhoto(String id) async {
    if (shouldThrow) throw Exception(errorMessage ?? 'Database error');
    _photos.removeWhere((p) => p.id == id);
  }
}
