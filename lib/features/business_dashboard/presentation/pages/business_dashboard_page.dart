import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/loading_dialog.dart';
import '../../domain/entities/business_dashboard.dart';
import '../../domain/entities/dashboard_failure.dart';
import '../bloc/dashboard_bloc.dart';
import '../widgets/dashboard_cards.dart';
import '../widgets/dashboard_charts.dart';
import '../widgets/dashboard_filters_bar.dart';

/// Dashboard analítico del negocio: reservas, cobros, ocupación, días y
/// horas con más movimiento, clientes frecuentes y métodos de pago.
class BusinessDashboardPage extends StatelessWidget {
  const BusinessDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Primera carga: diálogo con el ícono de la app sobre el fondo difuminado.
    return BlocLoadingDialog<DashboardBloc, DashboardState>(
      isLoading: (s) => s.isLoading && s.dashboard == null,
      child: Column(
        children: [
          const AppTopBar(
            title: 'Dashboard',
            subtitle: 'Rendimiento de tu negocio',
            icon: Icons.insights,
          ),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: BlocBuilder<DashboardBloc, DashboardState>(
                builder: (context, state) => _DashboardBody(state: state),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.state});

  final DashboardState state;

  static const _maxWidth = 1440.0;

  Future<void> _refresh(BuildContext context) async {
    final bloc = context.read<DashboardBloc>()..add(const DashboardRefreshed());
    await bloc.stream.firstWhere((s) => !s.isLoading);
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<DashboardBloc>();
    final dashboard = state.dashboard;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final gutter = width >= 680 ? 24.0 : 16.0;
        final side = width > _maxWidth + gutter * 2
            ? (width - _maxWidth) / 2
            : gutter;
        final content = width - side * 2;
        return RefreshIndicator(
          color: AppColors.brandTeal,
          onRefresh: () => _refresh(context),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(side, 12, side, 24),
            children: [
              DashboardFiltersBar(
                filter: state.filter,
                period: dashboard?.period,
                sports: state.sports,
                courts: state.filterCourts,
                today: DateUtils.dateOnly(DateTime.now()),
                onChanged: (filter) => bloc.add(DashboardFilterChanged(filter)),
              ),
              const SizedBox(height: 10),
              if (state.status == DashboardStatus.loading && dashboard != null)
                Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: LinearProgressIndicator(
                    minHeight: 3,
                    color: AppColors.brandTeal,
                    backgroundColor: AppColors.brandTealLight,
                  ),
                ),
              if (state.status == DashboardStatus.failure)
                _Failure(
                  failure: state.failure,
                  message: state.failureMessage,
                  onRetry: () => bloc.add(const DashboardRefreshed()),
                ),
              if (dashboard != null)
                _Metrics(dashboard: dashboard, width: content),
            ],
          ),
        );
      },
    );
  }
}

class _Metrics extends StatelessWidget {
  const _Metrics({required this.dashboard, required this.width});

  final BusinessDashboard dashboard;
  final double width;

  static const _gap = 10.0;

  /// Desde este ancho las secciones van de a tres por fila.
  static const wideWidth = 1100.0;

  /// Filas de [columns] tarjetas del mismo ancho.
  Widget _grid(List<Widget> children, int columns) {
    final itemWidth = (width - _gap * (columns - 1)) / columns;
    return Wrap(
      spacing: _gap,
      runSpacing: _gap,
      children: [
        for (final child in children) SizedBox(width: itemWidth, child: child),
      ],
    );
  }

  /// Desde este ancho de contenido se usa el diseño de escritorio (web,
  /// también en ventanas medianas o con zoom).
  static const desktopWidth = 640.0;

