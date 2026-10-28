import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../business_payments/domain/entities/payment.dart';
import '../../../business_payments/presentation/widgets/payment_styles.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/sale.dart';
import '../bloc/sale_cart_cubit.dart';
import 'product_category_style.dart';

/// Desde este ancho el carrito es un diálogo con el resumen al costado.
const _wideWidth = 720.0;

/// Cuántos de los primeros productos llevan la marca de "más vendido".
const _topBadges = 3;

/// Abre el carrito de productos. Con [reservationId] carga un consumo a esa
/// reserva (se cobra con su saldo); sin ella es una venta suelta que se
/// cobra en el momento. Devuelve la venta registrada, o `null`.
Future<Sale?> showSaleSheet(
  BuildContext context, {
  String? reservationId,
  String? subtitle,
  SaleCartCubit Function()? createCubit,
}) {
  Widget body(BuildContext _) => BlocProvider(
    create: (_) => (createCubit?.call() ?? sl<SaleCartCubit>())..load(),
    child: SaleSheetView(reservationId: reservationId, subtitle: subtitle),
  );

  final size = MediaQuery.sizeOf(context);
  if (size.width >= _wideWidth) {
    return showDialog<Sale>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: SizedBox(height: size.height * 0.88, child: body(context)),
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
  const SaleSheetView({super.key, this.reservationId, this.subtitle});

  final String? reservationId;
  final String? subtitle;

  bool get _isWalkIn => reservationId == null;

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
            title: _isWalkIn ? 'Nueva venta' : 'Agregar consumo',
            subtitle: subtitle,
          );
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
                      const Expanded(child: _ProductGrid()),
                      VerticalDivider(width: 1, color: AppColors.slate200),
                      SizedBox(
                        width: 320,
                        child: _CartPanel(reservationId: reservationId),
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
              const Expanded(child: _ProductGrid()),
              if (_isWalkIn) ...[
                Divider(height: 1, color: AppColors.slate200),
                // Una sola fila: en celulares pequeños no tapa la cuadrícula.
                const _PaymentMethods(singleLine: true),
              ],
              Divider(height: 1, color: AppColors.slate200),
              _Footer(reservationId: reservationId),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 8, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.brandTealLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.add_shopping_cart_rounded,
              color: AppColors.brandTealDeep,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTypography.headlineSm.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
                if (subtitle case final text?)
                  Text(
                    text,
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.slate500,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Cerrar',
            icon: Icon(Icons.close_rounded, color: AppColors.slate600),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

/// Cuadrícula de productos: los más vendidos primero (orden de la API).
class _ProductGrid extends StatelessWidget {
  const _ProductGrid();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SaleCartCubit, SaleCartState>(
      buildWhen: (prev, curr) =>
          prev.load != curr.load || prev.products != curr.products,
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
            final hasSales = state.products.any((p) => p.sold > 0);
            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      hasSales
                          ? 'Los más vendidos de los últimos 30 días van '
                                'primero. Toca un producto para sumarlo.'
                          : 'Toca un producto para sumarlo.',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.slate500,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  sliver: SliverGrid.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 180,
                          mainAxisExtent: 200,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                    itemCount: state.products.length,
                    itemBuilder: (_, i) {
                      final product = state.products[i];
                      return _ProductCard(
                        product: product,
                        rank: i < _topBadges && product.sold > 0 ? i + 1 : null,
                      );
                    },
                  ),
                ),
              ],
            );
        }
      },
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

