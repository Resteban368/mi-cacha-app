import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/session/business_modules.dart';
import '../../../../core/session/write_access.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../domain/entities/product.dart';
import '../bloc/inventory_cubit.dart';
import '../widgets/inventory_dialogs.dart';
import '../widgets/product_category_style.dart';
import '../widgets/sales_module_locked.dart';

/// Inventario: existencias de los productos, alertas, entradas de mercancía,
/// ajustes por conteo físico e historial.
class InventoryPage extends StatelessWidget {
  const InventoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final topBar = AppTopBar(
      title: 'Inventario',
      subtitle: 'Stock de tus productos',
      icon: Icons.inventory_2_rounded,
    );
    if (!BusinessModulesScope.salesOf(context)) {
      return Column(
        children: [
          topBar,
          const Expanded(child: SalesModuleLocked()),
        ],
      );
    }
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Column(
      children: [
        topBar,
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: BlocBuilder<InventoryCubit, InventoryState>(
              builder: (context, state) => switch (state.load) {
                InventoryLoad.loading => const Center(
                  child: CircularProgressIndicator(),
                ),
                InventoryLoad.failure => Center(
                  child: TextButton.icon(
                    onPressed: () => context.read<InventoryCubit>().load(),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text(
                      'No pudimos cargar el inventario. Reintentar',
                    ),
                  ),
                ),
                InventoryLoad.ready => RefreshIndicator(
                  onRefresh: context.read<InventoryCubit>().load,
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        sliver: SliverToBoxAdapter(
                          child: _Centered(child: _Header(state: state)),
                        ),
                      ),
                      if (state.overview.items.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Text(
                                'Primero crea tus productos en Ventas → '
                                'Productos.',
                                textAlign: TextAlign.center,
                                style: AppTypography.bodyMd.copyWith(
                                  color: AppColors.slate600,
                                ),
                              ),
                            ),
                          ),
                        )
                      else if (state.visible.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              'Ningún producto coincide.',
                              textAlign: TextAlign.center,
                              style: AppTypography.bodyMd.copyWith(
                                color: AppColors.slate600,
                              ),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            16,
                            12,
                            16,
                            bottomInset + 32,
                          ),
                          sliver: SliverList.separated(
                            itemCount: state.visible.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, i) => _Centered(
                              child: _ProductStockTile(
                                product: state.visible[i],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _Centered extends StatelessWidget {
  const _Centered({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 960),
      child: child,
    ),
  );
}

/// Indicadores, acciones generales, filtros y búsqueda.
class _Header extends StatelessWidget {
  const _Header({required this.state});

  final InventoryState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<InventoryCubit>();
    final overview = state.overview;
    final canWrite = WriteAccessScope.canWrite(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final cards = [
              _StatCard(
                key: const Key('stat-tracked'),
                label: 'Con control de stock',
                value: '${overview.tracked}',
                caption: 'de ${overview.items.length} productos',
                icon: Icons.inventory_2_outlined,
                color: AppColors.brandTeal,
                tint: AppColors.brandTealLight,
              ),
              _StatCard(
                key: const Key('stat-low'),
                label: 'Stock bajo',
                value: '${overview.low}',
                caption: 'en el mínimo o por debajo',
                icon: Icons.trending_down_rounded,
                color: AppColors.warningInk,
                tint: AppColors.warningTint,
              ),
              _StatCard(
                key: const Key('stat-out'),
                label: 'Agotados',
                value: '${overview.out}',
                caption: 'no se pueden vender',
                icon: Icons.remove_shopping_cart_outlined,
                color: AppColors.statusDue,
                tint: AppColors.dangerTint,
              ),
            ];
            if (constraints.maxWidth < 560) {
              return Column(
                children: [
                  for (final card in cards) ...[
                    card,
                    if (card != cards.last) const SizedBox(height: 8),
                  ],
                ],
              );
            }
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final card in cards) ...[
                    Expanded(child: card),
                    if (card != cards.last) const SizedBox(width: 12),
                  ],
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          children: [
            OutlinedButton.icon(
              key: const Key('inventory-history'),
              onPressed: () => showStockHistory(context),
              icon: const Icon(Icons.history_rounded, size: 18),
              label: const Text('Historial'),
            ),
            if (canWrite)
              FilledButton.icon(
                key: const Key('inventory-entry'),
                onPressed: overview.items.isEmpty
                    ? null
                    : () => showStockEntryDialog(context),
                icon: const Icon(Icons.move_to_inbox_rounded, size: 18),
                label: const Text('Entrada de mercancía'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('inventory-search'),
          onChanged: cubit.search,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Buscar producto',
            prefixIcon: Icon(Icons.search_rounded),
            isDense: true,
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final (filter, label) in const [
                (InventoryFilter.all, 'Todos'),
                (InventoryFilter.low, 'Stock bajo'),
                (InventoryFilter.out, 'Agotados'),
                (InventoryFilter.untracked, 'Sin control'),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    key: Key('inventory-filter-${filter.name}'),
                    label: Text('$label ${state.countOf(filter)}'),
                    selected: state.filter == filter,
                    onSelected: (_) => cubit.filter(filter),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.caption,
    required this.icon,
    required this.color,
    required this.tint,
  });

  final String label;
  final String value;
  final String caption;
  final IconData icon;
  final Color color;
  final Color tint;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.slate200),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.slate500,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                value,
                style: AppTypography.headlineMd.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                caption,
                style: AppTypography.bodySm.copyWith(
                  fontSize: 11,
                  color: AppColors.slate500,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

enum _Action { entry, adjust, alert, history }

class _ProductStockTile extends StatelessWidget {
  const _ProductStockTile({required this.product});

  final Product product;

  void _run(BuildContext context, _Action action) => switch (action) {
    _Action.entry => showStockEntryDialog(context, product: product),
    _Action.adjust => showStockAdjustDialog(context, product),
    _Action.alert => showStockAlertDialog(context, product),
    _Action.history => showStockHistory(context, product: product),
  };

  @override
  Widget build(BuildContext context) {
    final p = product;
    final canWrite = WriteAccessScope.canWrite(context);
    final (badge, badgeColor, badgeTint) = !p.trackStock
        ? ('Sin control', AppColors.slate600, AppColors.slate100)
        : p.isOut
        ? ('Agotado', AppColors.statusDue, AppColors.dangerTint)
        : p.isLow
        ? ('Stock bajo', AppColors.warningInk, AppColors.warningTint)
        : ('Disponible', AppColors.emerald600, AppColors.successTint);
    return Material(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        key: Key('inventory-${p.id}'),
        borderRadius: BorderRadius.circular(12),
        onTap: () => _run(context, _Action.history),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: p.isLow && p.trackStock
                  ? badgeColor.withValues(alpha: 0.4)
                  : AppColors.slate200,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: p.category.tint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(p.category.icon, color: p.category.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMd.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: badgeTint,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            badge,
                            style: AppTypography.labelSm.copyWith(
                              fontSize: 10,
                              color: badgeColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          [
                            AppFormatters.cop(p.price),
                            if (p.trackStock && p.minStock != null)
                              'mínimo ${p.minStock}',
                          ].join(' · '),
                          style: AppTypography.bodySm.copyWith(
                            fontSize: 11,
                            color: AppColors.slate500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (p.trackStock)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${p.stock}',
                      key: Key('inventory-stock-${p.id}'),
                      style: AppTypography.headlineSm.copyWith(
                        fontWeight: FontWeight.w800,
                        color: p.isLow ? badgeColor : AppColors.onSurface,
                      ),
                    ),
                    Text(
                      'und',
                      style: AppTypography.labelSm.copyWith(
                        fontSize: 10,
                        color: AppColors.slate500,
                      ),
                    ),
                  ],
                ),
              PopupMenuButton<_Action>(
                key: Key('inventory-menu-${p.id}'),
                tooltip: 'Acciones',
                icon: Icon(Icons.more_vert_rounded, color: AppColors.slate500),
                onSelected: (action) => _run(context, action),
                itemBuilder: (_) => [
                  if (canWrite) ...[
                    const PopupMenuItem(
                      value: _Action.entry,
                      child: ListTile(
                        leading: Icon(Icons.move_to_inbox_rounded),
                        title: Text('Entrada de mercancía'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: _Action.adjust,
                      child: ListTile(
                        leading: Icon(Icons.tune_rounded),
                        title: Text('Ajustar por conteo'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: _Action.alert,
                      child: ListTile(
                        leading: Icon(Icons.notification_important_outlined),
                        title: Text('Control y alerta'),
                      ),
                    ),
                  ],
                  const PopupMenuItem(
                    value: _Action.history,
                    child: ListTile(
                      leading: Icon(Icons.history_rounded),
                      title: Text('Historial'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
