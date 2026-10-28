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
              Wrap(spacing: 10, runSpacing: 10, children: [history, ?primary]),
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
    final s = widget.session;
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
            const SizedBox(height: 14),
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
            ],
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