/// Tarjeta de un producto: tocarla suma una unidad; abajo, − cantidad +.
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
          color: selected
              ? AppColors.brandTealLight
              : AppColors.surfaceContainerLowest,
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
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 6),
                      Center(
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: category.tint,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            category.icon,
                            color: category.color,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Text(
                          product.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMd.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                            height: 1.2,
                          ),
                        ),
                      ),
                      Text(
                        AppFormatters.cop(product.price),
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.slate600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (selected) ...[
                            IconButton(
                              key: Key('remove-${product.id}'),
                              tooltip: 'Quitar uno',
                              visualDensity: VisualDensity.compact,
                              onPressed: () => cubit.remove(product.id),
                              icon: const Icon(Icons.remove_circle_outline),
                              color: AppColors.slate600,
                            ),
                            SizedBox(
                              width: 28,
                              child: Text(
                                '$quantity',
                                textAlign: TextAlign.center,
                                style: AppTypography.bodyLg.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ),
                          ],
                          IconButton(
                            key: Key('add-${product.id}'),
                            tooltip: 'Agregar uno',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => cubit.add(product.id),
                            icon: const Icon(Icons.add_circle),
                            color: AppColors.brandTeal,
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (rank case final rank?)
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        key: Key('top-${product.id}'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
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
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              'Top $rank',
                              style: AppTypography.labelSm.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
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

/// Resumen al costado (pantallas anchas): productos elegidos, método de
/// pago en una venta suelta, total y confirmar.
class _CartPanel extends StatelessWidget {
  const _CartPanel({this.reservationId});

  final String? reservationId;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.slate50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Text(
              'RESUMEN',
              style: AppTypography.labelSm.copyWith(
                color: AppColors.slate500,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Expanded(child: _CartLines()),
          if (reservationId == null) ...[
            Divider(height: 1, color: AppColors.slate200),
            const _PaymentMethods(),
          ],
          Divider(height: 1, color: AppColors.slate200),
          _Footer(reservationId: reservationId, stacked: true),
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
              child: Text(
                'Aún no has agregado productos.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySm.copyWith(color: AppColors.slate400),
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 4, 8, 12),
          itemCount: lines.length,
          separatorBuilder: (_, _) => const SizedBox(height: 4),
          itemBuilder: (context, i) {
            final (product, quantity) = lines[i];
            return Row(
              children: [
                Icon(
                  product.category.icon,
                  size: 16,
                  color: product.category.color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$quantity × ${product.name}',
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySm.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
                Text(
                  AppFormatters.cop(product.price * quantity),
                  style: AppTypography.bodySm.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                IconButton(
                  tooltip: 'Quitar',
                  visualDensity: VisualDensity.compact,
                  onPressed: () =>
                      context.read<SaleCartCubit>().setQuantity(product.id, 0),
                  icon: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: AppColors.slate400,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _PaymentMethods extends StatelessWidget {
  const _PaymentMethods({this.singleLine = false});

  /// Una fila que se desplaza de lado en vez de varias filas.
  final bool singleLine;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<SaleCartCubit, SaleCartState, String>(
      selector: (state) => state.paymentMethod,
      builder: (context, selected) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          singleLine ? 8 : 10,
          16,
          singleLine ? 8 : 12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MÉTODO DE PAGO',
              style: AppTypography.labelSm.copyWith(
                color: AppColors.slate500,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            if (singleLine)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final chip in _chips(context, selected)) ...[
                      chip,
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _chips(context, selected),
              ),
          ],
        ),
      ),
    );
  }
}

List<Widget> _chips(BuildContext context, String selected) => [
  for (final method in PaymentMethod.selectable)
    ChoiceChip(
      key: Key('method-${method.apiCode}'),
      avatar: Icon(method.icon, size: 16, color: method.color),
      label: Text(method.label),
      selected: selected == method.apiCode,
      onSelected: (_) =>
          context.read<SaleCartCubit>().selectPaymentMethod(method.apiCode!),
    ),
];

class _Footer extends StatelessWidget {
  const _Footer({this.reservationId, this.stacked = false});

  final String? reservationId;

  /// En el panel lateral: total arriba y el botón a todo el ancho.
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SaleCartCubit, SaleCartState>(
      buildWhen: (prev, curr) =>
          prev.quantities != curr.quantities ||
          prev.submit != curr.submit ||
          prev.message != curr.message ||
          prev.products != curr.products,
      builder: (context, state) {
        final sending = state.submit == SaleCartSubmit.sending;
        final verb = reservationId == null ? 'Cobrar' : 'Agregar';
        final summary = Text(
          state.isEmpty
              ? 'Toca un producto para agregarlo'
              : '${state.units} '
                    '${state.units == 1 ? 'unidad' : 'unidades'}',
          style: AppTypography.bodySm.copyWith(
            color: AppColors.slate600,
            fontWeight: FontWeight.w600,
          ),
        );
        final button = FilledButton.icon(
          key: const Key('submit-sale'),
          onPressed: state.isEmpty || sending
              ? null
              : () => context.read<SaleCartCubit>().submit(
                  reservationId: reservationId,
                ),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.brandTeal,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 48),
          ),
          icon: sending
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check_rounded, size: 18),
          label: Text(
            state.isEmpty ? verb : '$verb ${AppFormatters.cop(state.total)}',
          ),
        );
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          color: AppColors.slate50,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.message case final message?) ...[
                Text(
                  message,
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.statusDue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (stacked) ...[
                summary,
                const SizedBox(height: 8),
                button,
              ] else
                Row(
                  children: [
                    Expanded(child: summary),
                    button,
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
