import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/sport.dart';
import 'court_rate.dart';
import 'court_schedule.dart';

/// Posiciones de las fotos de una cancha. Solo la principal es obligatoria
/// para que la cancha reciba reservas (lo confirma la API con `isComplete`).
enum CourtPhotoSlot {
  main('MAIN', 'Foto 1 (Principal)', 'Vista general o ángulo principal'),
  surface('SURFACE', 'Foto 2 · Opcional', 'Superficie / Grama'),
  lighting('LIGHTING', 'Foto 3 · Opcional', 'Iluminación / Red'),
  extra1('EXTRA_1', 'Foto 4 · Opcional', 'Bancas / Entorno'),
  extra2('EXTRA_2', 'Foto 5 · Opcional', 'Otro ángulo');

  const CourtPhotoSlot(this.apiCode, this.label, this.hint);

  final String apiCode;
  final String label;
  final String hint;

  bool get isRequired => this == main;

  /// Posiciones que se ofrecen para la segunda foto al crear la cancha.
  static const secondOptions = [surface, lighting];

  static CourtPhotoSlot? fromApi(String code) {
    for (final slot in values) {
      if (slot.apiCode == code) return slot;
    }
    return null;
  }
}

/// Duraciones de turno que acepta la API, en minutos.
const courtSlotDurations = [30, 60, 90, 120];

/// Límites de medidas (metros) y formato que acepta la API.
const courtMinMeters = 1.0;
const courtMaxMeters = 200.0;
const courtMaxPlayersPerSide = 11;

/// Superficie elegida del catálogo.
class CourtSurfaceRef extends Equatable {
  const CourtSurfaceRef({required this.code, required this.name});

  final String code;
  final String name;

  @override
  List<Object?> get props => [code, name];
}

/// Superficie, medidas y formato. Todo opcional; las medidas van juntas.
class CourtSpecs extends Equatable {
  const CourtSpecs({
    this.surface,
    this.lengthMeters,
    this.widthMeters,
    this.playersPerSide,
  });

  static const empty = CourtSpecs();

  final CourtSurfaceRef? surface;
  final double? lengthMeters;
  final double? widthMeters;

  /// Jugadores por equipo (5 en fútbol 5, 2 en pádel).
  final int? playersPerSide;

  bool get hasDimensions => lengthMeters != null && widthMeters != null;

  /// "Grama sintética · 42 × 25 m · Fútbol 5"; vacío si no hay datos.
  String label(Sport? sport) {
    String meters(double v) =>
        v == v.roundToDouble() ? '${v.toInt()}' : '$v'.replaceAll('.', ',');
    final players = playersPerSide;
    return [
      ?surface?.name,
      if (hasDimensions) '${meters(lengthMeters!)} × ${meters(widthMeters!)} m',
      if (players != null)
        sport == Sport.futbol ? 'Fútbol $players' : '$players vs $players',
    ].join(' · ');
  }

  @override
  List<Object?> get props => [
    surface,
    lengthMeters,
    widthMeters,
    playersPerSide,
  ];
}

/// Datos para crear una cancha.
class CourtDraft extends Equatable {
  const CourtDraft({
    required this.name,
    required this.sport,
    required this.isCovered,
    required this.basePricePerHour,
    required this.schedules,
    this.isActive = true,
    this.slotDuration = 60,
    this.rates = const [],
    this.specs = CourtSpecs.empty,
  });

  static const maxNameLength = 60;

  final String name;
  final Sport sport;
  final bool isCovered;
  final bool isActive;

  /// Pesos por hora en los horarios que no cubre ninguna tarifa.
  final int basePricePerHour;
  final int slotDuration;

  /// Los 7 días, en orden de lunes a domingo.
  final List<DaySchedule> schedules;
  final List<CourtRate> rates;

  /// Superficie, medidas y formato; lo que falte se borra en la API.
  final CourtSpecs specs;

  @override
  List<Object?> get props => [
    name,
    sport,
    isCovered,
    isActive,
    basePricePerHour,
    slotDuration,
    schedules,
    rates,
    specs,
  ];
}

/// Cancha registrada en la API.
class Court extends Equatable {
  const Court({
    required this.id,
    required this.name,
    required this.sport,
    required this.isActive,
    required this.isComplete,
    required this.isBookable,
    this.isCovered = false,
    this.basePricePerHour = 0,
    this.slotDuration = 60,
    this.schedules = const [],
    this.rates = const [],
    this.photos = const {},
    this.missingPhotos = const [],
    this.specs = CourtSpecs.empty,
  });

  final String id;
  final String name;

  /// `null` si la API envía un deporte que la app aún no conoce.
  final Sport? sport;
  final bool isActive;

  /// Tiene las fotos obligatorias (según la API).
  final bool isComplete;

  /// Activa y completa: puede recibir reservas.
  final bool isBookable;
  final bool isCovered;
  final int basePricePerHour;
  final int slotDuration;

  /// Los 7 días, de lunes a domingo.
  final List<DaySchedule> schedules;
  final List<CourtRate> rates;

  /// URL pública (HTTPS) de cada foto subida.
  final Map<CourtPhotoSlot, String> photos;

  /// Superficie, medidas y formato.
  final CourtSpecs specs;

  /// Fotos obligatorias que aún faltan, según la API.
  final List<CourtPhotoSlot> missingPhotos;

  @override
  List<Object?> get props => [
    id,
    name,
    sport,
    isActive,
    isComplete,
    isBookable,
    isCovered,
    basePricePerHour,
    slotDuration,
    schedules,
    rates,
    photos,
    missingPhotos,
    specs,
  ];
}
