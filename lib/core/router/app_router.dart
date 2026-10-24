import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/usecases/sign_out.dart';
import '../../features/auth/presentation/bloc/business_login/business_login_bloc.dart';
import '../../features/auth/presentation/bloc/login_bloc.dart';
import '../../features/auth/presentation/pages/business_login_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/business_account/domain/usecases/get_business_account.dart';
import '../../features/business_notifications/domain/repositories/push_repository.dart';
import '../../features/business_notifications/presentation/bloc/business_notifications_cubit.dart';
import '../../features/business_notifications/presentation/bloc/notifications_inbox_cubit.dart';
import '../../features/business_notifications/presentation/widgets/notifications_inbox_host.dart';
import '../../features/business_account/presentation/bloc/business_account_bloc.dart';
import '../../features/business_account/presentation/bloc/change_password_cubit.dart';
import '../../features/business_account/presentation/pages/business_account_page.dart';
import '../../features/business_clients/presentation/bloc/business_clients_bloc.dart';
import '../../features/business_clients/presentation/bloc/business_clients_event.dart';
import '../../features/business_clients/presentation/pages/business_clients_page.dart';
import '../../features/business_reservations/domain/entities/customer.dart';
import '../../features/business_reservations/domain/entities/reservation.dart';
import '../../features/business_courts/presentation/bloc/courts_bloc.dart';
import '../../features/business_courts/presentation/bloc/court_form_bloc.dart';
import '../../features/business_courts/presentation/pages/business_courts_page.dart';
import '../../features/business_courts/presentation/pages/court_form_page.dart';
import '../../features/business_home/presentation/pages/business_home_shell.dart';
import '../../features/business_dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../features/business_dashboard/presentation/pages/business_dashboard_page.dart';
import '../../features/business_home/presentation/widgets/read_only_banner.dart';
import '../../features/business_payments/presentation/bloc/new_payment/new_payment_bloc.dart';
import '../../features/business_payments/presentation/bloc/payments/payments_bloc.dart';
import '../../features/business_payments/presentation/pages/new_payment_page.dart';
import '../../features/business_payments/presentation/pages/payments_page.dart';
import '../../features/business_profile/presentation/bloc/business_profile_bloc.dart';
import '../../features/business_profile/presentation/pages/business_profile_page.dart';
import '../../features/business_reservations/presentation/bloc/business_reservations_bloc.dart';
import '../../features/business_reservations/presentation/bloc/new_reservation/new_reservation_bloc.dart';
import '../../features/business_reservations/domain/entities/reservation_query.dart';
import '../../features/business_reservations/presentation/bloc/reservation_detail/reservation_detail_cubit.dart';
import '../../features/business_reservations/presentation/bloc/reservations_list/reservations_list_bloc.dart';
import '../../features/business_reservations/presentation/pages/business_reservations_list_page.dart';
import '../../features/business_reservations/presentation/pages/business_new_reservation_page.dart';
import '../../features/business_reservations/presentation/pages/business_reservations_page.dart';
import '../../features/onboarding/presentation/bloc/onboarding_bloc.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/placeholder/placeholder_page.dart';
import '../../features/splash/presentation/bloc/splash_bloc.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../config/feature_flags.dart';
import '../di/injection_container.dart';
import '../location/device_location.dart';
import '../media/photo_picker.dart';
import '../session/session_manager.dart';
import '../session/write_access.dart';
import '../usecase/usecase.dart';
import 'app_routes.dart';

GoRouter buildAppRouter(SessionManager session) {
  // Navegador raíz: permite abrir pantallas a pantalla completa por encima
  // del menú lateral (p. ej. "Nuevo pago").
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  return _buildRouter(rootNavigatorKey, session);
}

/// Protege el panel del negocio: sin sesión de administrador (o cuando la
/// API respondió 401) se vuelve al login de negocio; con sesión, el login
/// lleva directo al panel.
Future<String?> businessGuard(SessionManager session, String path) async {
  final isBusinessArea = path.startsWith('/negocio/');
  if (!isBusinessArea) return null;
  await session.restore();
  final isLogin = path == AppRoutes.businessLogin;
  if (session.isBusinessAdmin) {
    return isLogin ? AppRoutes.businessReservations : null;
  }
  return isLogin ? null : AppRoutes.businessLogin;
}

