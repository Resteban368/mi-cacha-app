import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/push_exception.dart';
import '../../domain/entities/push_permission.dart';
import '../../domain/entities/push_snapshot.dart';
import '../../domain/usecases/push_usecases.dart';

enum BusinessNotificationsStatus {
  loading,
  unsupported,
  unavailable,
  denied,
  disabled,
  enabled,
  error,
}

final class BusinessNotificationsState extends Equatable {
  const BusinessNotificationsState({
    this.status = BusinessNotificationsStatus.loading,
    this.canPrompt = false,
  });

  final BusinessNotificationsStatus status;

  /// El navegador todavía no ha preguntado por el permiso: se puede pedir
  /// desde la campana.
  final bool canPrompt;

  @override
  List<Object?> get props => [status, canPrompt];
}

/// Aviso de nuevas reservas: activar o desactivar en este navegador.
class BusinessNotificationsCubit extends Cubit<BusinessNotificationsState> {
  BusinessNotificationsCubit({
    required GetPushStatus getStatus,
    required EnablePush enable,
    required DisablePush disable,
  }) : _getStatus = getStatus,
       _enable = enable,
       _disable = disable,
       super(const BusinessNotificationsState());

  final GetPushStatus _getStatus;
  final EnablePush _enable;
  final DisablePush _disable;

  Future<void> load() async {
    emit(const BusinessNotificationsState());
    try {
      final snapshot = await _getStatus(const NoParams());
      final status = _statusFrom(snapshot);
      emit(
        BusinessNotificationsState(
          status: status,
          canPrompt:
              status == BusinessNotificationsStatus.disabled &&
              snapshot.permission == PushPermission.defaultState,
        ),
      );
    } catch (error) {
      debugPrint('Avisos push (carga): $error');
      emit(
        const BusinessNotificationsState(
          status: BusinessNotificationsStatus.error,
        ),
      );
    }
  }

  /// Desde la campana: activa los avisos solo si el navegador nunca ha
  /// preguntado (no reactiva si el usuario los apagó ni insiste si los
  /// bloqueó). Debe llamarse en el toque para que se muestre el permiso.
  Future<void> promptIfNeeded() async {
    if (!state.canPrompt) return;
    await toggle(on: true);
  }

  /// Activa o desactiva. El permiso del navegador solo se pide al activar,
  /// siempre desde un toque del usuario.
  Future<void> toggle({required bool on}) async {
    emit(
      const BusinessNotificationsState(
        status: BusinessNotificationsStatus.loading,
      ),
    );
    try {
      if (on) {
        final permission = await _enable(const NoParams());
        emit(
          BusinessNotificationsState(
            status: switch (permission) {
              PushPermission.granted => BusinessNotificationsStatus.enabled,
              PushPermission.denied => BusinessNotificationsStatus.denied,
              PushPermission.defaultState =>
                BusinessNotificationsStatus.disabled,
            },
          ),
        );
      } else {
        await _disable(const NoParams());
        emit(
          const BusinessNotificationsState(
            status: BusinessNotificationsStatus.disabled,
          ),
        );
      }
    } on PushException catch (error) {
      debugPrint('Avisos push: $error');
      emit(
        BusinessNotificationsState(status: _statusFromFailure(error.failure)),
      );
    } catch (error) {
      debugPrint('Avisos push (activar/desactivar): $error');
      emit(
        const BusinessNotificationsState(
          status: BusinessNotificationsStatus.error,
        ),
      );
    }
  }

  static BusinessNotificationsStatus _statusFrom(PushSnapshot snapshot) {
    if (!snapshot.supported) return BusinessNotificationsStatus.unsupported;
    if (!snapshot.available) return BusinessNotificationsStatus.unavailable;
    if (snapshot.permission == PushPermission.denied) {
      return BusinessNotificationsStatus.denied;
    }
    return snapshot.enabled
        ? BusinessNotificationsStatus.enabled
        : BusinessNotificationsStatus.disabled;
  }

  static BusinessNotificationsStatus _statusFromFailure(PushFailure failure) =>
      switch (failure) {
        PushFailure.unsupported => BusinessNotificationsStatus.unsupported,
        PushFailure.unavailable => BusinessNotificationsStatus.unavailable,
        PushFailure.denied => BusinessNotificationsStatus.denied,
        PushFailure.network ||
        PushFailure.server => BusinessNotificationsStatus.error,
      };
}
