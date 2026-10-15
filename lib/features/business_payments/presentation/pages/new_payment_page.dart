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
import '../../domain/entities/new_payment.dart';
import '../../domain/entities/payment.dart';
import '../bloc/new_payment/new_payment_bloc.dart';
import '../widgets/payment_styles.dart';

/// Registrar un pago recibido en el negocio (efectivo, Nequi, etc.).
class NewPaymentPage extends StatefulWidget {
  const NewPaymentPage({super.key});

  static const quickAmounts = [20000, 50000, 100000];

  @override
  State<NewPaymentPage> createState() => _NewPaymentPageState();
}

class _NewPaymentPageState extends State<NewPaymentPage> {
  /// Desde este ancho (web/tablet horizontal) el resumen va a la derecha.
  static const _wideBreakpoint = 900.0;

  /// Ancho del formulario desde el que se reparte en dos columnas.
  static const _twoColumnFormWidth = 680.0;

  static const _summaryWidth = 360.0;

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

  void _submit() {
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
                const SnackBar(
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= _wideBreakpoint;
          return Scaffold(
            backgroundColor: AppColors.surface,
            body: Column(
              children: [
                AppTopBar(
                  title: 'Nuevo pago',
                  subtitle: 'Registra un pago recibido',
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
                      child: isWide ? _wideBody() : _narrowBody(),
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
      ),
    );
  }

  Widget _narrowBody() => ListView(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
    children: [
      ..._customerAndAmountFields(),
      const SizedBox(height: 20),
      ..._methodAndNoteFields(),
    ],
  );

  /// Formulario a la izquierda (2 columnas si cabe) y resumen fijo a la
  /// derecha con el botón de registrar.
  Widget _wideBody() => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final twoColumns = constraints.maxWidth - 48 >= _twoColumnFormWidth;
            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 12, 24),
              children: [
                if (twoColumns)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _customerAndAmountFields(),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _methodAndNoteFields(),
                        ),
                      ),
                    ],
                  )
                else ...[
                  ..._customerAndAmountFields(),
                  const SizedBox(height: 20),
                  ..._methodAndNoteFields(),
                ],
              ],
            );
          },
        ),
      ),
      SizedBox(
        width: _summaryWidth,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 24, 24, 24),
          child: ListenableBuilder(
            listenable: _customer,
            builder: (context, _) => _SummaryPanel(
              customer: _customer.text.trim(),
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

  List<Widget> _customerAndAmountFields() {
    return [
      AppTextField(
        label: 'Cliente',
        prefixIcon: Icons.person_outline,
        controller: _customer,
        hintText: 'Nombre de quien paga',
        textInputAction: TextInputAction.next,
        textCapitalization: TextCapitalization.words,
        validator: (v) => (v?.trim().isEmpty ?? true)
            ? 'Ingresa el nombre del cliente'
            : null,
      ),
      const SizedBox(height: 20),
      const _SectionLabel('Concepto'),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final concept in PaymentConcept.values)
            _ChoicePill(
              label: concept.label,
              selected: concept == _concept,
              onTap: () => setState(() => _concept = concept),
            ),
        ],
      ),
      const SizedBox(height: 20),
      AppTextField(
        label: 'Monto (COP)',
        prefixIcon: Icons.attach_money_rounded,
        controller: _amount,
        hintText: '0',
        keyboardType: TextInputType.number,
        inputFormatters: const [CopInputFormatter()],
        validator: (v) => CopInputFormatter.parse(v ?? '') <= 0
            ? 'Ingresa un monto mayor a cero'
            : null,
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final value in NewPaymentPage.quickAmounts)
            ActionChip(
              label: Text('+${AppFormatters.cop(value)}'),
              labelStyle: AppTypography.labelMd.copyWith(
                color: AppColors.brandTealDeep,
              ),
              backgroundColor: AppColors.accentLimeTint,
              side: BorderSide(
                color: AppColors.accentLime.withValues(alpha: 0.8),
              ),
              shape: const StadiumBorder(),
              onPressed: () => _addAmount(value),
            ),
          if (_amountValue > 0)
            ActionChip(
              label: const Text('Limpiar'),
              labelStyle: AppTypography.labelMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              backgroundColor: AppColors.surfaceContainer,
              side: BorderSide.none,
              shape: const StadiumBorder(),
              onPressed: _amount.clear,
            ),
        ],
      ),
    ];
  }

  List<Widget> _methodAndNoteFields() {
    final needsReference = NewPayment.requiresReference(_method);
    return [
      const _SectionLabel('Método de pago'),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final method in PaymentMethod.selectable)
            _ChoicePill(
              label: method.label,
              icon: method.icon,
              iconColor: method.color,
              selected: method == _method,
              onTap: () => setState(() => _method = method),
            ),
        ],
      ),
      AnimatedSize(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.topCenter,
        child: needsReference
            ? Padding(
                padding: const EdgeInsets.only(top: 20),
                child: AppTextField(
                  label: 'Referencia',
                  prefixIcon: Icons.tag_rounded,
                  controller: _reference,
                  hintText: 'Número de la transacción',
                  textInputAction: TextInputAction.next,
                  inputFormatters: [LengthLimitingTextInputFormatter(40)],
                  validator: (v) => (v?.trim().isEmpty ?? true)
                      ? 'Ingresa la referencia del pago'
                      : null,
                ),
              )
            : const SizedBox(width: double.infinity),
      ),
      const SizedBox(height: 20),
      AppTextField(
        label: 'Nota (opcional)',
        prefixIcon: Icons.notes_rounded,
        controller: _note,
        hintText: 'Ej.: pagó en taquilla',
        maxLines: 3,
        textCapitalization: TextCapitalization.sentences,
        inputFormatters: [LengthLimitingTextInputFormatter(200)],
      ),
    ];
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTypography.labelMd.copyWith(
        color: AppColors.slate700,
        letterSpacing: 0.6,
      ),
    );
  }
}

