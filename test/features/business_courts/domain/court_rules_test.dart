import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/core/domain/entities/sport.dart';
import 'package:mi_cancha/features/business_courts/domain/entities/court.dart';
import 'package:mi_cancha/features/business_courts/domain/entities/court_failure.dart';
import 'package:mi_cancha/features/business_courts/domain/entities/court_rate.dart';
import 'package:mi_cancha/features/business_courts/domain/entities/court_schedule.dart';
import 'package:mi_cancha/features/business_courts/domain/entities/court_time.dart';
import 'package:mi_cancha/features/business_courts/domain/entities/week_day.dart';
import 'package:mi_cancha/features/business_courts/domain/repositories/courts_repository.dart';
import 'package:mi_cancha/features/business_courts/domain/usecases/create_court.dart';
import 'package:mocktail/mocktail.dart';

import '../court_fixtures.dart';

class _MockRepository extends Mock implements CourtsRepository {}

CourtRate rate(String name, Set<WeekDay> days, int start, int end) => CourtRate(
  name: name,
  pricePerHour: 1000,
  days: days,
  start: CourtTime(start),
  end: CourtTime(end),
);

void main() {
  group('CourtTime', () {
    test('lee y escribe HH:mm', () {
      expect(CourtTime.tryParse('06:30'), const CourtTime(6, 30));
      expect(const CourtTime(6, 5).label, '06:05');
      expect(CourtTime.tryParse('24:00'), isNull);
      expect(CourtTime.tryParse('6:00'), isNull);
    });

    test('duración: cruza la medianoche y horas iguales = 24 h', () {
      expect(CourtTime.span(const CourtTime(18), const CourtTime(2)), 8 * 60);
      expect(CourtTime.span(const CourtTime(8), const CourtTime(8)), 24 * 60);
    });
  });

  group('tarifas que se cruzan (misma regla que la API)', () {
    test('franjas contiguas no se cruzan', () {
      expect(
        rate('Día', weekdays, 6, 18).overlaps(rate('Noche', weekdays, 18, 23)),
        isFalse,
      );
    });

    test('mismo día y horas superpuestas', () {
      expect(
        rate(
          'A',
          {WeekDay.monday},
          6,
          18,
        ).overlaps(rate('B', {WeekDay.monday}, 17, 20)),
        isTrue,
      );
    });

    test('la franja que pasa la medianoche invade el día siguiente', () {
      final trasnocho = rate('Trasnocho', {WeekDay.friday}, 23, 2);
      expect(trasnocho.overlaps(rate('Sáb', {WeekDay.saturday}, 1, 7)), isTrue);
      expect(
        trasnocho.overlaps(rate('Sáb', {WeekDay.saturday}, 7, 23)),
        isFalse,
      );
    });

    test('domingo de noche continúa el lunes', () {
      expect(
        rate(
          'Dom',
          {WeekDay.sunday},
          22,
          3,
        ).overlaps(rate('Lun', {WeekDay.monday}, 1, 5)),
        isTrue,
      );
    });
  });

  group('CreateCourt', () {
    late _MockRepository repository;
    setUp(() {
      repository = _MockRepository();
      registerFallbackValue(padelDraft);
    });

    test('el ejemplo de la API es válido', () {
      expect(CreateCourt.validate(padelDraft), isNull);
    });

    test('tarifas cruzadas: no llama a la API y explica cuáles', () async {
      final draft = CourtDraft(
        name: 'Cancha 1',
        sport: Sport.futbol,
        isCovered: false,
        basePricePerHour: 80000,
        schedules: DaySchedule.defaultWeek(),
        rates: [
          rate('Tarde', weekdays, 14, 19),
          rate('Noche', weekdays, 18, 23),
        ],
      );

      await expectLater(
        CreateCourt(repository)(draft),
        throwsA(
          isA<CourtException>()
              .having((e) => e.failure, 'tipo', CourtFailure.invalid)
              .having(
                (e) => e.message,
                'mensaje',
                'Las tarifas "Tarde" y "Noche" se cruzan.',
              ),
        ),
      );
      verifyNever(() => repository.create(any()));
    });

    test('sin días abiertos', () {
      final draft = CourtDraft(
        name: 'Cancha 1',
        sport: Sport.futbol,
        isCovered: false,
        basePricePerHour: 80000,
        schedules: [for (final d in WeekDay.values) DaySchedule.closed(d)],
      );
      expect(
        CreateCourt.validate(draft),
        'Abre la cancha al menos un día de la semana.',
      );
    });
  });
}
