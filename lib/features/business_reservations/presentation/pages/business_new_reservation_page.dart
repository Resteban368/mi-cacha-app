import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/catalogs/domain/entities/catalog_payment_method.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/session/write_access.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/cop_input_formatter.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/loading_dialog.dart';
import '../../../business_home/presentation/widgets/read_only_banner.dart';
import '../../../business_courts/presentation/widgets/court_pricing_card.dart';
import '../../../business_courts/presentation/widgets/court_summaries.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/new_reservation.dart';
import '../../domain/entities/reservation_failure.dart';
import '../bloc/new_reservation/new_reservation_bloc.dart';
import '../widgets/create_reservation_bottom_bar.dart';
import '../widgets/create_reservation_client_card.dart';
import '../widgets/create_reservation_day_card.dart';
import '../widgets/create_reservation_courts_card.dart';
import '../widgets/create_reservation_options_card.dart';
import '../widgets/create_reservation_payment_card.dart';
import '../widgets/create_reservation_schedule_card.dart';
import '../widgets/create_reservation_summary_card.dart';
import '../widgets/reservation_summary_dialog.dart';

/// "Crear Reserva": registro manual de un turno por el administrador.
class BusinessNewReservationPage extends StatelessWidget {
  const BusinessNewReservationPage({super.key});

