import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/sport.dart';

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

/// Cancha tal como llega en la disponibilidad por deporte.
class AvailabilityCourt extends Equatable {
  const AvailabilityCourt({
    required this.id,
    required this.name,
    required this.sport,
    required this.isCovered,
    required this.slotDuration,
    this.currency = 'COP',
    this.photoUrl,
  });

  final String id;
  final String name;
  final Sport sport;
  final bool isCovered;

  /// Minutos de cada turno.
  final int slotDuration;
  final String currency;

  /// Foto principal.
  final String? photoUrl;

  @override
  List<Object?> get props => [
    id,
    name,
    sport,
    isCovered,
    slotDuration,
    currency,
    photoUrl,
  ];
}

/// Turnos de una cancha en el día pedido.
class CourtSlots extends Equatable {
  CourtSlots({
    required this.court,
    required this.availableCount,
    required List<Slot> slots,
  }) : slots = List.unmodifiable(
         [...slots]..sort((a, b) => a.start.compareTo(b.start)),
       );

  final AvailabilityCourt court;

  /// Turnos libres del día (para la etiqueta "N libres").
  final int availableCount;

  /// Ordenados por hora; vacío si la cancha no abre ese día.
  final List<Slot> slots;

  bool get isClosed => slots.isEmpty;

  bool get hasAvailable => slots.any((s) => s.isAvailable);

  /// Índice del turno que empieza en [start] (-1 si no hay).
  int indexOf(DateTime start) => slots.indexWhere((s) => s.start == start);

  /// Turnos libres y seguidos desde [index] (0 si ese no está libre), con
  /// tope en [max]. "Seguidos" = cada uno empieza cuando termina el anterior.
  int consecutiveFrom(int index, int max) {
    if (index < 0 || index >= slots.length || !slots[index].isAvailable) {
      return 0;
    }
    var count = 1;
    while (count < max && index + count < slots.length) {
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
  List<Object?> get props => [court, availableCount, slots];
}

/// Un horario de la grilla "Cualquier cancha": une los turnos de todas las
/// canchas que empiezan a la misma hora.
class AnyCourtSlot extends Equatable {
  const AnyCourtSlot({
    required this.start,
    required this.end,
    required this.status,
    required this.price,
    required this.freeCourts,
    this.priceVaries = false,
  });

  final DateTime start;
  final DateTime end;

  /// Libre si al menos una cancha lo tiene libre; si no, ocupado (o pasado
  /// si ya terminó en todas).
  final SlotStatus status;

  /// Precio más bajo entre las canchas libres (o entre todas, si ninguna).
  final int price;

  /// Canchas con este turno libre.
  final int freeCourts;

  /// Las canchas libres cobran distinto este turno ("desde [price]").
  final bool priceVaries;

  bool get isAvailable => status == SlotStatus.available;

  @override
  List<Object?> get props => [
    start,
    end,
    status,
    price,
    freeCourts,
    priceVaries,
  ];
}

/// Turnos de un día de todas las canchas reservables de un deporte
/// (`GET /business/availability?date=&sport=`).
class SportAvailability extends Equatable {
  SportAvailability({
    required this.date,
    required this.sport,
    required this.maxSlots,
    required List<CourtSlots> courts,
  }) : courts = List.unmodifiable(courts);

  /// Día pedido (`YYYY-MM-DD`).
  final String date;
  final Sport sport;

  /// Turnos seguidos que se pueden reservar como máximo.
  final int maxSlots;

  /// En el orden de la API (por nombre), que es el que usa para asignar
  /// "cualquier cancha".
  final List<CourtSlots> courts;

  bool get isEmpty => courts.isEmpty;

  CourtSlots? courtById(String? id) =>
      courts.where((c) => c.court.id == id).firstOrNull;

  /// Horarios de todas las canchas, ordenados (para "Cualquier cancha").
  late final List<AnyCourtSlot> anyCourtSlots = _mergeSlots();

  List<AnyCourtSlot> _mergeSlots() {
    final byStart = <DateTime, List<Slot>>{};
    for (final court in courts) {
      for (final slot in court.slots) {
        (byStart[slot.start] ??= []).add(slot);
      }
    }
    final starts = byStart.keys.toList()..sort();
    return [
      for (final start in starts)
        () {
          final slots = byStart[start]!;
          final free = slots.where((s) => s.isAvailable).toList();
          final priced = free.isEmpty ? slots : free;
          return AnyCourtSlot(
            start: start,
            end: slots.first.end,
            status: free.isNotEmpty
                ? SlotStatus.available
                : slots.any((s) => s.status == SlotStatus.booked)
                ? SlotStatus.booked
                : SlotStatus.past,
            price: priced.map((s) => s.price).reduce((a, b) => a < b ? a : b),
            freeCourts: free.length,
            priceVaries: priced.map((s) => s.price).toSet().length > 1,
          );
        }(),
    ];
  }

  /// Turnos seguidos que se pueden pedir desde [start] en alguna cancha.
  int anyCourtReach(DateTime start) {
    var reach = 0;
    for (final court in courts) {
      final count = court.consecutiveFrom(court.indexOf(start), maxSlots);
      if (count > reach) reach = count;
    }
    return reach;
  }

  /// Turnos seguidos que se pueden pedir desde [start] en al menos [courts]
  /// canchas a la vez (0 si no hay tantas libres).
  int reachFor(DateTime start, int courts) {
    for (var count = maxSlots; count >= 1; count--) {
      if (courtsFreeAt(start, count).length >= courts) return count;
    }
    return 0;
  }

  /// Canchas con [count] turnos libres seguidos desde [start], en el orden
  /// en que la API las prueba.
  Iterable<CourtSlots> courtsFreeAt(DateTime start, int count) => courts.where(
    (c) => c.consecutiveFrom(c.indexOf(start), maxSlots) >= count,
  );

  /// La cancha que asignaría la API (la primera libre por nombre).
  CourtSlots? firstFreeCourt(DateTime start, int count) =>
      courtsFreeAt(start, count).firstOrNull;

  /// Valor más bajo posible de [count] turnos desde [start] con
  /// "Cualquier cancha" (`null` si ninguna los tiene libres).
  int? lowestPriceAt(DateTime start, int count) {
    int? lowest;
    for (final court in courtsFreeAt(start, count)) {
      final price = court.priceFor(court.indexOf(start), count);
      if (lowest == null || price < lowest) lowest = price;
    }
    return lowest;
  }

  @override
  List<Object?> get props => [date, sport, maxSlots, courts];
}
