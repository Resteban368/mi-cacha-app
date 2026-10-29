import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/session/write_access.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../business_payments/domain/entities/payment.dart';
import '../../../business_payments/presentation/pages/new_payment_page.dart';
import '../../../business_payments/presentation/widgets/payment_styles.dart';
import '../../../business_reservations/domain/entities/reservation.dart';
import '../../../business_reservations/domain/usecases/booking_usecases.dart';
import '../../../business_reservations/presentation/bloc/reservation_detail/reservation_detail_cubit.dart';
import '../../../business_reservations/presentation/widgets/reservation_detail_sheet.dart';
import '../../domain/entities/sale.dart';

const _sky = Color(0xFF0284C7);

/// Estado de cobro de una venta, para la etiqueta y su color.
(String, Color) saleStatusBadge(Sale sale) {
  if (sale.isVoided) return ('Anulada', AppColors.statusDue);
  if (sale.paymentMethod case final code?) {
    final method = PaymentMethod.fromApi(code);
    return ('Cobrado · ${method.label}', method.color);
  }
  if (sale.reservationPaid) {
    return ('Pagado con la reserva', AppColors.emerald600);
  }
  if (sale.isPartlyPaid) return ('Abonado con la reserva', AppColors.amber500);
  return ('Cargado a la reserva', _sky);
}

/// Lo que hay que pagar en la reserva para que [sale] quede cubierta: lo
/// pagado cubre primero la cancha y los consumos anteriores, así que es el
/// saldo menos lo pendiente de los consumos que se cargaron después.
int amountToCover(Sale sale, Reservation reservation) {
  final later = reservation.consumptions
      .where(
        (s) => !s.isVoided && !s.isPaid && s.createdAt.isAfter(sale.createdAt),
      )
      .fold(0, (sum, s) => sum + s.reservationPending);
  final balance = reservation.displayBalance;
  return (balance - later).clamp(sale.reservationPending, balance);
}

/// Detalle de una venta: productos, cobro y, si es un consumo, su reserva
/// con accesos para verla y cobrar lo pendiente. Devuelve `true` si se
/// registró un pago o cambió la reserva (hay que recargar).
Future<bool> showSaleDetail(
  BuildContext context, {
  required Sale sale,
  Future<Reservation> Function(String id)? loadReservation,
  ReservationDetailCubit Function()? createReservationCubit,
}) async {
  final detail = _SaleDetail(
    sale: sale,
    loadReservation: loadReservation ?? sl<GetReservation>().call,
    createReservationCubit:
        createReservationCubit ?? () => sl<ReservationDetailCubit>(),
  );
  final bool? changed;
  if (MediaQuery.sizeOf(context).width >= 600) {
    changed = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 760),
          child: detail,
        ),
      ),
    );
  } else {
    changed = await showModalBottomSheet<bool>(
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
        child: detail,
      ),
    );
  }
  return changed ?? false;
}

class _SaleDetail extends StatefulWidget {
  const _SaleDetail({
    required this.sale,
    required this.loadReservation,
    required this.createReservationCubit,
  });

  final Sale sale;
  final Future<Reservation> Function(String id) loadReservation;
  final ReservationDetailCubit Function() createReservationCubit;

  @override
  State<_SaleDetail> createState() => _SaleDetailState();
}

class _SaleDetailState extends State<_SaleDetail> {
  bool _busy = false;

  Sale get sale => widget.sale;

