import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/appearance/appearance_cubit.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../business_home/presentation/widgets/business_logout.dart';
import '../../../business_notifications/presentation/bloc/business_notifications_cubit.dart';
import '../../../business_notifications/presentation/widgets/notifications_setting_row.dart';
import '../../../business_profile/domain/entities/business.dart';
import '../../domain/entities/business_account.dart';
import '../bloc/business_account_bloc.dart';
import '../bloc/change_password_cubit.dart';
import '../widgets/sales_module_card.dart';
import '../widgets/account_profile_card.dart';
import '../widgets/account_settings_card.dart';
import '../widgets/appearance_setting_row.dart';
import '../widgets/change_password_dialog.dart';
import '../widgets/subscription_card.dart';
import '../utils/plan_upgrade_whatsapp.dart';
import '../../../../core/widgets/loading_dialog.dart';

/// Sección "Mi cuenta" del administrador (diseño "Mi Cuenta / Ajustes"):
/// perfil y sede, plan actual, configuración y seguridad.
class BusinessAccountPage extends StatelessWidget {
  const BusinessAccountPage({
    super.key,
    required this.onSignOut,
    this.createNotificationsCubit,
    this.createChangePasswordCubit,
  });

  /// Cubit del cambio de contraseña; sin él la opción queda "próximamente".
  final ChangePasswordCubit Function()? createChangePasswordCubit;

  /// Cubit del aviso de nuevas reservas; sin él no se muestra la fila.
  final BusinessNotificationsCubit Function()? createNotificationsCubit;

  /// Cierra la sesión (borra el token) al confirmar "Cerrar sesión".
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    // Al cargar: diálogo con el ícono de la app sobre el fondo difuminado.
    return BlocLoadingDialog<BusinessAccountBloc, BusinessAccountState>(
      isLoading: (s) =>
          s.status == BusinessAccountStatus.initial ||
          s.status == BusinessAccountStatus.loading,
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      children: [
        const AppTopBar(
          title: 'Mi cuenta',
          subtitle: 'Perfil, plan y seguridad',
          icon: Icons.manage_accounts_rounded,
        ),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: BlocBuilder<BusinessAccountBloc, BusinessAccountState>(
              builder: (context, state) => switch (state.status) {
                BusinessAccountStatus.initial ||
                BusinessAccountStatus.loading => const SizedBox.shrink(),
                BusinessAccountStatus.failure => _LoadError(
                  onRetry: () => context.read<BusinessAccountBloc>().add(
                    const BusinessAccountRequested(),
                  ),
                ),
                BusinessAccountStatus.ready => _AccountContent(
                  onSignOut: onSignOut,
                  createNotificationsCubit: createNotificationsCubit,
                  createChangePasswordCubit: createChangePasswordCubit,
                  account: state.account!,
                  venue: state.venue,
                  version: state.version,
                ),
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _AccountContent extends StatelessWidget {
  const _AccountContent({
    required this.onSignOut,
    this.createNotificationsCubit,
    this.createChangePasswordCubit,
    required this.account,
    required this.venue,
    required this.version,
  });

  /// Desde este ancho las tarjetas se reparten en dos columnas (web).
  static const _wideBreakpoint = 900.0;
  static const _maxWideWidth = 1100.0;

  final Future<void> Function() onSignOut;
  final BusinessNotificationsCubit Function()? createNotificationsCubit;
  final ChangePasswordCubit Function()? createChangePasswordCubit;
  final BusinessAccount account;
  final Business? venue;
  final String? version;

  // TODO: implementar cada flujo (edición de perfil, planes, facturación y
  // WhatsApp con url_launcher).
  void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$feature: próximamente')));
  }

  static bool _hasAppearance(BuildContext context) {
    try {
      context.read<AppearanceCubit>();
      return true;
    } on ProviderNotFoundException {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = AccountProfileCard(
      admin: account.admin,
      venue: venue,
      courtsInUse: account.subscription?.courtsInUse ?? 0,
      onVenueTap: () => context.go(AppRoutes.businessProfile),
      onEditProfile: () => _comingSoon(context, 'Editar perfil'),
    );
    final plan = account.subscription;
    final subscription = plan == null
        ? NoPlanCard(onSeePlans: () => _comingSoon(context, 'Planes'))
        : SubscriptionCard(
            subscription: plan,
            onUpgrade: () => openPlanUpgrade(
              context,
              plan.nextPlanName ?? '',
              businessName: venue?.name,
            ),
            onRequestMoreCourts: () => openMoreCourtsRequest(
              context,
              plan.courtLimit,
              businessName: venue?.name,
            ),
            onBillingHistory: () =>
                _comingSoon(context, 'Historial de facturación'),
          );
    // Módulo de Ventas e inventario, debajo del plan: su detalle si está
    // activo o el botón para pedirlo si no.
    final salesModule = SalesModuleCard(
      module: account.salesModule,
      onOpen: () => context.go(AppRoutes.businessSales),
      onRequest: () =>
          openSalesModuleRequest(context, businessName: venue?.name),
    );
    final create = createNotificationsCubit;
    final settings = AccountSettingsCard(
      onChangePassword: switch (createChangePasswordCubit) {
        final create? => () => showChangePasswordDialog(
          context,
          createCubit: create,
        ),
        null => () => _comingSoon(context, 'Cambiar contraseña'),
      },
      onSupport: () => _comingSoon(context, 'Soporte por WhatsApp'),
      onLogout: () => confirmBusinessLogout(context, signOut: onSignOut),
      // Solo si la app provee el modo de apariencia (no en algunos tests).
      appearance: _hasAppearance(context) ? const AppearanceSettingRow() : null,
      notifications: create == null
          ? null
          : BlocProvider(
              create: (_) => create()..load(),
              child: const NotificationsSettingRow(),
            ),
    );
    final footer = _Footer(
      version: version,
      place: venue?.city?.label ?? venue?.neighborhood,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _wideBreakpoint) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              profile,
              const SizedBox(height: 16),
              subscription,
              const SizedBox(height: 16),
              salesModule,
              const SizedBox(height: 16),
              settings,
              const SizedBox(height: 16),
              footer,
            ],
          );
        }
        // Web: perfil y configuración a la izquierda, plan a la derecha.
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxWideWidth),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            profile,
                            const SizedBox(height: 24),
                            settings,
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            subscription,
                            const SizedBox(height: 24),
                            salesModule,
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  footer,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.version, required this.place});

  final String? version;
  final String? place;

  @override
  Widget build(BuildContext context) {
    final parts = [
      version == null ? 'Mi Cancha' : 'Mi Cancha v$version',
      ?place,
    ];
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_soccer, size: 14, color: AppColors.brandTeal),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                parts.join(' · '),
                textAlign: TextAlign.center,
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Plataforma de Alto Rendimiento Deportivo',
          textAlign: TextAlign.center,
          style: AppTypography.bodySm.copyWith(
            fontSize: 11,
            color: AppColors.outline,
          ),
        ),
      ],
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 40,
              color: AppColors.brandTeal,
            ),
            const SizedBox(height: 12),
            Text(
              'No pudimos cargar tu cuenta',
              textAlign: TextAlign.center,
              style: AppTypography.headlineSm.copyWith(
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandTeal,
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
