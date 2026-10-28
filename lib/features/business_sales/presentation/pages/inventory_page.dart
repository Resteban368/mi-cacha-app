import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/session/business_modules.dart';
import '../../../../core/session/write_access.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../domain/entities/inventory.dart';
import '../../domain/entities/product.dart';
import '../bloc/inventory_cubit.dart';
import '../widgets/inventory_dialogs.dart';
import '../widgets/product_category_style.dart';
import '../widgets/sales_module_locked.dart';

/// Control de Inventario y Stock - Mi Cancha.
///
/// Supervisa niveles de stock en tiempo real, controla alertas de mínimo
/// y agiliza las entradas de producto para canchas y taquilla.
class InventoryPage extends StatelessWidget {
  const InventoryPage({super.key});

  static const _maxWidth = 1280.0;

  @override
  Widget build(BuildContext context) {
    const topBar = AppTopBar(
      title: 'Inventario',
      subtitle: 'Stock de tus productos',
      icon: Icons.inventory_2_rounded,
    );
    if (!BusinessModulesScope.salesOf(context)) {
      return const Column(
        children: [
          topBar,
          Expanded(child: SalesModuleLocked()),
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
                  color: AppColors.brandTeal,
                  onRefresh: context.read<InventoryCubit>().load,
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        sliver: SliverToBoxAdapter(
                          child: _Centered(
                            maxWidth: _maxWidth,
                            child: _HeaderSection(state: state),
                          ),
                        ),
                      ),
                      if (state.overview.items.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Container(
                                constraints: const BoxConstraints(maxWidth: 480),
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerLowest,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.slate200),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppColors.slate100,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.inventory_2_outlined,
                                        size: 40,
                                        color: AppColors.slate400,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Sin productos registrados',
                                      style: AppTypography.headlineSm.copyWith(
                                        color: AppColors.onSurface,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Primero crea tus productos en Ventas → Productos para comenzar a controlar tu stock.',
                                      textAlign: TextAlign.center,
                                      style: AppTypography.bodyMd.copyWith(
                                        color: AppColors.slate600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                      else if (state.visible.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: _Centered(
                              maxWidth: _maxWidth,
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerLowest,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.slate200),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.search_off_rounded,
                                      size: 36,
                                      color: AppColors.slate400,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Ningún producto coincide con el filtro o búsqueda.',
                                      textAlign: TextAlign.center,
                                      style: AppTypography.bodyMd.copyWith(
                                        color: AppColors.slate600,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextButton(
                                      onPressed: () {
                                        context
                                            .read<InventoryCubit>()
                                            .filter(InventoryFilter.all);
                                        context
                                            .read<InventoryCubit>()
                                            .search('');
                                      },
                                      child: const Text('Limpiar filtros'),
                                    ),
                                  ],
                                ),
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
                                const SizedBox(height: 10),
                            itemBuilder: (context, i) => _Centered(
                              maxWidth: _maxWidth,
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
  const _Centered({required this.child, required this.maxWidth});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}

/// Banner Hero con gradiente de cancha, KPIs de stock y barra de filtros.
class _HeaderSection extends StatelessWidget {
  const _HeaderSection({required this.state});

  final InventoryState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<InventoryCubit>();
    final overview = state.overview;
    final canWrite = WriteAccessScope.canWrite(context);

    // Suma del valor total en inventario para productos con control de stock.
    final totalValuation = overview.items.fold<int>(
      0,
      (sum, p) => p.trackStock ? sum + (p.price * p.stock) : sum,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Hero Card con fondo oscuro y textura de cancha
        _HeroPitchBanner(
          canWrite: canWrite,
          hasItems: overview.items.isNotEmpty,
        ),
        const SizedBox(height: 16),
        // Grid de 4 KPIs
        _KpiMetricsGrid(
          overview: overview,
          totalValuation: totalValuation,
        ),
        const SizedBox(height: 16),
        // Barra de búsqueda y filtros segmentados
        _SearchAndFiltersCard(
          state: state,
          onSearch: cubit.search,
          onFilterSelected: cubit.filter,
        ),
      ],
    );
  }
}

/// Banner Hero verde oscuro con textura de césped y botones de acción rápida.
class _HeroPitchBanner extends StatelessWidget {
  const _HeroPitchBanner({
    required this.canWrite,
    required this.hasItems,
  });

  final bool canWrite;
  final bool hasItems;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B382D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF065F46)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D4A27),
            Color(0xFF0B382D),
            Color(0xFF082820),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Marcas de cancha decorativas en el fondo
          Positioned(
            right: -30,
            bottom: -30,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.04),
                  width: 3,
                ),
              ),
            ),
          ),
          Positioned(
            right: 140,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.03),
                  width: 2,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 640;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Row(
                              //   children: [
                              //     Container(
                              //       padding: const EdgeInsets.symmetric(
                              //         horizontal: 8,
                              //         vertical: 3,
                              //       ),
                              //       decoration: BoxDecoration(
                              //         color: const Color(0xFFA3E635)
                              //             .withValues(alpha: 0.2),
                              //         borderRadius: BorderRadius.circular(6),
                              //         border: Border.all(
                              //           color: const Color(0xFFA3E635)
                              //               .withValues(alpha: 0.4),
                              //         ),
                              //       ),
                              //       child: Row(
                              //         mainAxisSize: MainAxisSize.min,
                              //         children: [
                              //           Container(
                              //             width: 6,
                              //             height: 6,
                              //             decoration: const BoxDecoration(
                              //               color: Color(0xFFA3E635),
                              //               shape: BoxShape.circle,
                              //             ),
                              //           ),
                              //           const SizedBox(width: 6),
                              //           Text(
                              //             'OPERACIÓN EN VIVO',
                              //             style: AppTypography.labelSm.copyWith(
                              //               color: const Color(0xFFA3E635),
                              //               fontSize: 10,
                              //               fontWeight: FontWeight.w800,
                              //               letterSpacing: 0.6,
                              //             ),
                              //           ),
                              //         ],
                              //       ),
                              //     ),
                              //   ],
                              // ),
                              // const SizedBox(height: 8),
                              Text(
                                'Control de Inventario y Existencias',
                                style: AppTypography.headlineLg.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: isCompact ? 20 : 24,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Supervisa niveles de stock en tiempo real, controla alertas de mínimo y agiliza las entradas de producto para canchas y taquilla.',
                                style: AppTypography.bodySm.copyWith(
                                  color: const Color(0xFFD1FAE5)
                                      .withValues(alpha: 0.85),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Botones de acción del Hero
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        // Botón Historial
                        _GlassHeroButton(
                          key: const Key('inventory-history'),
                          onPressed: () => showStockHistory(context),
                          icon: Icons.history_rounded,
                          label: 'Historial',
                        ),
                        // Botón Ajuste Rápido
                        if (canWrite)
                          _GlassHeroButton(
                            key: const Key('inventory-quick-adjust'),
                            onPressed: hasItems
                                ? () => showQuickAdjustDialog(context)
                                : null,
                            icon: Icons.tune_rounded,
                            label: 'Ajuste Rápido',
                          ),
                        // Botón Primario: Entrada de Mercancía
                        if (canWrite)
                          _VibrantHeroButton(
                            key: const Key('inventory-entry'),
                            onPressed: hasItems
                                ? () => showStockEntryDialog(context)
                                : null,
                            icon: Icons.move_to_inbox_rounded,
                            label: 'Entrada de mercancía',
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Botón traslúcido estilo vidrio para el Hero.
class _GlassHeroButton extends StatelessWidget {
  const _GlassHeroButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.22),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: const Color(0xFFA7F3D0),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelMd.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botón con degradado lima/esmeralda de alto impacto para Entrada de Mercancía.
class _VibrantHeroButton extends StatelessWidget {
  const _VibrantHeroButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: enabled ? 1.0 : 0.6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF34D399),
                  Color(0xFFA3E635),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelMd.copyWith(
                      color: const Color(0xFF0F172A),
                      fontWeight: FontWeight.w800,
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
}

/// Grid de 4 métricas KPI de inventario.
class _KpiMetricsGrid extends StatelessWidget {
  const _KpiMetricsGrid({
    required this.overview,
    required this.totalValuation,
  });

  final InventoryOverview overview;
  final int totalValuation;

  @override
  Widget build(BuildContext context) {
    // Buscar primer producto bajo y primer producto agotado para las etiquetas inferiores
    final firstLow = overview.items.where((p) => p.isLow && !p.isOut).firstOrNull;
    final firstOut = overview.items.where((p) => p.isOut).firstOrNull;

    final trackedPct = overview.items.isEmpty
        ? 0
        : ((overview.tracked / overview.items.length) * 100).round();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isSmall = width < 560;
        final isMedium = width >= 560 && width < 980;

        final card1 = _KpiCard(
          key: const Key('stat-tracked'),
          label: 'CON CONTROL DE STOCK',
          value: '${overview.tracked}',
          caption: 'de ${overview.items.length} productos',
          icon: Icons.inventory_2_outlined,
          iconBg: const Color(0xFFECFDF5),
          iconBorder: const Color(0xFFA7F3D0),
          iconColor: const Color(0xFF059669),
          bottomLeft: '$trackedPct% con monitoreo activo',
          bottomRight: 'Normal',
          bottomRightColor: const Color(0xFF059669),
        );

        final card2 = _KpiCard(
          key: const Key('stat-low'),
          label: 'STOCK BAJO',
          value: '${overview.low}',
          caption: 'en el mínimo o por debajo',
          icon: Icons.trending_down_rounded,
          iconBg: const Color(0xFFFEF3C7),
          iconBorder: const Color(0xFFFDE68A),
          iconColor: const Color(0xFFD97706),
          cardBg: const Color(0xFFFFFBEB),
          cardBorderColor: const Color(0xFFFDE68A),
          hasAlertPulse: overview.low > 0,
          valueColor: const Color(0xFF92400E),
          bottomLeft: firstLow != null
              ? '${firstLow.name} (${firstLow.stock} und)'
              : 'Sin alertas pendientes',
          bottomLeftIcon: firstLow != null ? Icons.warning_amber_rounded : null,
          bottomRight: firstLow != null ? 'Pedir hoy' : 'Al día',
          bottomRightColor: const Color(0xFFB45309),
        );

        final card3 = _KpiCard(
          key: const Key('stat-out'),
          label: 'AGOTADOS',
          value: '${overview.out}',
          caption: 'no se pueden vender',
          icon: Icons.remove_shopping_cart_outlined,
          iconBg: const Color(0xFFFFE4E6),
          iconBorder: const Color(0xFFFECDD3),
          iconColor: const Color(0xFFE11D48),
          cardBg: const Color(0xFFFFF1F2),
          cardBorderColor: const Color(0xFFFECDD3),
          valueColor: const Color(0xFF9F1239),
          bottomLeft: firstOut != null
              ? '${firstOut.name} (0 und)'
              : 'Todos disponibles',
          bottomRight: firstOut != null ? 'Bloqueado POS' : 'Normal',
          bottomRightColor: const Color(0xFFE11D48),
          bottomRightIsTag: firstOut != null,
        );

        final card4 = _KpiCard(
          key: const Key('stat-valuation'),
          label: 'VALUACIÓN EN EXHIBICIÓN',
          value: AppFormatters.cop(totalValuation),
          caption: 'COP',
          icon: Icons.attach_money_rounded,
          iconBg: AppColors.slate100,
          iconBorder: AppColors.slate200,
          iconColor: AppColors.slate700,
          bottomLeft: 'Precio venta acumulado',
          bottomRight: 'Total inventario',
          bottomRightColor: const Color(0xFF047857),
        );

        if (isSmall) {
          return Column(
            children: [
              card1,
              const SizedBox(height: 10),
              card2,
              const SizedBox(height: 10),
              card3,
              const SizedBox(height: 10),
              card4,
            ],
          );
        }

        if (isMedium) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: card1),
                  const SizedBox(width: 12),
                  Expanded(child: card2),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: card3),
                  const SizedBox(width: 12),
                  Expanded(child: card4),
                ],
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: card1),
            const SizedBox(width: 12),
            Expanded(child: card2),
            const SizedBox(width: 12),
            Expanded(child: card3),
            const SizedBox(width: 12),
            Expanded(child: card4),
          ],
        );
      },
    );
  }
}

