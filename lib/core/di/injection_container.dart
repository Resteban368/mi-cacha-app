import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/clock.dart';

import 'package:dio/dio.dart';
import '../location/device_location.dart';
import '../media/photo_picker.dart';
import '../network/api_client.dart';
import '../session/session_manager.dart';
import '../session/write_access.dart';
import '../session/session_storage.dart';
import '../catalogs/data/datasources/catalogs_api_data_source.dart';
import '../catalogs/data/datasources/catalogs_data_source.dart';
import '../catalogs/data/repositories/catalogs_repository_impl.dart';
import '../catalogs/domain/repositories/catalogs_repository.dart';
import '../catalogs/domain/usecases/get_catalogs.dart';
import '../../features/business_account/data/datasources/business_account_api_data_source.dart';
import '../../features/business_account/data/datasources/business_account_data_source.dart';
import '../../features/business_account/data/repositories/business_account_repository_impl.dart';
import '../../features/business_account/domain/repositories/business_account_repository.dart';
import '../../features/business_account/domain/usecases/change_password.dart';
import '../../features/business_account/domain/usecases/get_business_account.dart';
import '../../features/business_account/presentation/bloc/business_account_bloc.dart';
import '../../features/business_account/presentation/bloc/change_password_cubit.dart';
import '../../features/business_clients/data/datasources/business_customers_api_data_source.dart';
import '../../features/business_clients/data/datasources/business_customers_data_source.dart';
import '../../features/business_clients/data/repositories/business_customers_repository_impl.dart';
import '../../features/business_clients/domain/repositories/business_customers_repository.dart';
import '../../features/business_clients/domain/usecases/create_business_customer.dart';
import '../../features/business_clients/domain/usecases/get_business_customers.dart';
import '../../features/business_clients/domain/usecases/update_business_customer.dart';
import '../../features/business_clients/presentation/bloc/business_clients_bloc.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/datasources/business_auth_api_data_source.dart';
import '../../features/auth/domain/usecases/sign_out.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/sign_in.dart';
import '../../features/auth/domain/usecases/sign_in_with_credentials.dart';
import '../../features/auth/presentation/bloc/business_login/business_login_bloc.dart';
import '../../features/auth/presentation/bloc/login_bloc.dart';
import '../../features/business_courts/data/datasources/courts_api_data_source.dart';
import '../../features/business_courts/data/datasources/courts_data_source.dart';
import '../../features/business_courts/data/repositories/courts_repository_impl.dart';
import '../../features/business_courts/domain/repositories/courts_repository.dart';
import '../../features/business_courts/domain/usecases/create_court.dart';
import '../../features/business_courts/domain/usecases/upload_court_photo.dart';
import '../../features/business_courts/domain/usecases/get_courts.dart';
import '../../features/business_courts/domain/usecases/remove_court_photo.dart';
import '../../features/business_courts/domain/usecases/update_court.dart';
import '../../features/business_courts/presentation/bloc/courts_bloc.dart';
import '../../features/business_courts/presentation/bloc/court_form_bloc.dart';
import '../../features/business_payments/data/datasources/payments_api_data_source.dart';
import '../../features/business_payments/data/datasources/payments_data_source.dart';
import '../../features/business_payments/data/repositories/payments_repository_impl.dart';
import '../../features/business_payments/domain/repositories/payments_repository.dart';
import '../../features/business_payments/domain/usecases/create_payment.dart';
import '../../features/business_payments/domain/usecases/get_payments.dart';
import '../../features/business_payments/domain/usecases/validate_payment.dart';
import '../../features/business_payments/presentation/bloc/new_payment/new_payment_bloc.dart';
import '../../features/business_payments/presentation/bloc/payments/payments_bloc.dart';
import '../../features/business_profile/data/datasources/business_api_data_source.dart';
import '../../features/business_profile/data/datasources/business_data_source.dart';
import '../../features/business_profile/data/repositories/business_repository_impl.dart';
import '../../features/business_profile/domain/repositories/business_repository.dart';
import '../../features/business_profile/domain/usecases/get_my_business.dart';
import '../../features/business_profile/domain/usecases/business_photo_usecases.dart';
import '../../features/business_profile/domain/usecases/get_online_booking_link.dart';
import '../../features/business_profile/domain/usecases/save_business.dart';
import '../../features/business_profile/presentation/bloc/business_profile_bloc.dart';
import '../../features/business_reservations/data/datasources/reservations_api_data_source.dart';
import '../../features/business_reservations/data/datasources/reservations_data_source.dart';
import '../../features/business_reservations/data/repositories/reservations_repository_impl.dart';
import '../../features/business_reservations/domain/repositories/reservations_repository.dart';
import '../../features/business_reservations/domain/usecases/get_day_reservations.dart';
import '../../features/business_reservations/domain/usecases/booking_usecases.dart';
import '../../features/business_reservations/presentation/bloc/business_reservations_bloc.dart';
import '../../features/business_reservations/presentation/bloc/new_reservation/new_reservation_bloc.dart';
import '../../features/business_reservations/presentation/bloc/reservation_detail/reservation_detail_cubit.dart';
import '../../features/business_reservations/presentation/bloc/reservations_list/reservations_list_bloc.dart';
import '../../features/onboarding/data/datasources/onboarding_local_data_source.dart';
import '../../features/onboarding/data/repositories/onboarding_repository_impl.dart';
import '../../features/onboarding/domain/repositories/onboarding_repository.dart';
import '../../features/onboarding/domain/usecases/complete_onboarding.dart';
import '../../features/onboarding/presentation/bloc/onboarding_bloc.dart';
import '../../features/splash/data/datasources/app_info_data_source.dart';
import '../../features/splash/data/repositories/app_info_repository_impl.dart';
import '../../features/splash/data/repositories/session_repository_impl.dart';
import '../../features/splash/domain/repositories/app_info_repository.dart';
import '../../features/splash/domain/repositories/session_repository.dart';
import '../../features/business_dashboard/data/datasources/business_dashboard_api_data_source.dart';
import '../../features/business_dashboard/data/repositories/business_dashboard_repository_impl.dart';
import '../../features/business_dashboard/domain/repositories/business_dashboard_repository.dart';
import '../../features/business_dashboard/domain/usecases/get_business_dashboard.dart';
import '../../features/business_dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../features/business_notifications/data/datasources/browser_push.dart';
import '../../features/business_notifications/data/datasources/inbox_api_data_source.dart';
import '../../features/business_notifications/data/repositories/notifications_inbox_repository_impl.dart';
import '../../features/business_notifications/domain/repositories/notifications_inbox_repository.dart';
import '../../features/business_notifications/domain/usecases/inbox_usecases.dart';
import '../../features/business_notifications/presentation/bloc/notifications_inbox_cubit.dart';
import '../../features/business_notifications/data/datasources/push_api_data_source.dart';
import '../../features/business_notifications/data/repositories/push_repository_impl.dart';
import '../../features/business_notifications/domain/repositories/push_repository.dart';
import '../../features/business_notifications/domain/usecases/push_usecases.dart';
import '../../features/business_notifications/presentation/bloc/business_notifications_cubit.dart';
import '../../features/splash/domain/usecases/get_app_version.dart';
import '../../features/splash/domain/usecases/resolve_start_destination.dart';
import '../../features/splash/presentation/bloc/splash_bloc.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // External
  sl
    ..registerLazySingleton<FlutterSecureStorage>(
      () => const FlutterSecureStorage(),
    )
    ..registerLazySingleton<SharedPreferencesAsync>(SharedPreferencesAsync.new)
    ..registerLazySingleton<Clock>(Clock.new)
    // Sesión y API
    ..registerLazySingleton<SessionStorage>(() => SecureSessionStorage(sl()))
    ..registerLazySingleton(() => SessionManager(sl()))
    ..registerLazySingleton(WriteAccess.new)
    ..registerLazySingleton<Dio>(() => buildApiClient(sl(), sl()));

  _initCatalogs();
  _initOnboarding();
  _initSplash();
  _initAuth();
  _initBusinessReservations();
  _initBusinessPayments();
  _initBusinessProfile();
  _initBusinessAccount();
  _initBusinessNotifications();
  _initBusinessCourts();
  _initBusinessClients();
  _initBusinessDashboard();
}

