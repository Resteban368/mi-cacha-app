import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/session/write_access.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/cop_input_formatter.dart';
import '../../../../core/utils/formatters.dart';
import '../../../business_payments/domain/entities/payment.dart';
import '../../../business_payments/presentation/widgets/payment_styles.dart';
import '../../domain/entities/cash_session.dart';
import '../bloc/cash_cubit.dart';
import 'cash_receipt.dart';
import 'supplier_dialog.dart';

/// Fondo oscuro de la franja de caja (como en el diseño de Stitch).
const _ink = Color(0xFF0F172A);

String _signed(int value) => value > 0
    ? '+${AppFormatters.cop(value)}'
    : value < 0
    ? '−${AppFormatters.cop(-value)}'
    : AppFormatters.cop(0);

/// "Cuadra", "Sobrante" o "Faltante" con su color.
(String, Color) differenceLabel(int difference) => difference == 0
    ? ('Cuadra', AppColors.emerald600)
    : difference > 0
    ? ('Sobrante ${_signed(difference)}', AppColors.statusDeposit)
    : ('Faltante ${_signed(difference)}', AppColors.statusDue);

/// Franja de caja: abrir con base, cuadre (cierre) e historial de cierres.
class CashBanner extends StatelessWidget {
  const CashBanner({super.key, this.onChanged});

  /// Se abrió o se cerró la caja.
  final VoidCallback? onChanged;

