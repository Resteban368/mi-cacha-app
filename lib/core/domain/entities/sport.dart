/// Deportes soportados por las canchas (fijos en la plataforma).
enum Sport {
  futbol('FUTBOL'),
  padel('PADEL'),
  baloncesto('BALONCESTO'),
  voleibol('VOLEIBOL');

  const Sport(this.apiCode);

  /// Valor exacto que envía y recibe la API.
  final String apiCode;

  /// `null` si la API envía un deporte desconocido.
  static Sport? fromApi(String? code) {
    if (code == null) return null;
    for (final sport in values) {
      if (sport.apiCode == code) return sport;
    }
    return null;
  }
}
