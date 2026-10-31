import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/contact_launcher.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../domain/entities/coupon.dart';
import '../bloc/coupon_detail_cubit.dart';
import '../widgets/coupon_labels.dart';

/// Detalle del cupón: quién redimió y a qué hora, quién tiene el bono sin usar,
/// quién va en camino y el seguimiento visual de sellos por cliente.
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
              subtitle: 'Detalle de cupón y clientes participantes',
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

class _Body extends StatefulWidget {
  const _Body({required this.coupon, required this.state});

  final Coupon coupon;
  final CouponDetailState state;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CouponCard> _filterCards(List<CouponCard> cards) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return cards;
    return cards.where((c) {
      final nameMatches = c.customerName.toLowerCase().contains(query);
      final phoneMatches = c.customerPhone.replaceAll(RegExp(r'\D'), '').contains(query);
      return nameMatches || phoneMatches;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CouponDetailCubit>();
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final visibleCards = _filterCards(widget.state.cards);
    
    // Identificar clientes que están a 1 reserva de ganar en progreso
    final hotLeads = widget.state.cards.where((c) =>
        c.status == CouponCardStatus.inProgress &&
        c.required > 1 &&
        c.completed >= c.required - 1).toList();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 32),
          children: [
            _HeroSummary(coupon: widget.coupon, state: widget.state),
            const SizedBox(height: 16),
            if (widget.state.status == CouponCardStatus.inProgress && hotLeads.isNotEmpty) ...[
              _HotLeadsSection(coupon: widget.coupon, hotLeads: hotLeads),
              const SizedBox(height: 16),
            ],
            _ControlsBar(
              status: widget.state.status,
              onStatusSelected: (status) {
                _searchController.clear();
                setState(() => _searchQuery = '');
                cubit.selectStatus(status);
              },
              searchController: _searchController,
              onSearchChanged: (val) => setState(() => _searchQuery = val),
            ),
            const SizedBox(height: 14),
            if (widget.state.cardsFailed)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: TextButton.icon(
                    onPressed: cubit.retryCards,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('No pudimos cargar. Reintentar'),
                  ),
                ),
              )
            else if (widget.state.cards.isEmpty && widget.state.cardsLoading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (visibleCards.isEmpty)
              _EmptyCardsState(
                status: widget.state.status,
                hasSearchQuery: _searchQuery.isNotEmpty,
              )
            else ...[
              for (final card in visibleCards) ...[
                _CardTile(
                  card: card,
                  coupon: widget.coupon,
                ),
                const SizedBox(height: 10),
              ],
              if (widget.state.hasMore && _searchQuery.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: TextButton(
                      onPressed: widget.state.cardsLoading ? null : cubit.loadMore,
                      child: Text(widget.state.cardsLoading ? 'Cargando…' : 'Ver más jugadores'),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeroSummary extends StatelessWidget {
  const _HeroSummary({required this.coupon, required this.state});

  final Coupon coupon;
  final CouponDetailState state;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (coupon.imageUrl case final url?) ...[
            AspectRatio(
              aspectRatio: 2.4,
              child: AppNetworkImage(url),
            ),
          ],
          Padding(
            padding: const EdgeInsets.all(18),
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
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  coupon.name,
                                  style: AppTypography.headlineSm.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _StatusBadge(state: coupon.state),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            coupon.rewardDescription,
                            style: AppTypography.labelLg.copyWith(
                              color: AppColors.brandTeal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.outlineVariant),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.sports_soccer_rounded, size: 14, color: AppColors.brandTeal),
                          const SizedBox(width: 4),
                          Text(
                            'Sellos ${coupon.requiredReservations}x1',
                            style: AppTypography.labelSm.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    _InfoChip(
                      icon: Icons.repeat_rounded,
                      label: 'Cada ${coupon.requiredReservations} reservas completadas',
                    ),
                    _InfoChip(
                      icon: Icons.event_available_rounded,
                      label: couponExpiryLabel(coupon),
                    ),
                    _InfoChip(
                      icon: Icons.workspace_premium_rounded,
                      label: couponRedemptionsLabel(coupon),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 14),
                // Grid de métricas rápidas
                Row(
                  children: [
                    Expanded(
                      child: _MetricItem(
                        label: 'Tarjetas activas',
                        value: '${state.total}',
                        icon: Icons.people_alt_rounded,
                        color: AppColors.brandTeal,
                      ),
                    ),
                    Container(width: 1, height: 36, color: AppColors.outlineVariant),
                    Expanded(
                      child: _MetricItem(
                        label: 'Redimidos totales',
                        value: '${coupon.redeemedCount}',
                        icon: Icons.celebration_rounded,
                        color: AppColors.orange500,
                      ),
                    ),
                    Container(width: 1, height: 36, color: AppColors.outlineVariant),
                    Expanded(
                      child: _MetricItem(
                        label: 'Beneficio',
                        value: couponRewardTypeLabel(coupon),
                        icon: Icons.card_giftcard_rounded,
                        color: AppColors.emerald600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.state});

  final CouponState state;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (state) {
      CouponState.active => (AppColors.emerald50, AppColors.emerald800),
      CouponState.inactive => (AppColors.slate100, AppColors.slate700),
      CouponState.expired => (AppColors.errorContainer, AppColors.onErrorContainer),
      CouponState.exhausted => (AppColors.slate200, AppColors.slate800),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: fg,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            couponStateLabel(state),
            style: AppTypography.labelSm.copyWith(
              color: fg,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.slate500),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.bodySm.copyWith(color: AppColors.slate600),
        ),
      ],
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.bodySm.copyWith(
                fontSize: 11,
                color: AppColors.slate500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.labelMd.copyWith(
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Sección destacada de jugadores próximos a redimir (a 1 reserva de ganar)
class _HotLeadsSection extends StatelessWidget {
  const _HotLeadsSection({required this.coupon, required this.hotLeads});

  final Coupon coupon;
  final List<CouponCard> hotLeads;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accentLimeTint.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accentLime.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppColors.brandDark,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.electric_bolt_rounded,
                  size: 16,
                  color: AppColors.accentLime,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¡Próximos a ganar! (${hotLeads.length} jugadores a 1 reserva)',
                      style: AppTypography.labelMd.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.brandDark,
                      ),
                    ),
                    Text(
                      'Falta solo 1 partido para desbloquear su beneficio. ¡Escríbeles para agendar!',
                      style: AppTypography.bodySm.copyWith(
                        fontSize: 11,
                        color: AppColors.slate700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final lead in hotLeads) ...[
                  _HotLeadChip(lead: lead, coupon: coupon),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HotLeadChip extends StatelessWidget {
  const _HotLeadChip({required this.lead, required this.coupon});

  final CouponCard lead;
  final Coupon coupon;

  void _openWhatsApp(BuildContext context) {
    final text = '¡Hola ${lead.customerName}! ⚽ Estás a solo 1 reserva de completar tus sellos '
        'y ganar tu beneficio de ${coupon.rewardDescription}. ¿Te agendamos un turno esta semana?';
    final uri = ContactLauncher.whatsAppChat(lead.customerPhone, text: text);
    if (uri != null) {
      ContactLauncher.open(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: AppColors.brandTeal.withValues(alpha: 0.15),
            child: Text(
              lead.customerName.isNotEmpty ? lead.customerName[0].toUpperCase() : '?',
              style: AppTypography.labelSm.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.brandTeal,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                lead.customerName,
                style: AppTypography.labelSm.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                '${lead.completed}/${lead.required} sellos',
                style: AppTypography.bodySm.copyWith(
                  fontSize: 10,
                  color: AppColors.emerald800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (lead.customerPhone.isNotEmpty) ...[
            const SizedBox(width: 8),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              icon: Icon(Icons.chat_bubble_rounded, size: 16, color: AppColors.whatsapp),
              tooltip: 'Recordar por WhatsApp',
              onPressed: () => _openWhatsApp(context),
            ),
          ],
        ],
      ),
    );
  }
}

class _ControlsBar extends StatelessWidget {
  const _ControlsBar({
    required this.status,
    required this.onStatusSelected,
    required this.searchController,
    required this.onSearchChanged,
  });

  final CouponCardStatus status;
  final ValueChanged<CouponCardStatus> onStatusSelected;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;
        final segmented = SegmentedButton<CouponCardStatus>(
          segments: const [
            ButtonSegment(
              value: CouponCardStatus.redeemed,
              label: Text('Redimidos'),
              icon: Icon(Icons.check_circle_outline_rounded, size: 16),
            ),
            ButtonSegment(
              value: CouponCardStatus.earned,
              label: Text('Por redimir'),
              icon: Icon(Icons.card_giftcard_rounded, size: 16),
            ),
            ButtonSegment(
              value: CouponCardStatus.inProgress,
              label: Text('En progreso'),
              icon: Icon(Icons.timelapse_rounded, size: 16),
            ),
          ],
          selected: {status},
          onSelectionChanged: (selection) => onStatusSelected(selection.first),
        );

        final searchField = TextField(
          controller: searchController,
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Buscar por jugador o teléfono...',
            hintStyle: AppTypography.bodySm.copyWith(color: AppColors.slate400),
            prefixIcon: const Icon(Icons.search_rounded, size: 18),
            suffixIcon: searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 16),
                    onPressed: () {
                      searchController.clear();
                      onSearchChanged('');
                    },
                  )
                : null,
            isDense: true,
            filled: true,
            fillColor: AppColors.surfaceContainerLowest,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.outlineVariant),
            ),
          ),
          style: AppTypography.bodySm,
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              segmented,
              const SizedBox(height: 10),
              searchField,
            ],
          );
        }

        return Row(
          children: [
            Expanded(flex: 3, child: segmented),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: searchField),
          ],
        );
      },
    );
  }
}

