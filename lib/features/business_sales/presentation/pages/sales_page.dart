import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/session/write_access.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_add_fab.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../domain/entities/sale.dart';
import '../bloc/sale_cart_cubit.dart';
import '../bloc/sales_cubit.dart';
import '../widgets/sale_sheet.dart';
import '../widgets/sale_tile.dart';

/// Sección "Ventas": lo vendido en el día (ventas sueltas y consumos de
/// reservas) y acceso al catálogo de productos.
class SalesPage extends StatelessWidget {
  const SalesPage({super.key, this.createCartCubit});

  /// Para pruebas; por defecto el carrito sale del contenedor.
  final SaleCartCubit Function()? createCartCubit;

  Future<void> _newSale(BuildContext context) async {
    if (!ensureCanWrite(context)) return;
    final cubit = context.read<SalesCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final sale = await showSaleSheet(context, createCubit: createCartCubit);
    if (sale == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Venta registrada: ${AppFormatters.cop(sale.total)}.'),
        ),
      );
    await cubit.load(DateTime.now());
  }

  Future<void> _void(BuildContext context, Sale sale) async {
    if (!ensureCanWrite(context)) return;
    final cubit = context.read<SalesCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final reason = await showVoidSaleDialog(context);
    if (reason == null) return;
    final error = await cubit.voidSale(sale.id, reason);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(error ?? 'Venta anulada.'),
          backgroundColor: error == null ? null : AppColors.statusDue,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final canWrite = WriteAccessScope.canWrite(context);

    return Stack(
      children: [
        Column(
          children: [
            const AppTopBar(
              title: 'Ventas',
              subtitle: 'Bebidas, snacks y consumos de las reservas',
              icon: Icons.point_of_sale_rounded,
            ),
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: BlocBuilder<SalesCubit, SalesState>(
                  builder: (context, state) => RefreshIndicator(
                    color: AppColors.brandTeal,
                    onRefresh: () => context.read<SalesCubit>().load(),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        bottomInset + 96,
                      ),
                      children: [
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 760),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _Toolbar(day: state.day),
                                const SizedBox(height: 12),
                                ..._body(context, state, canWrite),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (canWrite)
          Positioned(
            right: 16,
            bottom: bottomInset + 16,
            child: AppAddFab(
              tooltip: 'Nueva venta',
              onPressed: () => _newSale(context),
            ),
          ),
      ],
    );
  }

  List<Widget> _body(BuildContext context, SalesState state, bool canWrite) {
    switch (state.load) {
      case SalesLoad.loading:
        return const [
          Padding(
            padding: EdgeInsets.all(48),
            child: Center(child: CircularProgressIndicator()),
          ),
        ];
      case SalesLoad.failure:
        return [
          _Empty(
            icon: Icons.cloud_off_outlined,
            text: 'No pudimos cargar las ventas. Revisa tu conexión.',
            action: TextButton(
              onPressed: () => context.read<SalesCubit>().load(),
              child: const Text('Reintentar'),
            ),
          ),
        ];
      case SalesLoad.ready:
        return [
          _Summary(state: state),
          const SizedBox(height: 16),
          if (state.sales.isEmpty)
            const _Empty(
              icon: Icons.receipt_long_outlined,
              text:
                  'No hay ventas este día. Registra una venta suelta con el '
                  'botón + o agrega consumos desde el detalle de una reserva.',
            ),
          for (final sale in state.sales) ...[
            SaleTile(
              sale: sale,
              title: sale.isWalkIn
                  ? sale.customerName ?? 'Venta suelta'
                  : 'Consumo · ${sale.customerName ?? 'Reserva'}',
              onVoid: canWrite ? () => _void(context, sale) : null,
            ),
            const SizedBox(height: 8),
          ],
        ];
    }
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SalesCubit>();
    final now = DateTime.now();
    final isToday =
        day.year == now.year && day.month == now.month && day.day == now.day;
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Día anterior',
              onPressed: () => cubit.shiftDay(-1),
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Text(
              isToday ? 'Hoy' : AppFormatters.shortDate(day),
              style: AppTypography.bodyLg.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
              ),
            ),
            IconButton(
              tooltip: 'Día siguiente',
              onPressed: isToday ? null : () => cubit.shiftDay(1),
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
        OutlinedButton.icon(
          key: const Key('open-products'),
          onPressed: () => context.go(AppRoutes.businessProducts),
          icon: const Icon(Icons.inventory_2_outlined, size: 18),
          label: const Text('Productos'),
        ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.state});

  final SalesState state;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _Metric(
          label: 'Total vendido',
          value: AppFormatters.cop(state.total),
          detail: '${state.count} ${state.count == 1 ? 'venta' : 'ventas'}',
          highlight: true,
        ),
        _Metric(
          label: 'Ventas sueltas',
          value: AppFormatters.cop(state.walkInTotal),
          detail: 'Cobradas en el momento',
        ),
        _Metric(
          label: 'Consumos en reservas',
          value: AppFormatters.cop(state.consumptionsTotal),
          detail: 'Se cobran con la reserva',
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.detail,
    this.highlight = false,
  });

  final String label;
  final String value;
  final String detail;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 160),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: highlight
              ? AppColors.brandTealLight
              : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: highlight ? AppColors.brandTeal : AppColors.slate200,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTypography.labelSm.copyWith(
                color: AppColors.slate500,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: AppTypography.headlineSm.copyWith(
                fontWeight: FontWeight.w800,
                color: highlight
                    ? AppColors.brandTealDeep
                    : AppColors.onSurface,
              ),
            ),
            Text(
              detail,
              style: AppTypography.bodySm.copyWith(
                color: AppColors.slate500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppColors.slate400),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMd.copyWith(color: AppColors.slate600),
          ),
          ?action,
        ],
      ),
    );
  }
}
