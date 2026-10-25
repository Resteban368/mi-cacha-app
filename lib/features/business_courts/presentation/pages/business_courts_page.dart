import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/session/write_access.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../bloc/courts_bloc.dart';
import '../widgets/court_list_card.dart';
import '../../../../core/widgets/loading_dialog.dart';

/// Sección "Canchas": las canchas del negocio y el acceso a crear una
/// nueva (desde cero o usando otra como base).
class BusinessCourtsPage extends StatelessWidget {
  const BusinessCourtsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Al cargar: diálogo con el ícono de la app sobre el fondo difuminado.
    return BlocLoadingDialog<CourtsBloc, CourtsState>(
      isLoading: (s) => s.status == CourtsStatus.loading,
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      children: [
        const AppTopBar(
          title: 'Canchas',
          subtitle: 'Tus canchas, horarios y tarifas',
          icon: Icons.stadium_rounded,
        ),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: BlocBuilder<CourtsBloc, CourtsState>(
              builder: (context, state) => switch (state.status) {
                CourtsStatus.loading => const SizedBox.shrink(),
                CourtsStatus.failure when state.courts.isEmpty => _Message(
                  icon: Icons.cloud_off_outlined,
                  title: 'No pudimos cargar tus canchas',
                  detail: 'Revisa tu conexión e intenta de nuevo.',
                  actionLabel: 'Reintentar',
                  onAction: () =>
                      context.read<CourtsBloc>().add(const CourtsRequested()),
                ),
                _ when state.courts.isEmpty => _Message(
                  icon: Icons.stadium_outlined,
                  title: 'Aún no tienes canchas',
                  detail:
                      'Crea tu primera cancha con su horario, precios y fotos '
                      'para empezar a recibir reservas.',
                  actionLabel: 'Crear mi primera cancha',
                  onAction: () {
                    if (ensureCanWrite(context)) {
                      context.go(AppRoutes.businessNewCourt);
                    }
                  },
                ),
                _ => _CourtsList(state: state),
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _CourtsList extends StatelessWidget {
  const _CourtsList({required this.state});

  final CourtsState state;

  @override
  Widget build(BuildContext context) {
    final courts = state.courts;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final gutter = isWide ? 24.0 : 16.0;
        final ready = courts.where((c) => c.isBookable).length;
        return RefreshIndicator(
          color: AppColors.brandTeal,
          onRefresh: () {
            final done = Completer<void>();
            context.read<CourtsBloc>().add(
              CourtsRequested(refresh: true, done: done),
            );
            return done.future;
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(gutter, 16, gutter, 12),
                sliver: SliverToBoxAdapter(
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 16,
                    runSpacing: 12,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mis canchas',
                            style: AppTypography.headlineLg.copyWith(
                              color: AppColors.onSurface,
                              letterSpacing: -0.24,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${courts.length} '
                            '${courts.length == 1 ? 'cancha' : 'canchas'} · '
                            '$ready lista${ready == 1 ? '' : 's'} para '
                            'reservas',
                            style: AppTypography.bodyMd.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      FilledButton.icon(
                        key: const Key('new-court'),
                        onPressed: WriteAccessScope.canWrite(context)
                            ? () => context.go(AppRoutes.businessNewCourt)
                            : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          minimumSize: const Size(0, 48),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: AppTypography.labelLg.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text('Nueva cancha'),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 24),
                // Una columna en el celular; tarjetas de ~420 px en web.
                sliver: SliverGrid.builder(
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: isWide ? 460 : 640,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    mainAxisExtent: CourtListCard.height,
                  ),
                  itemCount: courts.length,
                  itemBuilder: (context, index) {
                    final court = courts[index];
                    // Solo lectura: se ven las canchas, sin acciones.
                    final canWrite = WriteAccessScope.canWrite(context);
                    return CourtListCard(
                      court: court,
                      onEdit: canWrite
                          ? () => context.go(
                              AppRoutes.businessEditCourtFor(court.id),
                            )
                          : null,
                      onUseAsBase: canWrite
                          ? () => context.go(
                              AppRoutes.businessNewCourtFrom(court.id),
                            )
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Estado vacío o de error con una acción.
class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.detail,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String detail;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.brandTealLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 36, color: AppColors.brandTeal),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.headlineSm.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                detail,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                ),
                child: Text(actionLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
