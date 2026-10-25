import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../business_reservations/domain/entities/customer.dart';
import '../../../business_reservations/domain/entities/reservation.dart';
import '../bloc/new_payment/new_payment_bloc.dart';
import 'new_payment_shimmer.dart';
import 'payment_styles.dart';

/// Selector unificado para asociar el pago: Por Cliente, Por Reserva o Manual/Nuevo.
class NewPaymentTargetSelector extends StatefulWidget {
  const NewPaymentTargetSelector({
    super.key,
    required this.state,
    required this.onModeChanged,
    required this.onCustomerSearchChanged,
    required this.onCustomerSelected,
    required this.onReservationSearchChanged,
    required this.onReservationSelected,
    required this.manualCustomerController,
    this.onFillReservationBalance,
    this.onLoadMoreCustomers,
  });

  final NewPaymentState state;
  final ValueChanged<PaymentTargetMode> onModeChanged;
  final ValueChanged<String> onCustomerSearchChanged;
  final ValueChanged<Customer?> onCustomerSelected;
  final ValueChanged<String> onReservationSearchChanged;
  final ValueChanged<Reservation?> onReservationSelected;
  final TextEditingController manualCustomerController;
  final void Function(Reservation reservation)? onFillReservationBalance;

  /// Pide la página siguiente de clientes (al llegar al final de la lista).
  final VoidCallback? onLoadMoreCustomers;

  @override
  State<NewPaymentTargetSelector> createState() =>
      _NewPaymentTargetSelectorState();
}

class _NewPaymentTargetSelectorState extends State<NewPaymentTargetSelector> {
  final _customerSearchController = TextEditingController();
  final _reservationSearchController = TextEditingController();