  /// Una fila de secciones con su ancho relativo (flex); en móvil, una
  /// debajo de otra.
  Widget _row(List<(Widget, int)> items) => width >= desktopWidth
      ? Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (i, (child, flex)) in items.indexed) ...[
              if (i > 0) const SizedBox(width: _gap),
              Expanded(flex: flex, child: child),
            ],
          ],
        )
      : Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, (child, _)) in items.indexed) ...[
              if (i > 0) const SizedBox(height: _gap),
              child,
            ],
          ],
        );

  Widget _status() => ReservationStatusBreakdown(summary: dashboard.summary);
  Widget _methods() => PaymentMethodsList(methods: dashboard.paymentMethods);
  Widget _weekdays() =>
      WeekdayBars(days: dashboard.byWeekday, busiest: dashboard.busiestDay);
  Widget _heatmap() => ActivityHeatmap(dashboard: dashboard);
  Widget _courts() => CourtOccupancyList(courts: dashboard.occupancyByCourt);
  Widget _sports() => SportsBreakdown(sports: dashboard.bySport);
  Widget _customers(BuildContext context) => TopCustomersList(
    customers: dashboard.topCustomers,
    onTap: (c) =>
        context.go(AppRoutes.businessCustomerReservations(c.id, c.name)),
  );

  /// Web ancho: tres por fila y el mapa de calor junto a los días.
  List<Widget> _wideSections(BuildContext context) => [
    _row([(_status(), 1), (_methods(), 1), (_customers(context), 1)]),
    const SizedBox(height: _gap),
    _row([(_weekdays(), 1), (_heatmap(), 2)]),
    const SizedBox(height: _gap),
    _row([(_courts(), 2), (_sports(), 1)]),
  ];

  /// Ventanas medianas: de a dos (móvil: una debajo de otra).
  List<Widget> _sections(BuildContext context) => [
    _row([(_status(), 1), (_methods(), 1)]),
    const SizedBox(height: _gap),
    _row([(_weekdays(), 1), (_customers(context), 1)]),
    const SizedBox(height: _gap),
    _heatmap(),
    const SizedBox(height: _gap),
    _row([(_courts(), 1), (_sports(), 1)]),
  ];

  static String _pct(num value) {
    final rounded = value.round();
    return value == rounded ? '$rounded %' : '${value.toStringAsFixed(1)} %';
  }

  static String _hours(num value) {
    final rounded = value.round();
    return value == rounded ? '$rounded' : value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final s = dashboard.summary;
    // Web ancho: los 8 indicadores en una sola fila.
    final kpiColumns = width >= wideWidth
        ? 8
        : width >= desktopWidth
        ? 4
        : 2;
    final kpis = [
      KpiCard(
        key: const Key('kpi-reservations'),
        icon: Icons.event_available_outlined,
        label: 'Reservas',
        value: '${s.reservations.value}',
        trend: s.reservations,
        detail: '${s.confirmed} confirmadas · ${s.completed} jugadas',
      ),
      KpiCard(
        key: const Key('kpi-collected'),
        icon: Icons.payments_outlined,
        label: 'Cobrado',
        value: AppFormatters.cop(s.collected.value.round()),
        trend: s.collected,
        detail: 'Pagos aprobados del período',
      ),
      KpiCard(
        key: const Key('kpi-occupancy'),
        icon: Icons.stadium_outlined,
        label: 'Ocupación',
        value: _pct(s.occupancyPct.value),
        trend: s.occupancyPct,
        detail: '${_hours(s.bookedHours)} de ${_hours(s.openHours)} h abiertas',
      ),
      KpiCard(
        key: const Key('kpi-ticket'),
        icon: Icons.receipt_long_outlined,
        label: 'Ticket promedio',
        value: AppFormatters.cop(s.averageTicket),
        detail: 'Reservado: ${AppFormatters.cop(s.booked)}',
      ),
      KpiCard(
        key: const Key('kpi-new-customers'),
        icon: Icons.person_add_alt_1_outlined,
        label: 'Clientes nuevos',
        value: '${s.newCustomers.value}',
        trend: s.newCustomers,
        detail: '${s.newCustomers.previous} en el período anterior',
      ),
      KpiCard(
        key: const Key('kpi-pending-balance'),
        icon: Icons.hourglass_bottom_outlined,
        label: 'Por cobrar',
        value: AppFormatters.cop(s.pendingBalance),
        accent: AppColors.statusDeposit,
        detail: 'Saldo de las reservas del período',
      ),
      KpiCard(
        key: const Key('kpi-pending-payments'),
        icon: Icons.fact_check_outlined,
        label: 'Pagos por validar',
        value: '${s.pendingPayments.count}',
        accent: AppColors.statusDeposit,
        detail: s.pendingPayments.count == 0
            ? 'Todo al día'
            : '${AppFormatters.cop(s.pendingPayments.amount)} · ver pagos',
        onTap: s.pendingPayments.count == 0
            ? null
            : () => context.go(AppRoutes.businessPayments),
      ),
      KpiCard(
        key: const Key('kpi-discounts'),
        icon: Icons.discount_outlined,
        label: 'Descuentos y devoluciones',
        value: AppFormatters.cop(s.discounts),
        accent: AppColors.slate500,
        detail:
            '${s.refunds.count} '
            '${s.refunds.count == 1 ? 'devolución' : 'devoluciones'} · '
            '${AppFormatters.cop(s.refunds.amount)}',
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _grid(kpis, kpiColumns),
        const SizedBox(height: _gap),
        ...(width >= wideWidth ? _wideSections(context) : _sections(context)),
      ],
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure({
    required this.failure,
    required this.message,
    required this.onRetry,
  });

  final DashboardFailure? failure;
  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final (title, text) = switch (failure) {
      DashboardFailure.notAvailable => (
        'El dashboard aún no está disponible',
        'El servidor todavía no tiene las métricas. Intenta más tarde.',
      ),
      DashboardFailure.network => (
        'Sin conexión',
        'Revisa tu internet e intenta de nuevo.',
      ),
      DashboardFailure.invalid => (
        'Revisa el período',
        message ?? 'Las fechas elegidas no son válidas.',
      ),
      _ => (
        'No pudimos cargar las métricas',
        'Intenta de nuevo en un momento.',
      ),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        children: [
          Icon(Icons.cloud_off_outlined, size: 36, color: AppColors.slate400),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.labelLg.copyWith(
              color: AppColors.slate900,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            textAlign: TextAlign.center,
            style: AppTypography.bodySm.copyWith(color: AppColors.slate500),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const Key('dashboard-retry'),
            onPressed: onRetry,
            style: FilledButton.styleFrom(backgroundColor: AppColors.brandTeal),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
