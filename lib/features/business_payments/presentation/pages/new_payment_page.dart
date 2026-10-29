import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/cop_input_formatter.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../business_reservations/domain/entities/reservation.dart';
import '../../domain/entities/new_payment.dart';
import '../../domain/entities/payment.dart';
import '../bloc/new_payment/new_payment_bloc.dart';
import '../widgets/new_payment_target_selector.dart';
import '../widgets/payment_styles.dart';

/// Registrar un pago recibido en el negocio (efectivo, Nequi, etc.),
/// asociándolo a un cliente o reserva específica si aplica.
/// Abrir "Nuevo pago" con una reserva y un monto ya puestos (p. ej. para
/// cobrar un consumo desde Ventas).
class NewPaymentArgs {
  const NewPaymentArgs({required this.reservation, this.amount});

  final Reservation reservation;
  final int? amount;
}

class NewPaymentPage extends StatefulWidget {
  const NewPaymentPage({
    super.key,
    this.initialReservation,
    this.initialAmount,
  });

  /// Lo que llega como `extra` de la ruta: una reserva o [NewPaymentArgs].
  factory NewPaymentPage.fromExtra(Object? extra) => switch (extra) {
    NewPaymentArgs(:final reservation, :final amount) => NewPaymentPage(
      initialReservation: reservation,
      initialAmount: amount,
    ),
    final Reservation reservation => NewPaymentPage(
      initialReservation: reservation,
    ),
    _ => const NewPaymentPage(),
  };

  /// Reserva ya elegida (p. ej. desde su detalle): el pago queda ligado a
  /// ella y a su cliente, con el saldo pendiente como monto.
  final Reservation? initialReservation;

  /// Monto a usar en vez del saldo de la reserva.
  final int? initialAmount;

  static const quickAmounts = [20000, 50000, 100000];

  @override
  State<NewPaymentPage> createState() => _NewPaymentPageState();
}

class _NewPaymentPageState extends State<NewPaymentPage> {
  /// Desde este ancho (web/tablet horizontal) el resumen va a la derecha.
  static const _wideBreakpoint = 900.0;

  /// Ancho del formulario desde el que se reparte en dos columnas.
  static const _twoColumnFormWidth = 680.0;

  static const _summaryWidth = 370.0;

  final _formKey = GlobalKey<FormState>();
  final _customer = TextEditingController();
  final _amount = TextEditingController();
  final _reference = TextEditingController();
  final _note = TextEditingController();

  var _concept = PaymentConcept.anticipo;
  var _method = PaymentMethod.efectivo;
  var _autovalidate = AutovalidateMode.disabled;

  int get _amountValue => CopInputFormatter.parse(_amount.text);

  @override
  void initState() {
    super.initState();
    final bloc = context.read<NewPaymentBloc>()..add(const NewPaymentStarted());
    if (widget.initialReservation case final reservation?) {
      bloc
        ..add(const NewPaymentTargetModeChanged(PaymentTargetMode.reservation))
        ..add(NewPaymentReservationSelected(reservation));
      _customer.text = reservation.customerName;
      _onFillReservationBalance(reservation);
      if (widget.initialAmount case final amount? when amount > 0) {
        _amount.text = CopInputFormatter.format(amount);
      }
    }
    // Redibuja el total de la barra inferior al escribir el monto.
    _amount.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _customer.dispose();
    _amount.dispose();
    _reference.dispose();
    _note.dispose();
    super.dispose();
  }

  void _addAmount(int value) {
    _amount.text = CopInputFormatter.format(_amountValue + value);
  }

  void _onFillReservationBalance(Reservation reservation) {
    if (reservation.displayBalance > 0) {
      _amount.text = CopInputFormatter.format(reservation.displayBalance);
      if (reservation.displayPaid == 0) {
        _concept = PaymentConcept.anticipo;
      } else {
        _concept = PaymentConcept.saldo;
      }
      setState(() {});
    }
  }

