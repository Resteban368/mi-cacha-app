/// Rutas de la app. Navegar siempre con `context.go` para que solo exista
/// la ruta actual en el stack (sin rutas repetidas).
abstract final class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const businessLogin = '/negocio/login';

  // Home del administrador de negocio (secciones del menú lateral).
  static const businessReservations = '/negocio/reservas';
  static const businessNewReservation = '/negocio/reservas/nueva';
  static const businessAllReservations = '/negocio/reservas/todas';

  /// Historial de un cliente en el listado de reservas.
  static String businessCustomerReservations(String customerId, String name) =>
      Uri(
        path: businessAllReservations,
        queryParameters: {'cliente': customerId, 'nombre': name},
      ).toString();

  /// Agenda en un día concreto (`?dia=YYYY-MM-DD`).
  static String businessReservationsOn(DateTime day) =>
      '$businessReservations?dia=${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';
  static const businessClients = '/negocio/clientes';
  static const businessDashboard = '/negocio/dashboard';
  static const businessPayments = '/negocio/pagos';
  static const businessNewPayment = '/negocio/pagos/nuevo';
  static const businessSales = '/negocio/ventas';
  static const businessProducts = '/negocio/ventas/productos';
  static const businessSuppliers = '/negocio/ventas/proveedores';
  static const businessCourts = '/negocio/canchas';
  static const businessNewCourt = '/negocio/canchas/nueva';
  static const businessEditCourt = '/negocio/canchas/editar/:id';

  static String businessEditCourtFor(String courtId) =>
      '/negocio/canchas/editar/${Uri.encodeComponent(courtId)}';

  /// Formulario de cancha nueva copiando de [courtId] ("Usar como base").
  static String businessNewCourtFrom(String courtId) =>
      '$businessNewCourt?copiar=${Uri.encodeQueryComponent(courtId)}';
  static const businessProfile = '/negocio/mi-negocio';
  static const businessSettings = '/negocio/ajustes';
  static const home = '/home';
}
