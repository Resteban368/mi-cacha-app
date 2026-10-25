import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/payment.dart';
import '../bloc/payments/payments_bloc.dart';
import 'payment_styles.dart';

/// Filtros del listado de pagos: cancha, tipo de pago y día.
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

  Future<void> _pickDay(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: filter.day ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      locale: const Locale('es', 'CO'),
      helpText: 'Día del pago',
    );
    if (picked != null) {
      onChanged(
        PaymentsFilter(court: filter.court, method: filter.method, day: picked),
      );
    }
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
          onSelected: (court) => onChanged(
            PaymentsFilter(
              court: court,
              method: filter.method,
              day: filter.day,
            ),
          ),
        ),
        _MenuChip<PaymentMethod>(
          key: const Key('filter-method'),
          icon: Icons.payments_outlined,
          label: filter.method?.label ?? 'Tipo de pago',
          active: filter.method != null,
          allLabel: 'Todos los tipos',
          options: [for (final m in methods) (m, m.label)],
          onSelected: (method) => onChanged(
            PaymentsFilter(
              court: filter.court,
              method: method,
              day: filter.day,
            ),
          ),
        ),
        _ChipButton(
          key: const Key('filter-day'),
          icon: Icons.calendar_today_rounded,
          label: filter.day == null
              ? 'Día'
              : AppFormatters.mediumDate(filter.day!),
          active: filter.day != null,
          onTap: () => _pickDay(context),
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
          Text(label, style: AppTypography.labelLg.copyWith(color: fg)),
          if (trailing != null) ...[
            const SizedBox(width: 2),
            Icon(trailing, size: 18, color: fg),
          ],
        ],
      ),
    );
  }
}
