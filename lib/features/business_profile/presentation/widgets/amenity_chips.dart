import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/catalogs/domain/entities/catalog_amenity.dart';
import '../bloc/business_profile_bloc.dart';

/// Servicios de la sede, cargados del catálogo que se administra en el
/// panel: tocar uno lo agrega (✓) o lo quita (+).
class AmenityChips extends StatelessWidget {
  const AmenityChips({
    super.key,
    required this.options,
    required this.status,
    required this.selected,
    required this.onToggle,
    required this.onRetry,
  });

  final List<CatalogAmenity> options;
  final AmenityCatalogStatus status;

  /// Códigos seleccionados.
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      AmenityCatalogStatus.loading => Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.brandTeal,
            ),
          ),
        ),
      ),
      AmenityCatalogStatus.failure => _AmenitiesMessage(
        icon: Icons.cloud_off_outlined,
        text: 'No pudimos cargar los servicios.',
        action: TextButton.icon(
          onPressed: onRetry,
          style: TextButton.styleFrom(foregroundColor: AppColors.brandTeal),
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Reintentar'),
        ),
      ),
      AmenityCatalogStatus.ready when options.isEmpty =>
        const _AmenitiesMessage(
          icon: Icons.info_outline,
          text: 'Aún no hay servicios disponibles para elegir.',
        ),
      AmenityCatalogStatus.ready => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final amenity in options)
            _AmenityChip(
              label: amenity.name,
              selected: selected.contains(amenity.code),
              onTap: () => onToggle(amenity.code),
            ),
        ],
      ),
    };
  }
}

class _AmenitiesMessage extends StatelessWidget {
  const _AmenitiesMessage({
    required this.icon,
    required this.text,
    this.action,
  });

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySm.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
        ?action,
      ],
    );
  }
}

class _AmenityChip extends StatelessWidget {
  const _AmenityChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected
        ? AppColors.brandTealDeep
        : AppColors.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected
            ? AppColors.brandTealLight
            : AppColors.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? AppColors.brandTeal : Colors.transparent,
            width: 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    selected ? Icons.check_rounded : Icons.add_rounded,
                    size: 16,
                    color: selected ? AppColors.brandTeal : foreground,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelMd.copyWith(color: foreground),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
