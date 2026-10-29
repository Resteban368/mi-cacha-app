/// Aviso que llega con la app abierta (desde el Service Worker).
class PushMessage {
  const PushMessage({required this.type, this.title, this.body});

  /// `NEW_RESERVATION`, `ADMIN_NOTICE`…
  final String type;
  final String? title;
  final String? body;

  bool get isNewReservation => type == 'NEW_RESERVATION';
}
