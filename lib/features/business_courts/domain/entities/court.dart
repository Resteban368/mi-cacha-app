import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/sport.dart';
import 'court_rate.dart';
import 'court_schedule.dart';

/// Posiciones de las fotos de una cancha. Las 3 primeras son obligatorias
/// para que la cancha reciba reservas.
enum CourtPhotoSlot {
  main('MAIN', 'Foto 1 (Principal)', 'Vista general o ángulo principal'),
  surface('SURFACE', 'Foto 2 · Requerida', 'Superficie / Suelo'),
  lighting('LIGHTING', 'Foto 3 · Requerida', 'Iluminación / Red'),
  extra1('EXTRA_1', 'Foto 4 · Opcional', 'Bancas / Entorno'),
  extra2('EXTRA_2', 'Foto 5 · Opcional', 'Otro ángulo');

  const CourtPhotoSlot(this.apiCode, this.label, this.hint);

  final String apiCode;
  final String label;
  final String hint;

  bool get isRequired => index < 3;

  static Iterable<CourtPhotoSlot> get required =>
      values.where((slot) => slot.isRequired);

  static CourtPhotoSlot? fromApi(String code) {
    for (final slot in values) {
      if (slot.apiCode == code) return slot;
    }
    return null;
  }
}

/// Duraciones de turno que acepta la API, en minutos.
const courtSlotDurations = [30, 60, 90, 120];

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
  });

  final String id;
  final String name;

  /// `null` si la API envía un deporte que la app aún no conoce.
  final Sport? sport;
  final bool isActive;

  /// Tiene las 3 fotos obligatorias.
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

  /// Fotos obligatorias que aún faltan.
  List<CourtPhotoSlot> get missingRequiredPhotos =>
      CourtPhotoSlot.required.where((s) => !photos.containsKey(s)).toList();

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
  ];
}
