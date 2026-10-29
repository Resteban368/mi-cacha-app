import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/notifications_bell_scope.dart';
import '../bloc/business_notifications_cubit.dart';
import '../bloc/notifications_inbox_cubit.dart';
import 'notifications_inbox_sheet.dart';

/// Envuelve el panel del negocio: mantiene la bandeja y le da a la campana
/// de todas las barras superiores su insignia y la acción de abrirla.
class NotificationsInboxHost extends StatefulWidget {
  const NotificationsInboxHost({
    super.key,
    required this.createCubit,
    required this.child,
    this.createPushCubit,
    this.notificationsChanged,
    this.refreshInterval = const Duration(minutes: 1),
  });

  final NotificationsInboxCubit Function() createCubit;
  final Widget child;

  /// Avisos push del navegador: al tocar la campana se pide el permiso si
  /// nunca se ha pedido. Sin él la campana solo abre la bandeja.
  final BusinessNotificationsCubit Function()? createPushCubit;

  /// Avisos que llegan con la app abierta (push).
  final Stream<void>? notificationsChanged;

  /// Cada cuánto se consulta el contador por si no hay push (`null`: nunca).
  final Duration? refreshInterval;

  @override
  State<NotificationsInboxHost> createState() => _NotificationsInboxHostState();
}

class _NotificationsInboxHostState extends State<NotificationsInboxHost> {
  late final NotificationsInboxCubit _cubit = widget.createCubit()
    ..refreshUnread();
  late final BusinessNotificationsCubit? _push = widget.createPushCubit?.call()
    ?..load();
  StreamSubscription<void>? _changes;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _changes = widget.notificationsChanged?.listen((_) => _cubit.refresh());
    final interval = widget.refreshInterval;
    if (interval != null) {
      _timer = Timer.periodic(interval, (_) => _cubit.refreshUnread());
    }
  }

  @override
  void dispose() {
    _changes?.cancel();
    _timer?.cancel();
    _cubit.close();
    _push?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<NotificationsInboxCubit, NotificationsInboxState>(
        buildWhen: (prev, curr) => prev.unread != curr.unread,
        builder: (context, state) => NotificationsBellScope(
          unread: state.unread,
          onOpen: () {
            // Primero el permiso: el navegador solo lo muestra en el toque.
            _push?.promptIfNeeded();
            showNotificationsInbox(context, _cubit, push: _push);
          },
          child: widget.child,
        ),
      ),
    );
  }
}
