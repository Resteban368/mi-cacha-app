import 'dart:typed_data';

import 'package:mi_cancha/core/domain/entities/sport.dart';
import 'package:mi_cancha/core/media/image_upload.dart';
import 'package:mi_cancha/features/business_courts/domain/entities/court.dart';
import 'package:mi_cancha/features/business_courts/domain/entities/court_rate.dart';
import 'package:mi_cancha/features/business_courts/domain/entities/court_schedule.dart';
import 'package:mi_cancha/features/business_courts/domain/entities/court_time.dart';
import 'package:mi_cancha/features/business_courts/domain/entities/week_day.dart';

const weekdays = {
  WeekDay.monday,
  WeekDay.tuesday,
  WeekDay.wednesday,
  WeekDay.thursday,
  WeekDay.friday,
};

/// El ejemplo de la documentación de la API ("Cancha Central Pádel 1").
final padelDraft = CourtDraft(
  name: 'Cancha Central Pádel 1',
  sport: Sport.padel,
  isCovered: true,
  basePricePerHour: 89900,
  schedules: [
    for (final day in WeekDay.values.take(4))
      DaySchedule.open(
        day,
        open: const CourtTime(6),
        close: const CourtTime(23),
      ),
    const DaySchedule.open(
      WeekDay.friday,
      open: CourtTime(6),
      close: CourtTime(2),
    ),
    const DaySchedule.open(
      WeekDay.saturday,
      open: CourtTime(7),
      close: CourtTime(2),
    ),
    const DaySchedule.closed(WeekDay.sunday),
  ],
  rates: const [
    CourtRate(
      name: 'Diurna L-V',
      pricePerHour: 60000,
      days: weekdays,
      start: CourtTime(6),
      end: CourtTime(18),
    ),
    CourtRate(
      name: 'Trasnocho Vie-Sáb',
      pricePerHour: 110000,
      // Desordenados a propósito: la API los recibe en orden de semana.
      days: {WeekDay.saturday, WeekDay.friday},
      start: CourtTime(23),
      end: CourtTime(2),
    ),
  ],
);

ImageUpload jpeg(String name) => ImageUpload(
  bytes: Uint8List.fromList([0xff, 0xd8, 0xff, 0xe0]),
  fileName: name,
);

/// Las 2 fotos que se piden al crear: la principal (obligatoria) y la
/// segunda (por defecto, superficie).
const createSlots = [CourtPhotoSlot.main, CourtPhotoSlot.surface];

final requiredPhotos = {
  for (final slot in createSlots) slot: jpeg('${slot.apiCode}.jpg'),
};

/// Como la API: solo la foto principal es obligatoria.
Court courtWith(Set<CourtPhotoSlot> photos) => Court(
  id: 'c1',
  name: 'Cancha Central Pádel 1',
  sport: Sport.padel,
  isActive: true,
  isComplete: photos.contains(CourtPhotoSlot.main),
  isBookable: photos.contains(CourtPhotoSlot.main),
  photos: {for (final slot in photos) slot: 'https://api.test/${slot.apiCode}'},
  missingPhotos: [
    if (!photos.contains(CourtPhotoSlot.main)) CourtPhotoSlot.main,
  ],
);

/// Cancha ya creada con el horario, precio y tarifas del ejemplo de la API.
final padelCourt = Court(
  id: 'c-padel',
  name: 'Cancha Central Pádel 1',
  sport: Sport.padel,
  isActive: true,
  isComplete: true,
  isBookable: true,
  isCovered: true,
  basePricePerHour: 89900,
  slotDuration: 90,
  schedules: padelDraft.schedules,
  rates: padelDraft.rates,
  photos: const {CourtPhotoSlot.main: 'https://api.test/main.jpg'},
);
