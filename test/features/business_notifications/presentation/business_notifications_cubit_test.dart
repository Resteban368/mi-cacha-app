import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/core/usecase/usecase.dart';
import 'package:mi_cancha/features/business_notifications/domain/entities/push_exception.dart';
import 'package:mi_cancha/features/business_notifications/domain/entities/push_permission.dart';
import 'package:mi_cancha/features/business_notifications/domain/entities/push_snapshot.dart';
import 'package:mi_cancha/features/business_notifications/domain/usecases/push_usecases.dart';
import 'package:mi_cancha/features/business_notifications/presentation/bloc/business_notifications_cubit.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetStatus extends Mock implements GetPushStatus {}

class _MockEnable extends Mock implements EnablePush {}

class _MockDisable extends Mock implements DisablePush {}

void main() {
  setUpAll(() => registerFallbackValue(const NoParams()));

  late _MockGetStatus getStatus;
  late _MockEnable enable;
  late _MockDisable disable;

  setUp(() {
    getStatus = _MockGetStatus();
    enable = _MockEnable();
    disable = _MockDisable();
  });

  BusinessNotificationsCubit build() => BusinessNotificationsCubit(
    getStatus: getStatus,
    enable: enable,
    disable: disable,
  );

  group('carga inicial', () {
    blocTest<BusinessNotificationsCubit, BusinessNotificationsState>(
      'navegador sin Web Push: no soportado',
      setUp: () => when(() => getStatus(any())).thenAnswer(
        (_) async => const PushSnapshot(
          supported: false,
          available: false,
          permission: PushPermission.defaultState,
          enabled: false,
        ),
      ),
      build: build,
      act: (cubit) => cubit.load(),
      expect: () => [
        const BusinessNotificationsState(),
        const BusinessNotificationsState(
          status: BusinessNotificationsStatus.unsupported,
        ),
      ],
    );

    blocTest<BusinessNotificationsCubit, BusinessNotificationsState>(
      'el servidor no tiene push (404): no disponible',
      setUp: () => when(() => getStatus(any())).thenAnswer(
        (_) async => const PushSnapshot(
          supported: true,
          available: false,
          permission: PushPermission.granted,
          enabled: false,
        ),
      ),
      build: build,
      act: (cubit) => cubit.load(),
      expect: () => [
        const BusinessNotificationsState(),
        const BusinessNotificationsState(
          status: BusinessNotificationsStatus.unavailable,
        ),
      ],
    );

    blocTest<BusinessNotificationsCubit, BusinessNotificationsState>(
      'permiso denegado en el navegador: denegado',
      setUp: () => when(() => getStatus(any())).thenAnswer(
        (_) async => const PushSnapshot(
          supported: true,
          available: true,
          permission: PushPermission.denied,
          enabled: false,
        ),
      ),
      build: build,
      act: (cubit) => cubit.load(),
      expect: () => [
        const BusinessNotificationsState(),
        const BusinessNotificationsState(
          status: BusinessNotificationsStatus.denied,
        ),
      ],
    );

    blocTest<BusinessNotificationsCubit, BusinessNotificationsState>(
      'suscripción activa: activado',
      setUp: () => when(() => getStatus(any())).thenAnswer(
        (_) async => const PushSnapshot(
          supported: true,
          available: true,
          permission: PushPermission.granted,
          enabled: true,
        ),
      ),
      build: build,
      act: (cubit) => cubit.load(),
      expect: () => [
        const BusinessNotificationsState(),
        const BusinessNotificationsState(
          status: BusinessNotificationsStatus.enabled,
        ),
      ],
    );

    blocTest<BusinessNotificationsCubit, BusinessNotificationsState>(
      'falla al consultar: error',
      setUp: () => when(
        () => getStatus(any()),
      ).thenThrow(const PushException(PushFailure.network)),
      build: build,
      act: (cubit) => cubit.load(),
      expect: () => [
        const BusinessNotificationsState(),
        const BusinessNotificationsState(
          status: BusinessNotificationsStatus.error,
        ),
      ],
    );
  });

  group('activar', () {
    blocTest<BusinessNotificationsCubit, BusinessNotificationsState>(
      'permiso concedido: activado',
      setUp: () => when(
        () => enable(any()),
      ).thenAnswer((_) async => PushPermission.granted),
      build: build,
      act: (cubit) => cubit.toggle(on: true),
      expect: () => [
        const BusinessNotificationsState(
          status: BusinessNotificationsStatus.loading,
        ),
        const BusinessNotificationsState(
          status: BusinessNotificationsStatus.enabled,
        ),
      ],
    );

    blocTest<BusinessNotificationsCubit, BusinessNotificationsState>(
      'el usuario cierra el permiso sin decidir: desactivado',
      setUp: () => when(
        () => enable(any()),
      ).thenAnswer((_) async => PushPermission.defaultState),
      build: build,
      act: (cubit) => cubit.toggle(on: true),
      expect: () => [
        const BusinessNotificationsState(
          status: BusinessNotificationsStatus.loading,
        ),
        const BusinessNotificationsState(
          status: BusinessNotificationsStatus.disabled,
        ),
      ],
    );

    blocTest<BusinessNotificationsCubit, BusinessNotificationsState>(
      'permiso denegado: denegado',
      setUp: () => when(
        () => enable(any()),
      ).thenAnswer((_) async => PushPermission.denied),
      build: build,
      act: (cubit) => cubit.toggle(on: true),
      expect: () => [
        const BusinessNotificationsState(
          status: BusinessNotificationsStatus.loading,
        ),
        const BusinessNotificationsState(
          status: BusinessNotificationsStatus.denied,
        ),
      ],
    );

    blocTest<BusinessNotificationsCubit, BusinessNotificationsState>(
      'sin red al guardar la suscripción: error',
      setUp: () => when(
        () => enable(any()),
      ).thenThrow(const PushException(PushFailure.network)),
      build: build,
      act: (cubit) => cubit.toggle(on: true),
      expect: () => [
        const BusinessNotificationsState(
          status: BusinessNotificationsStatus.loading,
        ),
        const BusinessNotificationsState(
          status: BusinessNotificationsStatus.error,
        ),
      ],
    );
  });

  group('desactivar', () {
    blocTest<BusinessNotificationsCubit, BusinessNotificationsState>(
      'quita la suscripción: desactivado',
      setUp: () => when(() => disable(any())).thenAnswer((_) async {}),
      build: build,
      act: (cubit) => cubit.toggle(on: false),
      expect: () => [
        const BusinessNotificationsState(
          status: BusinessNotificationsStatus.loading,
        ),
        const BusinessNotificationsState(
          status: BusinessNotificationsStatus.disabled,
        ),
      ],
      verify: (_) => verify(() => disable(any())).called(1),
    );

    blocTest<BusinessNotificationsCubit, BusinessNotificationsState>(
      'error de red al desactivar: error',
      setUp: () => when(
        () => disable(any()),
      ).thenThrow(const PushException(PushFailure.network)),
      build: build,
      act: (cubit) => cubit.toggle(on: false),
      expect: () => [
        const BusinessNotificationsState(
          status: BusinessNotificationsStatus.loading,
        ),
        const BusinessNotificationsState(
          status: BusinessNotificationsStatus.error,
        ),
      ],
    );

    blocTest<BusinessNotificationsCubit, BusinessNotificationsState>(
      'error inesperado: error',
      setUp: () => when(() => disable(any())).thenThrow(StateError('x')),
      build: build,
      act: (cubit) => cubit.toggle(on: false),
      expect: () => [
        const BusinessNotificationsState(
          status: BusinessNotificationsStatus.loading,
        ),
        const BusinessNotificationsState(
          status: BusinessNotificationsStatus.error,
        ),
      ],
    );
  });
}