void _initCatalogs() {
  sl
    ..registerLazySingleton<CatalogsDataSource>(
      () => CatalogsApiDataSource(sl()),
    )
    ..registerLazySingleton<CatalogsRepository>(
      () => CatalogsRepositoryImpl(sl()),
    )
    ..registerLazySingleton(() => GetCatalogs(sl()));
}

void _initSplash() {
  sl
    // Data sources
    ..registerLazySingleton<AppInfoDataSource>(AppInfoDataSourceImpl.new)
    // Repositories
    ..registerLazySingleton<SessionRepository>(
      () => SessionRepositoryImpl(sl(), sl()),
    )
    ..registerLazySingleton<AppInfoRepository>(
      () => AppInfoRepositoryImpl(sl()),
    )
    // Use cases
    ..registerLazySingleton(() => ResolveStartDestination(sl(), sl()))
    ..registerLazySingleton(() => GetAppVersion(sl()))
    // Bloc: factory, una instancia nueva por pantalla
    ..registerFactory(
      () => SplashBloc(resolveStartDestination: sl(), getAppVersion: sl()),
    );
}

void _initAuth() {
  sl
    ..registerLazySingleton<AuthRemoteDataSource>(FakeAuthRemoteDataSource.new)
    ..registerLazySingleton<BusinessAuthApiDataSource>(
      () => BusinessAuthApiDataSourceImpl(sl()),
    )
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(
        playerDataSource: sl(),
        businessApi: sl(),
        session: sl(),
        beforeSignOut: _disablePushQuietly,
      ),
    )
    ..registerLazySingleton(() => SignIn(sl()))
    ..registerLazySingleton(() => SignInWithCredentials(sl()))
    ..registerLazySingleton(() => SignOut(sl()))
    ..registerFactory(() => LoginBloc(signIn: sl()))
    ..registerFactory(() => BusinessLoginBloc(signInWithCredentials: sl()));
}