  void _submit() {
    final state = context.read<NewPaymentBloc>().state;
    if (_customer.text.trim().isEmpty) {
      if (state.selectedCustomer != null) {
        _customer.text = state.selectedCustomer!.name;
      } else if (state.selectedReservation != null) {
        _customer.text = state.selectedReservation!.customerName;
      }
    }

    if (!_formKey.currentState!.validate()) {
      setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
      return;
    }
    FocusScope.of(context).unfocus();
    final needsReference = NewPayment.requiresReference(_method);
    context.read<NewPaymentBloc>().add(
      NewPaymentSubmitted(
        NewPayment(
          customerName: _customer.text.trim(),
          customerId: state.selectedCustomer?.id,
          reservationId: state.selectedReservation?.id,
          courtName: state.selectedReservation?.courtsLabel,
          reservationStart: state.selectedReservation?.start,
          amount: _amountValue,
          method: _method,
          concept: _concept,
          reference: needsReference ? _reference.text.trim() : null,
          note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<NewPaymentBloc, NewPaymentState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        switch (state.status) {
          case NewPaymentStatus.success:
            context.pop(true);
          case NewPaymentStatus.failure:
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(
                    'No pudimos registrar el pago. Intenta de nuevo.',
                  ),
                  backgroundColor: AppColors.statusDue,
                ),
              );
          case NewPaymentStatus.initial || NewPaymentStatus.submitting:
            break;
        }
      },
      child: BlocBuilder<NewPaymentBloc, NewPaymentState>(
        builder: (context, state) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= _wideBreakpoint;
              return Scaffold(
                backgroundColor: AppColors.surface,
                body: Column(
                  children: [
                    AppTopBar(
                      title: 'Nuevo pago',
                      subtitle:
                          'Registra cobro, abono o liquidación total de reservas',
                      icon: Icons.add_card_rounded,
                      showNotifications: false,
                      onBack: () => context.pop(),
                    ),
                    Expanded(
                      child: MediaQuery.removePadding(
                        context: context,
                        removeTop: true,
                        child: Form(
                          key: _formKey,
                          autovalidateMode: _autovalidate,
                          child: isWide ? _wideBody(state) : _narrowBody(state),
                        ),
                      ),
                    ),
                  ],
                ),
                bottomNavigationBar: isWide
                    ? null
                    : _BottomBar(
                        amount: _amountValue,
                        method: _method,
                        onSubmit: _submit,
                      ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _narrowBody(NewPaymentState state) => ListView(
    padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
    children: [
      ..._customerAndAmountCards(state),
      const SizedBox(height: 12),
      ..._methodAndNoteCards(),
    ],
  );

  /// Formulario a la izquierda (2 columnas si cabe) y resumen fijo a la
  /// derecha con el botón de registrar.
  Widget _wideBody(NewPaymentState state) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final twoColumns = constraints.maxWidth - 48 >= _twoColumnFormWidth;
            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 20, 12, 24),
              children: [
                if (twoColumns)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _customerAndAmountCards(state),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _methodAndNoteCards(),
                        ),
                      ),
                    ],
                  )
                else ...[
                  ..._customerAndAmountCards(state),
                  const SizedBox(height: 12),
                  ..._methodAndNoteCards(),
                ],
              ],
            );
          },
        ),
      ),
      SizedBox(
        width: _summaryWidth,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 20, 24, 24),
          child: ListenableBuilder(
            listenable: _customer,
            builder: (context, _) => _SummaryPanel(
              customer: _customer.text.trim().isNotEmpty
                  ? _customer.text.trim()
                  : (state.selectedCustomer?.name ??
                        state.selectedReservation?.customerName ??
                        ''),
              reservationCourt: state.selectedReservation?.courtsLabel,
              reservationDate: state.selectedReservation?.start,
              reservationPrice: state.selectedReservation?.displayTotal,
              reservationAmountPaid: state.selectedReservation?.displayPaid,
              concept: _concept,
              method: _method,
              amount: _amountValue,
              onSubmit: _submit,
            ),
          ),
        ),
      ),
    ],
  );

  List<Widget> _customerAndAmountCards(NewPaymentState state) {
    final bloc = context.read<NewPaymentBloc>();
    final hasReservation = state.selectedReservation != null;
    final resBalance = state.selectedReservation?.displayBalance ?? 0;

    return [
      _SectionCard(
        title: 'Destino del pago',
        subtitle: 'Asociar los recibos contables',
        child: NewPaymentTargetSelector(
          state: state,
          onModeChanged: (mode) => bloc.add(NewPaymentTargetModeChanged(mode)),
          onCustomerSearchChanged: (query) =>
              bloc.add(NewPaymentCustomerSearchChanged(query)),
          onLoadMoreCustomers: () =>
              bloc.add(const NewPaymentCustomersNextPage()),
          onCustomerSelected: (c) {
            bloc.add(NewPaymentCustomerSelected(c));
            if (c != null) {
              _customer.text = c.name;
            }
          },
          onReservationSearchChanged: (query) =>
              bloc.add(NewPaymentReservationSearchChanged(query)),
          onReservationSelected: (r) {
            bloc.add(NewPaymentReservationSelected(r));
            if (r != null) {
              _customer.text = r.customerName;
              _onFillReservationBalance(r);
            }
          },
          manualCustomerController: _customer,
          onFillReservationBalance: _onFillReservationBalance,
        ),
      ),
      const SizedBox(height: 12),
      _SectionCard(
        title: 'Concepto y Monto',
        subtitle: 'Registro de caja',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'CONCEPTO',
              style: AppTypography.labelSm.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.slate600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final concept in PaymentConcept.selectable)
                  _ChoicePill(
                    label: concept.label,
                    selected: concept == _concept,
                    onTap: () => setState(() => _concept = concept),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'MONTO (COP)',
                  style: AppTypography.labelSm.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.slate600,
                    letterSpacing: 0.5,
                  ),
                ),
                if (hasReservation && resBalance > 0)
                  Text(
                    'Sugerido por reserva',
                    style: AppTypography.labelSm.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.emerald600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.slate50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _amountValue > 0
                      ? AppColors.brandTeal
                      : AppColors.slate200,
                  width: _amountValue > 0 ? 1.5 : 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  Text(
                    r'$',
                    style: AppTypography.headlineMd.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.slate400,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _amount,
                      keyboardType: TextInputType.number,
                      inputFormatters: const [CopInputFormatter()],
                      style: AppTypography.headlineMd.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.slate900,
                        fontSize: 20,
                        letterSpacing: -0.5,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: '0',
                        hintStyle: TextStyle(
                          color: AppColors.slate400,
                          fontWeight: FontWeight.w700,
                        ),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      validator: (v) => CopInputFormatter.parse(v ?? '') <= 0
                          ? 'Ingresa un monto mayor a cero'
                          : null,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.slate200.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'COP',
                      style: AppTypography.labelSm.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.slate600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (hasReservation && resBalance > 0)
                  ActionChip(
                    avatar: Icon(
                      Icons.bolt_rounded,
                      size: 14,
                      color: AppColors.brandDark,
                    ),
                    label: Text(
                      '= Liquidar Exacto (${AppFormatters.cop(resBalance)})',
                    ),
                    labelStyle: AppTypography.labelSm.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF3F4C00),
                    ),
                    backgroundColor: AppColors.accentLimeTint,
                    side: const BorderSide(color: Color(0xFFCCFF00)),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    onPressed: () {
                      _amount.text = CopInputFormatter.format(resBalance);
                      setState(() {});
                    },
                  ),
                for (final value in NewPaymentPage.quickAmounts)
                  ActionChip(
                    label: Text('+${AppFormatters.cop(value)}'),
                    labelStyle: AppTypography.labelSm.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.brandTealDeep,
                    ),
                    backgroundColor: AppColors.brandTealLight,
                    side: BorderSide(
                      color: AppColors.brandTeal.withValues(alpha: 0.3),
                    ),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    onPressed: () => _addAmount(value),
                  ),
                if (_amountValue > 0)
                  ActionChip(
                    label: const Text('Limpiar'),
                    labelStyle: AppTypography.labelSm.copyWith(
                      color: AppColors.slate600,
                    ),
                    backgroundColor: AppColors.slate100,
                    side: BorderSide.none,
                    shape: const StadiumBorder(),
                    onPressed: _amount.clear,
                  ),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _methodAndNoteCards() {
    final needsReference = NewPayment.requiresReference(_method);
    return [
      _SectionCard(
        title: 'Método de pago',
        subtitle: 'Acreditación instantánea',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 400;
                final crossAxisCount = isCompact ? 2 : 3;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    mainAxisExtent: 58,
                  ),
                  itemCount: PaymentMethod.selectable.length,
                  itemBuilder: (context, index) {
                    final method = PaymentMethod.selectable[index];
                    final isSelected = method == _method;
                    return _MethodCardTile(
                      method: method,
                      selected: isSelected,
                      onTap: () => setState(() => _method = method),
                    );
                  },
                );
              },
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.topCenter,
              child: needsReference
                  ? Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: AppTextField(
                        label: 'Referencia (opcional)',
                        prefixIcon: Icons.tag_rounded,
                        controller: _reference,
                        hintText: 'Número de transacción o comprobante',
                        textInputAction: TextInputAction.next,
                        inputFormatters: [LengthLimitingTextInputFormatter(40)],
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      _SectionCard(
        title: 'Nota adicional',
        subtitle: 'Opcional',
        child: AppTextField(
          label: 'Nota (opcional)',
          prefixIcon: Icons.notes_rounded,
          controller: _note,
          hintText: 'Ej.: pagó en taquilla con billete de \$50.000',
          maxLines: 2,
          textCapitalization: TextCapitalization.sentences,
          inputFormatters: [LengthLimitingTextInputFormatter(200)],
        ),
      ),
    ];
  }
}