/// Mientras el acceso de jugadores esté oculto, sus pantallas llevan al
/// login de negocio (incluye el final del onboarding y el splash).
String? playerAccessRedirect(
  String path, {
  bool enabled = FeatureFlags.playerAccess,
}) {
  if (enabled) return null;
  final isPlayerRoute = path == AppRoutes.login || path == AppRoutes.home;
  return isPlayerRoute ? AppRoutes.businessLogin : null;
}

Future<void> _signOut() => sl<SignOut>()(const NoParams());

/// `?dia=2026-10-15` → día local; `null` si falta o no es válido.
DateTime? _dayParam(String? value) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value ?? '');
  if (match == null) return null;
  return DateTime(
    int.parse(match[1]!),
    int.parse(match[2]!),
    int.parse(match[3]!),
  );
}

/// Solo lectura si no hay suscripción o no está activa.
Future<bool> _loadCanWrite() async {
  final account = await sl<GetBusinessAccount>()(const NoParams());
  return account.subscription?.isActive ?? false;
}

GoRouter _buildRouter(
  GlobalKey<NavigatorState> rootNavigatorKey,
  SessionManager session,
) => GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: AppRoutes.splash,
  // Re-evalúa la guarda cuando la sesión cambia (login, logout, 401).
  refreshListenable: session,
  redirect: (_, state) async =>
      playerAccessRedirect(state.uri.path) ??
      await businessGuard(session, state.uri.path),
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (_, _) => BlocProvider(
        create: (_) => sl<SplashBloc>()..add(const SplashStarted()),
        child: const SplashPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (_, _) => BlocProvider(
        create: (_) => sl<OnboardingBloc>(),
        child: const OnboardingPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (_, _) => BlocProvider(
        create: (_) => sl<LoginBloc>(),
        child: const LoginPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.businessLogin,
      builder: (_, _) => BlocProvider(
        create: (_) => sl<BusinessLoginBloc>(),
        child: BusinessLoginPage(sessionExpired: session.consumeExpired()),
      ),
    ),
    // Home de negocio: ShellRoute (no stateful) para que solo la sección
    // visible esté montada; se cambia de sección con `go` (menú lateral).
    ShellRoute(
      builder: (_, state, child) => WriteAccessRefresher(
        writeAccess: sl<WriteAccess>(),
        loadCanWrite: _loadCanWrite,
        child: NotificationsInboxHost(
          createCubit: () => sl<NotificationsInboxCubit>(),
          notificationsChanged: sl<PushRepository>().notificationsChanged,
          child: BusinessHomeShell(
            location: state.uri.path,
            onSignOut: _signOut,
            child: child,
          ),
        ),
      ),
      routes: [
        GoRoute(
          path: AppRoutes.businessReservations,
          pageBuilder: (_, state) => NoTransitionPage(
            key: state.pageKey,
            child: BlocProvider(
              create: (_) => sl<BusinessReservationsBloc>()
                ..add(
                  ReservationsRequested(
                    _dayParam(state.uri.queryParameters['dia']),
                  ),
                ),
              child: BusinessReservationsPage(
                createDetailCubit: () => sl<ReservationDetailCubit>(),
                newReservations: sl<PushRepository>().newReservations,
              ),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.businessAllReservations,
          pageBuilder: (_, state) {
            final customerId = state.uri.queryParameters['cliente'];
            return NoTransitionPage(
              key: ValueKey(state.uri.toString()),
              child: BlocProvider(
                create: (_) => sl<ReservationsListBloc>()
                  ..add(
                    ReservationsListStarted(
                      ReservationQuery(customerId: customerId),
                    ),
                  ),
                child: BusinessReservationsListPage(
                  createDetailCubit: () => sl<ReservationDetailCubit>(),
                  customerName: state.uri.queryParameters['nombre'],
                ),
              ),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.businessNewReservation,
          pageBuilder: (_, state) {
            final customer = state.extra is Customer
                ? state.extra as Customer
                : null;
            return NoTransitionPage(
              // La URL completa: "Nueva reserva" desde el resumen (con otro
              // `?refresh=`) empieza con el formulario limpio.
              key: ValueKey(state.uri.toString()),
              child: BlocProvider(
                create: (_) => sl<NewReservationBloc>()
                  ..add(
                    NewReservationStarted(
                      courtId: state.uri.queryParameters['cancha'],
                      day: _dayParam(state.uri.queryParameters['dia']),
                      customer: customer,
                    ),
                  ),
                child: const BusinessNewReservationPage(),
              ),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.businessClients,
          pageBuilder: (_, state) => NoTransitionPage(
            key: state.pageKey,
            child: BlocProvider(
              create: (_) =>
                  sl<BusinessClientsBloc>()
                    ..add(const BusinessClientsStarted()),
              child: const BusinessClientsPage(),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.businessDashboard,
          pageBuilder: (_, state) => NoTransitionPage(
            key: state.pageKey,
            child: BlocProvider(
              create: (_) => sl<DashboardBloc>()..add(const DashboardStarted()),
              child: const BusinessDashboardPage(),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.businessPayments,
          pageBuilder: (_, state) => NoTransitionPage(
            key: state.pageKey,
            child: BlocProvider(
              create: (_) => sl<PaymentsBloc>()..add(const PaymentsRequested()),
              child: const PaymentsPage(),
            ),
          ),
          routes: [
            GoRoute(
              path: 'nuevo',
              parentNavigatorKey: rootNavigatorKey,
              builder: (_, state) => BlocProvider(
                create: (_) => sl<NewPaymentBloc>(),
                child: NewPaymentPage(
                  initialReservation: state.extra as Reservation?,
                ),
              ),
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.businessCourts,
          pageBuilder: (_, state) => NoTransitionPage(
            key: state.pageKey,
            child: BlocProvider(
              create: (_) => sl<CourtsBloc>()..add(const CourtsRequested()),
              child: const BusinessCourtsPage(),
            ),
          ),
        ),
        // Rutas hermanas (no hijas) de la lista: al volver, la lista se crea
        // de nuevo y muestra los cambios.
        GoRoute(
          path: AppRoutes.businessNewCourt,
          pageBuilder: (_, state) => NoTransitionPage(
            key: state.pageKey,
            child: BlocProvider(
              create: (_) => sl<CourtFormBloc>()..add(const CourtFormStarted()),
              child: CourtFormPage(
                photoPicker: sl<PhotoPicker>(),
                copyFromCourtId: state.uri.queryParameters['copiar'],
              ),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.businessEditCourt,
          pageBuilder: (_, state) {
            final courtId = state.pathParameters['id']!;
            return NoTransitionPage(
              key: state.pageKey,
              child: BlocProvider(
                create: (_) =>
                    sl<CourtFormBloc>()
                      ..add(CourtFormStarted(courtId: courtId)),
                child: CourtFormPage(
                  photoPicker: sl<PhotoPicker>(),
                  courtId: courtId,
                ),
              ),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.businessProfile,
          pageBuilder: (_, state) => NoTransitionPage(
            key: state.pageKey,
            child: BlocProvider(
              create: (_) =>
                  sl<BusinessProfileBloc>()
                    ..add(const BusinessProfileRequested()),
              child: BusinessProfilePage(
                photoPicker: sl<PhotoPicker>(),
                deviceLocation: sl<DeviceLocation>(),
              ),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.businessSettings,
          pageBuilder: (_, state) => NoTransitionPage(
            key: state.pageKey,
            child: BlocProvider(
              create: (_) =>
                  sl<BusinessAccountBloc>()
                    ..add(const BusinessAccountRequested()),
              child: BusinessAccountPage(
                onSignOut: _signOut,
                createNotificationsCubit: () =>
                    sl<BusinessNotificationsCubit>(),
                createChangePasswordCubit: () => sl<ChangePasswordCubit>(),
              ),
            ),
          ),
        ),
      ],
    ),
    // TODO: reemplazar por el home de jugador cuando se implemente.
    GoRoute(
      path: AppRoutes.home,
      builder: (_, _) => const PlaceholderPage(title: 'Inicio'),
    ),
  ],
);
