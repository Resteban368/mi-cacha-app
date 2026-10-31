import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/media/photo_picker.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/session/write_access.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../domain/entities/coupon.dart';
import '../bloc/coupons_cubit.dart';
import '../widgets/coupon_form_dialog.dart';
import '../widgets/coupon_labels.dart';

/// Cupones del negocio. Se desactivan con el interruptor; borrar solo se puede
/// si aún no hay bonos ganados ni redimidos (lo valida la API).
class CouponsPage extends StatelessWidget {
  const CouponsPage({super.key});

  static const _maxWidth = 1200.0;

  Future<void> _edit(BuildContext context, [Coupon? coupon]) async {
    if (!ensureCanWrite(context)) return;
    final cubit = context.read<CouponsCubit>();
    String? warning;
    final saved = await showCouponFormDialog(
      context,
      coupon: coupon,
      photoPicker: sl<PhotoPicker>(),
      onWarning: (message) => warning = message,
      onSave: (draft, image, {required removeImage}) =>
          cubit.save(draft, image: image, removeImage: removeImage),
    );
    if (!saved || !context.mounted) return;
    if (warning case final message?) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.statusDue,
          ),
        );
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            coupon == null ? 'Cupón creado.' : 'Cupón actualizado.',
          ),
        ),
      );
  }

  Future<void> _toggle(BuildContext context, Coupon coupon, bool active) async {
    if (!ensureCanWrite(context)) return;
    final messenger = ScaffoldMessenger.of(context);
    final error = await context.read<CouponsCubit>().setActive(coupon, active);
    if (error == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.statusDue),
      );
  }

  Future<void> _delete(BuildContext context, Coupon coupon) async {
    if (!ensureCanWrite(context)) return;
    final cubit = context.read<CouponsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Borrar cupón?'),
        content: Text(
          'Se borrará «${coupon.name}» y el avance de tus clientes en él. '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('coupon-delete-confirm'),
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.statusDue,
              foregroundColor: AppColors.onError,
            ),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final error = await cubit.delete(coupon);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        error == null
            ? const SnackBar(content: Text('Cupón borrado.'))
            : SnackBar(
                content: Text(error),
                backgroundColor: AppColors.statusDue,
              ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final canWrite = WriteAccessScope.canWrite(context);
    return Column(
      children: [
        const AppTopBar(
          title: 'Cupones',
          subtitle: 'Premia a quienes más reservan',
          icon: Icons.confirmation_number_rounded,
        ),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: BlocBuilder<CouponsCubit, CouponsState>(
              builder: (context, state) => switch (state.load) {
                CouponsLoad.loading => const Center(
                  child: CircularProgressIndicator(),
                ),
                CouponsLoad.failure => Center(
                  child: TextButton.icon(
                    onPressed: () => context.read<CouponsCubit>().load(),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text(
                      'No pudimos cargar los cupones. Reintentar',
                    ),
                  ),
                ),
                CouponsLoad.ready => LayoutBuilder(
                  builder: (context, constraints) {
                    final side = ((constraints.maxWidth - _maxWidth) / 2).clamp(
                      16.0,
                      double.infinity,
                    );
                    final visible = state.visible;
                    return CustomScrollView(
                      slivers: [
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(side, 24, side, 16),
                          sliver: SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _ViewHeader(
                                  onCreate: canWrite
                                      ? () => _edit(context)
                                      : null,
                                ),
                                const SizedBox(height: 20),
                                _Metrics(state: state),
                                if (state.coupons.isNotEmpty) ...[
                                  const SizedBox(height: 20),
                                  _SearchAndFilters(state: state),
                                ],
                              ],
                            ),
                          ),
                        ),
                        if (visible.isEmpty)
                          SliverPadding(
                            padding: EdgeInsets.symmetric(
                              horizontal: side,
                              vertical: 16,
                            ),
                            sliver: SliverToBoxAdapter(
                              child: Text(
                                state.coupons.isEmpty
                                    ? 'Crea tu primer cupón: por ejemplo, cada '
                                          '10 reservas jugadas y pagadas, una '
                                          'cancha gratis.'
                                    : 'Ningún cupón coincide con tu búsqueda.',
                                textAlign: TextAlign.center,
                                style: AppTypography.bodyMd.copyWith(
                                  color: AppColors.slate600,
                                ),
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: EdgeInsets.symmetric(horizontal: side),
                            sliver: SliverList.separated(
                              itemCount: visible.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, i) {
                                final coupon = visible[i];
                                return _CouponTile(
                                  coupon: coupon,
                                  onOpen: () => context.push(
                                    AppRoutes.businessCouponDetailPath(
                                      coupon.id,
                                    ),
                                  ),
                                  onEdit: canWrite
                                      ? () => _edit(context, coupon)
                                      : null,
                                  onDelete: canWrite
                                      ? () => _delete(context, coupon)
                                      : null,
                                  onToggle: canWrite && !coupon.isClosed
                                      ? (active) =>
                                            _toggle(context, coupon, active)
                                      : null,
                                );
                              },
                            ),
                          ),
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            side,
                            20,
                            side,
                            bottomInset + 24,
                          ),
                          sliver: const SliverToBoxAdapter(
                            child: _HowItWorks(),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ViewHeader extends StatelessWidget {
  const _ViewHeader({this.onCreate});

  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Programas de Fidelización y Cupones',
          style: AppTypography.headlineSm.copyWith(
            color: AppColors.slate900,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Incentiva a tus clientes a jugar más partidos con tarjetas de sellos '
          'por reserva cumplida y premios que redimes al cobrar.',
          style: AppTypography.bodySm.copyWith(color: AppColors.slate500),
        ),
      ],
    );
    final create = onCreate == null
        ? null
        : FilledButton.icon(
            key: const Key('coupon-create'),
            onPressed: onCreate,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandTeal,
              foregroundColor: AppColors.onPrimary,
              minimumSize: const Size(0, 46),
              textStyle: AppTypography.labelMd,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add, color: AppColors.accentLimeSignal),
            label: const Text('Crear nuevo cupón'),
          );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 700) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              title,
              if (create != null) ...[const SizedBox(height: 12), create],
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: title),
            if (create != null) ...[const SizedBox(width: 16), create],
          ],
        );
      },
    );
  }
}