void _initOnboarding() {
  sl
    ..registerLazySingleton<OnboardingLocalDataSource>(
      () => OnboardingLocalDataSourceImpl(sl()),
    )
    ..registerLazySingleton<OnboardingRepository>(
      () => OnboardingRepositoryImpl(sl()),
    )
    ..registerLazySingleton(() => CompleteOnboarding(sl()))
    ..registerFactory(() => OnboardingBloc(completeOnboarding: sl()));
}

void _initBusinessReservations() {
  sl
    ..registerLazySingleton<ReservationsDataSource>(
      () => ReservationsApiDataSource(sl()),
    )
    ..registerLazySingleton<ReservationsRepository>(
      () => ReservationsRepositoryImpl(sl()),
    )
    ..registerLazySingleton(() => GetDayReservations(sl()))
    ..registerLazySingleton(() => GetSportAvailability(sl()))
    ..registerLazySingleton(() => SearchCustomers(sl()))
    ..registerLazySingleton(() => CreateReservation(sl()))
    ..registerLazySingleton(() => GetReservation(sl()))
    ..registerLazySingleton(() => CancelReservation(sl()))
    ..registerLazySingleton(() => UpdateReservationStatus(sl()))
    ..registerLazySingleton(() => ListReservations(sl()))
    ..registerFactory(
      () => ReservationsListBloc(listReservations: sl(), getCourts: sl()),
    )
    ..registerFactory(
      () => BusinessReservationsBloc(
        getDayReservations: sl(),
        getCourts: sl(),
        clock: sl(),
      ),
    )
    ..registerFactory(
      () => ReservationDetailCubit(
        getReservation: sl(),
        cancelReservation: sl(),
        updateStatus: sl(),
      ),
    )
    ..registerFactory(
      () => NewReservationBloc(
        getCourts: sl(),
        getCatalogs: sl(),
        getSportAvailability: sl(),
        searchCustomers: sl(),
        createReservation: sl(),
        clock: sl(),
      ),
    );
}

void _initBusinessPayments() {
  sl
    ..registerLazySingleton<PaymentsDataSource>(
      () => PaymentsApiDataSource(sl()),
    )
    ..registerLazySingleton<PaymentsRepository>(
      () => PaymentsRepositoryImpl(sl()),
    )
    ..registerLazySingleton(() => GetPayments(sl()))
    ..registerLazySingleton(() => ValidatePayment(sl()))
    ..registerLazySingleton(() => CreatePayment(sl()))
    ..registerFactory(
      () => PaymentsBloc(getPayments: sl(), validatePayment: sl()),
    )
    ..registerFactory(
      () => NewPaymentBloc(
        createPayment: sl(),
        getBusinessCustomers: sl(),
        listReservations: sl(),
      ),
    );
}

void _initBusinessProfile() {
  sl
    ..registerLazySingleton<BusinessDataSource>(
      () => BusinessApiDataSource(sl()),
    )
    ..registerLazySingleton<BusinessRepository>(
      () => BusinessRepositoryImpl(sl()),
    )
    ..registerLazySingleton(() => GetMyBusiness(sl()))
    ..registerLazySingleton(() => SaveBusiness(sl()))
    ..registerLazySingleton(() => AddBusinessPhoto(sl()))
    ..registerLazySingleton(() => RemoveBusinessPhoto(sl()))
    ..registerLazySingleton(() => ReorderBusinessPhotos(sl()))
    ..registerLazySingleton(() => GetOnlineBookingLink(sl()))
    ..registerLazySingleton<PhotoPicker>(ImagePickerPhotoPicker.new)
    ..registerLazySingleton<DeviceLocation>(GeolocatorDeviceLocation.new)
    ..registerFactory(
      () => BusinessProfileBloc(
        getMyBusiness: sl(),
        saveBusiness: sl(),
        addPhoto: sl(),
        removePhoto: sl(),
        reorderPhotos: sl(),
        getBookingLink: sl(),
        getCatalogs: sl(),
      ),
    );
}

