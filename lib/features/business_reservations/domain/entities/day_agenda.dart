import 'package:equatable/equatable.dart';

import 'reservation.dart';
import 'reservation_filter.dart';

/// Reservas de un día evaluadas contra la hora actual: secciones de la línea
/// de tiempo, conteos por filtro e indicadores del resumen.
class DayAgenda extends Equatable {
  DayAgenda({
    required this.day,
    required this.now,
    required List<Reservation> reservations,
  }) : reservations = List.unmodifiable(
         [...reservations.where((r) => r.status != ReservationStatus.cancelled)]
           ..sort((a, b) => a.start.compareTo(b.start)),
       );

  final DateTime day;
  final DateTime now;

  /// Ordenadas por hora de inicio; las canceladas no se listan.
  final List<Reservation> reservations;

  bool get isToday =>
      day.year == now.year && day.month == now.month && day.day == now.day;

  bool matches(Reservation r, ReservationFilter filter) => switch (filter) {
    ReservationFilter.live =>
      !r.isVoid && r.timingAt(now) == ReservationTiming.live,
    ReservationFilter.upcoming =>
      !r.isVoid && r.timingAt(now) == ReservationTiming.upcoming,
    ReservationFilter.finished =>
      !r.isVoid &&
          (r.status == ReservationStatus.completed ||
              r.timingAt(now) == ReservationTiming.past),
    ReservationFilter.noShow => r.status == ReservationStatus.noShow,
  };

  int countFor(ReservationFilter filter) =>
      reservations.where((r) => matches(r, filter)).length;

  List<Reservation> filtered(ReservationFilter? filter) => filter == null
      ? reservations
      : reservations.where((r) => matches(r, filter)).toList();

  // --- Resumen del día ---

  int get totalCount => reservations.length;

  /// Dinero ya recibido (anticipos y pagos completos).
  int get collected => reservations.fold(0, (sum, r) => sum + r.amountPaid);

  /// Saldos pendientes de reservas que aún se juegan o se jugaron. Una
  /// reserva de varias canchas aporta su saldo una sola vez.
  int get pending {
    final groups = <String>{};
    var sum = 0;
    for (final r in reservations.where((r) => !r.isVoid)) {
      final group = r.group;
      if (group == null) {
        sum += r.balance;
      } else if (groups.add(group.id)) {
        sum += group.balance;
      }
    }
    return sum;
  }

  /// Proporción de reservas ya terminadas (0–1).
  double get finishedRatio => totalCount == 0
      ? 0
      : (totalCount -
                countFor(ReservationFilter.upcoming) -
                countFor(ReservationFilter.live)) /
            totalCount;

  double get collectedRatio =>
      collected + pending == 0 ? 0 : collected / (collected + pending);

  double get pendingRatio =>
      collected + pending == 0 ? 0 : pending / (collected + pending);

  @override
  List<Object?> get props => [day, now, reservations];
}