/// Contenedor en tarjeta blanca con bordes suaves y cabecera estándar Stitch.
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, this.subtitle, required this.child});

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.slate200),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0A312B),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.brandTeal,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSm.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.slate700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    subtitle!,
                    maxLines: 1,
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.slate400,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// Pastilla seleccionable para concepto.
class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
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
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected ? AppColors.brandTealLight : AppColors.slate50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: selected ? AppColors.brandTeal : AppColors.slate200,
            width: selected ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  Icon(
                    Icons.check_circle_rounded,
                    size: 15,
                    color: AppColors.brandTeal,
                  ),
                  const SizedBox(width: 5),
                ],
                Text(
                  label,
                  style: AppTypography.labelMd.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected
                        ? AppColors.brandTealDeep
                        : AppColors.slate700,
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

/// Tarjeta de método de pago en cuadrícula.
class _MethodCardTile extends StatelessWidget {
  const _MethodCardTile({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.brandTealLight.withValues(alpha: 0.6)
          : AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: selected ? AppColors.brandTeal : AppColors.slate200,
          width: selected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: method.tint,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: method.color.withValues(alpha: 0.2),
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(method.icon, size: 16, color: method.color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelMd.copyWith(
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: selected
                            ? AppColors.brandTealDeep
                            : AppColors.slate800,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      method.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySm.copyWith(
                        fontSize: 10,
                        color: selected
                            ? AppColors.brandTeal
                            : AppColors.slate500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Barra inferior fija (móvil): total a registrar + botón principal.
class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.amount,
    required this.method,
    required this.onSubmit,
  });

  final int amount;
  final PaymentMethod method;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(top: BorderSide(color: AppColors.outlineVariant)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1417231C),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total · ${method.label}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${AppFormatters.cop(amount)} COP',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.headlineMd.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.slate900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _SubmitButton(onSubmit: onSubmit),
            ],
          ),
        ),
      ),
    );
  }
}