/// Métricas que salen de los cupones cargados.
class _Metrics extends StatelessWidget {
  const _Metrics({required this.state});

  final CouponsState state;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _MetricCard(
        key: const Key('stat-active'),
        label: 'CUPONES ACTIVOS',
        value: state.countIn(CouponState.active),
        caption: 'Suman reservas y se redimen',
        icon: Icons.sell_rounded,
        tint: AppColors.brandTealLight,
        ink: AppColors.brandTeal,
      ),
      _MetricCard(
        key: const Key('stat-redeemed'),
        label: 'TOTAL REDENCIONES',
        value: state.totalRedeemed,
        caption: 'Bonos redimidos en tus cupones',
        icon: Icons.card_giftcard_rounded,
        tint: AppColors.warningTint,
        ink: AppColors.warningInk,
      ),
      _MetricCard(
        key: const Key('stat-inactive'),
        label: 'DESACTIVADOS',
        value: state.countIn(CouponState.inactive),
        caption: 'Solo redimen bonos ya ganados',
        icon: Icons.pause_circle_outline_rounded,
        tint: AppColors.slate100,
        ink: AppColors.slate600,
      ),
      _MetricCard(
        key: const Key('stat-closed'),
        label: 'CERRADOS',
        value:
            state.countIn(CouponState.expired) +
            state.countIn(CouponState.exhausted),
        caption: 'Vencidos o agotados',
        icon: Icons.event_busy_rounded,
        tint: AppColors.infoTint,
        ink: AppColors.infoInk,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final perRow = constraints.maxWidth >= 900 ? 4 : 2;
        return Column(
          children: [
            for (var start = 0; start < cards.length; start += perRow) ...[
              if (start > 0) const SizedBox(height: 12),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = start; i < start + perRow; i++) ...[
                      if (i > start) const SizedBox(width: 12),
                      Expanded(child: cards[i]),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.caption,
    required this.icon,
    required this.tint,
    required this.ink,
  });

  final String label;
  final int value;
  final String caption;
  final IconData icon;
  final Color tint;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.slate500,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: ink),
              ),
            ],
          ),
          Text(
            '$value',
            style: AppTypography.displayLg.copyWith(
              fontSize: 28,
              color: AppColors.slate900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            caption,
            style: AppTypography.bodySm.copyWith(color: AppColors.slate500),
          ),
        ],
      ),
    );
  }
}

class _SearchAndFilters extends StatelessWidget {
  const _SearchAndFilters({required this.state});

