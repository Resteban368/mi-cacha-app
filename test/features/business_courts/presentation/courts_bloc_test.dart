import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/core/usecase/usecase.dart';
import 'package:mi_cancha/features/business_courts/domain/usecases/get_courts.dart';
import 'package:mi_cancha/features/business_courts/presentation/bloc/courts_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../court_fixtures.dart';

class _MockGetCourts extends Mock implements GetCourts {}

void main() {
  late _MockGetCourts getCourts;

  setUpAll(() => registerFallbackValue(const NoParams()));
  setUp(() {
    getCourts = _MockGetCourts();
    when(() => getCourts(any())).thenAnswer((_) async => [padelCourt]);
  });

  blocTest<CourtsBloc, CourtsState>(
    'carga las canchas',
    build: () => CourtsBloc(getCourts: getCourts),
    act: (bloc) => bloc.add(const CourtsRequested()),
    expect: () => [
      const CourtsState(),
      CourtsState(status: CourtsStatus.ready, courts: [padelCourt]),
    ],
  );

  blocTest<CourtsBloc, CourtsState>(
    'error al cargar',
    setUp: () => when(() => getCourts(any())).thenThrow(Exception()),
    build: () => CourtsBloc(getCourts: getCourts),
    act: (bloc) => bloc.add(const CourtsRequested()),
    skip: 1,
    expect: () => [const CourtsState(status: CourtsStatus.failure)],
  );

  test('actualizar sin cambios igual cierra el indicador', () async {
    final bloc = CourtsBloc(getCourts: getCourts)..add(const CourtsRequested());
    await bloc.stream.firstWhere((s) => s.status == CourtsStatus.ready);

    final done = Completer<void>();
    bloc.add(CourtsRequested(refresh: true, done: done));
    await expectLater(done.future, completes);
    expect(bloc.state.courts, [padelCourt]);
    await bloc.close();
  });
}
