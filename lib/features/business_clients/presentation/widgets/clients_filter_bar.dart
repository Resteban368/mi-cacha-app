import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/client_filter.dart';

/// Barra de filtros y búsqueda responsiva para el directorio de clientes en Web y Móvil.
class ClientsFilterBar extends StatelessWidget {
  const ClientsFilterBar({
    super.key,
    required this.searchController,
    required this.selectedFilter,
    required this.selectedSort,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.onSortChanged,
    required this.onNewClientPressed,
    this.totalClients = 0,
    this.filteredClients = 0,
  });

  final TextEditingController searchController;
  final ClientFilterType selectedFilter;
  final ClientSortBy selectedSort;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<ClientFilterType> onFilterChanged;
  final ValueChanged<ClientSortBy> onSortChanged;
  final VoidCallback onNewClientPressed;
  final int totalClients;
  final int filteredClients;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 840;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isWide)
                Row(
                  children: [
                    Expanded(flex: 3, child: _buildSearchField()),
                    const SizedBox(width: 12),
                    _buildSortDropdown(),
                    const SizedBox(width: 12),
                    _buildNewClientButton(),
                  ],
                )
              else ...[
                Row(
                  children: [
                    Expanded(child: _buildSearchField()),
                    const SizedBox(width: 8),
                    _buildSortDropdown(),
                  ],
                ),
                const SizedBox(height: 12),
                _buildNewClientButton(),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ClientFilterType.values.map((filter) {
                          final isSelected = selectedFilter == filter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              selected: isSelected,
                              showCheckmark: false,
                              avatar: isSelected
                                  ? const Icon(
                                      Icons.check_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    )
                                  : null,
                              label: Text(
                                filter.label,
                                style: AppTypography.labelMd.copyWith(
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.onSurfaceVariant,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                              backgroundColor: AppColors.surfaceContainerLow,
                              selectedColor: AppColors.brandTeal,
                              side: BorderSide(
                                color: isSelected
                                    ? AppColors.brandTeal
                                    : AppColors.outlineVariant.withValues(
                                        alpha: 0.5,
                                      ),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              onSelected: (_) => onFilterChanged(filter),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  if (isWide) ...[
                    const SizedBox(width: 12),
                    Text(
                      'Mostrando $filteredClients de $totalClients clientes',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.slate500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: searchController,
      onChanged: onSearchChanged,
      style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
      decoration: InputDecoration(
        hintText: 'Buscar por nombre, cédula o teléfono (+57)...',
        hintStyle: AppTypography.bodyMd.copyWith(color: AppColors.slate400),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppColors.brandTeal,
          size: 20,
        ),
        suffixIcon: searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 18),
                color: AppColors.slate400,
                onPressed: () {
                  searchController.clear();
                  onSearchChanged('');
                },
              )
            : null,
        filled: true,
        fillColor: AppColors.slate50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.brandTeal, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildSortDropdown() {
    return PopupMenuButton<ClientSortBy>(
      initialValue: selectedSort,
      onSelected: onSortChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      itemBuilder: (context) => ClientSortBy.values
          .map(
            (sort) => PopupMenuItem(
              value: sort,
              child: Row(
                children: [
                  Icon(
                    selectedSort == sort
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    size: 18,
                    color: selectedSort == sort
                        ? AppColors.brandTeal
                        : AppColors.slate400,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    sort.label,
                    style: AppTypography.bodyMd.copyWith(
                      color: selectedSort == sort
                          ? AppColors.brandTeal
                          : AppColors.onSurface,
                      fontWeight: selectedSort == sort
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.slate50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sort_rounded, size: 20, color: AppColors.slate600),
            const SizedBox(width: 8),
            Text(
              selectedSort.label,
              style: AppTypography.labelMd.copyWith(
                color: AppColors.slate700,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_drop_down_rounded,
              size: 20,
              color: AppColors.slate500,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewClientButton() {
    return FilledButton.icon(
      onPressed: onNewClientPressed,
      icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
      label: const Text('Nuevo Cliente'),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.brandTeal,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: AppTypography.labelLg.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
