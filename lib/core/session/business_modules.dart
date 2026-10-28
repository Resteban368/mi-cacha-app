import 'package:flutter/material.dart';

/// Módulos adicionales del negocio, que activa el super admin desde el
/// panel. Se actualiza con la cuenta (`/business/account`) al entrar al home.
class BusinessModules extends ChangeNotifier {
  var _sales = false;

  /// Ventas: productos, consumos en reservas, ventas sueltas y caja.
  bool get sales => _sales;

  void update({required bool sales}) {
    if (_sales == sales) return;
    _sales = sales;
    notifyListeners();
  }
}

/// Expone [BusinessModules] al árbol y reconstruye a quien lo consulte
/// cuando cambia.
class BusinessModulesScope extends InheritedNotifier<BusinessModules> {
  const BusinessModulesScope({
    super.key,
    required BusinessModules super.notifier,
    required super.child,
  });

  /// `true` si no hay [BusinessModulesScope] arriba (p. ej. en tests).
  static bool salesOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<BusinessModulesScope>()
          ?.notifier
          ?.sales ??
      true;
}