  Future<Reservation?> _reservation() async {
    final id = sale.reservationId;
    if (id == null) return null;
    setState(() => _busy = true);
    try {
      return await widget.loadReservation(id);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: const Text('No pudimos cargar la reserva.'),
              backgroundColor: AppColors.statusDue,
            ),
          );
      }
      return null;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openReservation() async {
    final reservation = await _reservation();
    if (reservation == null || !mounted) return;
    final navigator = Navigator.of(context);
    final changed = await showReservationDetail(
      context,
      reservation: reservation,
      createCubit: widget.createReservationCubit,
    );
    // Desde la reserva se pudo pagar o anular: la lista se recarga.
    if (changed) navigator.pop(true);
  }

  Future<void> _charge() async {
    if (!ensureCanWrite(context)) return;
    final reservation = await _reservation();
    if (reservation == null || !mounted) return;
    final navigator = Navigator.of(context);
    final paid = await GoRouter.of(context).push<bool>(
      AppRoutes.businessNewPayment,
      extra: NewPaymentArgs(
        reservation: reservation,
        amount: amountToCover(sale, reservation),
      ),
    );
    if (paid == true) navigator.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final (badge, badgeColor) = saleStatusBadge(sale);
    final consumption = !sale.isWalkIn;
    final pending = !sale.isVoided && !sale.isPaid
        ? sale.reservationPending
        : 0;
    final canWrite = WriteAccessScope.canWrite(context);
    final muted = AppTypography.bodySm.copyWith(color: AppColors.slate500);

    final header = Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: (consumption ? _sky : AppColors.brandTeal).withValues(
              alpha: 0.1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            consumption ? Icons.stadium_outlined : Icons.shopping_cart_outlined,
            color: consumption ? _sky : AppColors.brandTeal,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                consumption ? 'Consumo de cancha' : 'Venta de mostrador',
                style: AppTypography.headlineSm.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${AppFormatters.longDate(sale.createdAt)} · '
                '${AppFormatters.time(sale.createdAt)}',
                style: muted,
              ),
            ],
          ),
        ),
      ],
    );

    final status = Container(
      key: const Key('sale-detail-status'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              badge,
              style: AppTypography.labelLg.copyWith(
                color: badgeColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (pending > 0)
            Text(
              'Faltan ${AppFormatters.cop(pending)}',
              key: const Key('sale-detail-pending'),
              style: AppTypography.labelLg.copyWith(
                color: AppColors.statusDue,
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
    );

    final items = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle('PRODUCTOS'),
        for (final item in sale.items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.quantity} × ${item.productName}',
                        style: AppTypography.bodyMd.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${AppFormatters.cop(item.unitPrice)} c/u',
                        style: muted,
                      ),
                    ],
                  ),
                ),
                Text(
                  AppFormatters.cop(item.subtotal),
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        Divider(height: 20, color: AppColors.slate200),
        Row(
          children: [
            Expanded(
              child: Text(
                'Total',
                style: AppTypography.labelLg.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              AppFormatters.cop(sale.total),
              key: const Key('sale-detail-total'),
              style: AppTypography.headlineSm.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w800,
                decoration: sale.isVoided ? TextDecoration.lineThrough : null,
              ),
            ),
          ],
        ),
      ],
    );

    final reservation = consumption
        ? Container(
            key: const Key('sale-detail-reservation'),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.slate100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionTitle('RESERVA'),
                Text(
                  sale.customerName ?? 'Cliente',
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  [
                    ?sale.courtName,
                    if (sale.reservationStart case final start?)
                      '${AppFormatters.mediumDate(start)} · turno '
                          '${AppFormatters.time(start)}',
                  ].join(' · '),
                  style: muted,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    key: const Key('sale-detail-open-reservation'),
                    onPressed: _busy ? null : _openReservation,
                    icon: const Icon(Icons.event_note_rounded, size: 18),
                    label: const Text('Ver reserva'),
                  ),
                ),
              ],
            ),
          )
        : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                const SizedBox(height: 16),
                status,
                if (sale.isVoided && sale.voidReason != null) ...[
                  const SizedBox(height: 6),
                  Text('Motivo: ${sale.voidReason}', style: muted),
                ],
                const SizedBox(height: 16),
                items,
                if (sale.note case final note? when note.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _SectionTitle('NOTA'),
                  Text(note, style: AppTypography.bodyMd),
                ],
                if (reservation != null) ...[
                  const SizedBox(height: 16),
                  reservation,
                ],
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            16 + MediaQuery.paddingOf(context).bottom,
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cerrar'),
                ),
              ),
              if (pending > 0 && canWrite) ...[
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    key: const Key('sale-detail-charge'),
                    onPressed: _busy ? null : _charge,
                    icon: _busy
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.payments_rounded, size: 18),
                    label: const Text('Cobrar esta venta'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: AppTypography.labelSm.copyWith(
        color: AppColors.slate500,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    ),
  );
}
