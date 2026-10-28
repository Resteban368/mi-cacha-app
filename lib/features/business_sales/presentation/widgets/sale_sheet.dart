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

  if (MediaQuery.sizeOf(context).width >= 600) {
    return showDialog<Sale>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 760),
          child: body(context),
        ),
      ),
    );
  }
  return showModalBottomSheet<Sale>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            title: _isWalkIn ? 'Nueva venta' : 'Agregar consumo',
            subtitle: subtitle,
          ),
          Divider(height: 1, color: AppColors.slate200),
          const Flexible(child: _ProductList()),
          if (_isWalkIn) const _PaymentMethods(),
          Divider(height: 1, color: AppColors.slate200),
          _Footer(reservationId: reservationId),
        ],
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
              Icons.local_drink_outlined,
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

class _ProductList extends StatelessWidget {
  const _ProductList();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SaleCartCubit, SaleCartState>(
      buildWhen: (prev, curr) =>
          prev.load != curr.load || prev.products != curr.products,
      builder: (context, state) {
        switch (state.load) {
          case SaleCartLoad.loading:
            return const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            );
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
            return ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: state.products.length,
              separatorBuilder: (_, _) => const SizedBox(height: 6),
              itemBuilder: (_, i) => _ProductRow(product: state.products[i]),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 36, color: AppColors.slate400),
          const SizedBox(height: 10),
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

/// Fila de un producto: tocarla suma una unidad; los botones suman o restan.
class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SaleCartCubit>();
    return BlocSelector<SaleCartCubit, SaleCartState, int>(
      selector: (state) => state.quantityOf(product.id),
      builder: (context, quantity) {
        final selected = quantity > 0;
        return Material(
          color: selected ? AppColors.brandTealLight : AppColors.slate50,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            key: Key('product-${product.id}'),
            borderRadius: BorderRadius.circular(12),
            onTap: () => cubit.add(product.id),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? AppColors.brandTeal : AppColors.slate200,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: AppTypography.bodyMd.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                        Text(
                          selected
                              ? '${AppFormatters.cop(product.price)} c/u · '
                                    '${AppFormatters.cop(product.price * quantity)}'
                              : AppFormatters.cop(product.price),
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.slate500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (selected) ...[
                    IconButton(
                      key: Key('remove-${product.id}'),
                      tooltip: 'Quitar uno',
                      onPressed: () => cubit.remove(product.id),
                      icon: const Icon(Icons.remove_circle_outline),
                      color: AppColors.slate600,
                    ),
                    SizedBox(
                      width: 32,
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
                    onPressed: () => cubit.add(product.id),
                    icon: const Icon(Icons.add_circle),
                    color: AppColors.brandTeal,
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

class _PaymentMethods extends StatelessWidget {
  const _PaymentMethods();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<SaleCartCubit, SaleCartState, String>(
      selector: (state) => state.paymentMethod,
      builder: (context, selected) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final method in PaymentMethod.selectable)
                  ChoiceChip(
                    key: Key('method-${method.apiCode}'),
                    avatar: Icon(method.icon, size: 16, color: method.color),
                    label: Text(method.label),
                    selected: selected == method.apiCode,
                    onSelected: (_) => context
                        .read<SaleCartCubit>()
                        .selectPaymentMethod(method.apiCode!),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({this.reservationId});

  final String? reservationId;

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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      state.isEmpty
                          ? 'Toca un producto para agregarlo'
                          : '${state.units} '
                                '${state.units == 1 ? 'unidad' : 'unidades'}',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.slate600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    key: const Key('submit-sale'),
                    onPressed: state.isEmpty || sending
                        ? null
                        : () => context.read<SaleCartCubit>().submit(
                            reservationId: reservationId,
                          ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brandTeal,
                      foregroundColor: Colors.white,
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
                      state.isEmpty
                          ? verb
                          : '$verb ${AppFormatters.cop(state.total)}',
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
