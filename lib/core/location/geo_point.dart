import 'package:equatable/equatable.dart';

/// Coordenada WGS84 (la que usan la API y los mapas).
class GeoPoint extends Equatable {
  const GeoPoint(this.latitude, this.longitude)
    : assert(latitude >= -90 && latitude <= 90),
      assert(longitude >= -180 && longitude <= 180);

  final double latitude;
  final double longitude;

  /// `4.60971, -74.08175`: 5 decimales ≈ 1 m de precisión.
  String get label =>
      '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';

  @override
  List<Object?> get props => [latitude, longitude];
}
