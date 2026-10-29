import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/session/business_modules.dart';
import '../../../../core/session/write_access.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_add_fab.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../business_payments/domain/entities/payment.dart';
import '../../../business_payments/presentation/widgets/payment_styles.dart';
import '../../domain/entities/sale.dart';
import '../bloc/cash_cubit.dart';
import '../bloc/sale_cart_cubit.dart';
import '../bloc/sales_cubit.dart';
import '../widgets/cash_widgets.dart';
import '../widgets/sale_sheet.dart';
import '../widgets/sales_module_locked.dart';
import '../widgets/sale_tile.dart';

/// Color de los consumos de reservas (como en el diseño de Stitch).
const _sky = Color(0xFF0284C7);

/// Sección "Ventas": ventas y caja del día (sueltas y consumos de reservas),
/// arqueo por método de pago y acceso al catálogo de productos.
class SalesPage extends StatelessWidget {
  const SalesPage({super.key, this.createCartCubit});

  /// Para pruebas; por defecto el carrito sale del contenedor.
  final SaleCartCubit Function()? createCartCubit;

  static const _maxWidth = 1280.0;

  Future<void> _newSale(BuildContext context) async {
    if (!ensureCanWrite(context)) return;
    // Sin caja abierta no se vende (la API también lo valida).
    final cash = context.read<CashCubit>().state;
    if (cash.load == CashLoad.ready && !cash.isOpen) {
      final open = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          key: const Key('cash-closed-dialog'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: Icon(Icons.lock_outline_rounded, color: AppColors.statusDue),
          title: const Text('La caja está cerrada'),
          content: const Text(
            'Para registrar ventas primero abre la caja con la base de '
            'efectivo. Así todo lo vendido queda en el cuadre del turno.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Ahora no'),
            ),
            FilledButton.icon(
              key: const Key('cash-closed-open'),
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.lock_open_rounded, size: 18),
              label: const Text('Abrir caja'),
            ),
          ],
        ),
      );
      if (open != true || !context.mounted) return;
      if (!await showOpenCashDialog(context) || !context.mounted) return;
    }
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
    if (context.mounted) await context.read<CashCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    if (!BusinessModulesScope.salesOf(context)) {
      return const Column(
        children: [
          AppTopBar(
            title: 'Ventas',
            subtitle: 'Bebidas, snacks y consumos de las reservas',
            icon: Icons.point_of_sale_rounded,
          ),
          Expanded(child: SalesModuleLocked()),
        ],
      );
    }
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
                    onRefresh: () => Future.wait([
                      context.read<SalesCubit>().load(),
                      context.read<CashCubit>().load(),
                    ]),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final gutter = constraints.maxWidth >= 680
                            ? 24.0
                            : 16.0;
                        final width = (constraints.maxWidth - gutter * 2).clamp(
                          0.0,
                          _maxWidth,
                        );
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            gutter,
                            16,
                            gutter,
                            bottomInset + 96,
                          ),
                          children: [
                            Center(
                              child: SizedBox(
                                width: width,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _HeaderCard(
                                      day: state.day,
                                      compact: width < 560,
                                    ),
                                    const SizedBox(height: 16),
                                    ..._body(context, state, canWrite, width),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
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

  List<Widget> _body(
    BuildContext context,
    SalesState state,
    bool canWrite,
    double width,
  ) {
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
        final visible = state.visible;
        return [
          _KpiGrid(state: state, width: width),
          const SizedBox(height: 16),
          const CashBanner(),
          const SizedBox(height: 16),
          _FilterBar(state: state, wide: width >= 900),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'TRANSACCIONES DEL DÍA · MÁS RECIENTES PRIMERO',
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.slate400,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                Text(
                  '${visible.length} de ${state.sales.length}',
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.slate400,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (state.sales.isEmpty)
            const _Empty(
              icon: Icons.receipt_long_outlined,
              text:
                  'No hay ventas este día. Registra una venta suelta con el '
                  'botón + o agrega consumos desde el detalle de una reserva.',
            )
          else if (visible.isEmpty)
            const _Empty(
              icon: Icons.filter_alt_off_outlined,
              text: 'Ninguna venta coincide con los filtros.',
            ),
          for (final sale in visible) ...[
            _SaleCard(sale: sale, canWrite: canWrite, wide: width >= 720),
            const SizedBox(height: 10),
          ],
        ];
    }
  }
}

// ---------------------------------------------------------------------------
// Encabezado
// ---------------------------------------------------------------------------

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.padding = 20});

  final Widget child;
  final double padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.slate200),
    ),
    child: child,
  );
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.day, this.compact = false});

  final DateTime day;

  /// Celular: fecha corta para que quepa el selector.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SalesCubit>();
    final now = DateTime.now();
    final isToday =
        day.year == now.year && day.month == now.month && day.day == now.day;
    return _Panel(
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 12,
        children: [
          Text(
            isToday ? 'Ventas y caja de hoy' : 'Ventas y caja',
            style: AppTypography.headlineMd.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.slate100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Día anterior',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => cubit.shiftDay(-1),
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 15,
                              color: AppColors.brandTeal,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                compact
                                    ? AppFormatters.mediumDate(day)
                                    : AppFormatters.longDate(day),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.labelMd.copyWith(
                                  color: AppColors.onSurface,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (isToday) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.brandTealLight,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'HOY',
                                  style: AppTypography.labelSm.copyWith(
                                    color: AppColors.brandTealDeep,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Día siguiente',
                      visualDensity: VisualDensity.compact,
                      onPressed: isToday ? null : () => cubit.shiftDay(1),
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Indicadores
// ---------------------------------------------------------------------------

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.state, required this.width});

  final SalesState state;
  final double width;

  @override
  Widget build(BuildContext context) {
    const gap = 12.0;
    final columns = width >= 1000
        ? 4
        : width >= 560
        ? 2
        : 1;
    final itemWidth = (width - gap * (columns - 1)) / columns;
    final pending = state.chargedToReservations;
    final cards = [
      _KpiCard(
        key: const Key('kpi-total'),
        label: 'Total vendido',
        icon: Icons.monetization_on_outlined,
        highlight: true,
        value: state.total,
        footer: Row(
          children: [
            Expanded(
              child: Text(
                '${state.count} ${state.count == 1 ? 'venta' : 'ventas'}',
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.brandTealDeep,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            _Chip(
              pending > 0
                  ? '${AppFormatters.cop(pending)} por cobrar'
                  : 'Todo cobrado',
              color: pending > 0
                  ? AppColors.statusDeposit
                  : AppColors.brandTealDeep,
            ),
          ],
        ),
      ),
      _KpiCard(
        key: const Key('kpi-walk-in'),
        label: 'Ventas sueltas',
        subtitle: 'Mostrador, cobradas en el momento',
        icon: Icons.shopping_bag_outlined,
        value: state.walkInTotal,
      ),
      _KpiCard(
        key: const Key('kpi-consumptions'),
        label: 'Consumos en reservas',
        subtitle: 'Cargados a la cuenta de la cancha',
        icon: Icons.receipt_long_outlined,
        iconColor: _sky,
        value: state.consumptionsTotal,
      ),
      _CashCountCard(state: state),
    ];
    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: [
        for (final card in cards) SizedBox(width: itemWidth, child: card),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.text, {required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      text,
      style: AppTypography.labelSm.copyWith(
        color: color,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    this.subtitle,
    this.iconColor,
    this.highlight = false,
    this.footer,
  });

  final String label;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;
  final int value;
  final bool highlight;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final accent = iconColor ?? AppColors.slate600;
    return Container(
      constraints: const BoxConstraints(minHeight: 150),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.brandTealLight
            : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight
              ? AppColors.brandTeal.withValues(alpha: 0.35)
              : AppColors.slate200,
          width: highlight ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label.toUpperCase(),
                      style: AppTypography.labelSm.copyWith(
                        color: highlight
                            ? AppColors.brandTealDeep
                            : AppColors.slate500,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    if (subtitle case final text?)
                      Text(
                        text,
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.slate400,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: (highlight ? AppColors.brandTeal : accent).withValues(
                    alpha: 0.12,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: highlight ? AppColors.brandTealDeep : accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: AppFormatters.cop(value)),
                TextSpan(
                  text: ' COP',
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.slate400,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            style: AppTypography.headlineMd.copyWith(
              color: highlight ? AppColors.brandTealDeep : AppColors.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: highlight ? 30 : 26,
            ),
          ),
          if (footer case final footer?) ...[const SizedBox(height: 8), footer],
        ],
      ),
    );
  }
}

/// Arqueo: lo cobrado por método, lo que queda en las reservas y las
/// anulaciones del día.
class _CashCountCard extends StatelessWidget {
  const _CashCountCard({required this.state});

  final SalesState state;

  @override
  Widget build(BuildContext context) {
    final row = AppTypography.bodySm.copyWith(color: AppColors.slate600);
    final amount = AppTypography.bodySm.copyWith(
      color: AppColors.onSurface,
      fontWeight: FontWeight.w700,
    );
    Widget line(Color dot, String label, String value, {TextStyle? style}) =>
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Expanded(child: Text(label, style: style ?? row)),
              Text(value, style: style ?? amount),
            ],
          ),
        );
    final methods = state.byMethod;
    return Container(
      key: const Key('kpi-cash-count'),
      constraints: const BoxConstraints(minHeight: 150),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'ARQUEO POR MÉTODOS',
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.slate500,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.credit_card_rounded,
                  size: 16,
                  color: Color(0xFF7C3AED),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (methods.isEmpty && state.chargedToReservations == 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Aún no hay cobros este día.',
                style: row.copyWith(color: AppColors.slate400),
              ),
            ),
          for (final MapEntry(key: code, value: total) in methods)
            line(
              PaymentMethod.fromApi(code).color,
              PaymentMethod.fromApi(code).label,
              AppFormatters.cop(total),
            ),
          if (state.chargedToReservations > 0)
            line(
              _sky,
              'Por cobrar en reservas',
              AppFormatters.cop(state.chargedToReservations),
            ),
          if (state.voidedCount > 0) ...[
            const SizedBox(height: 6),
            Divider(height: 1, color: AppColors.slate100),
            line(
              AppColors.statusDue,
              'Anulaciones (${state.voidedCount})',
              '−${AppFormatters.cop(state.voidedTotal)}',
              style: row.copyWith(
                color: AppColors.statusDue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filtros
// ---------------------------------------------------------------------------

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.state, required this.wide});

  final SalesState state;
  final bool wide;

  static String _methodLabel(String? code) => switch (code) {
    null => 'Métodos: todos',
    chargedToReservation => 'Cargado a reserva',
    final code => PaymentMethod.fromApi(code).label,
  };

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SalesCubit>();
    final tabs = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.slate100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            for (final (tab, label) in const [
              (SalesTab.all, 'Todas'),
              (SalesTab.walkIn, 'Ventas sueltas'),
              (SalesTab.consumptions, 'Consumos de cancha'),
              (SalesTab.voided, 'Anuladas'),
            ])
              _TabButton(
                key: Key('tab-${tab.name}'),
                label: label,
                count: state.countOf(tab),
                selected: state.tab == tab,
                danger: tab == SalesTab.voided,
                onTap: () => cubit.selectTab(tab),
              ),
          ],
        ),
      ),
    );
    final search = TextField(
      key: const Key('sales-search'),
      onChanged: cubit.search,
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Buscar producto o cliente…',
        prefixIcon: Icon(Icons.search_rounded, color: AppColors.slate400),
        contentPadding: const EdgeInsets.symmetric(vertical: 11),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.slate200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.slate200),
        ),
      ),
    );
    final methodMenu = PopupMenuButton<String?>(
      key: const Key('method-filter'),
      tooltip: 'Filtrar por método',
      onSelected: cubit.filterMethod,
      itemBuilder: (_) => [
        const PopupMenuItem<String?>(child: Text('Métodos: todos')),
        for (final code in state.methods)
          PopupMenuItem(value: code, child: Text(_methodLabel(code))),
        const PopupMenuItem(
          value: chargedToReservation,
          child: Text('Cargado a reserva'),
        ),
      ],
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: state.method == null
                ? AppColors.slate200
                : AppColors.brandTeal,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _methodLabel(state.method),
              style: AppTypography.labelMd.copyWith(
                color: AppColors.slate700,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.expand_more_rounded, color: AppColors.slate500),
          ],
        ),
      ),
    );
    final refresh = IconButton.outlined(
      key: const Key('sales-refresh'),
      tooltip: 'Actualizar',
      onPressed: () {
        cubit.load();
        context.read<CashCubit>().load();
      },
      style: IconButton.styleFrom(
        side: BorderSide(color: AppColors.slate200),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: Icon(Icons.refresh_rounded, color: AppColors.slate600),
    );
    return _Panel(
      padding: 14,
      child: wide
          ? Row(
              children: [
                Flexible(child: tabs),
                const SizedBox(width: 12),
                // El buscador ocupa el espacio que dejen las pestañas.
                Expanded(child: search),
                const SizedBox(width: 8),
                methodMenu,
                const SizedBox(width: 8),
                refresh,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                tabs,
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: search),
                    const SizedBox(width: 8),
                    refresh,
                  ],
                ),
                const SizedBox(height: 8),
                Align(alignment: Alignment.centerLeft, child: methodMenu),
              ],
            ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    super.key,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    this.danger = false,
  });

  final String label;
  final int count;
  final bool selected;
  final bool danger;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.surfaceContainerLowest : Colors.transparent,
      elevation: selected ? 1 : 0,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTypography.labelMd.copyWith(
                  color: selected ? AppColors.onSurface : AppColors.slate600,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$count',
                style: AppTypography.labelSm.copyWith(
                  color: danger && count > 0
                      ? AppColors.statusDue
                      : AppColors.slate400,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Lista de ventas
// ---------------------------------------------------------------------------

class _SaleCard extends StatelessWidget {
  const _SaleCard({
    required this.sale,
    required this.canWrite,
    required this.wide,
  });

  final Sale sale;
  final bool canWrite;
  final bool wide;

  Future<void> _void(BuildContext context) async {
    if (!ensureCanWrite(context)) return;
    final cubit = context.read<SalesCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final reason = await showVoidSaleDialog(context);
    if (reason == null) return;
    final error = await cubit.voidSale(sale.id, reason);
    // Anular devuelve el pago: cambia lo esperado en la caja.
    if (error == null && context.mounted) {
      await context.read<CashCubit>().load();
    }
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
    final voided = sale.isVoided;
    final consumption = !sale.isWalkIn;
    final method = switch (sale.paymentMethod) {
      final code? => PaymentMethod.fromApi(code),
      null => null,
    };
    final accent = voided
        ? AppColors.statusDue
        : consumption
        ? _sky
        : AppColors.brandTeal;

    final (badge, badgeColor) = voided
        ? ('Anulada', AppColors.statusDue)
        : method != null
        ? ('Cobrado · ${method.label}', method.color)
        : sale.reservationPaid
        ? ('Pagado con la reserva', AppColors.emerald600)
        : sale.isPartlyPaid
        ? ('Abonado con la reserva', AppColors.amber500)
        : ('Cargado a la reserva', _sky);

    final dot = Text(
      '•',
      style: AppTypography.bodySm.copyWith(color: AppColors.slate300),
    );
    final meta = AppTypography.bodySm.copyWith(color: AppColors.slate500);

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              consumption ? 'CONSUMO CANCHA' : 'VENTA SUELTA',
              style: AppTypography.labelSm.copyWith(
                color: voided
                    ? AppColors.statusDue
                    : consumption
                    ? _sky
                    : AppColors.slate500,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
            if (sale.customerName case final name?) ...[
              dot,
              Text(
                name,
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                badge,
                style: AppTypography.labelSm.copyWith(
                  color: badgeColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          sale.itemsLabel,
          style: AppTypography.bodyLg.copyWith(
            color: voided ? AppColors.slate400 : AppColors.onSurface,
            fontWeight: voided ? FontWeight.w500 : FontWeight.w800,
            decoration: voided ? TextDecoration.lineThrough : null,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              AppFormatters.time(sale.createdAt),
              style: meta.copyWith(
                color: AppColors.slate700,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (consumption && sale.courtName != null) ...[
              dot,
              Text(
                [
                  sale.courtName!,
                  if (sale.reservationStart case final start?)
                    'turno ${AppFormatters.time(start)}',
                ].join(' · '),
                style: meta.copyWith(color: _sky, fontWeight: FontWeight.w600),
              ),
            ],
            if (sale.note case final note?) ...[dot, Text(note, style: meta)],
            if (voided && sale.voidReason != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.dangerTint,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Motivo: ${sale.voidReason}',
                  style: meta.copyWith(
                    color: AppColors.statusDue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ],
    );

    final amountLabel = voided
        ? 'Monto anulado'
        : method != null || sale.reservationPaid
        ? 'Total pagado'
        : sale.isPartlyPaid
        ? 'Faltan ${AppFormatters.cop(sale.reservationPending)}'
        : 'Por cobrar con la reserva';
    final amount = Column(
      crossAxisAlignment: wide
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          amountLabel,
          style: AppTypography.labelSm.copyWith(
            color: voided
                ? AppColors.statusDue
                : method == null && !sale.reservationPaid
                ? _sky
                : AppColors.slate400,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: AppFormatters.cop(sale.total)),
              TextSpan(
                text: ' COP',
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.slate400,
                ),
              ),
            ],
          ),
          style: AppTypography.headlineSm.copyWith(
            color: voided ? AppColors.slate400 : AppColors.onSurface,
            fontWeight: FontWeight.w800,
            decoration: voided ? TextDecoration.lineThrough : null,
          ),
        ),
      ],
    );
    final menu = canWrite && !voided
        ? PopupMenuButton<void>(
            key: Key('sale-menu-${sale.id}'),
            tooltip: 'Opciones',
            icon: Icon(Icons.more_vert_rounded, color: AppColors.slate600),
            itemBuilder: (_) => [
              PopupMenuItem(
                key: Key('void-${sale.id}'),
                onTap: () => _void(context),
                child: Row(
                  children: [
                    Icon(
                      Icons.block_rounded,
                      size: 18,
                      color: AppColors.statusDue,
                    ),
                    const SizedBox(width: 8),
                    const Text('Anular venta'),
                  ],
                ),
              ),
            ],
          )
        : const SizedBox(width: 40);

    final leading = Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Icon(
        voided
            ? Icons.close_rounded
            : consumption
            ? Icons.stadium_outlined
            : Icons.shopping_cart_outlined,
        color: accent,
      ),
    );

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: voided
            ? AppColors.dangerTint.withValues(alpha: 0.4)
            : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: voided ? AppColors.dangerBorder : AppColors.slate200,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Franja de color de los consumos (como en el diseño).
            if (consumption && !voided) Container(width: 4, color: _sky),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                child: wide
                    ? Row(
                        children: [
                          leading,
                          const SizedBox(width: 14),
                          Expanded(child: info),
                          const SizedBox(width: 12),
                          amount,
                          const SizedBox(width: 4),
                          menu,
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              leading,
                              const SizedBox(width: 12),
                              Expanded(child: info),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Divider(height: 1, color: AppColors.slate100),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(child: amount),
                              menu,
                            ],
                          ),
                        ],
                      ),
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
