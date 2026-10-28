import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../business_payments/domain/entities/payment.dart';
import '../../../business_payments/presentation/widgets/payment_styles.dart';
import '../../domain/entities/new_sale.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/sale.dart';
import '../bloc/sale_cart_cubit.dart';
import 'product_category_style.dart';

/// Desde este ancho el punto de venta es un diálogo con el resumen al costado.
const _wideWidth = 720.0;

/// Cuántos de los primeros productos llevan la marca de "más vendido".
const _topBadges = 3;

/// Datos de la reserva que se muestran en el encabezado.
class SaleReservationInfo {
  const SaleReservationInfo({
    required this.customerName,
    required this.courtName,
    required this.start,
    required this.end,
    this.sportIcon,
  });

  final String customerName;
  final String courtName;
  final DateTime start;
  final DateTime end;
  final IconData? sportIcon;
}

/// Abre el punto de venta. Con [reservationId] carga un consumo a esa
/// reserva (se suma a su saldo o se cobra ya); sin ella es una venta suelta
/// que se cobra en el momento. Devuelve la venta registrada, o `null`.
Future<Sale?> showSaleSheet(
  BuildContext context, {
  String? reservationId,
  SaleReservationInfo? reservation,
  SaleCartCubit Function()? createCubit,
}) {
  Widget body(BuildContext _) => BlocProvider(
    create: (_) => (createCubit?.call() ?? sl<SaleCartCubit>())..load(),
    child: SaleSheetView(
      reservationId: reservationId,
      reservation: reservation,
    ),
  );

  final size = MediaQuery.sizeOf(context);
  if (size.width >= _wideWidth) {
    return showDialog<Sale>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280, maxHeight: 960),
          child: SizedBox(height: size.height * 0.94, child: body(context)),
        ),
      ),
    );
  }
  return showModalBottomSheet<Sale>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.94,
      child: body(context),
    ),
  );
}

class SaleSheetView extends StatelessWidget {
  const SaleSheetView({super.key, this.reservationId, this.reservation});

  final String? reservationId;
  final SaleReservationInfo? reservation;

