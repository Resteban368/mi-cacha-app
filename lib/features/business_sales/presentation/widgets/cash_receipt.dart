import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../business_payments/domain/entities/payment.dart';
import '../../../business_payments/presentation/widgets/payment_styles.dart';
import '../../domain/entities/cash_session.dart';

/// Colores fijos del comprobante: siempre claro (se comparte como imagen),
/// sin importar el modo de la app.
abstract final class _Ink {
  static const paper = Color(0xFFFFFFFF);
  static const page = Color(0xFFF1F5F9);
  static const brand = Color(0xFF0F8B7A);
  static const brandDeep = Color(0xFF084C43);
  static const lime = Color(0xFFCCFF00);
  static const text = Color(0xFF0F172A);
  static const muted = Color(0xFF64748B);
  static const faint = Color(0xFF94A3B8);
  static const line = Color(0xFFE2E8F0);
  static const soft = Color(0xFFF8FAFC);
  static const green = Color(0xFF059669);
  static const red = Color(0xFFDC2626);
  static const amber = Color(0xFFD97706);
}

String _code(CashSession s) {
  final id = s.id.replaceAll('-', '').toUpperCase();
  return 'CC-${id.length > 8 ? id.substring(0, 8) : id}';
}

String _signed(int value) => value > 0
    ? '+${AppFormatters.cop(value)}'
    : value < 0
    ? '−${AppFormatters.cop(-value)}'
    : AppFormatters.cop(0);

(String, Color, IconData) _status(int difference) => difference == 0
    ? ('CAJA CUADRADA', _Ink.green, Icons.verified_rounded)
    : difference > 0
    ? ('SOBRANTE', _Ink.amber, Icons.trending_up_rounded)
    : ('FALTANTE', _Ink.red, Icons.trending_down_rounded);

String _dateTime(DateTime d) =>
    '${AppFormatters.mediumDate(d)} · ${AppFormatters.time(d)}';

String _duration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  return h == 0 ? '$m min' : '$h h ${m.toString().padLeft(2, '0')} min';
}

/// Resumen del cierre en texto (para WhatsApp o copiar).
String cashReceiptText(CashSession s) {
  final diff = s.difference ?? 0;
  final (status, _, _) = _status(diff);
  final lines = [
    '🧾 *CIERRE DE CAJA · ${s.businessName}*',
    'N.° ${_code(s)}',
    'Apertura: ${_dateTime(s.openedAt)}${s.openedByName == null ? '' : ' (${s.openedByName})'}',
    if (s.closedAt case final closed?)
      'Cierre: ${_dateTime(closed)}${s.closedByName == null ? '' : ' (${s.closedByName})'}',
    '',
    '*Efectivo*',
    'Base: ${AppFormatters.cop(s.openingCash)}',
    'Cobros en efectivo: +${AppFormatters.cop(s.cashCollected)}',
    if (s.cashInTotal > 0) 'Ingresos: +${AppFormatters.cop(s.cashInTotal)}',
    if (s.cashExpensesTotal > 0)
      'Pagos a proveedores: −${AppFormatters.cop(s.cashExpensesTotal)}',
    if (s.cashOutTotal > 0) 'Retiros: −${AppFormatters.cop(s.cashOutTotal)}',
    'Esperado: ${AppFormatters.cop(s.expectedCash)}',
    'Contado: ${AppFormatters.cop(s.countedCash ?? 0)}',
    '*$status ${diff == 0 ? '' : _signed(diff)}*'.trimRight(),
    '',
    '*Cobros del turno: ${AppFormatters.cop(s.collected)}*',
    for (final m in s.methods)
      '• ${PaymentMethod.fromApi(m.code).label}: ${AppFormatters.cop(m.amount)}',
    if (s.closingNote case final note?) ...['', 'Nota: $note'],
    '',
    'Generado con Mi Cancha',
  ];
  return lines.join('\n');
}

/// Muestra el comprobante del cierre con sus acciones: compartir la imagen
/// (en web, si el navegador no comparte, se descarga) y copiar el texto.
Future<void> showCashReceipt(BuildContext context, CashSession session) =>
    showDialog<void>(
      context: context,
      builder: (_) => _ReceiptDialog(session: session),
    );

class _ReceiptDialog extends StatefulWidget {
  const _ReceiptDialog({required this.session});

  final CashSession session;

  @override
  State<_ReceiptDialog> createState() => _ReceiptDialogState();
}

class _ReceiptDialogState extends State<_ReceiptDialog> {
  final _boundary = GlobalKey();
  bool _sharing = false;

