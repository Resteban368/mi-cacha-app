import '../../../../core/utils/formatters.dart';
import '../../domain/entities/reservation.dart';

/// Enlace de WhatsApp con el comprobante de la reserva para el cliente.
/// Devuelve `null` si la reserva no tiene teléfono.
Uri? reservationWhatsAppUri(Reservation r) {
  var phone = r.phone.replaceAll(RegExp(r'\D'), '');
  if (phone.isEmpty) return null;
  if (!phone.startsWith('57')) phone = '57$phone';

  final id = r.id.length > 6 ? r.id.substring(0, 6) : r.id;
  final text = [
    'Hola ${r.customerName}, tu reserva en Mi Cancha está confirmada.',
    '',
    'Cancha: ${r.courtsLabel}',
    'Fecha: ${AppFormatters.longDate(r.start)}',
    'Horario: ${AppFormatters.timeRange(r.start, r.end)}',
    'Total: ${AppFormatters.cop(r.displayTotal)}',
    'Pagado: ${AppFormatters.cop(r.displayPaid)}',
    'Saldo: ${AppFormatters.cop(r.displayBalance)}',
    'Código: #RES-${id.toUpperCase()}',
  ].join('\n');
  return Uri.https('wa.me', '/$phone', {'text': text});
}
