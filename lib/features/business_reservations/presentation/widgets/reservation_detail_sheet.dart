import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/session/write_access.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../business_payments/domain/entities/payment.dart';
import '../../../business_payments/presentation/widgets/payment_styles.dart';
import '../../../business_sales/domain/entities/sale.dart';
import '../../../business_sales/presentation/widgets/sale_sheet.dart';
import '../../../business_sales/presentation/widgets/sale_tile.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/reservation.dart';
import '../../domain/entities/reservation_failure.dart';
import '../../domain/usecases/booking_usecases.dart';
import '../bloc/reservation_detail/reservation_detail_cubit.dart';
import 'reservation_contact.dart';
import 'reservation_section_card.dart';
import 'reservation_status_pill.dart';
import 'sport_style.dart';

/// Abre el detalle de [reservation] (hoja inferior en el celular, diálogo
/// centrado en web/escritorio). Devuelve `true` si se canceló o cambió su estado.
Future<bool> showReservationDetail(
  BuildContext context, {
  required Reservation reservation,
  required ReservationDetailCubit Function() createCubit,
}) async {
  Widget body(BuildContext _) => BlocProvider(
    create: (_) => createCubit()..load(reservation),
    child: const ReservationDetailView(),
  );

  final bool? changed;
  if (MediaQuery.sizeOf(context).width >= 600) {
    changed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580, maxHeight: 820),
          child: body(context),
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
          maxHeight: MediaQuery.sizeOf(context).height * 0.92,
        ),
        child: body(context),
      ),
    );
  }
  return changed ?? false;
}

class ReservationDetailView extends StatelessWidget {
  const ReservationDetailView({super.key});

  void _close(BuildContext context, ReservationDetailState state) =>
      Navigator.of(context).pop(state.changed);

