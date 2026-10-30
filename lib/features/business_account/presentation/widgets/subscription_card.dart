import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/pulsing_dot.dart';
import '../../domain/entities/business_account.dart';
import 'account_card.dart';

/// Tarjeta destacada "Plan actual": precio, fechas, uso de canchas,
/// acciones y beneficios.
class SubscriptionCard extends StatelessWidget {
  const SubscriptionCard({
    super.key,
    required this.subscription,
    required this.onUpgrade,
    required this.onRequestMoreCourts,
    required this.onBillingHistory,
  });

  final Subscription subscription;
  final VoidCallback onUpgrade;
  final VoidCallback onRequestMoreCourts;
  final VoidCallback onBillingHistory;

  @override
  Widget build(BuildContext context) {
    final plan = subscription;
    // En plan de pago se piden más canchas; en prueba se cambia de plan.
    final actionLabel = plan.isPaidPlan
        ? 'Agregar más canchas'
        : switch (plan.nextPlanName) {
            final next? => 'Cambiar al plan $next',
            null => null,
          };
    return AccountCard(
      elevated: true,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Acento deportivo superior.
          SizedBox(
            height: 6,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.brandTealGlow,
                    AppColors.accentLimeSignal,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(plan: plan),
                const SizedBox(height: 12),
                _Price(price: plan.monthlyPrice),
                if (plan.isPaidPlan) ...[
                  const SizedBox(height: 8),
                  _ContractedCourts(courtLimit: plan.courtLimit),
                ],
                const SizedBox(height: 12),
                _Dates(plan: plan),
                if (plan.autoBilling) ...[
                  const SizedBox(height: 8),
                  const _AutoBillingNote(),
                ],
                const SizedBox(height: 16),
                _CourtUsage(plan: plan),
                if (actionLabel != null) ...[
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: plan.isPaidPlan
                        ? onRequestMoreCourts
                        : onUpgrade,
                    icon: Icon(
                      plan.isPaidPlan ? Icons.add : Icons.rocket_launch,
                      size: 19,
                    ),
                    label: Text(actionLabel),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: AppColors.brandTeal,
                      foregroundColor: AppColors.onPrimary,
                      textStyle: AppTypography.labelLg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                TextButton.icon(
                  onPressed: onBillingHistory,
                  icon: const Icon(Icons.receipt_long, size: 17),
                  label: const Text('Ver historial de facturación'),
                  style: TextButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    foregroundColor: AppColors.brandTeal,
                    textStyle: AppTypography.labelMd,
                  ),
                ),
                const SizedBox(height: 8),
                _Benefits(benefits: plan.benefits),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.plan});

  final Subscription plan;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const AccountIconBox(icon: Icons.workspace_premium),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PLAN ACTUAL',
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.onSurfaceVariant,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                plan.planName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.headlineSm.copyWith(
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _StatusBadge(active: plan.isActive),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.brandTeal : AppColors.statusDue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active ? AppColors.brandTealLight : AppColors.errorContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          active
              ? PulsingDot(color: AppColors.brandTeal)
              : Icon(Icons.error_outline, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            active ? 'Activa' : 'Inactiva',
            style: AppTypography.labelSm.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _Price extends StatelessWidget {
  const _Price({required this.price});

  final int price;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 6,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: AppFormatters.cop(price),
                  style: AppTypography.displayLg.copyWith(
                    fontSize: 28,
                    color: AppColors.brandTeal,
                  ),
                ),
                TextSpan(
                  text: ' COP / mes',
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Sin sobrecostos',
              style: AppTypography.labelSm.copyWith(color: AppColors.brandTeal),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContractedCourts extends StatelessWidget {
  const _ContractedCourts({required this.courtLimit});

  final int courtLimit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.stadium, size: 16, color: AppColors.brandTeal),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            courtLimit == 1
                ? '1 cancha contratada'
                : '$courtLimit canchas contratadas',
            style: AppTypography.labelMd.copyWith(color: AppColors.onSurface),
          ),
        ),
      ],
    );
  }
}

