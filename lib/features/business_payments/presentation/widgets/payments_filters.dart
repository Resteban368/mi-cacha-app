import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/payment.dart';
import '../bloc/payments/payments_bloc.dart';
import 'payment_styles.dart';

/// Filtros del listado de pagos: cancha, tipo de pago y rango de fechas.
class PaymentsFilters extends StatelessWidget {
  const PaymentsFilters({
    super.key,
    required this.filter,
    required this.courts,
    required this.methods,
    required this.onChanged,
    required this.now,
  });

  final PaymentsFilter filter;
  final List<String> courts;
  final List<PaymentMethod> methods;
  final ValueChanged<PaymentsFilter> onChanged;
  final DateTime now;

  Future<void> _pickRange(BuildContext context) async {
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: filter.hasDates
          ? DateTimeRange(
              start: filter.from ?? filter.to!,
              end: filter.to ?? today,
            )
          : null,
      firstDate: DateTime(now.year - 2),
      lastDate: today,
      locale: const Locale('es', 'CO'),
      helpText: 'Fechas de los pagos',
      saveText: 'Aplicar',
      // En pantallas grandes, ventana centrada en vez de pantalla completa.
      builder: (context, child) => MediaQuery.sizeOf(context).width < 600
          ? child!
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 420,
                  maxHeight: 640,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: child,
                ),
              ),
            ),
    );
    if (picked != null) {
      onChanged(
        filter.copyWith(from: () => picked.start, to: () => picked.end),
      );
    }
  }

  /// `28 oct. 2026` o `28 oct. 2026 – 3 nov. 2026`.
  String get _rangeLabel {
    final from = filter.from, to = filter.to;
    if (from == null && to == null) return 'Fechas';
    if (from == null) return 'Hasta ${AppFormatters.mediumDate(to!)}';
    if (to == null || DateUtils.isSameDay(from, to)) {
      return AppFormatters.mediumDate(from);
    }
    // Mismo año: `1 oct – 9 oct. 2026`.
    final start = from.year == to.year
        ? AppFormatters.shortDate(from)
        : AppFormatters.mediumDate(from);
    return '$start – ${AppFormatters.mediumDate(to)}';
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _MenuChip<String>(
          key: const Key('filter-court'),
          icon: Icons.sports_soccer_rounded,
          label: filter.court ?? 'Cancha',
          active: filter.court != null,
          allLabel: 'Todas las canchas',
          options: [for (final c in courts) (c, c)],
          onSelected: (court) => onChanged(filter.copyWith(court: () => court)),
        ),
        _MenuChip<PaymentMethod>(
          key: const Key('filter-method'),
          icon: Icons.payments_outlined,
          label: filter.method?.label ?? 'Tipo de pago',
          active: filter.method != null,
          allLabel: 'Todos los tipos',
          options: [for (final m in methods) (m, m.label)],
          onSelected: (method) =>
              onChanged(filter.copyWith(method: () => method)),
        ),
        _ChipButton(
          key: const Key('filter-dates'),
          icon: Icons.date_range_rounded,
          label: _rangeLabel,
          active: filter.hasDates,
          onTap: () => _pickRange(context),
        ),
        if (filter.isActive)
          TextButton.icon(
            key: const Key('filter-clear'),
            onPressed: () => onChanged(const PaymentsFilter()),
            icon: const Icon(Icons.close_rounded, size: 16),
            label: const Text('Limpiar'),
            style: TextButton.styleFrom(foregroundColor: AppColors.brandTeal),
          ),
      ],
    );
  }
}

class _MenuChip<T> extends StatelessWidget {
  const _MenuChip({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
    required this.allLabel,
    required this.options,
    required this.onSelected,
  });

  final IconData icon;
  final String label;
  final bool active;
  final String allLabel;
  final List<(T, String)> options;
  final ValueChanged<T?> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T?>(
      tooltip: '',
      position: PopupMenuPosition.under,
      onSelected: onSelected,
      itemBuilder: (_) => [
        PopupMenuItem<T?>(value: null, child: Text(allLabel)),
        for (final (value, text) in options)
          PopupMenuItem<T?>(value: value, child: Text(text)),
      ],
      child: _ChipBody(
        icon: icon,
        label: label,
        active: active,
        trailing: Icons.expand_more_rounded,
      ),
    );
  }
}

class _ChipButton extends StatelessWidget {
  const _ChipButton({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(999),
    onTap: onTap,
    child: _ChipBody(icon: icon, label: label, active: active),
  );
}

class _ChipBody extends StatelessWidget {
  const _ChipBody({
    required this.icon,
    required this.label,
    required this.active,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final bool active;
  final IconData? trailing;

  @override
  Widget build(BuildContext context) {
    final fg = active ? AppColors.brandTeal : AppColors.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: active
            ? AppColors.brandTealLight
            : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: active ? AppColors.brandTeal : AppColors.outlineVariant,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelLg.copyWith(color: fg),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 2),
            Icon(trailing, size: 18, color: fg),
          ],
        ],
      ),
    );
  }
}
