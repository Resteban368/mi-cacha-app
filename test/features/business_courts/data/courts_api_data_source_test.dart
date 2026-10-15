import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/core/domain/entities/sport.dart';
import 'package:mi_cancha/features/business_courts/data/datasources/courts_api_data_source.dart';
import 'package:mi_cancha/features/business_courts/data/repositories/courts_repository_impl.dart';
import 'package:mi_cancha/features/business_courts/domain/entities/court.dart';
import 'package:mi_cancha/features/business_courts/domain/entities/court_failure.dart';
import 'package:mi_cancha/features/business_courts/domain/entities/court_schedule.dart';
import 'package:mi_cancha/features/business_courts/domain/entities/court_time.dart';
import 'package:mi_cancha/features/business_courts/domain/entities/week_day.dart';

import '../../../helpers/api_dio.dart';
import '../../../helpers/fake_http_adapter.dart';
import '../court_fixtures.dart';

void main() {
  // Respuesta de la API (CourtDto) tras subir la foto principal.
  final courtJson = {
    'id': 'c1',
    'name': 'Cancha Central Pádel 1',
    'sport': 'PADEL',
    'isCovered': true,
    'isActive': true,
    'isComplete': false,
    'isBookable': false,
    'missingPhotos': ['SURFACE', 'LIGHTING'],
    'currency': 'COP',
    'basePricePerHour': 89900,
    'slotDuration': 60,
    'schedules': <Object>[],
    'rates': <Object>[],
    'photos': [
      {
        'slot': 'MAIN',
        'url': 'http://mi-cancha-api.vercel.app/api/v1/images/courts/p1',
      },
      {'slot': 'NUEVA_POSICION', 'url': 'https://x'},
    ],
  };

  late FakeHttpAdapter adapter;
  late CourtsApiDataSource source;

  setUp(() {
    adapter = FakeHttpAdapter((_) => (201, courtJson));
    source = CourtsApiDataSource(apiDio(adapter));
  });

  Map<String, dynamic> body(RequestOptions request) =>
      (request.data is String
              ? jsonDecode(request.data as String)
              : request.data)
          as Map<String, dynamic>;

  test('crea con el formato de la API', () async {
    await source.create(padelDraft);

    final request = adapter.requests.single;
    expect(request.method, 'POST');
    expect(request.path, '/business/courts');
    final json = body(request);
    expect(json['name'], 'Cancha Central Pádel 1');
    expect(json['sport'], 'PADEL');
    expect(json['isCovered'], isTrue);
    expect(json['isActive'], isTrue);
    expect(json['currency'], 'COP');
    expect(json['basePricePerHour'], 89900);
    expect(json['slotDuration'], 60);

    final schedules = json['schedules'] as List<dynamic>;
    expect(schedules, hasLength(7));
    expect(schedules[4], {
      'dayOfWeek': 'FRIDAY',
      'isOpen': true,
      'openTime': '06:00',
      'closeTime': '02:00',
    });
    // Día cerrado: sin horas.
    expect(schedules[6], {'dayOfWeek': 'SUNDAY', 'isOpen': false});

    final rates = json['rates'] as List<dynamic>;
    expect(rates[1], {
      'name': 'Trasnocho Vie-Sáb',
      'pricePerHour': 110000,
      'days': ['FRIDAY', 'SATURDAY'],
      'startTime': '23:00',
      'endTime': '02:00',
    });
  });

  test('lee la cancha: fotos por posición, por HTTPS', () async {
    final court = await source.create(padelDraft);

    expect(court.id, 'c1');
    expect(court.sport, Sport.padel);
    expect(court.isBookable, isFalse);
    expect(court.photos, {
      CourtPhotoSlot.main:
          'https://mi-cancha-api.vercel.app/api/v1/images/courts/p1',
    });
  });

  test('sube cada foto como multipart en su posición', () async {
    await source.uploadPhoto('c1', CourtPhotoSlot.surface, jpeg('suelo.jpg'));

    final request = adapter.requests.single;
    expect(request.method, 'PUT');
    expect(request.path, '/business/courts/c1/photos/SURFACE');
    final file = (request.data as FormData).files.single;
    expect(file.key, 'image');
    expect(file.value.filename, 'suelo.jpg');
    expect(file.value.contentType.toString(), 'image/jpeg');
  });

  group('errores de la API', () {
    Future<CourtException> failWith(int status, Object body) async {
      adapter.handler = (_) => (status, body);
      final repository = CourtsRepositoryImpl(source);
      try {
        await repository.create(padelDraft);
      } on CourtException catch (error) {
        return error;
      }
      fail('debía lanzar CourtException');
    }

    test('403 límite del plan, con el mensaje del backend', () async {
      final error = await failWith(403, {
        'statusCode': 403,
        'code': 'PLAN_LIMIT_REACHED',
        'message': 'Tu plan Básico permite 3 cancha(s) activa(s)',
      });
      expect(error.failure, CourtFailure.planLimit);
      expect(error.message, 'Tu plan Básico permite 3 cancha(s) activa(s)');
    });

    test('409 nombre repetido', () async {
      final error = await failWith(409, {
        'statusCode': 409,
        'message': 'Ya existe un registro con esos datos',
      });
      expect(error.failure, CourtFailure.duplicateName);
    });

    test('400 con varios mensajes', () async {
      final error = await failWith(400, {
        'statusCode': 400,
        'message': [
          'Falta el horario de: domingo',
          'Las tarifas "A" y "B" se cruzan',
        ],
      });
      expect(error.failure, CourtFailure.invalid);
      expect(
        error.message,
        'Falta el horario de: domingo\nLas tarifas "A" y "B" se cruzan',
      );
    });

    test('sin conexión', () async {
      adapter.handler = offline;
      await expectLater(
        CourtsRepositoryImpl(source).create(padelDraft),
        throwsA(
          isA<CourtException>().having(
            (e) => e.failure,
            'tipo',
            CourtFailure.network,
          ),
        ),
      );
    });
  });

  test('lista las canchas con horario y tarifas', () async {
    adapter.handler = (_) => (
      200,
      [
        {
          ...courtJson,
          'basePricePerHour': 89900,
          'slotDuration': 90,
          'schedules': [
            {
              'dayOfWeek': 'FRIDAY',
              'isOpen': true,
              'openTime': '06:00',
              'closeTime': '02:00',
            },
            {'dayOfWeek': 'SUNDAY', 'isOpen': false, 'openTime': null},
          ],
          'rates': [
            {
              'name': 'Trasnocho',
              'pricePerHour': 110000.5,
              'days': ['FRIDAY', 'SATURDAY'],
              'startTime': '23:00',
              'endTime': '02:00',
            },
          ],
        },
      ],
    );

    final courts = await source.getCourts();

    expect(adapter.requests.single.path, '/business/courts');
    final court = courts.single;
    expect(court.slotDuration, 90);
    expect(court.schedules, const [
      DaySchedule.open(WeekDay.friday, open: CourtTime(6), close: CourtTime(2)),
      DaySchedule.closed(WeekDay.sunday),
    ]);
    final rate = court.rates.single;
    expect(rate.pricePerHour, 110001); // COP sin centavos
    expect(rate.days, {WeekDay.friday, WeekDay.saturday});
    expect(rate.crossesMidnight, isTrue);
  });

  test('edita con PATCH y quita fotos con DELETE', () async {
    adapter.handler = (_) => (200, courtJson);
    await source.update('c1', padelDraft);
    await source.removePhoto('c1', CourtPhotoSlot.lighting);

    final (patch, delete) = (adapter.requests[0], adapter.requests[1]);
    expect(patch.method, 'PATCH');
    expect(patch.path, '/business/courts/c1');
    expect(body(patch)['schedules'], hasLength(7));
    expect(delete.method, 'DELETE');
    expect(delete.path, '/business/courts/c1/photos/LIGHTING');
  });
}
