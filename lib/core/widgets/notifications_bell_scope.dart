import 'package:flutter/widgets.dart';

/// Insignia y acción de la campana de todas las barras superiores del panel.
/// Sin este scope (p. ej. en tests), la campana no hace nada.
class NotificationsBellScope extends InheritedWidget {
  const NotificationsBellScope({
    super.key,
    required this.unread,
    required this.onOpen,
    required super.child,
  });

  /// Notificaciones sin leer.
  final int unread;

  /// Abre la bandeja.
  final VoidCallback onOpen;

  static NotificationsBellScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<NotificationsBellScope>();

  @override
  bool updateShouldNotify(NotificationsBellScope oldWidget) =>
      unread != oldWidget.unread;
}