/// Quita el aviso push del navegador antes de cerrar sesión (endpoint
/// público: funciona aunque el token haya vencido). Si falla (sin
/// red, por ejemplo) se ignora: cerrar sesión no puede quedar bloqueado.
Future<void> _disablePushQuietly() async {
  try {
    await sl<PushRepository>().forget().timeout(const Duration(seconds: 5));
  } catch (_) {}
}

void _initBusinessNotifications() {
  sl
    ..registerLazySingleton<PushApiDataSource>(() => PushApiDataSource(sl()))
    ..registerLazySingleton<BrowserPush>(createBrowserPush)
    ..registerLazySingleton<PushRepository>(
      () => PushRepositoryImpl(api: sl(), browser: sl()),
    )
    ..registerLazySingleton(() => GetPushStatus(sl()))
    ..registerLazySingleton(() => EnablePush(sl()))
    ..registerLazySingleton(() => DisablePush(sl()))
    ..registerLazySingleton(() => InboxApiDataSource(sl()))
    ..registerLazySingleton<NotificationsInboxRepository>(
      () => NotificationsInboxRepositoryImpl(sl()),
    )
    ..registerLazySingleton(() => GetNotifications(sl()))
    ..registerLazySingleton(() => GetUnreadNotificationsCount(sl()))
    ..registerLazySingleton(() => MarkNotificationRead(sl()))
    ..registerLazySingleton(() => MarkAllNotificationsRead(sl()))
    ..registerFactory(
      () => NotificationsInboxCubit(
        getNotifications: sl(),
        getUnreadCount: sl(),
        markRead: sl(),
        markAllRead: sl(),
        clock: sl(),
      ),
    )
    ..registerFactory(
      () => BusinessNotificationsCubit(
        getStatus: sl(),
        enable: sl(),
        disable: sl(),
      ),
    );
}

void _initBusinessAccount() {
  sl
    ..registerLazySingleton<BusinessAccountDataSource>(
      () => BusinessAccountApiDataSource(sl()),
    )
    ..registerLazySingleton<BusinessAccountRepository>(
      () => BusinessAccountRepositoryImpl(sl()),
    )
    ..registerLazySingleton(() => GetBusinessAccount(sl()))
    ..registerLazySingleton(() => ChangePassword(sl()))
    ..registerFactory(
      () => BusinessAccountBloc(
        getAccount: sl(),
        getMyBusiness: sl(),
        getAppVersion: sl(),
      ),
    )
    ..registerFactory(() => ChangePasswordCubit(changePassword: sl()));
}

void _initBusinessCourts() {
  sl
    ..registerLazySingleton<CourtsDataSource>(() => CourtsApiDataSource(sl()))
    ..registerLazySingleton<CourtsRepository>(() => CourtsRepositoryImpl(sl()))
    ..registerLazySingleton(() => CreateCourt(sl()))
    ..registerLazySingleton(() => UploadCourtPhoto(sl()))
    ..registerLazySingleton(() => GetCourts(sl()))
    ..registerLazySingleton(() => UpdateCourt(sl()))
    ..registerLazySingleton(() => RemoveCourtPhoto(sl()))
    ..registerFactory(
      () => CourtFormBloc(
        getMyBusiness: sl(),
        getAccount: sl(),
        getCourts: sl(),
        getCatalogs: sl(),
        createCourt: sl(),
        updateCourt: sl(),
        uploadPhoto: sl(),
        removePhoto: sl(),
      ),
    )
    ..registerFactory(() => CourtsBloc(getCourts: sl()));
}

void _initBusinessClients() {
  sl
    ..registerLazySingleton<BusinessCustomersDataSource>(
      () => BusinessCustomersApiDataSource(sl()),
    )
    ..registerLazySingleton<BusinessCustomersRepository>(
      () => BusinessCustomersRepositoryImpl(sl()),
    )
    ..registerLazySingleton(() => GetBusinessCustomers(sl()))
    ..registerLazySingleton(() => CreateBusinessCustomer(sl()))
    ..registerLazySingleton(() => UpdateBusinessCustomer(sl()))
    ..registerFactory(
      () => BusinessClientsBloc(
        getBusinessCustomers: sl(),
        createBusinessCustomer: sl(),
        updateBusinessCustomer: sl(),
      ),
    );
}

void _initBusinessDashboard() {
  sl
    ..registerLazySingleton<BusinessDashboardDataSource>(
      () => BusinessDashboardApiDataSource(sl()),
    )
    ..registerLazySingleton<BusinessDashboardRepository>(
      () => BusinessDashboardRepositoryImpl(sl()),
    )
    ..registerLazySingleton(() => GetBusinessDashboard(sl()))
    ..registerFactory(() => DashboardBloc(getDashboard: sl(), getCourts: sl()));
}