class _Dates extends StatelessWidget {
  const _Dates({required this.plan});

  final Subscription plan;

  @override
  Widget build(BuildContext context) {
    Widget item(String label, DateTime date, {bool highlight = false}) =>
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      label,
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (highlight) ...[
                    const SizedBox(width: 4),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accentLime,
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                AppFormatters.mediumDate(date),
                style: AppTypography.labelMd.copyWith(
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
        );

    return Row(
      children: [
        item('Suscrito desde', plan.since),
        const SizedBox(width: 12),
        item('Próximo pago', plan.nextPayment, highlight: true),
      ],
    );
  }
}

class _AutoBillingNote extends StatelessWidget {
  const _AutoBillingNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.autorenew, size: 15, color: AppColors.brandTeal),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Facturación automática con tarjeta bancaria',
              style: AppTypography.bodySm.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CourtUsage extends StatelessWidget {
  const _CourtUsage({required this.plan});

  final Subscription plan;

  @override
  Widget build(BuildContext context) {
    final percent = (plan.usage * 100).round();
    final free = plan.freeCourtSlots;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceTealSubtle,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 8,
            runSpacing: 2,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.stadium, size: 16, color: AppColors.brandTeal),
                  const SizedBox(width: 6),
                  Text(
                    'Uso de canchas',
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
              Text(
                '${plan.courtsInUse} de ${plan.courtLimit} canchas ($percent%)',
                style: AppTypography.labelMd.copyWith(
                  color: AppColors.brandTeal,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Semantics(
            label: 'Uso de canchas: $percent%',
            child: ExcludeSemantics(
              child: Container(
                height: 10,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: plan.usage,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(999)),
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.brandTealGlow],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            free == 0
                ? plan.isPaidPlan
                      ? 'Usaste todas tus canchas contratadas. Pide más para '
                            'seguir creciendo.'
                      : 'Usaste todos los cupos de tu plan. Mejóralo para '
                            'sumar más canchas.'
                : 'Tienes $free ${free == 1 ? 'cupo libre disponible' : 'cupos libres disponibles'} '
                      'para expandir tu complejo deportivo.',
            style: AppTypography.bodySm.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Ver beneficios incluidos": se despliega al tocarlo.
class _Benefits extends StatefulWidget {
  const _Benefits({required this.benefits});

  final List<PlanBenefit> benefits;

  @override
  State<_Benefits> createState() => _BenefitsState();
}

class _BenefitsState extends State<_Benefits> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 200);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          expanded: _expanded,
          child: Material(
            color: AppColors.surfaceTealSubtle,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => _expanded = !_expanded),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      Icon(
                        Icons.task_alt,
                        size: 18,
                        color: AppColors.brandTeal,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Ver beneficios incluidos',
                          style: AppTypography.labelMd.copyWith(
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.brandTealLight,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${widget.benefits.length} activos',
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.brandTeal,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: duration,
                        child: Icon(
                          Icons.expand_more,
                          size: 20,
                          color: AppColors.outlineVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: duration,
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: _expanded
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
                  child: Column(
                    children: [
                      for (final benefit in widget.benefits)
                        _BenefitRow(benefit: benefit),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.benefit});

  final PlanBenefit benefit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.brandTealLight,
            ),
            child: Icon(Icons.check, size: 15, color: AppColors.brandTeal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  benefit.title,
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  benefit.detail,
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.onSurfaceVariant,
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

/// El negocio aún no tiene plan contratado.
class NoPlanCard extends StatelessWidget {
  const NoPlanCard({super.key, required this.onSeePlans});

  final VoidCallback onSeePlans;

  @override
  Widget build(BuildContext context) {
    return AccountCard(
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const AccountIconBox(icon: Icons.workspace_premium),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Sin plan activo',
                  style: AppTypography.headlineSm.copyWith(
                    color: AppColors.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Elige un plan para registrar tus canchas y recibir reservas.',
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onSeePlans,
            icon: const Icon(Icons.rocket_launch, size: 19),
            label: const Text('Ver planes'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: AppColors.brandTeal,
              textStyle: AppTypography.labelLg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
