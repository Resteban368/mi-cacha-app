import 'package:equatable/equatable.dart';

enum SlotStatus {
  /// Se puede elegir (incluye el turno en curso).
  available('AVAILABLE'),

  /// Ocupado por otra reserva.
  booked('BOOKED'),

  /// Ya terminó.
  past('PAST');

  const SlotStatus(this.apiCode);

  final String apiCode;

  static SlotStatus fromApi(String? code) => switch (code) {
    'AVAILABLE' => available,
    'BOOKED' => booked,
    _ => past,
  };
}

/// Turno de una cancha en un día.
class Slot extends Equatable {
  const Slot({
    required this.startIso,
    required this.start,
    required this.end,
    required this.status,
    required this.price,
  });

  /// Inicio tal como lo envió la API: se reenvía igual al reservar.
  final String startIso;

  /// Hora local (para mostrar).
  final DateTime start;
  final DateTime end;
  final SlotStatus status;

  /// Valor del turno según las tarifas (COP, sin centavos en la app).
  final int price;

  bool get isAvailable => status == SlotStatus.available;

  @override
  List<Object?> get props => [startIso, start, end, status, price];
}

/// Turnos de una cancha en un día (`GET …/availability?date=`).
class Availability extends Equatable {
  Availability({
    required this.date,
    required this.courtId,
    required this.slotDuration,
    required this.currency,
    required this.maxSlots,
    required List<Slot> slots,
  }) : slots = List.unmodifiable(
         [...slots]..sort((a, b) => a.start.compareTo(b.start)),
       );

  /// Día pedido (`YYYY-MM-DD`).
  final String date;
  final String courtId;

  /// Minutos de cada turno.
  final int slotDuration;
  final String currency;

  /// Turnos seguidos que se pueden reservar como máximo.
  final int maxSlots;

  /// Ordenados por hora; vacío si la cancha no abre ese día.
  final List<Slot> slots;

  bool get isClosed => slots.isEmpty;

  bool get hasAvailable => slots.any((s) => s.isAvailable);

  /// Turnos libres y seguidos desde [index] (0 si ese no está libre),
  /// con tope en [maxSlots]. "Seguidos" = cada uno empieza cuando termina
  /// el anterior.
  int consecutiveFrom(int index) {
    if (index < 0 || index >= slots.length || !slots[index].isAvailable) {
      return 0;
    }
    var count = 1;
    while (count < maxSlots && index + count < slots.length) {
      final previous = slots[index + count - 1];
      final next = slots[index + count];
      if (!next.isAvailable || next.start != previous.end) break;
      count++;
    }
    return count;
  }

  /// Suma de los precios de [count] turnos desde [index].
  int priceFor(int index, int count) =>
      slots.skip(index).take(count).fold(0, (sum, slot) => sum + slot.price);

  @override
  List<Object?> get props => [
    date,
    courtId,
    slotDuration,
    currency,
    maxSlots,
    slots,
  ];
}