/// Tarjeta individual de métrica KPI con encabezado, valor e indicador inferior.
class _KpiCard extends StatelessWidget {
  const _KpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.caption,
    required this.icon,
    required this.iconBg,
    required this.iconBorder,
    required this.iconColor,
    required this.bottomLeft,
    required this.bottomRight,
    this.bottomRightColor,
    this.cardBg,
    this.cardBorderColor,
    this.valueColor,
    this.hasAlertPulse = false,
    this.bottomLeftIcon,
    this.bottomRightIsTag = false,
  });

  final String label;
  final String value;
  final String caption;
  final IconData icon;
  final Color iconBg;
  final Color iconBorder;
  final Color iconColor;
  final String bottomLeft;
  final String bottomRight;
  final Color? bottomRightColor;
  final Color? cardBg;
  final Color? cardBorderColor;
  final Color? valueColor;
  final bool hasAlertPulse;
  final IconData? bottomLeftIcon;
  final bool bottomRightIsTag;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg ?? AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cardBorderColor ?? AppColors.slate200,
          width: cardBorderColor != null ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            label,
                            style: AppTypography.labelSm.copyWith(
                              color: valueColor ?? AppColors.slate500,
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                              letterSpacing: 0.6,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasAlertPulse) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF59E0B),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      children: [
                        Text(
                          value,
                          style: AppTypography.displayLgMobile.copyWith(
                            color: valueColor ?? AppColors.onSurface,
                            fontWeight: FontWeight.w800,
                            fontSize: 26,
                          ),
                        ),
                        Text(
                          caption,
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.slate500,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: iconBorder),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: (cardBorderColor ?? AppColors.slate100).withValues(
                    alpha: 0.6,
                  ),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (bottomLeftIcon != null) ...[
                        Icon(
                          bottomLeftIcon,
                          size: 13,
                          color: const Color(0xFFD97706),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          bottomLeft,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySm.copyWith(
                            fontSize: 11,
                            color: AppColors.slate600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (bottomRightIsTag)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE4E6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      bottomRight,
                      style: AppTypography.labelSm.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: bottomRightColor ?? const Color(0xFFE11D48),
                      ),
                    ),
                  )
                else
                  Text(
                    bottomRight,
                    style: AppTypography.labelSm.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: bottomRightColor ?? AppColors.slate600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de búsqueda y filtros segmentados de estado de stock.
class _SearchAndFiltersCard extends StatefulWidget {
  const _SearchAndFiltersCard({
    required this.state,
    required this.onSearch,
    required this.onFilterSelected,
  });

  final InventoryState state;
  final ValueChanged<String> onSearch;
  final ValueChanged<InventoryFilter> onFilterSelected;

  @override
  State<_SearchAndFiltersCard> createState() => _SearchAndFiltersCardState();
}

class _SearchAndFiltersCardState extends State<_SearchAndFiltersCard> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.state.query);
  }

  @override
  void didUpdateWidget(covariant _SearchAndFiltersCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.query != _controller.text &&
        widget.state.query != oldWidget.state.query) {
      _controller.text = widget.state.query;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Campo de búsqueda principal
          TextField(
            key: const Key('inventory-search'),
            controller: _controller,
            onChanged: widget.onSearch,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText:
                  'Buscar por nombre o categoría (ej. poker, agua, petos)...',
              prefixIcon: Icon(
                Icons.search_rounded,
                color: AppColors.slate400,
              ),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _controller.clear();
                        widget.onSearch('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.slate50,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
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
                borderSide: BorderSide(color: AppColors.brandTeal, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Pastillas de estado
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterPill(
                  filterKey: const Key('inventory-filter-all'),
                  label: 'Todos',
                  count: widget.state.countOf(InventoryFilter.all),
                  isSelected: widget.state.filter == InventoryFilter.all,
                  onTap: () => widget.onFilterSelected(InventoryFilter.all),
                ),
                const SizedBox(width: 8),
                _FilterPill(
                  filterKey: const Key('inventory-filter-low'),
                  label: 'Stock bajo',
                  count: widget.state.countOf(InventoryFilter.low),
                  dotColor: const Color(0xFFF59E0B),
                  isSelected: widget.state.filter == InventoryFilter.low,
                  onTap: () => widget.onFilterSelected(InventoryFilter.low),
                ),
                const SizedBox(width: 8),
                _FilterPill(
                  filterKey: const Key('inventory-filter-out'),
                  label: 'Agotados',
                  count: widget.state.countOf(InventoryFilter.out),
                  dotColor: const Color(0xFFE11D48),
                  isSelected: widget.state.filter == InventoryFilter.out,
                  onTap: () => widget.onFilterSelected(InventoryFilter.out),
                ),
                const SizedBox(width: 8),
                _FilterPill(
                  filterKey: const Key('inventory-filter-untracked'),
                  label: 'Sin control',
                  count: widget.state.countOf(InventoryFilter.untracked),
                  icon: Icons.all_inclusive_rounded,
                  isSelected: widget.state.filter == InventoryFilter.untracked,
                  onTap: () =>
                      widget.onFilterSelected(InventoryFilter.untracked),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pastilla segmentada de filtro interactivo con estilo activo de Stitch (neón/lima).
class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.filterKey,
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
    this.dotColor,
    this.icon,
  });

  final Key filterKey;
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? dotColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: filterKey,
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFA3E635)
                : AppColors.slate100,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF84CC16)
                  : AppColors.slate200,
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                const Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: Color(0xFF0F172A),
                ),
                const SizedBox(width: 6),
              ] else if (dotColor != null) ...[
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ] else if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: AppColors.slate500,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: AppTypography.labelSm.copyWith(
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? const Color(0xFF0F172A)
                      : AppColors.slate700,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 1,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.black.withValues(alpha: 0.14)
                      : AppColors.slate200,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: AppTypography.labelSm.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isSelected
                        ? const Color(0xFF0F172A)
                        : AppColors.slate700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _ProductAction { entry, adjust, alert, history }

/// Tarjeta de producto con barra visual de existencias, estados de alerta y acciones.
class _ProductStockTile extends StatelessWidget {
  const _ProductStockTile({required this.product});

  final Product product;

  void _run(BuildContext context, _ProductAction action) => switch (action) {
    _ProductAction.entry => showStockEntryDialog(context, product: product),
    _ProductAction.adjust => showStockAdjustDialog(context, product),
    _ProductAction.alert => showStockAlertDialog(context, product),
    _ProductAction.history => showStockHistory(context, product: product),
  };

  @override
  Widget build(BuildContext context) {
    final p = product;
    final canWrite = WriteAccessScope.canWrite(context);

    // Configuración según el estado de inventario
    final bool isOut = p.trackStock && p.isOut;
    final bool isLow = p.trackStock && p.isLow && !p.isOut;
    final bool isNormal = p.trackStock && !p.isLow;
    final bool isUntracked = !p.trackStock;

    final Color cardBorderColor = isOut
        ? const Color(0xFFFECDD3)
        : isLow
        ? const Color(0xFFFDE68A)
        : AppColors.slate200;

    final double borderWidth = (isOut || isLow) ? 1.8 : 1.0;

    final String badgeLabel = isUntracked
        ? 'Sin control'
        : isOut
        ? 'Agotado'
        : isLow
        ? 'Stock bajo'
        : 'Disponible';

    final Color badgeBg = isUntracked
        ? AppColors.slate100
        : isOut
        ? const Color(0xFFFFE4E6)
        : isLow
        ? const Color(0xFFFEF3C7)
        : const Color(0xFFD1FAE5);

    final Color badgeText = isUntracked
        ? AppColors.slate600
        : isOut
        ? const Color(0xFFE11D48)
        : isLow
        ? const Color(0xFFB45309)
        : const Color(0xFF059669);

    final Color iconBoxBg = isOut
        ? const Color(0xFFFFF1F2)
        : isLow
        ? const Color(0xFFFFFBEB)
        : isUntracked
        ? AppColors.slate100
        : p.category.tint;

    final Color iconBoxBorder = isOut
        ? const Color(0xFFFECDD3)
        : isLow
        ? const Color(0xFFFDE68A)
        : isUntracked
        ? AppColors.slate200
        : p.category.color.withValues(alpha: 0.25);

    final Color iconColor = isOut
        ? const Color(0xFFE11D48)
        : isLow
        ? const Color(0xFFD97706)
        : isUntracked
        ? AppColors.slate500
        : p.category.color;

    return Material(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: Key('inventory-${p.id}'),
        borderRadius: BorderRadius.circular(16),
        onTap: () => _run(context, _ProductAction.history),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorderColor, width: borderWidth),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 620;

              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Ícono de categoría / estado
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: iconBoxBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: iconBoxBorder),
                        ),
                        child: Icon(
                          p.category.icon,
                          color: iconColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Información central
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Text(
                                  p.name,
                                  style: AppTypography.bodyLg.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: isOut
                                        ? const Color(0xFF9F1239)
                                        : isLow
                                        ? const Color(0xFF92400E)
                                        : AppColors.onSurface,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: badgeBg,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    badgeLabel,
                                    style: AppTypography.labelSm.copyWith(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: badgeText,
                                    ),
                                  ),
                                ),
                                if (!isNarrow)
                                  Text(
                                    '• ${p.category.label}',
                                    style: AppTypography.bodySm.copyWith(
                                      fontSize: 11,
                                      color: AppColors.slate400,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  AppFormatters.cop(p.price),
                                  style: AppTypography.labelLg.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                                Text(
                                  'COP',
                                  style: AppTypography.bodySm.copyWith(
                                    fontSize: 10,
                                    color: AppColors.slate400,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '·',
                                  style: AppTypography.bodySm.copyWith(
                                    color: AppColors.slate300,
                                  ),
                                ),
                                if (p.trackStock)
                                  if (p.minStock != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isLow
                                            ? const Color(0xFFFEF3C7)
                                            : AppColors.slate100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Mínimo: ${p.minStock} und',
                                        style: AppTypography.bodySm.copyWith(
                                          fontSize: 11,
                                          fontWeight: isLow
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: isLow
                                              ? const Color(0xFF92400E)
                                              : AppColors.slate600,
                                        ),
                                      ),
                                    )
                                  else
                                    Text(
                                      'Sin alerta de mínimo',
                                      style: AppTypography.bodySm.copyWith(
                                        fontSize: 11,
                                        color: AppColors.slate400,
                                      ),
                                    )
                                else
                                  Text(
                                    'Venta libre directa en POS sin conteo',
                                    style: AppTypography.bodySm.copyWith(
                                      fontSize: 11,
                                      color: AppColors.slate400,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (!isNarrow) ...[
                        const SizedBox(width: 16),
                        _StockMetricAndActions(
                          product: p,
                          canWrite: canWrite,
                          isOut: isOut,
                          isLow: isLow,
                          isNormal: isNormal,
                          isUntracked: isUntracked,
                          onAction: (a) => _run(context, a),
                        ),
                      ] else ...[
                        PopupMenuButton<_ProductAction>(
                          key: Key('inventory-menu-${p.id}'),
                          tooltip: 'Opciones de producto',
                          icon: Icon(
                            Icons.more_vert_rounded,
                            color: AppColors.slate500,
                          ),
                          onSelected: (action) => _run(context, action),
                          itemBuilder: (_) => [
                            if (canWrite) ...[
                              const PopupMenuItem(
                                value: _ProductAction.entry,
                                child: ListTile(
                                  leading: Icon(Icons.move_to_inbox_rounded),
                                  title: Text('Entrada de mercancía'),
                                ),
                              ),
                              const PopupMenuItem(
                                value: _ProductAction.adjust,
                                child: ListTile(
                                  leading: Icon(Icons.tune_rounded),
                                  title: Text('Ajustar por conteo'),
                                ),
                              ),
                              const PopupMenuItem(
                                value: _ProductAction.alert,
                                child: ListTile(
                                  leading: Icon(
                                    Icons.notification_important_outlined,
                                  ),
                                  title: Text('Control y alerta'),
                                ),
                              ),
                            ],
                            const PopupMenuItem(
                              value: _ProductAction.history,
                              child: ListTile(
                                leading: Icon(Icons.history_rounded),
                                title: Text('Historial'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  if (isNarrow) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.only(top: 10),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.slate100),
                        ),
                      ),
                      child: _StockMetricAndActions(
                        product: p,
                        canWrite: canWrite,
                        isOut: isOut,
                        isLow: isLow,
                        isNormal: isNormal,
                        isUntracked: isUntracked,
                        onAction: (a) => _run(context, a),
                        isNarrow: true,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Métrica de stock numérico, barra de progreso y botones de acción rápida.
class _StockMetricAndActions extends StatelessWidget {
  const _StockMetricAndActions({
    required this.product,
    required this.canWrite,
    required this.isOut,
    required this.isLow,
    required this.isNormal,
    required this.isUntracked,
    required this.onAction,
    this.isNarrow = false,
  });

  final Product product;
  final bool canWrite;
  final bool isOut;
  final bool isLow;
  final bool isNormal;
  final bool isUntracked;
  final ValueChanged<_ProductAction> onAction;
  final bool isNarrow;

  @override
  Widget build(BuildContext context) {
    final p = product;

    // Cálculo del porcentaje de la barra de existencias
    final double stockFraction;
    final Color progressColor;
    if (isOut) {
      stockFraction = 0.0;
      progressColor = const Color(0xFFE11D48);
    } else if (isLow) {
      final min = math.max(p.minStock ?? 1, 1);
      stockFraction = (p.stock / min * 0.5).clamp(0.1, 0.5);
      progressColor = const Color(0xFFF59E0B);
    } else if (isNormal) {
      final min = math.max(p.minStock ?? 5, 1);
      stockFraction = (p.stock / (min * 2)).clamp(0.6, 1.0);
      progressColor = const Color(0xFF10B981);
    } else {
      stockFraction = 1.0;
      progressColor = AppColors.slate300;
    }

    final stockMetric = p.trackStock
        ? Column(
            crossAxisAlignment:
                isNarrow ? CrossAxisAlignment.start : CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${p.stock}',
                    key: Key('inventory-stock-${p.id}'),
                    style: AppTypography.headlineSm.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isOut
                          ? const Color(0xFFE11D48)
                          : isLow
                          ? const Color(0xFFD97706)
                          : AppColors.onSurface,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'und',
                    style: AppTypography.labelSm.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isOut
                          ? const Color(0xFFE11D48)
                          : isLow
                          ? const Color(0xFFD97706)
                          : AppColors.slate400,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Barra visual de stock
              Container(
                width: 100,
                height: 6,
                decoration: BoxDecoration(
                  color: isOut
                      ? const Color(0xFFFFE4E6)
                      : AppColors.slate100,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: stockFraction,
                  child: Container(
                    decoration: BoxDecoration(
                      color: progressColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ],
          )
        : Column(
            crossAxisAlignment:
                isNarrow ? CrossAxisAlignment.start : CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '∞',
                    style: AppTypography.headlineSm.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.slate400,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Ilimitado',
                    style: AppTypography.labelSm.copyWith(
                      fontSize: 11,
                      color: AppColors.slate500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'No descuenta existencias',
                style: AppTypography.bodySm.copyWith(
                  fontSize: 10,
                  color: AppColors.slate400,
                ),
              ),
            ],
          );

    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (canWrite) ...[
          if (isOut)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE11D48),
                backgroundColor: const Color(0xFFFFF1F2),
                side: const BorderSide(color: Color(0xFFFECDD3)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => onAction(_ProductAction.entry),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Surtir'),
            )
          else if (isLow)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF92400E),
                backgroundColor: const Color(0xFFFEF3C7),
                side: const BorderSide(color: Color(0xFFFDE68A)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => onAction(_ProductAction.entry),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Pedir'),
            )
          else if (isNormal)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.slate700,
                backgroundColor: AppColors.slate50,
                side: BorderSide(color: AppColors.slate200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => onAction(_ProductAction.adjust),
              icon: const Icon(Icons.tune_rounded, size: 16),
              label: const Text('Ajustar'),
            )
          else
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.slate600,
                backgroundColor: AppColors.slate50,
                side: BorderSide(color: AppColors.slate200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => onAction(_ProductAction.alert),
              icon: const Icon(
                Icons.notification_important_outlined,
                size: 15,
              ),
              label: const Text('Activar control'),
            ),
        ],
        if (!isNarrow) ...[
          const SizedBox(width: 4),
          PopupMenuButton<_ProductAction>(
            key: Key('inventory-menu-${p.id}'),
            tooltip: 'Opciones de producto',
            icon: Icon(Icons.more_vert_rounded, color: AppColors.slate500),
            onSelected: onAction,
            itemBuilder: (_) => [
              if (canWrite) ...[
                const PopupMenuItem(
                  value: _ProductAction.entry,
                  child: ListTile(
                    leading: Icon(Icons.move_to_inbox_rounded),
                    title: Text('Entrada de mercancía'),
                  ),
                ),
                const PopupMenuItem(
                  value: _ProductAction.adjust,
                  child: ListTile(
                    leading: Icon(Icons.tune_rounded),
                    title: Text('Ajustar por conteo'),
                  ),
                ),
                const PopupMenuItem(
                  value: _ProductAction.alert,
                  child: ListTile(
                    leading: Icon(Icons.notification_important_outlined),
                    title: Text('Control y alerta'),
                  ),
                ),
              ],
              const PopupMenuItem(
                value: _ProductAction.history,
                child: ListTile(
                  leading: Icon(Icons.history_rounded),
                  title: Text('Historial'),
                ),
              ),
            ],
          ),
        ],
      ],
    );

    if (isNarrow) {
      return Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          stockMetric,
          actions,
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        stockMetric,
        const SizedBox(width: 16),
        actions,
      ],
    );
  }
}