  @override
  Widget build(BuildContext context) {
    return BlocListener<SaleCartCubit, SaleCartState>(
      listenWhen: (prev, curr) =>
          prev.submit != curr.submit && curr.submit == SaleCartSubmit.done,
      listener: (context, state) => Navigator.of(context).pop(state.sale),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= _wideWidth;
          final header = _Header(
            walkIn: reservationId == null,
            reservation: reservation,
            compact: !wide,
          );
          final catalog = _Catalog(wide: wide);
          if (wide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                Divider(height: 1, color: AppColors.slate200),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: catalog),
                      VerticalDivider(width: 1, color: AppColors.slate200),
                      SizedBox(
                        width: constraints.maxWidth >= 1100 ? 410 : 340,
                        child: _TicketPanel(reservationId: reservationId),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              Divider(height: 1, color: AppColors.slate200),
              Expanded(child: catalog),
              Divider(height: 1, color: AppColors.slate200),
              _CompactCheckout(reservationId: reservationId),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Encabezado
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({
    required this.walkIn,
    required this.reservation,
    required this.compact,
  });

  final bool walkIn;
  final SaleReservationInfo? reservation;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final info = reservation;
    final muted = AppTypography.bodySm.copyWith(
      color: AppColors.slate600,
      fontWeight: FontWeight.w600,
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 16 : 24,
        compact ? 4 : 12,
        12,
        compact ? 8 : 12,
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 40 : 48,
            height: compact ? 40 : 48,
            decoration: BoxDecoration(
              color: AppColors.brandTealLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.brandTeal.withValues(alpha: 0.2),
              ),
            ),
            child: Icon(
              walkIn ? Icons.point_of_sale_rounded : Icons.local_mall_outlined,
              color: AppColors.brandTealDeep,
              size: compact ? 20 : 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      walkIn ? 'Nueva venta' : 'Agregar consumo',
                      style:
                          (compact
                                  ? AppTypography.headlineSm
                                  : AppTypography.headlineMd)
                              .copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.onSurface,
                              ),
                    ),
                    if (info != null) _TurnPill(info: info),
                  ],
                ),
                const SizedBox(height: 4),
                if (info == null)
                  Text(
                    'Venta de mostrador, se cobra en el momento',
                    style: muted,
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _Meta(Icons.person_rounded, info.customerName, muted),
                      _Meta(
                        info.sportIcon ?? Icons.stadium_outlined,
                        info.courtName,
                        muted,
                        iconColor: AppColors.brandTeal,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.slate100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: _Meta(
                          Icons.schedule_rounded,
                          AppFormatters.timeRange(info.start, info.end),
                          muted.copyWith(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: AppColors.slate100,
            borderRadius: BorderRadius.circular(12),
            child: IconButton(
              tooltip: 'Cerrar',
              icon: Icon(Icons.close_rounded, color: AppColors.slate600),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta(this.icon, this.text, this.style, {this.iconColor});

  final IconData icon;
  final String text;
  final TextStyle style;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: iconColor ?? AppColors.slate400),
      const SizedBox(width: 4),
      Flexible(
        child: Text(text, style: style, overflow: TextOverflow.ellipsis),
      ),
    ],
  );
}

/// "Turno activo" mientras se juega; si no, si ya pasó o aún no empieza.
class _TurnPill extends StatelessWidget {
  const _TurnPill({required this.info});

  final SaleReservationInfo info;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final (label, color) = now.isBefore(info.start)
        ? ('Próximo turno', AppColors.slate500)
        : now.isBefore(info.end)
        ? ('Turno activo', AppColors.emerald600)
        : ('Turno terminado', AppColors.slate500);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.labelSm.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Catálogo: buscador, categorías y cuadrícula
// ---------------------------------------------------------------------------

class _Catalog extends StatelessWidget {
  const _Catalog({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.slate50,
      child: BlocBuilder<SaleCartCubit, SaleCartState>(
        buildWhen: (prev, curr) =>
            prev.load != curr.load ||
            prev.products != curr.products ||
            prev.query != curr.query ||
            prev.category != curr.category,
        builder: (context, state) {
          switch (state.load) {
            case SaleCartLoad.loading:
              return const Center(child: CircularProgressIndicator());
            case SaleCartLoad.failure:
              return _Message(
                icon: Icons.wifi_off_rounded,
                text: 'No pudimos cargar los productos.',
                action: TextButton(
                  onPressed: () => context.read<SaleCartCubit>().load(),
                  child: const Text('Reintentar'),
                ),
              );
            case SaleCartLoad.ready when state.products.isEmpty:
              return const _Message(
                icon: Icons.inventory_2_outlined,
                text:
                    'Aún no tienes productos. Créalos en Ventas › Productos '
                    '(agua, bebidas, snacks…).',
              );
            case SaleCartLoad.ready:
              final visible = state.visibleProducts;
              // El "Top" sale del orden general, no del filtrado.
              final ranks = {
                for (final (i, p) in state.products.take(_topBadges).indexed)
                  if (p.sold > 0) p.id: i + 1,
              };
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Toolbar(state: state, wide: wide),
                  Divider(height: 1, color: AppColors.slate200),
                  Expanded(
                    child: visible.isEmpty
                        ? const _Message(
                            icon: Icons.search_off_rounded,
                            text: 'Ningún producto coincide con la búsqueda.',
                          )
                        : GridView.builder(
                            padding: EdgeInsets.all(wide ? 16 : 12),
                            gridDelegate:
                                SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: wide ? 210 : 200,
                                  mainAxisExtent: wide ? 118 : 132,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                ),
                            itemCount: visible.length,
                            itemBuilder: (_, i) => _ProductCard(
                              product: visible[i],
                              rank: ranks[visible[i].id],
                            ),
                          ),
                  ),
                ],
              );
          }
        },
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.state, required this.wide});

  final SaleCartState state;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SaleCartCubit>();
    final hasSales = state.products.any((p) => p.sold > 0);
    final search = TextField(
      key: const Key('product-search'),
      onChanged: cubit.search,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Buscar bebida, snack o alquiler…',
        prefixIcon: Icon(Icons.search_rounded, color: AppColors.slate400),
        filled: true,
        fillColor: AppColors.slate50,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.slate200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.slate200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.brandTeal, width: 2),
        ),
      ),
    );
    final banner = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.amber500.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.amber500.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            size: 16,
            color: AppColors.amber500,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Los más vendidos de los últimos 30 días van primero',
              style: AppTypography.labelSm.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    return Container(
      color: AppColors.surfaceContainerLowest,
      padding: EdgeInsets.fromLTRB(
        wide ? 20 : 12,
        wide ? 14 : 8,
        wide ? 20 : 12,
        wide ? 12 : 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (wide)
            Row(
              children: [
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: search,
                  ),
                ),
                if (hasSales) ...[
                  const SizedBox(width: 12),
                  Flexible(child: banner),
                ],
              ],
            )
          else
            search,
          SizedBox(height: wide ? 12 : 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _CategoryChip(
                  key: const Key('category-all'),
                  icon: Icons.grid_view_rounded,
                  label: 'Todos (${state.products.length})',
                  selected: state.category == null,
                  onTap: () => cubit.filterCategory(null),
                ),
                for (final MapEntry(key: category, value: count)
                    in state.categoryCounts.entries) ...[
                  const SizedBox(width: 8),
                  _CategoryChip(
                    key: Key('category-${category.apiCode}'),
                    icon: category.icon,
                    iconColor: category.color,
                    label: '${category.label} ($count)',
                    selected: state.category == category,
                    onTap: () => cubit.filterCategory(category),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.brandTealDeep
          : AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.brandTealDeep : AppColors.slate200,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected
                    ? Colors.white
                    : iconColor ?? AppColors.slate600,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.labelMd.copyWith(
                  color: selected ? Colors.white : AppColors.slate700,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.slate400),
            const SizedBox(height: 10),
            Text(
              text,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMd.copyWith(color: AppColors.slate600),
            ),
            ?action,
          ],
        ),
      ),
    );
  }
}