  Future<void> _open(BuildContext context) async {
    if (!ensureCanWrite(context)) return;
    final opened = await showDialog<bool>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<CashCubit>(),
        child: const _OpenCashDialog(),
      ),
    );
    if (opened != true || !context.mounted) return;
    onChanged?.call();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Caja abierta.')));
  }

  Future<void> _close(BuildContext context, CashSession session) async {
    if (!ensureCanWrite(context)) return;
    final closed = await showDialog<CashSession>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<CashCubit>(),
        child: _CloseCashDialog(session: session),
      ),
    );
    if (closed == null || !context.mounted) return;
    onChanged?.call();
    final (label, _) = differenceLabel(closed.difference ?? 0);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Caja cerrada · $label.')));
    // El comprobante, listo para compartir.
    await showCashReceipt(context, closed);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CashCubit, CashState>(
      builder: (context, state) {
        final session = state.session;
        final canWrite = WriteAccessScope.canWrite(context);
        final (title, text) = switch (state.load) {
          CashLoad.loading => ('Caja', 'Cargando el estado de la caja…'),
          CashLoad.failure => (
            'Caja',
            'No pudimos cargar la caja. Desliza para actualizar.',
          ),
          CashLoad.ready when session == null => (
            'Caja cerrada',
            'Ábrela con la base de efectivo para empezar el turno y '
                'cuadrar al final.',
          ),
          CashLoad.ready => (
            '¿Listo para el cuadre de caja?',
            'Abierta desde las ${AppFormatters.time(session!.openedAt)}'
                '${session.openedByName == null ? '' : ' por ${session.openedByName}'}'
                ' · Base ${AppFormatters.cop(session.openingCash)} · '
                '${session.expensesTotal > 0 ? 'Pagos a proveedores ${AppFormatters.cop(session.expensesTotal)} · ' : ''}'
                'Efectivo esperado ${AppFormatters.cop(session.expectedCash)}',
          ),
        };
        final history = OutlinedButton(
          key: const Key('cash-history'),
          onPressed: () => showCashHistory(context),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFF334155)),
            backgroundColor: const Color(0xFF1E293B),
            minimumSize: const Size(0, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Historial de cierres'),
        );
        final primary = switch (session) {
          _ when !canWrite || state.load != CashLoad.ready => null,
          null => FilledButton.icon(
            key: const Key('cash-open'),
            onPressed: () => _open(context),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandTeal,
              minimumSize: const Size(0, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.lock_open_rounded, size: 18),
            label: const Text('Abrir caja'),
          ),
          final session => FilledButton.icon(
            key: const Key('cash-close'),
            onPressed: () => _close(context, session),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandTeal,
              minimumSize: const Size(0, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.fact_check_outlined, size: 18),
            label: const Text('Realizar cuadre de caja'),
          ),
        };
        return Container(
          key: const Key('cash-banner'),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _ink,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 14,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.brandTeal.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.brandTeal.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Icon(
                        session == null
                            ? Icons.lock_outline_rounded
                            : Icons.verified_user_outlined,
                        color: const Color(0xFFCCFF00),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: AppTypography.labelLg.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            text,
                            style: AppTypography.bodySm.copyWith(
                              color: const Color(0xFFCBD5E1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  history,
                  if (session != null && canWrite)
                    OutlinedButton.icon(
                      key: const Key('cash-expense'),
                      onPressed: () => showCashExpenseDialog(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF334155)),
                        backgroundColor: const Color(0xFF1E293B),
                        minimumSize: const Size(0, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.local_shipping_outlined, size: 18),
                      label: const Text('Pago a proveedor'),
                    ),
                  if (session != null && canWrite)
                    OutlinedButton.icon(
                      key: const Key('cash-movement'),
                      onPressed: () => showCashMovementDialog(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF334155)),
                        backgroundColor: const Color(0xFF1E293B),
                        minimumSize: const Size(0, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.swap_vert_rounded, size: 18),
                      label: const Text('Ingreso / retiro'),
                    ),
                  ?primary,
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MoneyField extends StatelessWidget {
  const _MoneyField({
    required this.controller,
    required this.label,
    this.fieldKey,
    this.onChanged,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String label;
  final Key? fieldKey;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  @override
  Widget build(BuildContext context) => TextField(
    key: fieldKey,
    controller: controller,
    autofocus: autofocus,
    keyboardType: TextInputType.number,
    inputFormatters: [
      FilteringTextInputFormatter.digitsOnly,
      const CopInputFormatter(),
    ],
    onChanged: onChanged,
    style: AppTypography.headlineSm.copyWith(fontWeight: FontWeight.w800),
    decoration: InputDecoration(labelText: label, prefixText: r'$ '),
  );
}

class _OpenCashDialog extends StatefulWidget {
  const _OpenCashDialog();

  @override
  State<_OpenCashDialog> createState() => _OpenCashDialogState();
}

class _OpenCashDialogState extends State<_OpenCashDialog> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await context.read<CashCubit>().openCash(
      CopInputFormatter.parse(_amount.text),
      note: _note.text,
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _saving = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      scrollable: true,
      title: const Text('Abrir caja'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Cuenta el efectivo con que empiezas (la base para dar '
              'vueltas). Al cerrar se compara con lo que entró en efectivo.',
              style: AppTypography.bodySm.copyWith(color: AppColors.slate600),
            ),
            const SizedBox(height: 12),
            _MoneyField(
              fieldKey: const Key('cash-opening'),
              controller: _amount,
              label: 'Base de efectivo',
              autofocus: true,
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('cash-open-note'),
              controller: _note,
              maxLength: 300,
              decoration: const InputDecoration(
                labelText: 'Nota (opcional)',
                hintText: 'Ej. Turno de la tarde',
              ),
            ),
            if (_error case final error?)
              Text(
                error,
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.statusDue,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('cash-open-confirm'),
          onPressed: _saving ? null : _submit,
          child: Text(_saving ? 'Abriendo…' : 'Abrir caja'),
        ),
      ],
    );
  }
}

class _CloseCashDialog extends StatefulWidget {
  const _CloseCashDialog({required this.session});

  final CashSession session;

  @override
  State<_CloseCashDialog> createState() => _CloseCashDialogState();
}

class _CloseCashDialogState extends State<_CloseCashDialog> {
  final _counted = TextEditingController();
  final _note = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _counted.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || _counted.text.isEmpty) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await context.read<CashCubit>().closeCash(
      CopInputFormatter.parse(_counted.text),
      note: _note.text,
    );
    if (!mounted) return;
    if (result.error == null) {
      Navigator.of(context).pop(result.closed);
    } else {
      setState(() {
        _saving = false;
        _error = result.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Al pagar a un proveedor desde el cuadre, la caja se recarga.
    return BlocBuilder<CashCubit, CashState>(
      buildWhen: (prev, curr) => prev.session != curr.session,
      builder: (context, state) =>
          _build(context, state.session ?? widget.session),
    );
  }

  Future<void> _voidExpense(CashExpense expense) async {
    final cubit = context.read<CashCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _ReasonDialog(title: '¿Anular este pago?'),
    );
    if (reason == null) return;
    final error = await cubit.voidExpense(expense.id, reason);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(error ?? 'Pago anulado.'),
          backgroundColor: error == null ? null : AppColors.statusDue,
        ),
      );
  }

  Future<void> _voidMovement(CashMovement movement) async {
    final cubit = context.read<CashCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => _ReasonDialog(
        title: '¿Anular este ${movement.type.label.toLowerCase()}?',
      ),
    );
    if (reason == null) return;
    final error = await cubit.voidMovement(movement.id, reason);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(error ?? '${movement.type.label} anulado.'),
          backgroundColor: error == null ? null : AppColors.statusDue,
        ),
      );
  }

  Widget _build(BuildContext context, CashSession s) {
    final row = AppTypography.bodySm.copyWith(color: AppColors.slate600);
    final value = AppTypography.bodySm.copyWith(
      color: AppColors.onSurface,
      fontWeight: FontWeight.w700,
    );
    final counted = _counted.text.isEmpty
        ? null
        : CopInputFormatter.parse(_counted.text);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      scrollable: true,
      title: const Text('Cuadre de caja'),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Desde las ${AppFormatters.time(s.openedAt)} '
              '(${AppFormatters.shortDate(s.openedAt)})',
              style: row,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.slate50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.slate200),
              ),
              child: Column(
                children: [
                  for (final m in s.methods)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: PaymentMethod.fromApi(m.code).color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${m.name} · ${m.count} '
                              '${m.count == 1 ? 'pago' : 'pagos'}',
                              style: row,
                            ),
                          ),
                          Text(AppFormatters.cop(m.amount), style: value),
                        ],
                      ),
                    ),
                  if (s.methods.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('Sin cobros en este turno.', style: row),
                    ),
                  Divider(height: 14, color: AppColors.slate200),
                  Row(
                    children: [
                      Expanded(child: Text('Base de efectivo', style: row)),
                      Text(AppFormatters.cop(s.openingCash), style: value),
                    ],
                  ),
                  if (s.cashExpensesTotal > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Pagos a proveedores en efectivo',
                            style: row,
                          ),
                        ),
                        Text(
                          '−${AppFormatters.cop(s.cashExpensesTotal)}',
                          style: value.copyWith(color: AppColors.statusDue),
                        ),
                      ],
                    ),
                  ],
                  if (s.cashInTotal > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text('Ingresos de efectivo', style: row),
                        ),
                        Text(
                          '+${AppFormatters.cop(s.cashInTotal)}',
                          style: value.copyWith(color: AppColors.emerald600),
                        ),
                      ],
                    ),
                  ],
                  if (s.cashOutTotal > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text('Retiros de efectivo', style: row),
                        ),
                        Text(
                          '−${AppFormatters.cop(s.cashOutTotal)}',
                          style: value.copyWith(color: AppColors.statusDue),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Efectivo esperado en caja',
                          style: value.copyWith(fontSize: 14),
                        ),
                      ),
                      Text(
                        AppFormatters.cop(s.expectedCash),
                        style: AppTypography.headlineSm.copyWith(
                          color: AppColors.brandTealDeep,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _ExpensesList(
              expenses: s.expenses,
              onVoid: s.isOpen ? _voidExpense : null,
            ),
            _MovementsList(
              movements: s.movements,
              onVoid: s.isOpen ? _voidMovement : null,
            ),
            Wrap(
              spacing: 4,
              children: [
                TextButton.icon(
                  key: const Key('close-add-expense'),
                  onPressed: () => showCashExpenseDialog(context),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Pago a proveedor'),
                ),
                TextButton.icon(
                  key: const Key('close-add-movement'),
                  onPressed: () => showCashMovementDialog(context),
                  icon: const Icon(Icons.swap_vert_rounded, size: 18),
                  label: const Text('Ingreso / retiro'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            _MoneyField(
              fieldKey: const Key('cash-counted'),
              controller: _counted,
              label: 'Efectivo contado',
              autofocus: true,
              onChanged: (_) => setState(() {}),
            ),
            if (counted != null) ...[
              const SizedBox(height: 8),
              Builder(
                builder: (_) {
                  final (label, color) = differenceLabel(
                    counted - s.expectedCash,
                  );
                  return Container(
                    key: const Key('cash-difference'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      label,
                      style: AppTypography.labelLg.copyWith(
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 8),
            TextField(
              key: const Key('cash-close-note'),
              controller: _note,
              maxLength: 300,
              decoration: const InputDecoration(
                labelText: 'Nota (opcional)',
                hintText: 'Ej. Se pagaron \$10.000 de hielo',
              ),
            ),
            if (_error case final error?)
              Text(
                error,
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.statusDue,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('cash-close-confirm'),
          onPressed: _saving || counted == null ? null : _submit,
          child: Text(_saving ? 'Cerrando…' : 'Cerrar caja'),
        ),
      ],
    );
  }
}

/// Historial de cierres de caja (paginado de a 20).
Future<void> showCashHistory(BuildContext context) => showDialog<void>(
  context: context,
  builder: (_) => BlocProvider.value(
    value: context.read<CashCubit>(),
    child: const _CashHistoryDialog(),
  ),
);

class _CashHistoryDialog extends StatefulWidget {
  const _CashHistoryDialog();

  @override
  State<_CashHistoryDialog> createState() => _CashHistoryDialogState();
}

class _CashHistoryDialogState extends State<_CashHistoryDialog> {
  final _items = <CashSession>[];
  int _total = 0;
  int _page = 0;
  bool _loading = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _next();
  }

  Future<void> _next() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final page = await context.read<CashCubit>().history(_page + 1);
      if (!mounted) return;
      setState(() {
        _page++;
        _items.addAll(page.items);
        _total = page.total;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Historial de cierres',
                      style: AppTypography.headlineSm.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Flexible(
              child: _items.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: _loading
                            ? const CircularProgressIndicator()
                            : Text(
                                _failed
                                    ? 'No pudimos cargar los cierres.'
                                    : 'Aún no hay cierres de caja.',
                                style: AppTypography.bodyMd.copyWith(
                                  color: AppColors.slate600,
                                ),
                              ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      itemCount: _items.length + 1,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        if (i == _items.length) {
                          if (_items.length >= _total) {
                            return const SizedBox.shrink();
                          }
                          return Center(
                            child: TextButton(
                              onPressed: _loading ? null : _next,
                              child: Text(
                                _loading ? 'Cargando…' : 'Ver más cierres',
                              ),
                            ),
                          );
                        }
                        return _ClosedSessionTile(session: _items[i]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClosedSessionTile extends StatelessWidget {
  const _ClosedSessionTile({required this.session});

  final CashSession session;

  @override
  Widget build(BuildContext context) {
    final s = session;
    final (label, color) = differenceLabel(s.difference ?? 0);
    final muted = AppTypography.bodySm.copyWith(color: AppColors.slate500);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  AppFormatters.mediumDate(s.closedAt ?? s.openedAt),
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  label,
                  style: AppTypography.labelSm.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${AppFormatters.time(s.openedAt)} – '
            '${s.closedAt == null ? '' : AppFormatters.time(s.closedAt!)}'
            '${s.closedByName == null ? '' : ' · Cerró ${s.closedByName}'}',
            style: muted,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              Text('Base ${AppFormatters.cop(s.openingCash)}', style: muted),
              Text(
                'Esperado ${AppFormatters.cop(s.expectedCash)}',
                style: muted,
              ),
              Text(
                'Contado ${AppFormatters.cop(s.countedCash ?? 0)}',
                style: muted.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text('Cobrado ${AppFormatters.cop(s.collected)}', style: muted),
              if (s.expensesTotal > 0)
                Text(
                  'Pagos a proveedores ${AppFormatters.cop(s.expensesTotal)}',
                  style: muted,
                ),
              if (s.cashInTotal > 0)
                Text(
                  'Ingresos ${AppFormatters.cop(s.cashInTotal)}',
                  style: muted,
                ),
              if (s.cashOutTotal > 0)
                Text(
                  'Retiros ${AppFormatters.cop(s.cashOutTotal)}',
                  style: muted,
                ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: Key('receipt-${s.id}'),
              onPressed: () => showCashReceipt(context, s),
              icon: const Icon(Icons.receipt_long_rounded, size: 18),
              label: const Text('Ver comprobante'),
            ),
          ),
          if (s.closingNote case final note?) ...[
            const SizedBox(height: 4),
            Text('Nota: $note', style: muted),
          ],
        ],
      ),
    );
  }
}

/// Pagos a proveedores del turno, con opción de anular los vigentes.
class _ExpensesList extends StatelessWidget {
  const _ExpensesList({required this.expenses, this.onVoid});

  final List<CashExpense> expenses;
  final ValueChanged<CashExpense>? onVoid;

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) return const SizedBox.shrink();
    final muted = AppTypography.bodySm.copyWith(
      color: AppColors.slate500,
      fontSize: 11,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'PAGOS A PROVEEDORES',
          style: AppTypography.labelSm.copyWith(
            color: AppColors.slate500,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        for (final e in expenses)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Container(
              key: Key('expense-${e.id}'),
              padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
              decoration: BoxDecoration(
                color: e.isVoided
                    ? AppColors.dangerTint.withValues(alpha: 0.4)
                    : AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.slate200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.local_shipping_outlined,
                    size: 18,
                    color: e.isVoided ? AppColors.slate400 : AppColors.slate600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${e.supplierName} · ${e.concept}',
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySm.copyWith(
                            color: e.isVoided
                                ? AppColors.slate400
                                : AppColors.onSurface,
                            fontWeight: FontWeight.w700,
                            decoration: e.isVoided
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        Text(
                          [
                            AppFormatters.time(e.createdAt),
                            PaymentMethod.fromApi(e.method).label,
                            if (e.isVoided)
                              'Anulado${e.voidReason == null ? '' : ': ${e.voidReason}'}',
                          ].join(' · '),
                          style: e.isVoided
                              ? muted.copyWith(color: AppColors.statusDue)
                              : muted,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '−${AppFormatters.cop(e.amount)}',
                    style: AppTypography.bodySm.copyWith(
                      color: e.isVoided
                          ? AppColors.slate400
                          : AppColors.statusDue,
                      fontWeight: FontWeight.w800,
                      decoration: e.isVoided
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  if (onVoid != null && !e.isVoided)
                    IconButton(
                      key: Key('void-expense-${e.id}'),
                      tooltip: 'Anular pago',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => onVoid!(e),
                      icon: Icon(
                        Icons.block_rounded,
                        size: 16,
                        color: AppColors.slate400,
                      ),
                    )
                  else
                    const SizedBox(width: 8),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Pide un motivo; `null` si se cancela.
class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog({required this.title});

  final String title;

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(widget.title),
      content: TextField(
        key: const Key('expense-void-reason'),
        controller: _reason,
        autofocus: true,
        maxLength: 300,
        decoration: const InputDecoration(labelText: 'Motivo'),
        onChanged: (_) => setState(() {}),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Volver'),
        ),
        FilledButton(
          key: const Key('expense-void-confirm'),
          onPressed: _reason.text.trim().length < 3
              ? null
              : () => Navigator.of(context).pop(_reason.text.trim()),
          style: FilledButton.styleFrom(backgroundColor: AppColors.statusDue),
          child: const Text('Anular'),
        ),
      ],
    );
  }
}

/// Registra un pago a un proveedor en la caja abierta. Devuelve `true` si se
/// registró.
Future<bool> showCashExpenseDialog(BuildContext context) async {
  if (!ensureCanWrite(context)) return false;
  final cubit = context.read<CashCubit>();
  final messenger = ScaffoldMessenger.of(context);
  final saved =
      await showDialog<bool>(
        context: context,
        builder: (_) =>
            BlocProvider.value(value: cubit, child: const _ExpenseDialog()),
      ) ??
      false;
  if (saved) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Pago a proveedor registrado.')),
      );
  }
  return saved;
}

class _ExpenseDialog extends StatefulWidget {
  const _ExpenseDialog();

  @override
  State<_ExpenseDialog> createState() => _ExpenseDialogState();
}

class _ExpenseDialogState extends State<_ExpenseDialog> {
  final _amount = TextEditingController();
  final _concept = TextEditingController();
  List<Supplier>? _suppliers;
  String? _supplierId;
  String _method = 'EFECTIVO';
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  @override
  void dispose() {
    _amount.dispose();
    _concept.dispose();
    super.dispose();
  }

  Future<void> _loadSuppliers({String? select}) async {
    try {
      final suppliers = await context.read<CashCubit>().activeSuppliers();
      if (!mounted) return;
      setState(() {
        _suppliers = suppliers;
        _supplierId =
            select ??
            _supplierId ??
            (suppliers.length == 1 ? suppliers.single.id : null);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _suppliers = const [];
        _error = 'No pudimos cargar los proveedores.';
      });
    }
  }

  /// Registrar un proveedor sin salir del pago.
  Future<void> _newSupplier() async {
    final cubit = context.read<CashCubit>();
    Supplier? created;
    await showSupplierDialog(
      context,
      onSave: (draft) async {
        final result = await cubit.createSupplier(draft);
        created = result.supplier;
        return result.error;
      },
    );
    if (created case final supplier?) {
      await _loadSuppliers(select: supplier.id);
    }
  }

  Future<void> _submit() async {
    final supplierId = _supplierId;
    if (_saving) return;
    if (supplierId == null) {
      setState(() => _error = 'Elige el proveedor.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await context.read<CashCubit>().addExpense((
      supplierId: supplierId,
      amount: CopInputFormatter.parse(_amount.text),
      method: _method,
      concept: _concept.text,
    ));
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _saving = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final suppliers = _suppliers;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      scrollable: true,
      title: const Text('Pago a proveedor'),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Si lo pagas en efectivo, se descuenta del efectivo esperado '
              'al cerrar la caja.',
              style: AppTypography.bodySm.copyWith(color: AppColors.slate600),
            ),
            const SizedBox(height: 12),
            if (suppliers == null)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              if (suppliers.isEmpty)
                Text(
                  'Aún no tienes proveedores registrados.',
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.slate500,
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  key: const Key('expense-supplier'),
                  initialValue: _supplierId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Proveedor'),
                  items: [
                    for (final s in suppliers)
                      DropdownMenuItem(
                        value: s.id,
                        child: Text(s.name, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (id) => setState(() => _supplierId = id),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const Key('expense-new-supplier'),
                  onPressed: _saving ? null : _newSupplier,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Registrar proveedor'),
                ),
              ),
            ],
            _MoneyField(
              fieldKey: const Key('expense-amount'),
              controller: _amount,
              label: 'Valor pagado',
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('expense-concept'),
              controller: _concept,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'Concepto',
                hintText: 'Ej. Pedido de bebidas',
              ),
            ),
            Text(
              'MÉTODO DE PAGO',
              style: AppTypography.labelSm.copyWith(
                color: AppColors.slate500,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final method in PaymentMethod.selectable)
                  ChoiceChip(
                    key: Key('expense-method-${method.apiCode}'),
                    avatar: Icon(method.icon, size: 16, color: method.color),
                    label: Text(method.label),
                    selected: _method == method.apiCode,
                    onSelected: (_) =>
                        setState(() => _method = method.apiCode!),
                  ),
              ],
            ),
            if (_error case final error?) ...[
              const SizedBox(height: 10),
              Text(
                error,
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.statusDue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('expense-save'),
          onPressed: _saving || (suppliers?.isEmpty ?? true) ? null : _submit,
          child: Text(_saving ? 'Registrando…' : 'Registrar pago'),
        ),
      ],
    );
  }
}

/// Ingresos y retiros manuales del turno, con opción de anular los vigentes.
class _MovementsList extends StatelessWidget {
  const _MovementsList({required this.movements, this.onVoid});

  final List<CashMovement> movements;
  final ValueChanged<CashMovement>? onVoid;

  @override
  Widget build(BuildContext context) {
    if (movements.isEmpty) return const SizedBox.shrink();
    final muted = AppTypography.bodySm.copyWith(
      color: AppColors.slate500,
      fontSize: 11,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 4),
        Text(
          'INGRESOS Y RETIROS',
          style: AppTypography.labelSm.copyWith(
            color: AppColors.slate500,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        for (final m in movements)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Container(
              key: Key('movement-${m.id}'),
              padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
              decoration: BoxDecoration(
                color: m.isVoided
                    ? AppColors.dangerTint.withValues(alpha: 0.4)
                    : AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.slate200),
              ),
              child: Row(
                children: [
                  Icon(
                    m.type == CashMovementType.ingreso
                        ? Icons.south_west_rounded
                        : Icons.north_east_rounded,
                    size: 18,
                    color: m.isVoided
                        ? AppColors.slate400
                        : m.type == CashMovementType.ingreso
                        ? AppColors.emerald600
                        : AppColors.statusDue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${m.type.label} · ${m.reason}',
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySm.copyWith(
                            color: m.isVoided
                                ? AppColors.slate400
                                : AppColors.onSurface,
                            fontWeight: FontWeight.w700,
                            decoration: m.isVoided
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        Text(
                          [
                            AppFormatters.time(m.createdAt),
                            ?m.createdByName,
                            if (m.isVoided)
                              'Anulado${m.voidReason == null ? '' : ': ${m.voidReason}'}',
                          ].join(' · '),
                          style: m.isVoided
                              ? muted.copyWith(color: AppColors.statusDue)
                              : muted,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${m.type == CashMovementType.ingreso ? '+' : '−'}'
                    '${AppFormatters.cop(m.amount)}',
                    style: AppTypography.bodySm.copyWith(
                      color: m.isVoided
                          ? AppColors.slate400
                          : m.type == CashMovementType.ingreso
                          ? AppColors.emerald600
                          : AppColors.statusDue,
                      fontWeight: FontWeight.w800,
                      decoration: m.isVoided
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  if (onVoid != null && !m.isVoided)
                    IconButton(
                      key: Key('void-movement-${m.id}'),
                      tooltip: 'Anular',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => onVoid!(m),
                      icon: Icon(
                        Icons.block_rounded,
                        size: 16,
                        color: AppColors.slate400,
                      ),
                    )
                  else
                    const SizedBox(width: 8),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Ingreso o retiro manual de efectivo en la caja abierta. Devuelve `true`
/// si se registró.
Future<bool> showCashMovementDialog(
  BuildContext context, {
  CashMovementType initial = CashMovementType.retiro,
}) async {
  if (!ensureCanWrite(context)) return false;
  final cubit = context.read<CashCubit>();
  final messenger = ScaffoldMessenger.of(context);
  final type = await showDialog<CashMovementType>(
    context: context,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: _MovementDialog(initial: initial),
    ),
  );
  if (type != null) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('${type.label} registrado.')));
  }
  return type != null;
}

class _MovementDialog extends StatefulWidget {
  const _MovementDialog({required this.initial});

  final CashMovementType initial;

  @override
  State<_MovementDialog> createState() => _MovementDialogState();
}

class _MovementDialogState extends State<_MovementDialog> {
  late var _type = widget.initial;
  final _amount = TextEditingController();
  final _reason = TextEditingController();
  bool _saving = false;
  String? _error;

  static const _suggestions = {
    CashMovementType.retiro: [
      'Consignación al banco',
      'Retiro del dueño',
      'Pago de nómina',
    ],
    CashMovementType.ingreso: [
      'Monedas para cambio',
      'Base adicional',
      'Devolución de un retiro',
    ],
  };

  @override
  void dispose() {
    _amount.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await context.read<CashCubit>().addMovement((
      type: _type,
      amount: CopInputFormatter.parse(_amount.text),
      reason: _reason.text,
    ));
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(_type);
    } else {
      setState(() {
        _saving = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIn = _type == CashMovementType.ingreso;
    Widget option(CashMovementType type, IconData icon, Color color) {
      final selected = _type == type;
      return Expanded(
        child: Material(
          color: selected
              ? AppColors.surfaceContainerLowest
              : Colors.transparent,
          elevation: selected ? 1 : 0,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            key: Key('movement-type-${type.apiCode}'),
            borderRadius: BorderRadius.circular(10),
            onTap: () => setState(() => _type = type),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: selected ? color : AppColors.slate500,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    type.label,
                    style: AppTypography.labelLg.copyWith(
                      color: selected ? color : AppColors.slate600,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      scrollable: true,
      title: const Text('Ingreso o retiro de efectivo'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.slate100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  option(
                    CashMovementType.retiro,
                    Icons.north_east_rounded,
                    AppColors.statusDue,
                  ),
                  option(
                    CashMovementType.ingreso,
                    Icons.south_west_rounded,
                    AppColors.emerald600,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isIn
                  ? 'Efectivo que entra a la caja (p. ej. monedas para dar '
                        'cambio). Suma al efectivo esperado.'
                  : 'Efectivo que sale de la caja (el dueño lo retira o lo '
                        'consigna). Resta al efectivo esperado.',
              style: AppTypography.bodySm.copyWith(color: AppColors.slate600),
            ),
            const SizedBox(height: 10),
            _MoneyField(
              fieldKey: const Key('movement-amount'),
              controller: _amount,
              label: isIn ? 'Valor que entra' : 'Valor que sale',
              autofocus: true,
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('movement-reason'),
              controller: _reason,
              maxLength: 200,
              decoration: const InputDecoration(labelText: 'Motivo'),
            ),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final text in _suggestions[_type]!)
                  ActionChip(
                    label: Text(text),
                    onPressed: () => setState(() => _reason.text = text),
                  ),
              ],
            ),
            if (_error case final error?) ...[
              const SizedBox(height: 10),
              Text(
                error,
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.statusDue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('movement-save'),
          onPressed: _saving ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: isIn ? AppColors.emerald600 : AppColors.statusDue,
          ),
          child: Text(
            _saving ? 'Registrando…' : 'Registrar ${_type.label.toLowerCase()}',
          ),
        ),
      ],
    );
  }
}
