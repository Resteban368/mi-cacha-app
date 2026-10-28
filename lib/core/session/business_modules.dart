import 'package:flutter/material.dart';

/// Módulos adicionales del negocio, que activa el super admin desde el
/// panel. Se actualiza con la cuenta (`/business/account`) al entrar al home.
class BusinessModules extends ChangeNotifier {
  var _sales = false;
  var _inventory = false;

  /// Ventas: productos, consumos en reservas, ventas sueltas y caja.
  bool get sales => _sales;

  /// Inventario: stock de productos (requiere Ventas).
  bool get inventory => _inventory;

  void update({required bool sales, bool inventory = false}) {
    if (_sales == sales && _inventory == inventory) return;
    _sales = sales;
    _inventory = inventory;
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

  /// Como [inventoryOf] pero sin suscribirse (para callbacks).
  static bool readInventory(BuildContext context) =>
      context
          .getInheritedWidgetOfExactType<BusinessModulesScope>()
          ?.notifier
          ?.inventory ??
      false;

  /// `false` si no hay [BusinessModulesScope] arriba.
  static bool inventoryOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<BusinessModulesScope>()
          ?.notifier
          ?.inventory ??
      false;

  /// `true` si no hay [BusinessModulesScope] arriba (p. ej. en tests).
  static bool salesOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<BusinessModulesScope>()
          ?.notifier
          ?.sales ??
      true;
}