  Future<void> _confirmCancel(BuildContext context) async {
    if (!ensureCanWrite(context)) return;
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => _CancelDialog(
        courts: switch (context
            .read<ReservationDetailCubit>()
            .state
            .reservation) {
          final r? when r.group != null => r.courtsLabel,
          _ => null,
        },
      ),
    );
    if (reason == null || !context.mounted) return;
    final cubit = context.read<ReservationDetailCubit>();
    await cubit.cancel(reason);
    if (!context.mounted || cubit.state.action != ReservationAction.done) {
      return;
    }
    // Cancelada: cierra el detalle (el aviso lo muestra el listener).
    _close(context, cubit.state);
  }

  /// Pide confirmación antes de marcar "No asistió" o "Jugada".
  Future<void> _confirmStatus(
    BuildContext context,
    ReservationStatus status,
  ) async {
    if (!ensureCanWrite(context)) return;
    final noShow = status == ReservationStatus.noShow;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          noShow ? '¿Marcar como no asistió?' : '¿Marcar como jugada?',
        ),
        content: Text(
          noShow
              ? 'La reserva quedará como no asistió. Puedes deshacerlo con '
                    '"Volver a confirmada".'
              : 'La reserva quedará marcada como jugada.',
        ),
        actions: [
          TextButton(
            key: const Key('status-back'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Volver'),
          ),
          FilledButton(
            key: const Key('status-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    _setStatus(context, status);
  }

  /// Abre "Nuevo pago" con esta reserva y su cliente ya elegidos. Al volver
  /// con el pago registrado, el detalle muestra el saldo al día.
  Future<void> _registerPayment(BuildContext context, Reservation r) async {
    if (!ensureCanWrite(context)) return;
    final cubit = context.read<ReservationDetailCubit>();
    final paid = await GoRouter.of(
      context,
    ).push<bool>(AppRoutes.businessNewPayment, extra: r);
    if (paid != true || !context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Pago registrado.')));
    await cubit.paymentRegistered();
  }

  /// Carga bebidas, snacks… a la reserva: suman a su saldo.
  Future<void> _addConsumption(BuildContext context, Reservation r) async {
    if (!ensureCanWrite(context)) return;
    final cubit = context.read<ReservationDetailCubit>();
    final sale = await showSaleSheet(
      context,
      reservationId: r.id,
      subtitle: '${r.customerName} · ${r.courtName}',
    );
    if (sale == null || !context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Consumo agregado: ${AppFormatters.cop(sale.total)}.'),
        ),
      );
    await cubit.refresh();
  }

  Future<void> _voidConsumption(BuildContext context, Sale sale) async {
    if (!ensureCanWrite(context)) return;
    final reason = await showVoidSaleDialog(context);
    if (reason == null || !context.mounted) return;
    final error = await context.read<ReservationDetailCubit>().voidConsumption(
      sale.id,
      reason,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(error ?? 'Consumo anulado.'),
          backgroundColor: error == null ? null : AppColors.statusDue,
        ),
      );
  }

  void _setStatus(BuildContext context, ReservationStatus status) {
    if (!ensureCanWrite(context)) return;
    context.read<ReservationDetailCubit>().setStatus(status);
  }

  void _copySummary(BuildContext context, Reservation r) {
    final text = [
      '🏟️ *RESERVA EN MI CANCHA*',
      'Cliente: ${r.customerName}',
      if (r.phone.isNotEmpty) 'Tel: ${r.phone}',
      'Cancha: ${r.courtsLabel} (${r.sport.name})',
      'Fecha: ${AppFormatters.shortDate(r.start)}',
      'Horario: ${AppFormatters.timeRange(r.start, r.end)}',
      'Total: ${AppFormatters.cop(r.displayTotal)}',
      'Pagado: ${AppFormatters.cop(r.displayPaid)}',
      'Saldo: ${AppFormatters.cop(r.displayBalance)}',
      'Estado: ${r.status.label}',
    ].join('\n');

    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Resumen copiado al portapapeles.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReservationDetailCubit, ReservationDetailState>(
      listenWhen: (prev, curr) => prev.action != curr.action,
      listener: (context, state) {
        final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
        if (state.action == ReservationAction.done) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                'Reserva ${state.reservation!.status.label.toLowerCase()}.',
              ),
            ),
          );
        } else if (state.action == ReservationAction.failure) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(switch (state.failure) {
                ReservationFailure.subscriptionInactive =>
                  'Tu plan no está activo: solo puedes consultar.',
                ReservationFailure.network =>
                  'Sin conexión. Revisa tu internet e intenta de nuevo.',
                _ =>
                  state.failureMessage ??
                      'No pudimos actualizar la reserva. Intenta de nuevo.',
              }),
              backgroundColor: AppColors.statusDue,
            ),
          );
        }
      },
      builder: (context, state) {
        final r = state.reservation;
        if (r == null) {
          return const Padding(
            padding: EdgeInsets.all(48),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final working = state.action == ReservationAction.working;
        final canAct =
            WriteAccessScope.canWrite(context) &&
            r.status != ReservationStatus.cancelled;
        // "No asistió" y "Jugada" solo tienen sentido con el turno iniciado.
        final now = DateTime.now();
        final started = !now.isBefore(r.start);
        // Con el turno ya terminado no se cancela: solo se marca o se cobra.
        final ended = !now.isBefore(r.end);
        const notStartedHint = 'Disponible cuando empiece el turno';

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _close(context, state);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Bar Header
              _HeaderBar(
                reservation: r,
                onClose: () => _close(context, state),
                onCopy: () => _copySummary(context, r),
              ),

              Divider(height: 1, color: AppColors.slate200),

              // Content Body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: _Details(
                    reservation: r,
                    state: state,
                    onAddConsumption: canAct && r.acceptsConsumptions
                        ? () => _addConsumption(context, r)
                        : null,
                    onVoidConsumption: canAct
                        ? (sale) => _voidConsumption(context, sale)
                        : null,
                  ),
                ),
              ),

              if (working) const LinearProgressIndicator(minHeight: 2),

              Divider(height: 1, color: AppColors.slate200),

              // Actions Footer
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(color: AppColors.slate50),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  runAlignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (canAct && r.status == ReservationStatus.confirmed) ...[
                      Tooltip(
                        message: started ? '' : notStartedHint,
                        child: OutlinedButton.icon(
                          key: const Key('mark-no-show'),
                          onPressed: working || !started
                              ? null
                              : () => _confirmStatus(
                                  context,
                                  ReservationStatus.noShow,
                                ),
                          icon: const Icon(Icons.person_off_outlined, size: 18),
                          label: const Text('No asistió'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.slate700,
                            side: BorderSide(color: AppColors.slate200),
                          ),
                        ),
                      ),
                      Tooltip(
                        message: started ? '' : notStartedHint,
                        child: FilledButton.tonalIcon(
                          key: const Key('mark-completed'),
                          onPressed: working || !started
                              ? null
                              : () => _confirmStatus(
                                  context,
                                  ReservationStatus.completed,
                                ),
                          icon: const Icon(Icons.sports_score, size: 18),
                          label: const Text('Jugada'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.emerald50,
                            foregroundColor: AppColors.emerald600,
                          ),
                        ),
                      ),
                      if (!ended)
                        TextButton.icon(
                          key: const Key('cancel-reservation'),
                          onPressed: working
                              ? null
                              : () => _confirmCancel(context),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.statusDue,
                          ),
                          icon: const Icon(Icons.event_busy_outlined, size: 18),
                          label: const Text('Cancelar reserva'),
                        ),
                    ],
                    if (canAct && r.displayBalance > 0)
                      FilledButton.tonalIcon(
                        key: const Key('register-payment'),
                        onPressed: working
                            ? null
                            : () => _registerPayment(context, r),
                        icon: const Icon(Icons.add_card_rounded, size: 18),
                        label: const Text('Realizar pago'),
                      ),
                    if (canAct && r.status != ReservationStatus.confirmed)
                      OutlinedButton.icon(
                        key: const Key('mark-confirmed'),
                        onPressed: working
                            ? null
                            : () => _setStatus(
                                context,
                                ReservationStatus.confirmed,
                              ),
                        icon: const Icon(Icons.undo_rounded, size: 18),
                        label: const Text('Volver a confirmada'),
                      ),
                    FilledButton(
                      onPressed: () => _close(context, state),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brandTeal,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Cerrar'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({
    required this.reservation,
    required this.onClose,
    required this.onCopy,
  });

  final Reservation reservation;
  final VoidCallback onClose;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    final shortId = r.id.length > 8
        ? r.id.substring(0, 8).toUpperCase()
        : r.id.toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: r.sport.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(r.sport.icon, color: r.sport.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 2,
                  children: [
                    Text(
                      'Detalle de Reserva',
                      style: AppTypography.headlineSm.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.slate100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '#$shortId',
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.slate600,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${r.sport.name.toUpperCase()} · ${r.courtsLabel}',
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.slate500,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ReservationStatusPill(status: r.status),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Copiar resumen',
            icon: Icon(Icons.copy_rounded, size: 18, color: AppColors.slate600),
            splashRadius: 18,
            onPressed: onCopy,
          ),
          IconButton(
            tooltip: 'Cerrar',
            icon: Icon(
              Icons.close_rounded,
              size: 20,
              color: AppColors.slate600,
            ),
            splashRadius: 18,
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({
    required this.reservation,
    required this.state,
    this.onAddConsumption,
    this.onVoidConsumption,
  });

  final Reservation reservation;
  final ReservationDetailState state;
  final VoidCallback? onAddConsumption;
  final ValueChanged<Sale>? onVoidConsumption;

  void _launchWhatsApp(BuildContext context) =>
      openReservationChat(context, reservation);

  void _callPhone(BuildContext context) =>
      showCallOptions(context, reservation);

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    final customer = r.customer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. MATCH & SCHEDULE HERO CARD
        _ScheduleHeroCard(reservation: r),

        const SizedBox(height: 16),

        // 2. CUSTOMER & CONTACT CARD
        _CustomerCard(
          reservation: r,
          customer: customer,
          onWhatsApp: () => _launchWhatsApp(context),
          onCall: () => _callPhone(context),
          onHistoryTap: () {
            if (customer != null) {
              final router = GoRouter.of(context);
              Navigator.of(context).pop(state.changed);
              router.go(
                AppRoutes.businessCustomerReservations(
                  customer.id,
                  customer.name,
                ),
              );
            }
          },
        ),

        // 3. CONSUMOS (BEBIDAS, SNACKS…)
        if (onAddConsumption != null || r.consumptions.isNotEmpty) ...[
          const SizedBox(height: 16),
          _ConsumptionsCard(
            reservation: r,
            onAdd: onAddConsumption,
            onVoid: onVoidConsumption,
          ),
        ],

        const SizedBox(height: 16),

        // 4. FINANCIAL SUMMARY & PAYMENTS CARD
        _FinancialCard(reservation: r),

        // 5. CANCELLATION DETAILS (IF CANCELLED)
        if (r.status == ReservationStatus.cancelled) ...[
          const SizedBox(height: 16),
          _CancellationCard(reservation: r),
        ],
      ],
    );
  }
}

