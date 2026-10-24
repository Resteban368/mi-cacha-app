import 'package:equatable/equatable.dart';

/// Link público de reservas en línea del negocio
/// (`GET /business/online-booking`), para compartir con los clientes.
class OnlineBookingLink extends Equatable {
  const OnlineBookingLink({
    required this.url,
    required this.slug,
    required this.enabled,
    required this.bookingAvailable,
    this.unavailableReason,
  });

  /// Link para compartir (HTTPS).
  final String url;
  final String slug;

  /// Si el negocio tiene activado el link.
  final bool enabled;

  /// Si hoy se puede reservar (p. ej. tiene canchas listas y plan activo).
  final bool bookingAvailable;

  /// Por qué no se puede reservar, escrito por la API para el usuario.
  final String? unavailableReason;

  /// El link está activo y recibe reservas.
  bool get isLive => enabled && bookingAvailable;

  @override
  List<Object?> get props => [
    url,
    slug,
    enabled,
    bookingAvailable,
    unavailableReason,
  ];
}
