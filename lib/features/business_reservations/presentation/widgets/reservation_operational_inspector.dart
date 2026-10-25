import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../business_payments/domain/entities/payment.dart';
import '../../domain/entities/reservation.dart';
import '../bloc/reservation_detail/reservation_detail_cubit.dart';
import 'reservation_contact.dart';
import 'reservation_status_pill.dart';
import 'sport_style.dart';

/// Panel lateral de inspección operativa y cobro en taquilla para Web / Escritorio.
class ReservationOperationalInspector extends StatelessWidget {
  const ReservationOperationalInspector({
    super.key,
    required this.reservation,
    required this.onOpenDetail,
    this.createDetailCubit,
  });

  final Reservation reservation;
  final ValueChanged<Reservation> onOpenDetail;
  final ReservationDetailCubit Function()? createDetailCubit;

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    final isFinished = r.status == ReservationStatus.completed;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(
          left: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header del Inspector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.brandTealLight.withValues(alpha: 0.4),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.brandTeal,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DETALLE OPERATIVO DE CANCHA',
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Reserva #${r.id.length > 8 ? r.id.substring(0, 8).toUpperCase() : r.id.toUpperCase()}',
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                _statusBadge(r),
              ],
            ),
          ),
          // Contenido con scroll
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Highlight de la cancha y horario
                _CourtHighlightBanner(reservation: r),
                const SizedBox(height: 14),

                // Tarjeta de Identidad del Cliente
                _CustomerIdentityCard(
                  reservation: r,
                  onCall: () => showCallOptions(context, r),
                ),
                const SizedBox(height: 14),

                // Liquidación Financiera del Turno
                _FinancialBreakdownCard(
                  reservation: r,
                  onSelectPaymentMethod: (method) {
                    onOpenDetail(r);
                  },
                ),
                const SizedBox(height: 14),

                // Acciones operativas de gestión
                _ManagementActionsCard(
                  reservation: r,
                  onActionSelected: () => onOpenDetail(r),
                ),
              ],
            ),
          ),
          // Botón inferior sticky CTA
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              border: Border(
                top: BorderSide(
                  color: AppColors.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: FilledButton.icon(
              onPressed: () => onOpenDetail(r),
              style: FilledButton.styleFrom(
                backgroundColor: !r.isFullyPaid
                    ? AppColors.accentLime
                    : AppColors.brandTeal,
                foregroundColor: !r.isFullyPaid
                    ? AppColors.inverseSurface
                    : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(
                !r.isFullyPaid
                    ? Icons.point_of_sale_rounded
                    : (isFinished ? Icons.receipt_long : Icons.open_in_new),
                size: 18,
              ),
              label: Text(
                !r.isFullyPaid
                    ? 'Cobrar ${AppFormatters.cop(r.displayBalance)} y Dar Entrada'
                    : 'Ver Detalle Completo',
                style: AppTypography.labelMd.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(Reservation r) {
    if (r.status == ReservationStatus.noShow) {
      return const ReservationStatusPill(status: ReservationStatus.noShow);
    }
    if (r.status == ReservationStatus.completed) {
      return const ReservationStatusPill(status: ReservationStatus.completed);
    }
    if (r.isFullyPaid) {
      return const ReservationStatusPill(status: ReservationStatus.confirmed);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.statusDeposit.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.statusDeposit.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        'Pago Pendiente',
        style: AppTypography.labelSm.copyWith(
          color: AppColors.statusDeposit,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _CourtHighlightBanner extends StatelessWidget {
  const _CourtHighlightBanner({required this.reservation});

  final Reservation reservation;

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    final time =
        '${AppFormatters.timeRange(r.start, r.end)} (${AppFormatters.duration(r.duration)})';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.brandDark, AppColors.brandTeal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandTeal.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CANCHA ASIGNADA',
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.accentLime,
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                  letterSpacing: 0.8,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(r.sport.icon, size: 12, color: AppColors.accentLime),
                    const SizedBox(width: 4),
                    Text(
                      r.sport.name.toUpperCase(),
                      style: AppTypography.labelSm.copyWith(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            r.courtsLabel,
            style: AppTypography.headlineSm.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.schedule, size: 14, color: AppColors.accentLime),
              const SizedBox(width: 4),
              Text(
                time,
                style: AppTypography.bodySm.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Grama Sintética Pro',
                  style: AppTypography.bodySm.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 11,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brandDark,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Luz LED Incluida',
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.accentLime,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
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

class _CustomerIdentityCard extends StatelessWidget {
  const _CustomerIdentityCard({
    required this.reservation,
    required this.onCall,
  });

  final Reservation reservation;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    final initial = r.customerName.isNotEmpty
        ? r.customerName.substring(0, 1).toUpperCase()
        : 'C';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.brandTeal,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: AppTypography.headlineSm.copyWith(
                      color: AppColors.accentLime,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            r.customerName,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.headlineSm.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.verified_rounded,
                          size: 14,
                          color: AppColors.brandTeal,
                        ),
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      r.phone.isNotEmpty ? r.phone : 'Sin teléfono',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '100% Asistencia',
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.brandTeal,
                        fontWeight: FontWeight.w800,
                        fontSize: 9,
                      ),
                    ),
                    Text(
                      'Cliente habitual',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCall,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.call_outlined, size: 14),
                  label: const Text('Llamar', style: TextStyle(fontSize: 11)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => openReservationChat(context, r),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.whatsappDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.chat_outlined, size: 14),
                  label: const Text('WhatsApp', style: TextStyle(fontSize: 11)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FinancialBreakdownCard extends StatelessWidget {
  const _FinancialBreakdownCard({
    required this.reservation,
    required this.onSelectPaymentMethod,
  });

  final Reservation reservation;
  final ValueChanged<PaymentMethod> onSelectPaymentMethod;

  @override
  Widget build(BuildContext context) {
    final r = reservation;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LIQUIDACIÓN DE TURNO',
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                r.isFullyPaid ? 'Pagado Total' : 'Pendiente de Cobro',
                style: AppTypography.labelSm.copyWith(
                  color: r.isFullyPaid
                      ? AppColors.statusPaid
                      : AppColors.statusDeposit,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          _row(
            'Tarifa Turno (${AppFormatters.duration(r.duration)})',
            AppFormatters.cop(r.displayTotal),
          ),
          const SizedBox(height: 4),
          _row(
            'Anticipo recibido',
            AppFormatters.cop(r.displayPaid),
            color: AppColors.statusPaid,
          ),
          const Divider(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total por Cobrar en Taquilla',
                style: AppTypography.labelMd.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              Text(
                '${AppFormatters.cop(r.displayBalance)} COP',
                style: AppTypography.headlineSm.copyWith(
                  color: r.displayBalance > 0
                      ? AppColors.statusDeposit
                      : AppColors.statusPaid,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          if (!r.isFullyPaid) ...[
            const SizedBox(height: 12),
            Text(
              'Registrar Cobro Rápido:',
              style: AppTypography.labelSm.copyWith(
                color: AppColors.onSurfaceVariant,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _PayButton(
                    label: 'Efectivo',
                    icon: Icons.money_rounded,
                    color: AppColors.brandTeal,
                    onTap: () => onSelectPaymentMethod(PaymentMethod.efectivo),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _PayButton(
                    label: 'Nequi',
                    icon: Icons.phone_android_rounded,
                    color: Colors.purple,
                    onTap: () => onSelectPaymentMethod(PaymentMethod.nequi),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _PayButton(
                    label: 'Transferencia',
                    icon: Icons.credit_card_rounded,
                    color: Colors.blueGrey,
                    onTap: () =>
                        onSelectPaymentMethod(PaymentMethod.transferencia),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodySm.copyWith(
            color: AppColors.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
        Text(
          value,
          style: AppTypography.bodySm.copyWith(
            color: color ?? AppColors.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _PayButton extends StatelessWidget {
  const _PayButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.labelSm.copyWith(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManagementActionsCard extends StatelessWidget {
  const _ManagementActionsCard({
    required this.reservation,
    required this.onActionSelected,
  });

  final Reservation reservation;
  final VoidCallback onActionSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GESTIÓN DEL TURNO',
          style: AppTypography.labelSm.copyWith(
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w800,
            fontSize: 10,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _actionButton(
                icon: Icons.edit_calendar_outlined,
                label: 'Reprogramar',
                onTap: onActionSelected,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _actionButton(
                icon: Icons.sports_score_rounded,
                label: 'Ver detalle',
                onTap: onActionSelected,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 11)),
    );
  }
}