/// Pastilla seleccionable (concepto y método de pago).
class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.iconColor,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected
            ? AppColors.brandTealLight
            : AppColors.surfaceContainerLowest,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? AppColors.brandTeal : AppColors.slate200,
            width: 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected)
                  const Icon(
                    Icons.check_circle,
                    size: 18,
                    color: AppColors.brandTeal,
                  )
                else if (icon != null)
                  Icon(icon, size: 18, color: iconColor),
                if (selected || icon != null) const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTypography.labelLg.copyWith(
                    color: selected
                        ? AppColors.brandTealDeep
                        : AppColors.onSurface,
                    letterSpacing: 0,
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
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(top: BorderSide(color: Color(0xFFE1E6E2))),
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
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
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

/// Resumen fijo (pantallas anchas): datos clave, total y botón principal.
class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({
    required this.customer,
    required this.concept,
    required this.method,
    required this.amount,
    required this.onSubmit,
  });

  final String customer;
  final PaymentConcept concept;
  final PaymentMethod method;
  final int amount;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.slate200),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1417231C),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionLabel('Resumen'),
          const SizedBox(height: 12),
          _SummaryRow(
            label: 'Cliente',
            value: customer.isEmpty ? '—' : customer,
          ),
          _SummaryRow(label: 'Concepto', value: concept.label),
          _SummaryRow(label: 'Método', value: method.label),
          const Divider(height: 28, color: AppColors.slate200),
          Text(
            'Total',
            style: AppTypography.labelSm.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          Text(
            '${AppFormatters.cop(amount)} COP',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.headlineMd.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          _SubmitButton(onSubmit: onSubmit),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelLg.copyWith(
                color: AppColors.onSurface,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
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
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTypography.labelLg,
        ),
        child: state.isSubmitting
            ? const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: AppColors.onPrimary,
                ),
              )
            : const Text('Registrar pago'),
      ),
    );
  }
}