  @override
  void dispose() {
    _customerSearchController.dispose();
    _reservationSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ModeSelector(
          currentMode: widget.state.targetMode,
          onChanged: widget.onModeChanged,
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: switch (widget.state.targetMode) {
            PaymentTargetMode.customer => _buildCustomerView(),
            PaymentTargetMode.reservation => _buildReservationView(),
            PaymentTargetMode.newCustomer => _buildManualCustomerView(),
          },
        ),
      ],
    );
  }

  Widget _buildCustomerView() {
    final selected = widget.state.selectedCustomer;

    if (selected != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        key: ValueKey('customer_selected_${selected.id}'),
        children: [
          _SelectedCustomerCard(
            customer: selected,
            onClear: () {
              widget.onCustomerSelected(null);
              widget.onReservationSelected(null);
            },
          ),
          const SizedBox(height: 14),
          _CustomerReservationsSection(
            customer: selected,
            status: widget.state.customerReservationsStatus,
            reservations: widget.state.customerReservations,
            selectedReservation: widget.state.selectedReservation,
            onSelectReservation: (res) {
              final isCurrentlySelected =
                  widget.state.selectedReservation?.id == res.id;
              if (isCurrentlySelected) {
                widget.onReservationSelected(null);
              } else {
                widget.onReservationSelected(res);
                widget.onFillReservationBalance?.call(res);
              }
            },
          ),
        ],
      );
    }

    final results = widget.state.customerResults;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      key: const ValueKey('customer_search_view'),
      children: [
        _CompactSearchField(
          key: const Key('payment-customer-search'),
          controller: _customerSearchController,
          hint: 'Buscar por nombre, celular o documento…',
          onChanged: (v) {
            widget.manualCustomerController.text = v.trim();
            widget.onCustomerSearchChanged(v);
            setState(() {});
          },
          validator: (v) =>
              (widget.manualCustomerController.text.trim().isEmpty)
              ? 'Ingresa el nombre del cliente'
              : null,
          onClear: () {
            _customerSearchController.clear();
            widget.manualCustomerController.clear();
            widget.onCustomerSearchChanged('');
            setState(() {});
          },
        ),
        const SizedBox(height: 8),
        if (widget.state.customerSearchStatus == EntitySearchStatus.loading &&
            results.isEmpty)
          const NewPaymentCustomerListShimmer(itemCount: 3)
        else if (results.isEmpty)
          _EmptyNotice(
            icon: Icons.person_off_outlined,
            message: _customerSearchController.text.trim().isEmpty
                ? 'Aún no tienes clientes registrados'
                : 'No se encontraron clientes con "${_customerSearchController.text.trim()}"',
          )
        else ...[
          // Mientras busca se mantienen los resultados anteriores.
          if (widget.state.customerSearchStatus == EntitySearchStatus.loading)
            Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: LinearProgressIndicator(
                minHeight: 2,
                color: AppColors.brandTeal,
                backgroundColor: AppColors.brandTealLight,
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 4),
            child: Text(
              _customerSearchController.text.trim().isEmpty
                  ? 'CLIENTES (${results.length}${widget.state.customerHasMore ? '+' : ''})'
                  : 'RESULTADOS',
              style: AppTypography.labelSm.copyWith(
                color: AppColors.slate400,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                fontSize: 10,
              ),
            ),
          ),
          _PagedCustomerList(
            customers: results,
            hasMore: widget.state.customerHasMore,
            loadMoreStatus: widget.state.customerLoadMoreStatus,
            onLoadMore: widget.onLoadMoreCustomers,
            onSelected: (c) {
              _customerSearchController.text = c.name;
              widget.manualCustomerController.text = c.name;
              widget.onCustomerSelected(c);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildReservationView() {
    final selected = widget.state.selectedReservation;

    if (selected != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        key: ValueKey('res_selected_${selected.id}'),
        children: [
          _SelectedReservationCard(
            reservation: selected,
            onClear: () => widget.onReservationSelected(null),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      key: const ValueKey('reservation_search_view'),
      children: [
        AppTextField(
          label: 'Buscar reserva',
          prefixIcon: Icons.calendar_today_rounded,
          controller: _reservationSearchController,
          hintText: 'Cancha, nombre o teléfono...',
          onChanged: widget.onReservationSearchChanged,
          suffixIcon: _reservationSearchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    _reservationSearchController.clear();
                    widget.onReservationSearchChanged('');
                  },
                )
              : null,
        ),
        const SizedBox(height: 10),
        if (widget.state.reservationSearchStatus == EntitySearchStatus.loading)
          const NewPaymentReservationListShimmer(itemCount: 3)
        else if (widget.state.reservationResults.isEmpty)
          _EmptyNotice(
            icon: Icons.event_busy_outlined,
            message: _reservationSearchController.text.trim().isEmpty
                ? 'No hay reservas recientes disponibles'
                : 'No se encontraron reservas con "${_reservationSearchController.text.trim()}"',
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.state.reservationResults.length.clamp(0, 5),
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final res = widget.state.reservationResults[index];
              return _ReservationTile(
                reservation: res,
                onTap: () {
                  widget.onReservationSelected(res);
                  widget.manualCustomerController.text = res.customerName;
                  widget.onFillReservationBalance?.call(res);
                },
              );
            },
          ),
      ],
    );
  }

  Widget _buildManualCustomerView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      key: const ValueKey('manual_customer_view'),
      children: [
        AppTextField(
          label: 'Nombre del cliente',
          prefixIcon: Icons.person_outline_rounded,
          controller: widget.manualCustomerController,
          hintText: 'Ej. Andrés Parra',
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          validator: (v) => (v?.trim().isEmpty ?? true)
              ? 'Ingresa el nombre del cliente'
              : null,
        ),
      ],
    );
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.currentMode, required this.onChanged});

  final PaymentTargetMode currentMode;
  final ValueChanged<PaymentTargetMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.slate100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Row(
        children: [
          _TabItem(
            label: 'Por Cliente',
            icon: Icons.person_rounded,
            selected: currentMode == PaymentTargetMode.customer,
            onTap: () => onChanged(PaymentTargetMode.customer),
          ),
          const SizedBox(width: 4),
          _TabItem(
            label: 'Por Reserva',
            icon: Icons.event_rounded,
            selected: currentMode == PaymentTargetMode.reservation,
            onTap: () => onChanged(PaymentTargetMode.reservation),
          ),
          const SizedBox(width: 4),
          _TabItem(
            label: 'Manual',
            icon: Icons.edit_note_rounded,
            selected: currentMode == PaymentTargetMode.newCustomer,
            onTap: () => onChanged(PaymentTargetMode.newCustomer),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected ? AppColors.surfaceContainerLowest : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        elevation: selected ? 1 : 0,
        shadowColor: const Color(0x14000000),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? AppColors.slate200 : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: selected
                      ? AppColors.brandTealDeep
                      : AppColors.slate500,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelMd.copyWith(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      color: selected
                          ? AppColors.brandTealDeep
                          : AppColors.slate600,
                    ),
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 4),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.emerald600,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedCustomerCard extends StatelessWidget {
  const _SelectedCustomerCard({required this.customer, required this.onClear});

  final Customer customer;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.emerald50.withValues(alpha: 0.8),
            AppColors.surfaceContainerLowest,
            AppColors.emerald50.withValues(alpha: 0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.brandTeal.withValues(alpha: 0.35)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080A312B),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.brandTealDeep,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.brandTealLight, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(
              customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'C',
              style: AppTypography.headlineSm.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontSize: 16,
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
                        customer.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelLg.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.slate900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.emerald100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.emerald200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 10,
                            color: AppColors.emerald800,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'Frecuente',
                            style: AppTypography.labelSm.copyWith(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.emerald800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${customer.phone} · CC ${customer.documentId}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.slate600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.swap_horiz_rounded, size: 14),
            label: const Text('Cambiar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.brandTealDeep,
              backgroundColor: AppColors.surfaceContainerLowest,
              side: BorderSide(
                color: AppColors.brandTeal.withValues(alpha: 0.3),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(0, 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: AppTypography.labelSm.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerReservationsSection extends StatelessWidget {
  const _CustomerReservationsSection({
    required this.customer,
    required this.status,
    required this.reservations,
    required this.selectedReservation,
    required this.onSelectReservation,
  });

  final Customer customer;
  final EntitySearchStatus status;
  final List<Reservation> reservations;
  final Reservation? selectedReservation;
  final ValueChanged<Reservation> onSelectReservation;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.event_note_rounded,
                  size: 15,
                  color: AppColors.brandTeal,
                ),
                const SizedBox(width: 6),
                Text(
                  'RESERVAS DE ${customer.name.toUpperCase()}',
                  style: AppTypography.labelSm.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.slate700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            if (reservations.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 1.5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.brandTealLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.brandTeal.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '${reservations.length} encontrada(s)',
                  style: AppTypography.labelSm.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandTealDeep,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (status == EntitySearchStatus.loading)
          const NewPaymentReservationListShimmer(itemCount: 2)
        else if (reservations.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.slate50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.slate200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: AppColors.slate500,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No hay reservas activas asociadas a este cliente.',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.slate600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reservations.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final res = reservations[index];
              final isSelected = selectedReservation?.id == res.id;
              return _CustomerReservationCard(
                reservation: res,
                isSelected: isSelected,
                onTap: () => onSelectReservation(res),
              );
            },
          ),
      ],
    );
  }
}

class _CustomerReservationCard extends StatelessWidget {
  const _CustomerReservationCard({
    required this.reservation,
    required this.isSelected,
    required this.onTap,
  });

  final Reservation reservation;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasBalance = reservation.displayBalance > 0;
    final now = DateTime.now();
    return Material(
      color: isSelected
          ? AppColors.brandTealLight.withValues(alpha: 0.5)
          : AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? AppColors.brandTeal : AppColors.slate200,
          width: isSelected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2, right: 8),
                child: Icon(
                  isSelected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 18,
                  color: isSelected ? AppColors.brandTeal : AppColors.slate400,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.brandTealDeep
                                : AppColors.slate900,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '⚽ F7',
                            style: AppTypography.labelSm.copyWith(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            reservation.courtsLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelLg.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.slate900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${reservationWhen(reservation.start, now)} · ${AppFormatters.time(reservation.start)}',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.slate600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: hasBalance
                          ? AppColors.statusDue.withValues(alpha: 0.1)
                          : AppColors.statusPaid.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: hasBalance
                            ? AppColors.statusDue.withValues(alpha: 0.3)
                            : AppColors.statusPaid.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      hasBalance
                          ? 'Pendiente: ${AppFormatters.cop(reservation.displayBalance)}'
                          : 'Pagado',
                      style: AppTypography.labelSm.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: hasBalance
                            ? AppColors.statusDue
                            : AppColors.statusPaid,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Total: ${AppFormatters.cop(reservation.displayTotal)} COP',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.slate500,
                      fontSize: 10,
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

class _SelectedReservationCard extends StatelessWidget {
  const _SelectedReservationCard({
    required this.reservation,
    required this.onClear,
  });

  final Reservation reservation;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final hasBalance = reservation.displayBalance > 0;
    final now = DateTime.now();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.brandTealLight.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.brandTeal.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.brandTeal,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  reservation.courtsLabel,
                  style: AppTypography.labelLg.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandTealDeep,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.swap_horiz_rounded, size: 14),
                label: const Text('Cambiar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.brandTealDeep,
                  backgroundColor: AppColors.surfaceContainerLowest,
                  side: BorderSide(
                    color: AppColors.brandTeal.withValues(alpha: 0.3),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  minimumSize: const Size(0, 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: AppTypography.labelSm.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.slate200),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Cliente: ${reservation.customerName}',
                      style: AppTypography.labelMd.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${reservationWhen(reservation.start, now)} · ${AppFormatters.time(reservation.start)}',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.slate600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total: ${AppFormatters.cop(reservation.displayTotal)} COP',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.slate600,
                      ),
                    ),
                    Text(
                      hasBalance
                          ? 'Pendiente: ${AppFormatters.cop(reservation.displayBalance)}'
                          : 'Completamente pagada',
                      style: AppTypography.labelSm.copyWith(
                        fontWeight: FontWeight.w700,
                        color: hasBalance
                            ? AppColors.statusDue
                            : AppColors.statusPaid,
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

class _CustomerTile extends StatelessWidget {
  const _CustomerTile({required this.customer, required this.onTap});

  final Customer customer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppColors.slate200),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.brandTealDeep,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  customer.name.isNotEmpty
                      ? customer.name[0].toUpperCase()
                      : '?',
                  style: AppTypography.labelMd.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelMd.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${customer.phone} · CC ${customer.documentId}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.slate600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.slate400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReservationTile extends StatelessWidget {
  const _ReservationTile({required this.reservation, required this.onTap});

  final Reservation reservation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasBalance = reservation.displayBalance > 0;
    final now = DateTime.now();
    return Material(
      color: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppColors.slate200),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${reservation.courtsLabel} · ${reservation.customerName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelLg.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: hasBalance
                          ? AppColors.statusDue.withValues(alpha: 0.1)
                          : AppColors.statusPaid.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: hasBalance
                            ? AppColors.statusDue.withValues(alpha: 0.3)
                            : AppColors.statusPaid.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      hasBalance
                          ? 'Saldo: ${AppFormatters.cop(reservation.displayBalance)}'
                          : 'Pagado',
                      style: AppTypography.labelSm.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: hasBalance
                            ? AppColors.statusDue
                            : AppColors.statusPaid,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${reservationWhen(reservation.start, now)} · ${AppFormatters.time(reservation.start)}',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.slate600,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    'Total ${AppFormatters.cop(reservation.displayTotal)}',
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.slate700,
                      fontSize: 11,
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

class _EmptyNotice extends StatelessWidget {
  const _EmptyNotice({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: AppColors.slate400),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodySm.copyWith(
              color: AppColors.slate600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Buscador compacto (sin etiqueta encima) con botón para limpiar.
class _CompactSearchField extends StatelessWidget {
  const _CompactSearchField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.onClear,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: color),
    );
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      validator: validator,
      textInputAction: TextInputAction.search,
      style: AppTypography.bodyMd.copyWith(color: AppColors.slate900),
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: AppTypography.bodyMd.copyWith(color: AppColors.slate400),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 18,
          color: AppColors.slate400,
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 38),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Limpiar',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.clear_rounded, size: 16),
                onPressed: onClear,
              ),
        filled: true,
        fillColor: AppColors.slate50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
        enabledBorder: border(AppColors.slate200),
        focusedBorder: border(AppColors.brandTeal),
        errorBorder: border(AppColors.statusDue),
        focusedErrorBorder: border(AppColors.statusDue),
      ),
    );
  }
}

/// Lista de clientes de altura fija que pide la página siguiente al
/// acercarse al final (scroll infinito). Solo construye los visibles.
class _PagedCustomerList extends StatelessWidget {
  const _PagedCustomerList({
    required this.customers,
    required this.hasMore,
    required this.loadMoreStatus,
    required this.onLoadMore,
    required this.onSelected,
  });

  final List<Customer> customers;
  final bool hasMore;
  final EntitySearchStatus loadMoreStatus;
  final VoidCallback? onLoadMore;
  final ValueChanged<Customer> onSelected;

  static const maxHeight = 260.0;
  static const _loadMoreThreshold = 200.0;

  bool get _canLoadMore =>
      hasMore &&
      loadMoreStatus == EntitySearchStatus.idle &&
      onLoadMore != null;

  @override
  Widget build(BuildContext context) {
    final footer = hasMore || loadMoreStatus == EntitySearchStatus.failure;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: maxHeight),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.axis == Axis.vertical &&
              notification.metrics.extentAfter < _loadMoreThreshold &&
              _canLoadMore) {
            onLoadMore!();
          }
          return false;
        },
        child: ListView.separated(
          key: const Key('payment-customer-list'),
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: customers.length + (footer ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(height: 6),
          itemBuilder: (context, index) {
            if (index == customers.length) {
              return _LoadMoreRow(
                status: loadMoreStatus,
                onRetry: onLoadMore,
                // Si la lista no alcanza a llenar el alto, pide más al verse.
                onVisible: _canLoadMore ? onLoadMore : null,
              );
            }
            final c = customers[index];
            return _CustomerTile(customer: c, onTap: () => onSelected(c));
          },
        ),
      ),
    );
  }
}

class _LoadMoreRow extends StatefulWidget {
  const _LoadMoreRow({
    required this.status,
    required this.onRetry,
    required this.onVisible,
  });

  final EntitySearchStatus status;
  final VoidCallback? onRetry;
  final VoidCallback? onVisible;

  @override
  State<_LoadMoreRow> createState() => _LoadMoreRowState();
}

class _LoadMoreRowState extends State<_LoadMoreRow> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onVisible?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.status == EntitySearchStatus.failure) {
      return Center(
        child: TextButton.icon(
          key: const Key('payment-customers-retry'),
          onPressed: widget.onRetry,
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('No pudimos cargar más. Reintentar'),
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: SizedBox.square(
          key: Key('payment-customers-loading-more'),
          dimension: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.brandTeal,
          ),
        ),
      ),
    );
  }
}