  void _back(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go(AppRoutes.businessReservations);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocLoadingDialog<NewReservationBloc, NewReservationState>(
      isLoading: (s) => s.load == NewReservationLoad.loading,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: Column(
          children: [
            AppTopBar(
              title: 'Crear Reserva',
              titleBadge: 'Manual',
              subtitle: 'Registro manual de turno',
              icon: Icons.event_available,
              onBack: () => _back(context),
            ),
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: BlocBuilder<NewReservationBloc, NewReservationState>(
                  buildWhen: (prev, curr) =>
                      prev.load != curr.load ||
                      prev.hasBookableCourts != curr.hasBookableCourts,
                  builder: (context, state) => switch (state.load) {
                    _ when !WriteAccessScope.canWrite(context) =>
                      const ReadOnlyMessage(action: 'crear reservas'),
                    NewReservationLoad.loading => const SizedBox.shrink(),
                    NewReservationLoad.failure => _Message(
                      icon: Icons.cloud_off_outlined,
                      title: 'No pudimos cargar tus canchas',
                      actionLabel: 'Reintentar',
                      onAction: () => context.read<NewReservationBloc>().add(
                        const NewReservationStarted(),
                      ),
                    ),
                    NewReservationLoad.ready when !state.hasBookableCourts =>
                      _Message(
                        icon: Icons.stadium_outlined,
                        title:
                            'No tienes canchas listas para reservar: deben '
                            'estar activas y con sus 3 fotos.',
                        actionLabel: 'Ir a Canchas',
                        onAction: () => context.go(AppRoutes.businessCourts),
                      ),
                    NewReservationLoad.ready => const _ReservationForm(),
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReservationForm extends StatefulWidget {
  const _ReservationForm();

  @override
  State<_ReservationForm> createState() => _ReservationFormState();
}

class _ReservationFormState extends State<_ReservationForm> {
  static const _wideBreakpoint = 900.0;

  /// Altura de la columna derecha desde la que el resumen va completo.
  static const _fullSummaryHeight = 820.0;

  final _formKey = GlobalKey<FormState>();
  var _autovalidate = AutovalidateMode.disabled;

  var _isNewCustomer = false;
  final _search = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _document = TextEditingController();

  final _discount = TextEditingController();
  var _registerPayment = false;
  final _amount = TextEditingController();
  final _reference = TextEditingController();
  CatalogPaymentMethod? _method;

  final _detail = TextEditingController();
  final _tag = TextEditingController();
  final _note = TextEditingController();
  var _isRecurring = false;

  late final List<TextEditingController> _watched = [
    _name,
    _phone,
    _document,
    _discount,
    _amount,
    _reference,
  ];

  @override
  void initState() {
    super.initState();
    for (final controller in _watched) {
      controller.addListener(_refresh);
    }
    final methods = context.read<NewReservationBloc>().state.paymentMethods;
    // Efectivo por defecto, como la API.
    _method =
        methods.where((m) => m.code == 'EFECTIVO').firstOrNull ??
        methods.firstOrNull;
  }

  @override
  void dispose() {
    for (final controller in [
      _search,
      _name,
      _phone,
      _document,
      _discount,
      _amount,
      _reference,
      _detail,
      _tag,
      _note,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _refresh() => setState(() {});

  NewCustomer get _newCustomer => NewCustomer(
    name: _name.text,
    phone: _phone.text,
    documentId: _document.text,
  );

  /// Lo que falta para poder confirmar (vacío = listo).
  List<String> _missing(NewReservationState state) => [
    if (state.sport == null) 'deporte',
    if (state.selectedSlots.isEmpty) 'turno',
    if (_isNewCustomer ? _newCustomer.error != null : state.customer == null)
      'cliente',
    if (_registerPayment && CopInputFormatter.parse(_amount.text) <= 0)
      'monto del pago',
  ];

  void _submit(NewReservationState state) {
    if (!ensureCanWrite(context)) return;
    if (!_formKey.currentState!.validate()) {
      setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
      return;
    }
    FocusScope.of(context).unfocus();
    final slot = state.selectedSlots.first;
    final method = _method;
    context.read<NewReservationBloc>().add(
      NewReservationSubmitted(
        NewReservation(
          target: state.anyCourt
              ? AnyCourtOfSport(state.sport!, courts: state.anyCourtCount)
              : state.extraCourtIds.isEmpty
              ? CourtById(state.selectedCourtId!)
              : CourtsByIds([state.selectedCourtId!, ...state.extraCourtIds]),
          start: slot.startIso,
          slots: state.slotCount,
          customerId: _isNewCustomer ? null : state.customer!.id,
          customer: _isNewCustomer ? _newCustomer : null,
          customerDetail: _detail.text,
          contactNote: _note.text,
          tag: _tag.text,
          isRecurring: _isRecurring,
          discount: CopInputFormatter.parse(_discount.text),
          payment: _registerPayment && method != null
              ? NewPayment(
                  amount: CopInputFormatter.parse(_amount.text),
                  method: method.code,
                  reference: method.requiresReference ? _reference.text : null,
                )
              : null,
        ),
      ),
    );
  }

  Future<void> _onSubmitStatus(
    BuildContext context,
    NewReservationState state,
  ) async {
    switch (state.submit) {
      case NewReservationSubmit.success:
        final reservation = state.created!;
        final action = await showReservationSummary(
          context,
          reservation,
          courtAssigned: state.anyCourt,
        );
        if (!context.mounted) return;
        if (action == ReservationSummaryAction.createAnother) {
          context.go(
            '${AppRoutes.businessNewReservation}?refresh='
            '${DateTime.now().millisecondsSinceEpoch}',
          );
        } else {
          context.go(AppRoutes.businessReservationsOn(reservation.start));
        }
      case NewReservationSubmit.failure:
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(_failureMessage(state)),
              backgroundColor: AppColors.statusDue,
            ),
          );
      case NewReservationSubmit.idle || NewReservationSubmit.submitting:
        break;
    }
  }

  static String _failureMessage(NewReservationState state) {
    final message = state.failureMessage;
    return switch (state.failure) {
      ReservationFailure.slotTaken when state.anyCourt =>
        'Ya no hay canchas libres a esa hora. Actualizamos los turnos: '
            'elige otro.',
      ReservationFailure.slotTaken =>
        'Ese horario se acaba de ocupar. Actualizamos los turnos: elige otro.',
      ReservationFailure.subscriptionInactive =>
        'Tu plan no está activo: no puedes crear reservas.',
      ReservationFailure.network =>
        'Sin conexión. Revisa tu internet e intenta de nuevo.',
      ReservationFailure.server ||
      null => 'No pudimos crear la reserva. Intenta de nuevo.',
      _ => message ?? 'Revisa los datos de la reserva.',
    };
  }

  String _summary(NewReservationState state) {
    final sport = state.sport;
    final court = state.anyCourt && sport != null
        ? state.anyCourtCount > 1
              ? '${state.anyCourtCount} canchas de '
                    '${CourtSummaries.sport(sport).toLowerCase()}'
              : 'Cualquier cancha de ${CourtSummaries.sport(sport).toLowerCase()}'
        : _courtNames(state) ??
              (sport == null ? 'Sin deporte' : CourtSummaries.sport(sport));
    final day = AppFormatters.shortDate(state.day);
    final slots = state.selectedSlots;
    if (slots.isEmpty) return '$court · $day';
    return '$court · $day · '
        '${AppFormatters.timeRange(slots.first.start, slots.last.end)}';
  }

  /// "Fútbol · Cancha c1" (o "Fútbol · Cualquier cancha libre").
  String _summaryTitle(NewReservationState state) {
    final sport = state.sport;
    final sportLabel = sport == null
        ? 'Sin deporte'
        : CourtSummaries.sport(sport);
    final court = state.anyCourt
        ? state.anyCourtCount > 1
              ? '${state.anyCourtCount} canchas libres'
              : 'Cualquier cancha libre'
        : _courtNames(state);
    return court == null ? sportLabel : '$sportLabel · $court';
  }

  /// "Cancha 1" o "Cancha 1 + Cancha 2" con varias canchas a la vez.
  static String? _courtNames(NewReservationState state) {
    final courts = state.selectedCourts;
    if (courts.isEmpty) return state.selectedCourt?.court.name;
    return courts.map((c) => c.court.name).join(' + ');
  }

  String? _schedule(NewReservationState state) {
    final slots = state.selectedSlots;
    if (slots.isEmpty) return null;
    return '${AppFormatters.shortDate(state.day)} · '
        '${AppFormatters.timeRange(slots.first.start, slots.last.end)}';
  }

  String? _customerLabel(NewReservationState state) {
    if (_isNewCustomer) {
      final name = _name.text.trim();
      return name.isEmpty ? null : '$name (nuevo)';
    }
    final customer = state.customer;
    if (customer == null) return null;
    return customer.phone.isEmpty
        ? customer.name
        : '${customer.name} (${customer.phone})';
  }

  String _paymentLabel(NewReservationState state) {
    if (!_registerPayment) return 'Sin abono';
    final paid = CopInputFormatter.parse(_amount.text);
    if (paid <= 0) return 'Sin abono';
    final total = _total(state);
    if (total == null || paid >= total) return 'Pago total';
    return 'Abono ${AppFormatters.cop(paid)} '
        '(resta ${AppFormatters.cop(total - paid)})';
  }

  int? _total(NewReservationState state) {
    final subtotal = state.subtotal;
    if (subtotal == null) return null;
    return (subtotal - CopInputFormatter.parse(_discount.text)).clamp(
      0,
      subtotal,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NewReservationBloc, NewReservationState>(
      listenWhen: (prev, curr) => prev.submit != curr.submit,
      listener: _onSubmitStatus,
      builder: (context, state) {
        final bloc = context.read<NewReservationBloc>();
        final today = DateUtils.dateOnly(DateTime.now());
        final missing = _missing(state);
        final submitting = state.submit == NewReservationSubmit.submitting;

        final dayCard = CreateReservationDayCard(
          sports: state.sports,
          sport: state.sport,
          day: state.day,
          minDay: today.isAfter(state.day) ? state.day : today,
          onSportChanged: (sport) =>
              bloc.add(NewReservationSportSelected(sport)),
          onDayChanged: (day) => bloc.add(NewReservationDaySelected(day)),
        );
        final scheduleCard = CreateReservationScheduleCard(
          load: state.availabilityLoad,
          availability: state.availability,
          hiddenCourtCount: state.hiddenCourtCount,
          anyCourt: state.anyCourt,
          selectedCourtId: state.selectedCourtId,
          selectedStart: state.selectedStart,
          selectedCourt: state.selectedCourt,
          selectedSlots: state.selectedSlots,
          slotCount: state.slotCount,
          maxSlotCount: state.maxSlotCount,
          subtotal: state.subtotal,
          priceMayVary: state.priceMayVary,
          focusCourtId: state.focusCourtId,
          onAnyCourtChanged: (on) =>
              bloc.add(NewReservationAnyCourtToggled(on)),
          onSlotTap: (courtId, start) => bloc.add(
            NewReservationSlotTapped(courtId: courtId, start: start),
          ),
          onCountChanged: (n) => bloc.add(NewReservationSlotCountChanged(n)),
          onRetry: () => bloc.add(const NewReservationAvailabilityReloaded()),
          onManageCourts: () => context.go(AppRoutes.businessCourts),
        );
        // Con un turno elegido, se pueden sumar otras canchas en la franja.
        final courtsCard =
            state.selectedSlots.isNotEmpty &&
                (state.availability?.courts.length ?? 0) > 1
            ? CreateReservationCourtsCard(
                anyCourt: state.anyCourt,
                selectedCourts: state.selectedCourts,
                extraCourtIds: state.extraCourtIds,
                addableCourts: state.addableCourts,
                anyCourtCount: state.anyCourtCount,
                anyCourtCountMax: state.anyCourtCountMax,
                onExtraCourtToggled: (id) =>
                    bloc.add(NewReservationExtraCourtToggled(id)),
                onAnyCourtCountChanged: (n) =>
                    bloc.add(NewReservationAnyCourtCountChanged(n)),
              )
            : null;
        final clientCard = CreateReservationClientCard(
          isNewCustomer: _isNewCustomer,
          onModeChanged: (isNew) => setState(() => _isNewCustomer = isNew),
          selectedCustomer: state.customer,
          results: state.customerResults,
          searchStatus: state.customerSearch,
          searchController: _search,
          onQueryChanged: (q) =>
              bloc.add(NewReservationCustomerQueryChanged(q)),
          onCustomerSelected: (c) =>
              bloc.add(NewReservationCustomerSelected(c)),
          nameController: _name,
          phoneController: _phone,
          documentController: _document,
        );
        final paymentCard = CreateReservationPaymentCard(
          subtotal: state.subtotal,
          lowestSubtotal: state.lowestSubtotal,
          durationLabel: state.selectedCourt == null
              ? null
              : CourtPricingCard.durationLabel(
                  state.slotCount * state.selectedCourt!.court.slotDuration,
                ),
          discountController: _discount,
          registerPayment: _registerPayment,
          onRegisterPaymentChanged: (on) =>
              setState(() => _registerPayment = on),
          amountController: _amount,
          methods: state.paymentMethods,
          selectedMethod: _method,
          onMethodChanged: (m) => setState(() => _method = m),
          referenceController: _reference,
        );
        final optionsCard = CreateReservationOptionsCard(
          isRecurring: _isRecurring,
          onRecurringChanged: (on) => setState(() => _isRecurring = on),
          detailController: _detail,
          tagController: _tag,
          noteController: _note,
        );

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= _wideBreakpoint;
            Widget bar({required bool inline}) => CreateReservationBottomBar(
              summary: _summary(state),
              total: _total(state),
              missing: missing,
              isLoading: submitting,
              inline: inline,
              onConfirm: missing.isEmpty ? () => _submit(state) : null,
            );
            const gap = SizedBox(height: 16);
            return Form(
              key: _formKey,
              autovalidateMode: _autovalidate,
              child: isWide
                  // Web: turnos a la izquierda; cliente y pago a la derecha,
                  // cada columna con su scroll y "Confirmar" siempre visible.
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 3,
                          child: SingleChildScrollView(
                            key: const Key('reservation-main-scroll'),
                            padding: const EdgeInsets.fromLTRB(24, 24, 12, 24),
                            child: Column(
                              children: [
                                dayCard,
                                gap,
                                scheduleCard,
                                if (courtsCard != null) ...[gap, courtsCard],
                                gap,
                                optionsCard,
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: LayoutBuilder(
                            // Con poca altura el resumen se compacta para no
                            // tapar el cliente y el pago.
                            builder: (context, column) => Column(
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.fromLTRB(
                                      12,
                                      24,
                                      24,
                                      16,
                                    ),
                                    child: Column(
                                      children: [clientCard, gap, paymentCard],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    12,
                                    0,
                                    24,
                                    24,
                                  ),
                                  child: CreateReservationSummaryCard(
                                    compact:
                                        column.maxHeight < _fullSummaryHeight,
                                    title: _summaryTitle(state),
                                    schedule: _schedule(state),
                                    customer: _customerLabel(state),
                                    payment: _paymentLabel(state),
                                    total: _total(state),
                                    missing: missing,
                                    isLoading: submitting,
                                    onConfirm: missing.isEmpty
                                        ? () => _submit(state)
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                            child: Column(
                              children: [
                                dayCard,
                                gap,
                                scheduleCard,
                                if (courtsCard != null) ...[gap, courtsCard],
                                gap,
                                clientCard,
                                gap,
                                paymentCard,
                                gap,
                                optionsCard,
                              ],
                            ),
                          ),
                        ),
                        bar(inline: false),
                      ],
                    ),
            );
          },
        );
      },
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: AppColors.brandTeal),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.bodyLg.copyWith(
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(actionLabel)),
            ],
          ),
        ),
      ),
    );
  }
}
