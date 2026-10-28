import 'package:flutter/material.dart';

/// Módulos adicionales del negocio, que activa el super admin desde el
/// panel. Se actualiza con la cuenta (`/business/account`) al entrar al home.
class BusinessModules extends ChangeNotifier {
  var _sales = false;
  var _stockAlerts = 0;

  /// Ventas e inventario: productos, consumos en reservas, ventas sueltas,
  /// caja y stock.
  bool get sales => _sales;

  /// Productos agotados o con stock bajo (contador del menú Inventario).
  int get stockAlerts => _stockAlerts;

  void update({required bool sales}) {
    if (_sales == sales) return;
    _sales = sales;
    if (!sales) _stockAlerts = 0;
    notifyListeners();
  }

  void updateStockAlerts(int count) {
    if (_stockAlerts == count) return;
    _stockAlerts = count;
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

  /// `0` si no hay [BusinessModulesScope] arriba.
  static int stockAlertsOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<BusinessModulesScope>()
          ?.notifier
          ?.stockAlerts ??
      0;
}
