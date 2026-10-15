import 'package:flutter/material.dart';

/// Si el negocio puede crear, editar o borrar. Sin plan activo la API solo
/// permite consultar (403 `SUBSCRIPTION_INACTIVE`) y la app pasa a modo
/// solo lectura: deshabilita las acciones de escritura.
class WriteAccess extends ChangeNotifier {
  var _canWrite = true;

  bool get canWrite => _canWrite;

  void update({required bool canWrite}) {
    if (_canWrite == canWrite) return;
    _canWrite = canWrite;
    notifyListeners();
  }
}

/// Expone [WriteAccess] al árbol y reconstruye a quien lo consulte cuando
/// cambia.
class WriteAccessScope extends InheritedNotifier<WriteAccess> {
  const WriteAccessScope({
    super.key,
    required WriteAccess super.notifier,
    required super.child,
  });

  /// `true` si no hay [WriteAccessScope] arriba (p. ej. en tests).
  static bool canWrite(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<WriteAccessScope>()
          ?.notifier
          ?.canWrite ??
      true;
}

/// `true` si se puede escribir; si no, avisa que el plan no está activo.
/// Para acciones puntuales (subir una foto, guardar, cancelar…).
bool ensureCanWrite(BuildContext context) {
  if (WriteAccessScope.canWrite(context)) return true;
  final messenger = ScaffoldMessenger.maybeOf(context);
  messenger
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      const SnackBar(
        content: Text(
          'Tu plan no está activo: solo puedes consultar información.',
        ),
      ),
    );
  return false;
}