  Future<Uint8List?> _png() async {
    final boundary =
        _boundary.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data?.buffer.asUint8List();
  }

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final bytes = await _png();
      if (bytes == null) throw StateError('Sin imagen');
      final name = 'cierre-caja-${_code(widget.session).toLowerCase()}.png';
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(bytes, mimeType: 'image/png', name: name)],
          fileNameOverrides: [name],
          title: 'Cierre de caja ${_code(widget.session)}',
          text: 'Cierre de caja · ${widget.session.businessName}',
        ),
      );
    } catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo compartir la imagen. Copia el resumen en texto.',
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _copy() async {
    await Clipboard.setData(
      ClipboardData(text: cashReceiptText(widget.session)),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Resumen copiado. Pégalo en WhatsApp.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Dialog(
      backgroundColor: _Ink.page,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 460,
          maxHeight: size.height * 0.92,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Comprobante de cierre',
                      style: AppTypography.labelLg.copyWith(
                        color: _Ink.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: _Ink.muted),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                // En celulares angostos se ve más pequeño; la imagen que se
                // comparte sale siempre a tamaño completo.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: RepaintBoundary(
                    key: _boundary,
                    child: CashReceipt(session: widget.session),
                  ),
                ),
              ),
            ),
            Container(
              color: _Ink.paper,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('receipt-copy'),
                      onPressed: _copy,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _Ink.brandDeep,
                        side: const BorderSide(color: _Ink.line),
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('Copiar texto'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      key: const Key('receipt-share'),
                      onPressed: _sharing ? null : _share,
                      style: FilledButton.styleFrom(
                        backgroundColor: _Ink.brand,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _sharing
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.ios_share_rounded, size: 18),
                      label: const Text('Compartir'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// El comprobante como ticket: se dibuja igual en pantalla y en la imagen.
class CashReceipt extends StatelessWidget {
  const CashReceipt({super.key, required this.session});

  final CashSession session;

  @override
  Widget build(BuildContext context) {
    final s = session;
    final diff = s.difference ?? 0;
    final (status, statusColor, statusIcon) = _status(diff);
    final expenses = [
      for (final e in s.expenses)
        if (!e.isVoided) e,
    ];
    final movements = [
      for (final m in s.movements)
        if (!m.isVoided) m,
    ];
    return SizedBox(
      width: 400,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Encabezado de marca.
          Container(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_Ink.brandDeep, _Ink.brand],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: _Ink.lime,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.sports_soccer_rounded,
                        color: _Ink.brandDeep,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Mi Cancha',
                      style: AppTypography.labelLg.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _code(s),
                        style: AppTypography.labelSm.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'COMPROBANTE DE CIERRE DE CAJA',
                  style: AppTypography.labelSm.copyWith(
                    color: _Ink.lime,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.businessName.isEmpty ? 'Mi negocio' : s.businessName,
                  style: AppTypography.headlineSm.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppFormatters.longDate(s.closedAt ?? s.openedAt),
                  style: AppTypography.bodySm.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          // Cuerpo del ticket.
          Container(
            color: _Ink.paper,
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Resultado del cuadre.
                Container(
                  key: const Key('receipt-status'),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, color: statusColor, size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              status,
                              style: AppTypography.labelLg.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                              ),
                            ),
                            Text(
                              'Contado ${AppFormatters.cop(s.countedCash ?? 0)}'
                              ' · Esperado ${AppFormatters.cop(s.expectedCash)}',
                              style: AppTypography.bodySm.copyWith(
                                color: _Ink.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (diff != 0)
                        Text(
                          _signed(diff),
                          style: AppTypography.headlineSm.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _Section(
                  title: 'Turno',
                  children: [
                    _Row(
                      'Apertura',
                      _dateTime(s.openedAt),
                      detail: s.openedByName,
                    ),
                    if (s.closedAt case final closed?) ...[
                      _Row('Cierre', _dateTime(closed), detail: s.closedByName),
                      _Row(
                        'Duración',
                        _duration(closed.difference(s.openedAt)),
                      ),
                    ],
                  ],
                ),
                _Section(
                  title: 'Efectivo en caja',
                  children: [
                    _Row('Base de apertura', AppFormatters.cop(s.openingCash)),
                    _Row(
                      'Cobros en efectivo',
                      '+${AppFormatters.cop(s.cashCollected)}',
                      color: _Ink.green,
                    ),
                    if (s.cashInTotal > 0)
                      _Row(
                        'Ingresos de efectivo',
                        '+${AppFormatters.cop(s.cashInTotal)}',
                        color: _Ink.green,
                      ),
                    if (s.cashExpensesTotal > 0)
                      _Row(
                        'Pagos a proveedores',
                        '−${AppFormatters.cop(s.cashExpensesTotal)}',
                        color: _Ink.red,
                      ),
                    if (s.cashOutTotal > 0)
                      _Row(
                        'Retiros',
                        '−${AppFormatters.cop(s.cashOutTotal)}',
                        color: _Ink.red,
                      ),
                    const _Dashed(),
                    _Row(
                      'Efectivo esperado',
                      AppFormatters.cop(s.expectedCash),
                      strong: true,
                    ),
                    _Row(
                      'Efectivo contado',
                      AppFormatters.cop(s.countedCash ?? 0),
                      strong: true,
                    ),
                    _Row(
                      'Diferencia',
                      _signed(diff),
                      color: statusColor,
                      strong: true,
                    ),
                  ],
                ),
                _Section(
                  title: 'Cobros del turno',
                  trailing: AppFormatters.cop(s.collected),
                  children: [
                    if (s.methods.isEmpty)
                      const _Row('Sin cobros en el turno', ''),
                    for (final m in s.methods)
                      _Row(
                        PaymentMethod.fromApi(m.code).label,
                        AppFormatters.cop(m.amount),
                        detail: '${m.count} ${m.count == 1 ? 'pago' : 'pagos'}',
                        dot: PaymentMethod.fromApi(m.code).color,
                      ),
                  ],
                ),
                if (expenses.isNotEmpty)
                  _Section(
                    title: 'Pagos a proveedores',
                    trailing: AppFormatters.cop(s.expensesTotal),
                    children: [
                      for (final e in expenses)
                        _Row(
                          e.supplierName,
                          '−${AppFormatters.cop(e.amount)}',
                          detail:
                              '${e.concept} · '
                              '${PaymentMethod.fromApi(e.method).label}',
                          color: _Ink.red,
                        ),
                    ],
                  ),
                if (movements.isNotEmpty)
                  _Section(
                    title: 'Ingresos y retiros',
                    children: [
                      for (final m in movements)
                        _Row(
                          m.type.label,
                          '${m.type == CashMovementType.ingreso ? '+' : '−'}'
                          '${AppFormatters.cop(m.amount)}',
                          detail: m.reason,
                          color: m.type == CashMovementType.ingreso
                              ? _Ink.green
                              : _Ink.red,
                        ),
                    ],
                  ),
                if (s.closingNote case final note?)
                  _Section(
                    title: 'Nota del cierre',
                    children: [
                      Text(
                        note,
                        style: AppTypography.bodySm.copyWith(color: _Ink.text),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          // Pie troquelado.
          Container(
            color: _Ink.paper,
            padding: const EdgeInsets.fromLTRB(22, 4, 22, 14),
            child: Column(
              children: [
                const _Dashed(),
                const SizedBox(height: 8),
                Text(
                  'Generado con Mi Cancha · micanchaapp.com',
                  textAlign: TextAlign.center,
                  style: AppTypography.labelSm.copyWith(
                    color: _Ink.faint,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 12,
            child: CustomPaint(painter: _ZigZagPainter()),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children, this.trailing});

  final String title;
  final String? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: AppTypography.labelSm.copyWith(
                    color: _Ink.brand,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              if (trailing case final value?)
                Text(
                  value,
                  style: AppTypography.labelSm.copyWith(
                    color: _Ink.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            decoration: BoxDecoration(
              color: _Ink.soft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _Ink.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(
    this.label,
    this.value, {
    this.detail,
    this.color,
    this.strong = false,
    this.dot,
  });

  final String label;
  final String value;
  final String? detail;
  final Color? color;
  final bool strong;
  final Color? dot;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (dot case final dot?) ...[
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.bodySm.copyWith(
                    color: strong ? _Ink.text : _Ink.muted,
                    fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
                if (detail case final text?)
                  Text(
                    text,
                    style: AppTypography.labelSm.copyWith(
                      color: _Ink.faint,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: AppTypography.bodySm.copyWith(
              color: color ?? _Ink.text,
              fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Línea punteada (como la de un ticket).
class _Dashed extends StatelessWidget {
  const _Dashed();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 6),
    child: SizedBox(
      height: 1,
      width: double.infinity,
      child: CustomPaint(painter: _DashPainter()),
    ),
  );
}

class _DashPainter extends CustomPainter {
  const _DashPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _Ink.line
      ..strokeWidth = 1.2;
    for (var x = 0.0; x < size.width; x += 8) {
      canvas.drawLine(Offset(x, 0), Offset(x + 4, 0), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Borde inferior en zigzag, como papel de caja registradora.
class _ZigZagPainter extends CustomPainter {
  const _ZigZagPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const tooth = 12.0;
    final path = Path()..moveTo(0, 0);
    var x = 0.0;
    while (x < size.width) {
      path
        ..lineTo(x + tooth / 2, size.height)
        ..lineTo(x + tooth, 0);
      x += tooth;
    }
    path
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = _Ink.paper);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
