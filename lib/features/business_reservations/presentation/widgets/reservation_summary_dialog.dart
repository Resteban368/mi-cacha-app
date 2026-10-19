import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/reservation.dart';

enum ReservationSummaryAction { viewAgenda, createAnother }

// Paleta del diseño "Modal Confirmación de Reserva" (Stitch): modo oscuro.
const _surface = Color(0xFF0F172A);
const _card = Color(0xFF111827);
const _border = Color(0xFF1F2937);
const _brand = Color(0xFF34D399);
const _brandDeep = Color(0xFF10B981);
const _muted = Color(0xFF94A3B8);
const _soft = Color(0xFFCBD5E1);
const _amber = Color(0xFFFBBF24);

/// Resumen tras crear la reserva: total, pagado, saldo y estado. Con
/// [courtAssigned] (la API eligió la cancha) se destaca en cuál quedó.
Future<ReservationSummaryAction?> showReservationSummary(
  BuildContext context,
  Reservation reservation, {
  bool courtAssigned = false,
}) => showDialog<ReservationSummaryAction>(
  context: context,
  barrierDismissible: false,
  builder: (context) => Dialog(
    backgroundColor: _surface,
    insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: BorderSide(color: _border.withValues(alpha: 0.6)),
    ),
    clipBehavior: Clip.antiAlias,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: _SummaryBody(
        reservation: reservation,
        courtAssigned: courtAssigned,
      ),
    ),
  ),
);

class _SummaryBody extends StatelessWidget {
  const _SummaryBody({required this.reservation, required this.courtAssigned});

  final Reservation reservation;
  final bool courtAssigned;

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    final hours = AppFormatters.duration(r.end.difference(r.start));
    final code = r.id.length > 6 ? r.id.substring(0, 6) : r.id;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              tooltip: 'Cerrar',
              icon: const Icon(Icons.close_rounded, color: _muted),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const _CheckBadge(),
          const SizedBox(height: 16),
          Text(
            '¡Reserva confirmada!',
            textAlign: TextAlign.center,
            style: AppTypography.headlineSm.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: _Dot(),
              ),
              Flexible(
                child: Text(
                  '${r.courtsLabel} · ${AppFormatters.shortDate(r.start)} · '
                  '${AppFormatters.timeRange(r.start, r.end)}'
                      .toUpperCase(),
                  textAlign: TextAlign.center,
                  style: AppTypography.labelSm.copyWith(
                    color: _brand,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Initials(name: r.customerName),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      r.customerName,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelLg.copyWith(color: _soft),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('|', style: TextStyle(color: Color(0xFF64748B))),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '#RES-${code.toUpperCase()}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: _muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (courtAssigned) ...[
            const SizedBox(height: 12),
            Container(
              key: const Key('assigned-court'),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF064E3B).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Reserva creada en ${r.courtsLabel}',
                textAlign: TextAlign.center,
                style: AppTypography.labelLg.copyWith(color: _brand),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
            ),
            child: Column(
              children: [
                _TotalRow(
                  label: 'Total turno',
                  hint: hours.isEmpty ? null : '$hours de juego',
                  value: AppFormatters.cop(r.displayTotal),
                ),
                if (r.discount > 0)
                  _PlainRow(
                    label: 'Descuento',
                    value: '−${AppFormatters.cop(r.discount)}',
                  ),
                const _Divider(),
                _PlainRow(
                  label: 'Pagado',
                  value: AppFormatters.cop(r.displayPaid),
                ),
                const _Divider(),
                _TotalRow(
                  label: 'Saldo a pagar',
                  hint: r.isFullyPaid ? 'Pagado completo' : 'Pendiente',
                  hintColor: r.isFullyPaid ? _brand : _amber,
                  value: AppFormatters.cop(r.displayBalance),
                  emphasis: false,
                ),
                const _Divider(),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Estado',
                        style: TextStyle(color: _muted, fontSize: 14),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _brandDeep.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: _brandDeep.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        r.status.label,
                        style: AppTypography.labelSm.copyWith(
                          color: _brand,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            key: const Key('summary-view-agenda'),
            style: FilledButton.styleFrom(
              backgroundColor: _brandDeep,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () => Navigator.of(
              context,
            ).pop(ReservationSummaryAction.viewAgenda),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Ver en la agenda'),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            key: const Key('summary-create-another'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _soft,
              side: const BorderSide(color: _border),
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () => Navigator.of(
              context,
            ).pop(ReservationSummaryAction.createAnother),
            child: const Text('Nueva reserva'),
          ),
        ],
      ),
    );
  }
}

/// Check que aparece una sola vez con un leve rebote (sin animación infinita).
class _CheckBadge extends StatelessWidget {
  const _CheckBadge();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) => Transform.scale(
        scale: scale,
        child: Opacity(opacity: scale.clamp(0.0, 1.0), child: child),
      ),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [_brandDeep, _brand],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: _brandDeep.withValues(alpha: 0.35),
              blurRadius: 18,
            ),
          ],
        ),
        child: Container(
          margin: const EdgeInsets.all(2.5),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: _surface,
          ),
          child: const Icon(Icons.check_rounded, size: 38, color: _brand),
        ),
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final initials = parts.take(2).map((p) => p[0]).join().toUpperCase();
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [_brandDeep, Color(0xFF2DD4BF)]),
      ),
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) => Container(
    width: 8,
    height: 8,
    decoration: const BoxDecoration(shape: BoxShape.circle, color: _brand),
  );
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 20, thickness: 1, color: Color(0xFF1E293B));
}

class _PlainRow extends StatelessWidget {
  const _PlainRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(label, style: const TextStyle(color: _muted, fontSize: 14)),
      ),
      Text(
        value,
        style: const TextStyle(
          color: _soft,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.hint,
    this.hintColor = _muted,
    this.emphasis = true,
  });

  final String label;
  final String value;
  final String? hint;
  final Color hintColor;
  final bool emphasis;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: emphasis ? _soft : Colors.white,
                fontSize: 14,
                fontWeight: emphasis ? FontWeight.w500 : FontWeight.w600,
              ),
            ),
            if (hint != null)
              Text(
                hint!,
                style: TextStyle(color: hintColor, fontSize: 12),
              ),
          ],
        ),
      ),
      Text(
        value,
        style: TextStyle(
          color: emphasis ? _brand : Colors.white,
          fontSize: emphasis ? 22 : 17,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}