  final CouponsState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CouponsCubit>();
    final search = TextField(
      key: const Key('coupon-search'),
      onChanged: cubit.search,
      decoration: InputDecoration(
        hintText: 'Buscar por cupón o premio...',
        hintStyle: AppTypography.bodyMd.copyWith(color: AppColors.slate400),
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        isDense: true,
        filled: true,
        fillColor: AppColors.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.slate200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.slate200),
        ),
      ),
    );
    final filters = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (filter, label) in [
            (CouponFilter.all, 'Todos (${state.coupons.length})'),
            (
              CouponFilter.active,
              'Activos (${state.countIn(CouponState.active)})',
            ),
            (
              CouponFilter.inactive,
              'Desactivados (${state.countIn(CouponState.inactive)})',
            ),
            (CouponFilter.freeCourt, 'Por Cancha Gratis'),
            (CouponFilter.percent, 'Por Descuento %'),
          ])
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _FilterPill(
                label: label,
                selected: state.filter == filter,
                onTap: () => cubit.selectFilter(filter),
              ),
            ),
        ],
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 1000) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [search, const SizedBox(height: 10), filters],
          );
        }
        return Row(
          children: [
            Expanded(child: search),
            const SizedBox(width: 16),
            filters,
          ],
        );
      },
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected
            ? AppColors.brandTeal
            : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 40),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? AppColors.brandTeal : AppColors.slate200,
              ),
            ),
            child: Text(
              label,
              style: AppTypography.labelSm.copyWith(
                color: selected ? AppColors.onPrimary : AppColors.slate600,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CouponTile extends StatelessWidget {
  const _CouponTile({
    required this.coupon,
    required this.onOpen,
    this.onEdit,
    this.onDelete,
    this.onToggle,
  });

  final Coupon coupon;
  final VoidCallback onOpen;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final ValueChanged<bool>? onToggle;

  @override
  Widget build(BuildContext context) {
    final info = Row(
      children: [
        _CouponBadge(coupon: coupon),
        const SizedBox(width: 14),
        Expanded(child: _CouponInfo(coupon: coupon)),
      ],
    );
    final controls = <Widget>[
      if (onEdit != null)
        IconButton(
          tooltip: 'Editar cupón ${coupon.name}',
          onPressed: onEdit,
          color: AppColors.slate500,
          icon: const Icon(Icons.edit_rounded, size: 18),
        ),
      if (onDelete case final delete?)
        PopupMenuButton<VoidCallback>(
          key: Key('coupon-menu-${coupon.id}'),
          tooltip: 'Más opciones',
          icon: Icon(Icons.more_vert, size: 20, color: AppColors.slate500),
          onSelected: (action) => action(),
          itemBuilder: (_) => [
            PopupMenuItem(value: delete, child: const Text('Borrar')),
          ],
        ),
      if (!coupon.isClosed) ...[
        Container(
          width: 1,
          height: 28,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          color: AppColors.slate100,
        ),
        Tooltip(
          message: coupon.isActive ? 'Desactivar' : 'Activar',
          child: Switch(
            value: coupon.isActive,
            onChanged: onToggle,
            activeTrackColor: AppColors.emerald600,
            activeThumbColor: AppColors.onPrimary,
          ),
        ),
      ],
    ];
    return Material(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.slate200),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 640) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    info,
                    if (coupon.maxRedemptions != null) ...[
                      const SizedBox(height: 10),
                      _QuotaProgress(coupon: coupon),
                    ],
                    if (controls.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Divider(height: 1, color: AppColors.slate100),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: controls,
                      ),
                    ],
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: info),
                  if (coupon.maxRedemptions != null) ...[
                    const SizedBox(width: 16),
                    SizedBox(width: 110, child: _QuotaProgress(coupon: coupon)),
                  ],
                  const SizedBox(width: 8),
                  ...controls,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CouponBadge extends StatelessWidget {
  const _CouponBadge({required this.coupon});

  final Coupon coupon;

  @override
  Widget build(BuildContext context) {
    final open = coupon.state == CouponState.active;
    if (coupon.imageUrl case final url?) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox.square(
          dimension: 48,
          child: AppNetworkImage(url, cacheWidth: 144),
        ),
      );
    }
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: open ? AppColors.emerald50 : AppColors.slate100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: open ? AppColors.emerald200 : AppColors.slate200,
        ),
      ),
      child: Icon(
        Icons.confirmation_number_rounded,
        size: 24,
        color: open ? AppColors.brandTeal : AppColors.slate600,
      ),
    );
  }
}