/// Tarjeta compacta de un producto: ícono a la izquierda, nombre y precio,
/// y abajo "Agregar" o − cantidad +. Tocarla suma una unidad.
class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, this.rank});

  final Product product;

  /// Puesto entre los más vendidos (1, 2, 3) o `null`.
  final int? rank;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SaleCartCubit>();
    final category = product.category;
    return BlocSelector<SaleCartCubit, SaleCartState, int>(
      selector: (state) => state.quantityOf(product.id),
      builder: (context, quantity) {
        final selected = quantity > 0;
        return Material(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            key: Key('product-${product.id}'),
            borderRadius: BorderRadius.circular(14),
            onTap: () => cubit.add(product.id),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? AppColors.brandTeal : AppColors.slate200,
                  width: selected ? 2 : 1,
                ),
              ),
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: category.tint,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          category.icon,
                          color: category.color,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodySm.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              AppFormatters.cop(product.price),
                              style: AppTypography.labelMd.copyWith(
                                color: selected
                                    ? AppColors.brandTealDeep
                                    : AppColors.slate600,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (rank case final rank?)
                        Container(
                          key: Key('top-${product.id}'),
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.amber500,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 10,
                                color: Colors.white,
                              ),
                              Text(
                                '$rank',
                                style: AppTypography.labelSm.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 30,
                    child: selected
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _RoundButton(
                                key: Key('remove-${product.id}'),
                                icon: Icons.remove_rounded,
                                tooltip: 'Quitar uno',
                                onTap: () => cubit.remove(product.id),
                              ),
                              Text(
                                '$quantity',
                                style: AppTypography.bodyMd.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              _RoundButton(
                                key: Key('add-${product.id}'),
                                icon: Icons.add_rounded,
                                tooltip: 'Agregar uno',
                                filled: true,
                                onTap: () => cubit.add(product.id),
                              ),
                            ],
                          )
                        : TextButton.icon(
                            key: Key('add-${product.id}'),
                            onPressed: () => cubit.add(product.id),
                            style: TextButton.styleFrom(
                              backgroundColor: AppColors.slate100,
                              foregroundColor: AppColors.slate700,
                              padding: EdgeInsets.zero,
                              textStyle: AppTypography.labelMd.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text('Agregar'),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: filled ? AppColors.brandTeal : AppColors.slate100,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox.square(
            dimension: 30,
            child: Icon(
              icon,
              size: 18,
              color: filled ? Colors.white : AppColors.slate700,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Resumen y cobro
// ---------------------------------------------------------------------------

/// Resumen al costado (pantallas anchas).
class _TicketPanel extends StatelessWidget {
  const _TicketPanel({this.reservationId});

  final String? reservationId;

  @override
  Widget build(BuildContext context) {
    final walkIn = reservationId == null;
    return ColoredBox(
      color: AppColors.slate50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: AppColors.surfaceContainerLowest,
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.brandTealLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    size: 16,
                    color: AppColors.brandTealDeep,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        walkIn ? 'RESUMEN DE VENTA' : 'RESUMEN DE CONSUMO',
                        style: AppTypography.labelMd.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                      Text(
                        walkIn
                            ? 'Se cobra en el momento'
                            : 'Cuenta de consumo del turno',
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.slate500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                BlocSelector<SaleCartCubit, SaleCartState, bool>(
                  selector: (s) => s.isEmpty,
                  builder: (context, empty) => TextButton.icon(
                    key: const Key('clear-cart'),
                    onPressed: empty
                        ? null
                        : () => context.read<SaleCartCubit>().clear(),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.statusDue,
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 16),
                    label: const Text('Vaciar'),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.slate200),
          const Expanded(child: _CartLines()),
          Divider(height: 1, color: AppColors.slate200),
          _Checkout(reservationId: reservationId),
        ],
      ),
    );
  }
}

class _CartLines extends StatelessWidget {
  const _CartLines();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SaleCartCubit, SaleCartState>(
      buildWhen: (prev, curr) =>
          prev.quantities != curr.quantities || prev.products != curr.products,
      builder: (context, state) {
        final lines = [
          for (final p in state.products)
            if (state.quantityOf(p.id) > 0) (p, state.quantityOf(p.id)),
        ];
        if (lines.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shopping_basket_outlined,
                    size: 36,
                    color: AppColors.slate300,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aún no has agregado productos.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.slate400,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(14),
          itemCount: lines.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final (product, quantity) = lines[i];
            final category = product.category;
            return Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.slate200),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: category.tint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(category.icon, size: 18, color: category.color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$quantity × ${product.name}',
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySm.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                        Text(
                          quantity > 1
                              ? '${AppFormatters.cop(product.price)} c/u'
                              : category.label,
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.slate400,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    AppFormatters.cop(product.price * quantity),
                    style: AppTypography.bodySm.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Quitar',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => context.read<SaleCartCubit>().setQuantity(
                      product.id,
                      0,
                    ),
                    icon: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: AppColors.slate400,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// "Cargar al turno" o "Cobrar ya" (solo en un consumo de reserva).
class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.chargeNow});

  final bool chargeNow;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SaleCartCubit>();
    Widget option(String label, IconData icon, bool value, Key key) {
      final selected = chargeNow == value;
      return Expanded(
        child: Material(
          color: selected
              ? AppColors.surfaceContainerLowest
              : Colors.transparent,
          elevation: selected ? 1 : 0,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            key: key,
            borderRadius: BorderRadius.circular(10),
            onTap: () => cubit.setChargeNow(value),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: selected
                        ? AppColors.brandTealDeep
                        : AppColors.slate500,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelMd.copyWith(
                        color: selected
                            ? AppColors.brandTealDeep
                            : AppColors.slate600,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.slate100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          option(
            'Cargar al turno',
            Icons.request_quote_outlined,
            false,
            const Key('mode-charge-later'),
          ),
          option(
            'Cobrar ya',
            Icons.payments_outlined,
            true,
            const Key('mode-charge-now'),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethods extends StatelessWidget {
  const _PaymentMethods({required this.selected, this.singleLine = false});

  final String selected;

  /// Una fila que se desplaza de lado (celular) en vez de varias filas.
  final bool singleLine;

  @override
  Widget build(BuildContext context) {
    final chips = [
      for (final method in PaymentMethod.selectable)
        ChoiceChip(
          key: Key('method-${method.apiCode}'),
          avatar: Icon(method.icon, size: 16, color: method.color),
          label: Text(method.label),
          selected: selected == method.apiCode,
          onSelected: (_) => context.read<SaleCartCubit>().selectPaymentMethod(
            method.apiCode!,
          ),
        ),
    ];
    if (singleLine) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final chip in chips) ...[chip, const SizedBox(width: 8)],
          ],
        ),
      );
    }
    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }
}

/// Botón de nota: muestra un diálogo y guarda el texto en el carrito.
class _NoteButton extends StatelessWidget {
  const _NoteButton({required this.note, this.iconOnly = false});

  final String note;
  final bool iconOnly;

  Future<void> _edit(BuildContext context) async {
    final cubit = context.read<SaleCartCubit>();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _NoteDialog(initial: note),
    );
    if (result != null) cubit.setNote(result);
  }

  @override
  Widget build(BuildContext context) {
    final hasNote = note.isNotEmpty;
    final icon = Icon(
      hasNote ? Icons.sticky_note_2_rounded : Icons.sticky_note_2_outlined,
      size: 18,
      color: hasNote ? AppColors.brandTeal : AppColors.slate500,
    );
    if (iconOnly) {
      return IconButton(
        key: const Key('open-note'),
        tooltip: hasNote ? 'Nota: $note' : 'Agregar nota',
        onPressed: () => _edit(context),
        icon: icon,
      );
    }
    return OutlinedButton.icon(
      key: const Key('open-note'),
      onPressed: () => _edit(context),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.slate700,
        side: BorderSide(color: AppColors.slate200),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.centerLeft,
      ),
      icon: icon,
      label: Text(
        hasNote ? note : 'Agregar nota',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Diálogo de la nota; es dueño de su controlador (se libera al cerrarse).
class _NoteDialog extends StatefulWidget {
  const _NoteDialog({required this.initial});

  final String initial;

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Nota de la venta'),
      content: TextField(
        key: const Key('sale-note'),
        controller: _controller,
        autofocus: true,
        maxLength: NewSale.maxNote,
        maxLines: 3,
        decoration: const InputDecoration(
          hintText: 'Ej. Las cervezas bien frías, sin hielo',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('sale-note-save'),
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

String _verb(String? reservationId, bool chargeNow, int total) {
  final amount = AppFormatters.cop(total);
  if (reservationId != null && !chargeNow) {
    return total == 0 ? 'Cargar a la cuenta' : 'Cargar $amount a la cuenta';
  }
  return total == 0 ? 'Cobrar' : 'Cobrar $amount';
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.state, required this.reservationId});

  final SaleCartState state;
  final String? reservationId;

  @override
  Widget build(BuildContext context) {
    final sending = state.submit == SaleCartSubmit.sending;
    return FilledButton.icon(
      key: const Key('submit-sale'),
      onPressed: state.isEmpty || sending
          ? null
          : () => context.read<SaleCartCubit>().submit(
              reservationId: reservationId,
            ),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.brandTeal,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: AppTypography.labelLg.copyWith(fontWeight: FontWeight.w800),
      ),
      icon: sending
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.check_circle_rounded, size: 20),
      label: Text(_verb(reservationId, state.chargeNow, state.total)),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      message,
      style: AppTypography.bodySm.copyWith(
        color: AppColors.statusDue,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

/// Pie del panel lateral: modo, método de pago, totales, confirmar y nota.
class _Checkout extends StatelessWidget {
  const _Checkout({this.reservationId});

  final String? reservationId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SaleCartCubit, SaleCartState>(
      buildWhen: (prev, curr) =>
          prev.quantities != curr.quantities ||
          prev.submit != curr.submit ||
          prev.message != curr.message ||
          prev.products != curr.products ||
          prev.chargeNow != curr.chargeNow ||
          prev.paymentMethod != curr.paymentMethod ||
          prev.note != curr.note,
      builder: (context, state) {
        final payNow = reservationId == null || state.chargeNow;
        final label = AppTypography.bodySm.copyWith(color: AppColors.slate600);
        return Container(
          color: AppColors.surfaceContainerLowest,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (reservationId != null) ...[
                _ModeToggle(chargeNow: state.chargeNow),
                const SizedBox(height: 12),
              ],
              if (payNow) ...[
                Text(
                  'MÉTODO DE PAGO',
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.slate500,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                // Una fila: así el resumen conserva espacio para la lista.
                _PaymentMethods(
                  selected: state.paymentMethod,
                  singleLine: true,
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(child: Text('Unidades', style: label)),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.slate100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${state.units} '
                      '${state.units == 1 ? 'unidad' : 'unidades'}',
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Divider(height: 1, color: AppColors.slate200),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(
                      payNow ? 'Total a cobrar' : 'Total a sumar al turno',
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    AppFormatters.cop(state.total),
                    style: AppTypography.headlineMd.copyWith(
                      color: AppColors.brandTealDeep,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (state.message case final message?) _ErrorText(message),
              _SubmitButton(state: state, reservationId: reservationId),
              const SizedBox(height: 8),
              _NoteButton(note: state.note),
            ],
          ),
        );
      },
    );
  }
}

/// Pie en celular: modo, método de pago en una fila, total y confirmar.
class _CompactCheckout extends StatelessWidget {
  const _CompactCheckout({this.reservationId});

  final String? reservationId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SaleCartCubit, SaleCartState>(
      buildWhen: (prev, curr) =>
          prev.quantities != curr.quantities ||
          prev.submit != curr.submit ||
          prev.message != curr.message ||
          prev.products != curr.products ||
          prev.chargeNow != curr.chargeNow ||
          prev.paymentMethod != curr.paymentMethod ||
          prev.note != curr.note,
      builder: (context, state) {
        final payNow = reservationId == null || state.chargeNow;
        return Container(
          color: AppColors.surfaceContainerLowest,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (reservationId != null) ...[
                _ModeToggle(chargeNow: state.chargeNow),
                const SizedBox(height: 8),
              ],
              if (payNow) ...[
                _PaymentMethods(
                  selected: state.paymentMethod,
                  singleLine: true,
                ),
                const SizedBox(height: 8),
              ],
              if (state.message case final message?) _ErrorText(message),
              Row(
                children: [
                  _NoteButton(note: state.note, iconOnly: true),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _SubmitButton(
                      state: state,
                      reservationId: reservationId,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
