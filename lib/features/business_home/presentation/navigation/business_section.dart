import 'package:flutter/material.dart';

import '../../../../core/router/app_routes.dart';

/// Grupos del menú lateral del administrador de negocio.
enum BusinessSectionGroup {
  operacion('Operación'),
  gestion('Gestión'),
  cuenta('Cuenta');

  const BusinessSectionGroup(this.label);

  final String label;
}

/// Secciones del home de negocio. El orden define el orden en el menú;
/// para agregar una opción basta con sumarla aquí y registrar su ruta.
enum BusinessSection {
  reservas(
    group: BusinessSectionGroup.operacion,
    path: AppRoutes.businessReservations,
    label: 'Reservas',
    icon: Icons.calendar_month_outlined,
    activeIcon: Icons.calendar_month,
    fullWidth: true,
  ),
  clientes(
    group: BusinessSectionGroup.operacion,
    path: AppRoutes.businessClients,
    label: 'Clientes',
    icon: Icons.group_outlined,
    activeIcon: Icons.group,
    fullWidth: true,
  ),
  dashboard(
    group: BusinessSectionGroup.operacion,
    path: AppRoutes.businessDashboard,
    label: 'Dashboard',
    icon: Icons.insights_outlined,
    activeIcon: Icons.insights,
    fullWidth: true,
  ),
  pagos(
    group: BusinessSectionGroup.gestion,
    path: AppRoutes.businessPayments,
    label: 'Pagos',
    icon: Icons.account_balance_wallet_outlined,
    activeIcon: Icons.account_balance_wallet,
    fullWidth: true,
  ),
  ventas(
    group: BusinessSectionGroup.gestion,
    path: AppRoutes.businessSales,
    label: 'Ventas',
    icon: Icons.point_of_sale_outlined,
    activeIcon: Icons.point_of_sale,
    fullWidth: true,
  ),
  inventario(
    group: BusinessSectionGroup.gestion,
    path: AppRoutes.businessInventory,
    label: 'Inventario',
    icon: Icons.inventory_2_outlined,
    activeIcon: Icons.inventory_2,
    fullWidth: true,
  ),
  canchas(
    group: BusinessSectionGroup.gestion,
    path: AppRoutes.businessCourts,
    label: 'Canchas',
    icon: Icons.stadium_outlined,
    activeIcon: Icons.stadium,
    fullWidth: true,
  ),
  negocio(
    group: BusinessSectionGroup.gestion,
    path: AppRoutes.businessProfile,
    label: 'Mi negocio',
    icon: Icons.storefront_outlined,
    activeIcon: Icons.storefront,
    fullWidth: true,
  ),
  ajustes(
    group: BusinessSectionGroup.cuenta,
    path: AppRoutes.businessSettings,
    label: 'Mi cuenta',
    icon: Icons.manage_accounts_outlined,
    activeIcon: Icons.manage_accounts,
    fullWidth: true,
  );

  const BusinessSection({
    required this.group,
    required this.path,
    required this.label,
    required this.icon,
    required this.activeIcon,
    this.fullWidth = false,
  });

  final BusinessSectionGroup group;
  final String path;
  final String label;
  final IconData icon;
  final IconData activeIcon;

  /// Si la sección arma su propio layout responsivo y ocupa todo el ancho
  /// disponible; si no, el shell la centra en una columna de ancho móvil.
  final bool fullWidth;

  /// Sección correspondiente a la URL actual (por defecto, Reservas).
  static BusinessSection fromLocation(String location) => values.firstWhere(
    (section) => location.startsWith(section.path),
    orElse: () => reservas,
  );
}
