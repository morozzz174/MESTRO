import 'package:geolocator/geolocator.dart';

class LocationHelper {
  /// Проверка доступности геолокации
  static Future<bool> isLocationEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Запрос разрешений и получение позиции
  static Future<Position?> getCurrentPosition() async {
    final enabled = await isLocationEnabled();
    if (!enabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) return null;

    try {
      return await Geolocator.getCurrentPosition();
    } catch (e) {
      return null;
    }
  }
}
