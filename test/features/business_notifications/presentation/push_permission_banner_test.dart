import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mi_cancha/features/business_notifications/presentation/bloc/business_notifications_cubit.dart';
import 'package:mi_cancha/features/business_notifications/presentation/widgets/push_permission_banner.dart';
import 'package:mocktail/mocktail.dart';

class _MockPushCubit extends MockCubit<BusinessNotificationsState>
    implements BusinessNotificationsCubit {}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  late _MockPushCubit cubit;

  setUp(() {
    cubit = _MockPushCubit();
    when(() => cubit.toggle(on: any(named: 'on'))).thenAnswer((_) async {});
    when(() => cubit.load()).thenAnswer((_) async {});
  });

  Future<void> pump(WidgetTester tester, BusinessNotificationsStatus status) {
    when(
      () => cubit.state,
    ).thenReturn(BusinessNotificationsState(status: status));
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider<BusinessNotificationsCubit>.value(
            value: cubit,
            child: const PushPermissionBanner(),
          ),
        ),
      ),
    );
  }

  testWidgets('desactivadas: "Activar" pide el permiso', (tester) async {
    await pump(tester, BusinessNotificationsStatus.disabled);
    await tester.tap(find.byKey(const Key('push-banner-action')));
    verify(() => cubit.toggle(on: true)).called(1);
  });

  testWidgets('bloqueadas: explica cómo permitirlas y vuelve a revisar', (
    tester,
  ) async {
    await pump(tester, BusinessNotificationsStatus.denied);
    expect(find.textContaining('bloqueadas'), findsOneWidget);
    await tester.tap(find.text('Ya las permití'));
    verify(() => cubit.load()).called(1);
  });

  testWidgets('sin soporte: indica cómo instalarla en iPhone', (tester) async {
    await pump(tester, BusinessNotificationsStatus.unsupported);
    expect(find.textContaining('Agregar a inicio'), findsOneWidget);
    expect(find.byKey(const Key('push-banner-action')), findsNothing);
  });

  testWidgets('activas: no muestra nada', (tester) async {
    await pump(tester, BusinessNotificationsStatus.enabled);
    expect(find.byType(Container), findsNothing);
  });
}