class _ScheduleHeroCard extends StatelessWidget {
  const _ScheduleHeroCard({required this.reservation});

  final Reservation reservation;

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    final durationMinutes = r.duration.inMinutes;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
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
                    Text(
                      r.courtsLabel,
                      style: AppTypography.headlineSm.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${r.sport.name.toUpperCase()} · CANCHA DEPORTIVA',
                      style: AppTypography.labelSm.copyWith(
                        color: r.sport.color,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              if (r.tag != null || r.isRecurring)
                Wrap(
                  spacing: 6,
                  children: [
                    if (r.isRecurring)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.infoTint,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.repeat_rounded,
                              size: 12,
                              color: AppColors.infoInk,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Recurrente',
                              style: AppTypography.labelSm.copyWith(
                                color: AppColors.infoInk,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (r.tag case final tag?)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.brandTealLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tag,
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.brandTealDeep,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),

          const SizedBox(height: 14),
          Divider(height: 1, color: AppColors.slate100),
          const SizedBox(height: 14),

          // Date and Time info
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.slate50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.slate200),
                      ),
                      child: Icon(
                        Icons.calendar_today_rounded,
                        size: 18,
                        color: AppColors.slate700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FECHA',
                            style: AppTypography.labelSm.copyWith(
                              color: AppColors.slate500,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            AppFormatters.shortDate(r.start),
                            style: AppTypography.bodyMd.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.brandTealLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.access_time_filled_rounded,
                        size: 18,
                        color: AppColors.brandTeal,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'HORARIO ($durationMinutes min)',
                            style: AppTypography.labelSm.copyWith(
                              color: AppColors.slate500,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            AppFormatters.timeRange(r.start, r.end),
                            style: AppTypography.bodyMd.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({
    required this.reservation,
    required this.customer,
    required this.onWhatsApp,
    required this.onCall,
    required this.onHistoryTap,
  });

  final Reservation reservation;
  final Customer? customer;
  final VoidCallback onWhatsApp;
  final VoidCallback onCall;
  final VoidCallback onHistoryTap;

  String _initials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'CL';
    if (parts.length == 1)
      return parts.first.substring(0, min(2, parts.first.length)).toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    final initials = _initials(r.customerName);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.brandTeal,
                child: Text(
                  initials,
                  style: AppTypography.labelMd.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.customerName,
                      style: AppTypography.headlineSm.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (r.customerDetail case final detail?)
                      Text(
                        detail,
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.slate500,
                        ),
                      ),
                  ],
                ),
              ),
              if (customer != null)
                TextButton.icon(
                  key: const Key('customer-history'),
                  onPressed: onHistoryTap,
                  icon: const Icon(Icons.history_rounded, size: 16),
                  label: const Text(
                    'Historial del cliente',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppColors.brandTeal,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),
          Divider(height: 1, color: AppColors.slate100),
          const SizedBox(height: 12),

          // Contact details & WhatsApp Actions
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CONTACTO / DOCUMENTO',
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.slate500,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (r.phone.isNotEmpty) r.phone,
                        if (customer != null && customer!.documentId.isNotEmpty)
                          'C.C. ${customer!.documentId}',
                      ].join(' · '),
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (r.phone.isNotEmpty) ...[
                OutlinedButton.icon(
                  onPressed: onWhatsApp,
                  icon: Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 16,
                    color: AppColors.whatsappDark,
                  ),
                  label: Text(
                    'WhatsApp',
                    style: TextStyle(
                      color: AppColors.whatsappDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.whatsapp),
                    backgroundColor: AppColors.successTint,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  tooltip: 'Llamar',
                  onPressed: onCall,
                  icon: Icon(
                    Icons.phone_outlined,
                    size: 16,
                    color: AppColors.slate700,
                  ),
                  style: IconButton.styleFrom(
                    side: BorderSide(color: AppColors.slate200),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ],
          ),

          if (r.contactNote case final note?) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.slate50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.slate200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.notes_rounded,
                    size: 16,
                    color: AppColors.slate500,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      note,
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.slate600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FinancialCard extends StatelessWidget {
  const _FinancialCard({required this.reservation});

  final Reservation reservation;

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    final isPaid = r.isFullyPaid;
    final progress = r.displayTotal > 0
        ? (r.displayPaid / r.displayTotal).clamp(0.0, 1.0)
        : 1.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Text(
                'RESUMEN FINANCIERO',
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.slate500,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isPaid
                      ? AppColors.brandTealLight
                      : AppColors.warningTint,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isPaid ? 'PAGADO 100%' : 'SALDO PENDIENTE',
                  style: AppTypography.labelSm.copyWith(
                    color: isPaid
                        ? AppColors.brandTealDeep
                        : AppColors.warningInk,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Total and Pending amount highlight boxes
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.slate50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Reserva',
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.slate500,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppFormatters.cop(r.displayTotal),
                        style: AppTypography.headlineSm.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isPaid
                        ? AppColors.successTint
                        : AppColors.dangerTint,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isPaid
                          ? AppColors.successBorder
                          : AppColors.dangerBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPaid ? 'Completado' : 'Saldo por Cobrar',
                        style: AppTypography.labelSm.copyWith(
                          color: isPaid
                              ? AppColors.emerald800
                              : AppColors.statusDue,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppFormatters.cop(r.displayBalance),
                        style: AppTypography.headlineSm.copyWith(
                          color: isPaid
                              ? AppColors.emerald800
                              : AppColors.statusDue,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.slate100,
              valueColor: AlwaysStoppedAnimation<Color>(
                isPaid ? AppColors.brandTeal : const Color(0xFFF59E0B),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Detailed Breakdown
          if (r.displayConsumptions > 0) ...[
            ReservationAmountRow(
              label: r.group == null ? 'Cancha' : 'Canchas',
              value: AppFormatters.cop(r.displayTotal - r.displayConsumptions),
            ),
            ReservationAmountRow(
              label: 'Consumos',
              value: AppFormatters.cop(r.displayConsumptions),
            ),
          ],
          if (r.discount > 0) ...[
            ReservationAmountRow(
              label: 'Subtotal',
              value: AppFormatters.cop(r.subtotal),
            ),
            ReservationAmountRow(
              label: 'Descuento',
              value: '−${AppFormatters.cop(r.discount)}',
            ),
          ],
          ReservationAmountRow(
            label: 'Total',
            value: AppFormatters.cop(r.displayTotal),
            emphasis: true,
          ),
          ReservationAmountRow(
            label: 'Pagado',
            value: AppFormatters.cop(r.displayPaid),
          ),
          ReservationAmountRow(
            label: 'Saldo',
            value: AppFormatters.cop(r.displayBalance),
            valueColor: isPaid ? AppColors.brandTeal : AppColors.statusDue,
          ),

          // Payments list
          if (r.payments.isNotEmpty) ...[
            const SizedBox(height: 14),
            Divider(height: 1, color: AppColors.slate100),
            const SizedBox(height: 12),
            Text(
              'HISTORIAL DE PAGOS REGISTRADOS',
              style: AppTypography.labelSm.copyWith(
                color: AppColors.slate500,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            for (final p in r.payments) ...[
              _PaymentTile(payment: p),
              const SizedBox(height: 6),
            ],
          ],
        ],
      ),
    );
  }
}

class _ConsumptionsCard extends StatelessWidget {
  const _ConsumptionsCard({required this.reservation, this.onAdd, this.onVoid});

  final Reservation reservation;
  final VoidCallback? onAdd;
  final ValueChanged<Sale>? onVoid;

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'CONSUMOS',
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.slate500,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (r.consumptionsTotal > 0)
                Text(
                  AppFormatters.cop(r.consumptionsTotal),
                  style: AppTypography.bodyMd.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (r.consumptions.isEmpty)
            Text(
              'Bebidas, snacks o alquileres que pidan en el turno. Suman al '
              'saldo de la reserva.',
              style: AppTypography.bodySm.copyWith(color: AppColors.slate500),
            ),
          for (final sale in r.consumptions) ...[
            SaleTile(
              sale: sale,
              onVoid: onVoid == null ? null : () => onVoid!(sale),
            ),
            const SizedBox(height: 6),
          ],
          if (onAdd != null) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                key: const Key('add-consumption'),
                onPressed: onAdd,
                icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                label: const Text('Agregar consumo'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({required this.payment});

  final ReservationPayment payment;

  @override
  Widget build(BuildContext context) {
    final method = PaymentMethod.fromApi(payment.method);
    final p = payment;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: method.tint,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(method.icon, color: method.color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      method.label,
                      style: AppTypography.bodySm.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    if (p.concept != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.slate200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          p.concept!.label,
                          style: AppTypography.labelSm.copyWith(
                            fontSize: 10,
                            color: AppColors.slate700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  [
                    if (p.reference case final ref?) 'Ref. $ref',
                    if (p.status != null) p.status!.label,
                  ].join(' · '),
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.slate500,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            AppFormatters.cop(p.amount),
            style: AppTypography.bodyMd.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _CancellationCard extends StatelessWidget {
  const _CancellationCard({required this.reservation});

  final Reservation reservation;

  @override
  Widget build(BuildContext context) {
    final r = reservation;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.dangerTint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dangerBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.cancel_rounded, color: AppColors.statusDue, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RESERVA CANCELADA',
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.statusDue,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                if (r.cancellationReason case final reason?) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Motivo: $reason',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.slate700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  [
                    if (r.cancelledBy case final by?) 'Por $by',
                    if (r.cancelledAt case final at?)
                      AppFormatters.shortDate(at),
                  ].join(' · '),
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.slate600,
                    fontSize: 11,
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

/// Pide el motivo (3 a 200 caracteres) antes de cancelar.
class _CancelDialog extends StatefulWidget {
  const _CancelDialog({this.courts});

  /// Canchas de una reserva de varias canchas: se cancelan todas.
  final String? courts;

  @override
  State<_CancelDialog> createState() => _CancelDialogState();
}

class _CancelDialogState extends State<_CancelDialog> {
  final _reason = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  static const _quickReasons = [
    'El cliente no asistió',
    'El cliente no pagó',
    'Cliente problemático',
    'El cliente pidió cancelar',
    'Cancha no disponible',
    'Mal clima',
  ];

  void _useReason(String reason) {
    _reason.value = TextEditingValue(
      text: reason,
      selection: TextSelection.collapsed(offset: reason.length),
    );
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.dangerTint,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.event_busy_rounded,
              color: AppColors.statusDue,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(child: Text('¿Cancelar la reserva?')),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.courts == null
                  ? 'El turno quedará libre al instante en la agenda. Los pagos aprobados se registrarán para devolución.'
                  : 'Es una reserva de varias canchas: se cancelan todas '
                        '(${widget.courts}) y quedan libres al instante. Los '
                        'pagos aprobados se registrarán para devolución.',
              style: AppTypography.bodyMd.copyWith(color: AppColors.slate600),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('cancel-reason'),
              controller: _reason,
              autofocus: true,
              maxLines: 2,
              maxLength: CancelReservation.maxReason,
              inputFormatters: [
                LengthLimitingTextInputFormatter(CancelReservation.maxReason),
              ],
              decoration: InputDecoration(
                labelText: 'Motivo de la cancelación',
                hintText: 'Ej. El cliente avisó que no puede asistir',
                filled: true,
                fillColor: AppColors.slate50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.slate200),
                ),
              ),
              validator: (value) =>
                  CancelReservation.validateReason(value ?? ''),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 0,
              children: [
                for (final reason in _quickReasons)
                  ActionChip(
                    label: Text(reason),
                    labelStyle: AppTypography.bodyMd.copyWith(
                      color: AppColors.slate600,
                    ),
                    backgroundColor: AppColors.slate50,
                    side: BorderSide(color: AppColors.slate200),
                    onPressed: () => _useReason(reason),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Volver'),
        ),
        FilledButton(
          key: const Key('confirm-cancel'),
          style: FilledButton.styleFrom(backgroundColor: AppColors.statusDue),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop(_reason.text.trim());
            }
          },
          child: const Text('Cancelar reserva'),
        ),
      ],
    );
  }
}
