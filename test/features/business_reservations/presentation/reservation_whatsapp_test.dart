import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/core/domain/entities/sport.dart';
import 'package:mi_cancha/features/business_reservations/domain/entities/reservation.dart';
import 'package:mi_cancha/features/business_reservations/presentation/utils/reservation_whatsapp.dart';

Reservation _res({String phone = '300 123 4567'}) => Reservation(
  id: 'abcdef123',
  courtName: 'Cancha 1',
  sport: Sport.futbol,
  start: DateTime(2026, 10, 19, 15),
  end: DateTime(2026, 10, 19, 16),
  customerName: 'Tomás',
  phone: phone,
  totalPrice: 50000,
  amountPaid: 20000,
  status: ReservationStatus.confirmed,
);

void main() {
  test('arma el enlace con el código 57 y el comprobante', () {
    final uri = reservationWhatsAppUri(_res())!;
    expect(uri.host, 'wa.me');
    expect(uri.path, '/573001234567');
    final text = uri.queryParameters['text']!;
    expect(text, contains('Hola Tomás'));
    expect(text, contains('Cancha: Cancha 1'));
    expect(text, contains('Saldo: \$30.000'));
    expect(text, contains('Código: #RES-ABCDEF'));
  });

  test('no repite el 57 si el número ya lo trae', () {
    final uri = reservationWhatsAppUri(_res(phone: '+57 300 123 4567'))!;
    expect(uri.path, '/573001234567');
  });

  test('sin teléfono no hay enlace', () {
    expect(reservationWhatsAppUri(_res(phone: '')), isNull);
  });
}
