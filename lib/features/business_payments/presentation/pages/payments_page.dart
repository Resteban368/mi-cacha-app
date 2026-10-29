import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/clock.dart';
import '../../../../core/widgets/app_add_fab.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/sliver_card_grid.dart';
import '../bloc/payments/payments_bloc.dart';
import '../widgets/payment_card.dart';
import '../widgets/payment_detail_sheet.dart';
import '../widgets/payments_summary_card.dart';
import '../widgets/payments_filters.dart';
import '../../../../core/widgets/loading_dialog.dart';
import '../../../../core/session/write_access.dart';

/// Sección "Pagos": validar los pagos que llegan y registrar nuevos.
class PaymentsPage extends StatelessWidget {
  const PaymentsPage({super.key, this.clock = const Clock()});

  final Clock clock;

  Future<void> _openNewPayment(BuildContext context) async {
    final bloc = context.read<PaymentsBloc>();
    final messenger = ScaffoldMessenger.of(context);
    final created = await context.push<bool>(AppRoutes.businessNewPayment);
    if (created ?? false) {
      bloc.add(const PaymentsRequested());
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Pago registrado')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Al cargar: diálogo con el ícono de la app sobre el fondo difuminado.
    return BlocLoadingDialog<PaymentsBloc, PaymentsState>(
      isLoading: (s) =>
          s.status == PaymentsStatus.initial ||
          s.status == PaymentsStatus.loading,
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return BlocListener<PaymentsBloc, PaymentsState>(
      listenWhen: (prev, curr) =>
          curr.notice != null && prev.notice != curr.notice,
      listener: (context, state) {
        final notice = state.notice!;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(notice.message),
              backgroundColor: notice.isError
                  ? AppColors.statusDue
                  : AppColors.inverseSurface,
            ),
          );
      },
      child: Stack(
        children: [
          Column(
            children: [
              const AppTopBar(
                title: 'Pagos',
                subtitle: 'Valida y registra pagos',
                icon: Icons.account_balance_wallet_rounded,
              ),
              Expanded(
                child: MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
                  child: BlocBuilder<PaymentsBloc, PaymentsState>(
                    builder: (context, state) => LayoutBuilder(
                      builder: (context, constraints) => RefreshIndicator(
                        color: AppColors.brandTeal,
                        onRefresh: () async {
                          final bloc = context.read<PaymentsBloc>()
                            ..add(const PaymentsRequested());
                          await bloc.stream.first;
                        },
                        child: CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: _slivers(
                            context,
                            state,
                            CardGridLayout.of(constraints.maxWidth),
                            bottomInset,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (WriteAccessScope.canWrite(context))
            Positioned(
              right: 16,
              bottom: bottomInset + 16,
              child: AppAddFab(
                tooltip: 'Nuevo pago',
                onPressed: () => _openNewPayment(context),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _slivers(
    BuildContext context,
    PaymentsState state,
    CardGridLayout layout,
    double bottomInset,
  ) {
    switch (state.status) {
      case PaymentsStatus.initial || PaymentsStatus.loading:
        return const [
          // La carga se muestra con el diálogo (BlocLoadingDialog).
          SliverFillRemaining(hasScrollBody: false, child: SizedBox.shrink()),
        ];
      case PaymentsStatus.failure:
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyMessage(
              icon: Icons.cloud_off_outlined,
              title: 'No pudimos cargar los pagos',
              message: 'Revisa tu conexión e intenta de nuevo.',
              action: 'Reintentar',
              onAction: () =>
                  context.read<PaymentsBloc>().add(const PaymentsRequested()),
            ),
          ),
        ];
      case PaymentsStatus.success:
        final now = clock.now();
        final visible = state.visible;
        final gutter = layout.gutter;
        final filters = PaymentsFilters(
          filter: state.filter,
          courts: state.courtOptions,
          methods: state.methodOptions,
          now: now,
          onChanged: (filter) =>
              context.read<PaymentsBloc>().add(PaymentsFilterChanged(filter)),
        );
        return [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(gutter, 16, gutter, 0),
            sliver: SliverToBoxAdapter(child: filters),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(gutter, 12, gutter, 0),
            sliver: SliverToBoxAdapter(
              child: PaymentsSummaryCard(summary: state.summary),
            ),
          ),
          SliverPadding(
            // Espacio final para el botón flotante.
            padding: EdgeInsets.fromLTRB(gutter, 12, gutter, bottomInset + 96),
            sliver: visible.isEmpty
                ? SliverToBoxAdapter(child: _emptyFor(state))
                : SliverCardGrid(
                    itemCount: visible.length,
                    columns: layout.columns,
                    itemBuilder: (context, i) {
                      final payment = visible[i];
                      return PaymentCard(
                        key: ValueKey(payment.id),
                        payment: payment,
                        now: now,
                        onTap: () => showPaymentDetailSheet(context, payment),
                      );
                    },
                  ),
          ),
        ];
    }
  }

  Widget _emptyFor(PaymentsState state) => state.filter.isActive
      ? const _EmptyMessage(
          icon: Icons.filter_alt_off_outlined,
          title: 'Sin resultados',
          message: 'No hay pagos aprobados con estos filtros.',
        )
      : const _EmptyMessage(
          icon: Icons.receipt_long_outlined,
          title: 'Sin pagos aprobados',
          message: 'Los pagos que apruebes o registres aparecerán aquí.',
        );
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.brandTealLight,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 30, color: AppColors.brandTeal),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.headlineSm.copyWith(
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandTeal,
              ),
              child: Text(action!),
            ),
          ],
        ],
      ),
    );
  }
}