class _CouponInfo extends StatelessWidget {
  const _CouponInfo({required this.coupon});

  final Coupon coupon;

  @override
  Widget build(BuildContext context) {
    final meta = AppTypography.bodySm.copyWith(color: AppColors.slate500);
    final max = coupon.maxRedemptions;
    final reward = switch (coupon.rewardType) {
      CouponRewardType.freeCourt => 'Cancha gratis',
      CouponRewardType.percent => '${coupon.percent ?? 0}% de descuento',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              coupon.name,
              style: AppTypography.labelLg.copyWith(color: AppColors.slate900),
            ),
            _StateTag(state: coupon.state),
            if (max != null)
              _Tag(
                label: 'Cupo limitado ($max)',
                tint: AppColors.warningTint,
                border: AppColors.warningBorder,
                ink: AppColors.warningInk,
              ),
          ],
        ),
        const SizedBox(height: 2),
        Text.rich(
          TextSpan(
            text: 'Cada ${coupon.requiredReservations} reservas: ',
            children: [
              TextSpan(
                text: coupon.rewardDescription,
                style: TextStyle(
                  color: AppColors.slate800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          style: AppTypography.bodyMd.copyWith(color: AppColors.slate600),
        ),
        const SizedBox(height: 2),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: reward,
                style: TextStyle(
                  color: AppColors.slate600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextSpan(text: ' • ${couponExpiryLabel(coupon)} • '),
              if (max == null) ...[
                TextSpan(
                  text: coupon.redeemedCount == 1
                      ? '1 redimido • '
                      : '${coupon.redeemedCount} redimidos • ',
                ),
                TextSpan(
                  text: 'Ilimitado',
                  style: TextStyle(
                    color: AppColors.brandTeal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ] else
                TextSpan(
                  text: couponRedemptionsLabel(coupon),
                  style: TextStyle(
                    color: AppColors.slate600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          style: meta,
        ),
      ],
    );
  }
}

class _StateTag extends StatelessWidget {
  const _StateTag({required this.state});

  final CouponState state;

  @override
  Widget build(BuildContext context) {
    final label = couponStateLabel(state);
    return switch (state) {
      CouponState.active => _Tag(
        label: label,
        tint: AppColors.emerald50,
        border: AppColors.emerald200,
        ink: AppColors.emerald800,
        dot: AppColors.emerald600,
      ),
      CouponState.inactive => _Tag(
        label: label,
        tint: AppColors.slate100,
        border: AppColors.slate200,
        ink: AppColors.slate600,
        dot: AppColors.slate400,
      ),
      CouponState.expired || CouponState.exhausted => _Tag(
        label: label,
        tint: AppColors.dangerTint,
        border: AppColors.dangerBorder,
        ink: AppColors.dangerInk,
        dot: AppColors.dangerInk,
      ),
    };
  }
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.label,
    required this.tint,
    required this.border,
    required this.ink,
    this.dot,
  });

  final String label;
  final Color tint;
  final Color border;
  final Color ink;
  final Color? dot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot case final color?) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: AppTypography.labelSm.copyWith(
              color: ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuotaProgress extends StatelessWidget {
  const _QuotaProgress({required this.coupon});

  final Coupon coupon;

  @override
  Widget build(BuildContext context) {
    final max = coupon.maxRedemptions ?? 0;
    final progress = max == 0
        ? 0.0
        : (coupon.redeemedCount / max).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Progreso de cupo',
          style: AppTypography.labelSm.copyWith(color: AppColors.slate500),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            color: AppColors.brandTeal,
            backgroundColor: AppColors.slate100,
            semanticsLabel: 'Progreso de cupo',
          ),
        ),
      ],
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.brandTealLight, AppColors.emerald50],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.brandTeal.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.lightbulb_rounded,
              size: 20,
              color: AppColors.brandTeal,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿Cómo funcionan los sellos en Mi Cancha?',
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.slate900,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Cada reserva jugada y pagada suma automáticamente un sello '
                  'a la tarjeta del cliente. Al completar la meta gana un bono, '
                  'que redimes desde el detalle de su reserva con «Redimir '
                  'cupón».',
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.slate600,
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
