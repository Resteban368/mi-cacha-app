import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../domain/entities/coupon.dart';
import '../bloc/coupon_detail_cubit.dart';
import '../widgets/coupon_labels.dart';

/// Detalle del cupón: quién redimió y a qué hora, quién tiene el bono sin usar,
/// quién va en camino y cuándo se llenó cada reserva.
class CouponDetailPage extends StatelessWidget {
  const CouponDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CouponDetailCubit, CouponDetailState>(
      builder: (context, state) {
        final coupon = state.coupon;
        return Column(
          children: [
            AppTopBar(
              title: coupon?.name ?? 'Cupón',
              subtitle: 'Historial del cupón',
              icon: Icons.confirmation_number_rounded,
              onBack: () => context.canPop()
                  ? context.pop()
                  : context.go(AppRoutes.businessCoupons),
            ),
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: switch (state.load) {
                  CouponDetailLoad.loading => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  CouponDetailLoad.failure => Center(
                    child: Text(
                      'No pudimos cargar el cupón.',
                      style: AppTypography.bodyMd,
                    ),
                  ),
                  CouponDetailLoad.ready => _Body(
                    coupon: coupon!,
                    state: state,
                  ),
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.coupon, required this.state});

  final Coupon coupon;
  final CouponDetailState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CouponDetailCubit>();
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 24),
          children: [
            _Summary(coupon: coupon),
            const SizedBox(height: 16),
            SegmentedButton<CouponCardStatus>(
              segments: const [
                ButtonSegment(
                  value: CouponCardStatus.redeemed,
                  label: Text('Redimidos'),
                ),
                ButtonSegment(
                  value: CouponCardStatus.earned,
                  label: Text('Por redimir'),
                ),
                ButtonSegment(
                  value: CouponCardStatus.inProgress,
                  label: Text('En progreso'),
                ),
              ],
              selected: {state.status},
              onSelectionChanged: (selection) =>
                  cubit.selectStatus(selection.first),
            ),
            const SizedBox(height: 12),
            if (state.cardsFailed)
              Center(
                child: TextButton.icon(
                  onPressed: cubit.retryCards,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('No pudimos cargar. Reintentar'),
                ),
              )
            else if (state.cards.isEmpty && state.cardsLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state.cards.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  switch (state.status) {
                    CouponCardStatus.redeemed => 'Aún no se ha redimido.',
                    CouponCardStatus.earned => 'Nadie tiene el bono sin usar.',
                    CouponCardStatus.inProgress =>
                      'Ningún cliente ha empezado esta tarjeta.',
                  },
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.slate600,
                  ),
                ),
              )
            else ...[
              for (final card in state.cards) ...[
                _CardTile(card: card),
                const SizedBox(height: 8),
              ],
              if (state.hasMore)
                Center(
                  child: TextButton(
                    onPressed: state.cardsLoading ? null : cubit.loadMore,
                    child: Text(state.cardsLoading ? 'Cargando…' : 'Ver más'),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.coupon});

  final Coupon coupon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (coupon.imageUrl case final url?) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AspectRatio(aspectRatio: 2, child: AppNetworkImage(url)),
            ),
            const SizedBox(height: 12),
          ],
          Text(coupon.rewardDescription, style: AppTypography.labelLg),
          const SizedBox(height: 4),
          Text(
            '${couponRewardTypeLabel(coupon)} · cada '
            '${coupon.requiredReservations} reservas',
            style: AppTypography.bodySm.copyWith(color: AppColors.slate600),
          ),
          const SizedBox(height: 4),
          Text(
            '${couponStateLabel(coupon.state)} · ${couponExpiryLabel(coupon)} '
            '· ${couponRedemptionsLabel(coupon)}',
            style: AppTypography.bodySm.copyWith(color: AppColors.slate600),
          ),
        ],
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  const _CardTile({required this.card});

  final CouponCard card;

  String get _headline => switch (card.status) {
    CouponCardStatus.redeemed => switch (card.redeemedAt) {
      final date? => 'Redimido el ${couponDateTime(date)}',
      null => 'Redimido',
    },
    CouponCardStatus.earned => switch (card.earnedAt) {
      final date? => 'Tarjeta llena el ${couponDateTime(date)}',
      null => 'Tarjeta llena',
    },
    CouponCardStatus.inProgress =>
      '${card.completed} de ${card.required} reservas',
  };

  @override
  Widget build(BuildContext context) {
    final subtle = AppTypography.bodySm.copyWith(color: AppColors.slate600);
    return Material(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.slate200),
        ),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          title: Text(card.customerName, style: AppTypography.labelLg),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_headline, style: subtle),
              if (card.redeemedAmount case final amount?)
                Text(
                  [
                    'Descuento de ${AppFormatters.cop(amount)}',
                    if (card.redeemedCourts case final courts?)
                      courts == 1 ? '1 cancha' : '$courts canchas',
                  ].join(' · '),
                  style: subtle,
                ),
            ],
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (card.customerPhone.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(card.customerPhone, style: subtle),
              ),
            for (final (i, stamp) in card.stamps.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reserva ${i + 1}: ${stamp.courtNames.join(' + ')}',
                      style: AppTypography.labelMd,
                    ),
                    Text(
                      'Jugada el ${couponDateTime(stamp.playedAt)} · '
                      '${AppFormatters.cop(stamp.amount)}',
                      style: subtle,
                    ),
                    Text(
                      'Llenada el ${couponDateTime(stamp.stampedAt)}',
                      style: subtle,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