class _EmptyCardsState extends StatelessWidget {
  const _EmptyCardsState({
    required this.status,
    required this.hasSearchQuery,
  });

  final CouponCardStatus status;
  final bool hasSearchQuery;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        children: [
          Icon(
            hasSearchQuery ? Icons.search_off_rounded : Icons.sports_soccer_rounded,
            size: 42,
            color: AppColors.slate400,
          ),
          const SizedBox(height: 12),
          Text(
            hasSearchQuery
                ? 'Ningún cliente coincide con la búsqueda.'
                : switch (status) {
                    CouponCardStatus.redeemed => 'Aún no se ha redimido este cupón.',
                    CouponCardStatus.earned => 'Nadie tiene el bono ganado pendiente de redimir.',
                    CouponCardStatus.inProgress => 'Ningún cliente ha empezado a acumular sellos todavía.',
                  },
            textAlign: TextAlign.center,
            style: AppTypography.bodyMd.copyWith(color: AppColors.slate600),
          ),
        ],
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  const _CardTile({required this.card, required this.coupon});

  final CouponCard card;
  final Coupon coupon;

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

  void _openWhatsApp(BuildContext context) {
    final text = switch (card.status) {
      CouponCardStatus.inProgress =>
        '¡Hola ${card.customerName}! ⚽ Llevas ${card.completed} de ${card.required} sellos '
        'en tu tarjeta "${coupon.name}". Te faltan ${card.required - card.completed} reservas para ganar ${coupon.rewardDescription}.',
      CouponCardStatus.earned =>
        '¡Hola ${card.customerName}! 🎉 ¡Completaste todos tus sellos de "${coupon.name}"! '
        'Tienes tu beneficio de ${coupon.rewardDescription} listo para redimir en tu próxima reserva.',
      CouponCardStatus.redeemed =>
        '¡Hola ${card.customerName}! Gracias por participar en nuestro programa de fidelización "${coupon.name}".',
    };
    final uri = ContactLauncher.whatsAppChat(card.customerPhone, text: text);
    if (uri != null) {
      ContactLauncher.open(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtle = AppTypography.bodySm.copyWith(color: AppColors.slate600);
    return Material(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.7)),
        ),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          leading: CircleAvatar(
            radius: 20,
            backgroundColor: switch (card.status) {
              CouponCardStatus.earned => AppColors.accentLimeTint,
              CouponCardStatus.redeemed => AppColors.emerald50,
              CouponCardStatus.inProgress => AppColors.surfaceContainerLow,
            },
            child: Text(
              card.customerName.isNotEmpty ? card.customerName[0].toUpperCase() : '?',
              style: AppTypography.labelMd.copyWith(
                fontWeight: FontWeight.bold,
                color: switch (card.status) {
                  CouponCardStatus.earned => AppColors.brandDark,
                  CouponCardStatus.redeemed => AppColors.brandTeal,
                  CouponCardStatus.inProgress => AppColors.slate700,
                },
              ),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  card.customerName,
                  style: AppTypography.labelLg,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (card.customerPhone.isNotEmpty) ...[
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  icon: Icon(Icons.chat_bubble_rounded, size: 16, color: AppColors.whatsapp),
                  tooltip: 'Contactar por WhatsApp',
                  onPressed: () => _openWhatsApp(context),
                ),
              ],
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(_headline, style: subtle),
                  if (card.status == CouponCardStatus.inProgress && card.completed == card.required - 1) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.accentLimeTint,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.accentLime),
                      ),
                      child: Text(
                        '¡Falta 1!',
                        style: AppTypography.labelSm.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.brandDark,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (card.redeemedAmount case final amount?)
                Text(
                  [
                    'Descuento de ${AppFormatters.cop(amount)}',
                    if (card.redeemedCourts case final courts?)
                      courts == 1 ? '1 cancha' : '$courts canchas',
                  ].join(' · '),
                  style: subtle,
                ),
              const SizedBox(height: 6),
              // Tracker visual de sellos
              _StampProgressBar(
                completed: card.completed,
                required: card.required,
                status: card.status,
              ),
            ],
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 1),
            const SizedBox(height: 10),
            if (card.customerPhone.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.phone_rounded, size: 14, color: AppColors.slate500),
                    const SizedBox(width: 4),
                    Text(
                      ContactLauncher.display(card.customerPhone),
                      style: subtle.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            Text(
              'HISTORIAL DE RESERVAS VINCULADAS',
              style: AppTypography.labelSm.copyWith(
                fontSize: 10,
                color: AppColors.slate500,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            if (card.stamps.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text('Sin detalle de reservas registradas.', style: subtle),
              )
            else
              for (final (i, stamp) in card.stamps.indexed)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Sello #${i + 1}: ${stamp.courtNames.join(' + ')}',
                            style: AppTypography.labelMd.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.emerald50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Validado',
                              style: AppTypography.labelSm.copyWith(
                                fontSize: 10,
                                color: AppColors.emerald800,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Jugada el ${couponDateTime(stamp.playedAt)} · '
                        '${AppFormatters.cop(stamp.amount)}',
                        style: subtle,
                      ),
                      Text(
                        'Llenada en sistema el ${couponDateTime(stamp.stampedAt)}',
                        style: subtle.copyWith(fontSize: 11),
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

/// Visual Step-Progress Bar con sellos
class _StampProgressBar extends StatelessWidget {
  const _StampProgressBar({
    required this.completed,
    required this.required,
    required this.status,
  });

  final int completed;
  final int required;
  final CouponCardStatus status;

  @override
  Widget build(BuildContext context) {
    final totalSteps = required.clamp(1, 10);
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < totalSteps; i++) ...[
            if (i > 0)
              Container(
                width: 10,
                height: 2,
                color: i < completed ? AppColors.brandTeal : AppColors.outlineVariant,
              ),
            _StampDot(
              index: i + 1,
              isCompleted: i < completed,
              isLast: i == totalSteps - 1,
              status: status,
            ),
          ],
        ],
      ),
    );
  }
}