/// Resumen ticket fiscal / taquilla (pantallas anchas).
class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({
    required this.customer,
    this.reservationCourt,
    this.reservationDate,
    this.reservationPrice,
    this.reservationAmountPaid,
    required this.concept,
    required this.method,
    required this.amount,
    required this.onSubmit,
  });

  final String customer;
  final String? reservationCourt;
  final DateTime? reservationDate;
  final int? reservationPrice;
  final int? reservationAmountPaid;
  final PaymentConcept concept;
  final PaymentMethod method;
  final int amount;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final hasReservation = reservationCourt != null;
    final totalTurno = reservationPrice ?? 0;
    final anticiposPrevios = reservationAmountPaid ?? 0;
    final pendingAfter = (totalTurno - (anticiposPrevios + amount)).clamp(
      0,
      999999999,
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140A312B),
            blurRadius: 18,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Barra de acento gradiente superior
          Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.brandDark,
                  AppColors.brandTeal,
                  AppColors.accentLimeSignal,
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.brandTealLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'RESUMEN',
                              style: AppTypography.labelSm.copyWith(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: AppColors.brandTealDeep,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Resumen del cobro',
                            style: AppTypography.labelLg.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.slate900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: AppColors.emerald600,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Caja #1',
                          style: AppTypography.labelSm.copyWith(
                            fontSize: 10,
                            color: AppColors.slate500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _SummaryRow(
                  label: 'Cliente',
                  value: customer.isEmpty ? '—' : customer,
                ),
                _SummaryRow(
                  label: 'Concepto',
                  value: concept.label,
                  isPill: true,
                ),
                _SummaryRow(
                  label: 'Método registrado',
                  value: method.label,
                  dotColor: method.color,
                ),
                if (hasReservation) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.slate50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.slate200),
                    ),
                    child: Column(
                      children: [
                        _SubRow(
                          label: 'Cancha vinculada',
                          value: reservationCourt!,
                        ),
                        if (reservationDate != null)
                          _SubRow(
                            label: 'Horario reserva',
                            value:
                                '${AppFormatters.shortDate(reservationDate!)} · ${AppFormatters.time(reservationDate!)}',
                          ),
                        if (totalTurno > 0) ...[
                          Divider(height: 12, color: AppColors.slate200),
                          _SubRow(
                            label: 'Valor total turno',
                            value: '${AppFormatters.cop(totalTurno)} COP',
                          ),
                          _SubRow(
                            label: 'Anticipos previos',
                            value: '${AppFormatters.cop(anticiposPrevios)} COP',
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                const _TicketPerforationDivider(),
                // Total destacado: panel verde suave con el monto grande en
                // tinta de superficie (legible en claro y en oscuro).
                Container(
                  key: const Key('payment-total'),
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  decoration: BoxDecoration(
                    color: AppColors.brandTealLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.brandTeal.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.payments_outlined,
                            size: 14,
                            color: AppColors.brandTeal,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Total a cobrar ahora',
                            style: AppTypography.labelSm.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.brandTeal,
                              letterSpacing: 0.2,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text.rich(
                          TextSpan(
                            text: AppFormatters.cop(amount),
                            children: [
                              TextSpan(
                                text: ' COP',
                                style: AppTypography.labelLg.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSurfaceVariant,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          style: AppTypography.headlineLg.copyWith(
                            fontSize: 30,
                            height: 1.15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSurface,
                            letterSpacing: -0.6,
                          ),
                        ),
                      ),
                      if (hasReservation && totalTurno > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Icon(
                                pendingAfter == 0
                                    ? Icons.check_circle_rounded
                                    : Icons.info_outline_rounded,
                                size: 13,
                                color: pendingAfter == 0
                                    ? AppColors.emerald600
                                    : AppColors.amber500,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  pendingAfter == 0
                                      ? 'El saldo de esta reserva quedará en \$0 COP'
                                      : 'Saldo restante: ${AppFormatters.cop(pendingAfter)} COP',
                                  style: AppTypography.bodySm.copyWith(
                                    fontSize: 10,
                                    color: AppColors.slate600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SubmitButton(onSubmit: onSubmit),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.slate100)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: AppColors.emerald600,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Soporte DIAN POS',
                            style: AppTypography.bodySm.copyWith(
                              fontSize: 10,
                              color: AppColors.slate400,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'v2.4.0-CO',
                        style: AppTypography.bodySm.copyWith(
                          fontSize: 10,
                          color: AppColors.slate400,
                        ),
                      ),
                    ],
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

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isPill = false,
    this.dotColor,
  });

  final String label;
  final String value;
  final bool isPill;
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySm.copyWith(
              color: AppColors.slate500,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: isPill
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.brandTealLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelSm.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.brandTealDeep,
                        fontSize: 10,
                      ),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (dotColor != null) ...[
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Flexible(
                        child: Text(
                          value,
                          textAlign: TextAlign.end,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelMd.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.slate900,
                            fontSize: 12,
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

class _SubRow extends StatelessWidget {
  const _SubRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySm.copyWith(
              color: AppColors.slate500,
              fontSize: 11,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelSm.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.slate800,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Línea divisoria para el estilo ticket de taquilla.
class _TicketPerforationDivider extends StatelessWidget {
  const _TicketPerforationDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Divider(height: 1, thickness: 1, color: AppColors.slate200),
    );
  }
}

/// "Registrar pago"; muestra progreso y se deshabilita mientras se envía.
class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.onSubmit});

  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NewPaymentBloc, NewPaymentState>(
      buildWhen: (p, c) => p.isSubmitting != c.isSubmitting,
      builder: (context, state) => FilledButton(
        onPressed: state.isSubmitting ? null : onSubmit,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brandTeal,
          disabledBackgroundColor: AppColors.brandTeal,
          foregroundColor: AppColors.onPrimary,
          disabledForegroundColor: AppColors.onPrimary,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: AppTypography.labelLg.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        child: state.isSubmitting
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: AppColors.onPrimary,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: AppColors.accentLimeSignal,
                  ),
                  SizedBox(width: 6),
                  Text('Registrar pago'),
                ],
              ),
      ),
    );
  }
}
