import 'package:geolocator/geolocator.dart';

import 'geo_point.dart';

enum DeviceLocationError {
  /// El GPS / la ubicación del dispositivo está apagada.
  serviceDisabled,

  /// El usuario no dio permiso (se puede volver a pedir).
  denied,

  /// Permiso negado para siempre: hay que ir a los ajustes.
  deniedForever,

  /// No se pudo obtener la posición (tiempo agotado, sin señal…).
  unavailable,
}

class DeviceLocationException implements Exception {
  const DeviceLocationException(this.error);

  final DeviceLocationError error;

  @override
  String toString() => 'DeviceLocationException($error)';
}

/// Ubicación actual del dispositivo. Interfaz propia para poder
/// reemplazarla en los tests.
abstract interface class DeviceLocation {
  /// Pide permiso si hace falta. Lanza [DeviceLocationException].
  Future<GeoPoint> current();

  /// Abre los ajustes de la app (permiso negado para siempre).
  Future<void> openSettings();
}

class GeolocatorDeviceLocation implements DeviceLocation {
  const GeolocatorDeviceLocation();

  @override
  Future<GeoPoint> current() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const DeviceLocationException(DeviceLocationError.serviceDisabled);
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    switch (permission) {
      case LocationPermission.denied:
        throw const DeviceLocationException(DeviceLocationError.denied);
      case LocationPermission.deniedForever:
        throw const DeviceLocationException(DeviceLocationError.deniedForever);
      case LocationPermission.whileInUse ||
          LocationPermission.always ||
          LocationPermission.unableToDetermine:
        break;
    }
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return GeoPoint(position.latitude, position.longitude);
    } catch (_) {
      throw const DeviceLocationException(DeviceLocationError.unavailable);
    }
  }

  @override
  Future<void> openSettings() => Geolocator.openAppSettings();
}