class _StampDot extends StatelessWidget {
  const _StampDot({
    required this.index,
    required this.isCompleted,
    required this.isLast,
    required this.status,
  });

  final int index;
  final bool isCompleted;
  final bool isLast;
  final CouponCardStatus status;

  @override
  Widget build(BuildContext context) {
    if (isLast) {
      final isUnlocked = isCompleted || status == CouponCardStatus.earned || status == CouponCardStatus.redeemed;
      return Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isUnlocked ? AppColors.accentLime : AppColors.surfaceContainerLow,
          border: Border.all(
            color: isUnlocked ? AppColors.brandDark : AppColors.outlineVariant,
            width: 1.5,
          ),
        ),
        child: Icon(
          isUnlocked ? Icons.card_giftcard_rounded : Icons.lock_outline_rounded,
          size: 11,
          color: isUnlocked ? AppColors.brandDark : AppColors.slate400,
        ),
      );
    }

    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted ? AppColors.brandTeal : AppColors.surfaceContainerLow,
        border: Border.all(
          color: isCompleted ? AppColors.brandTeal : AppColors.outlineVariant,
        ),
      ),
      child: Icon(
        isCompleted ? Icons.sports_soccer_rounded : Icons.circle_outlined,
        size: 10,
        color: isCompleted ? Colors.white : AppColors.slate400,
      ),
    );
  }
}
