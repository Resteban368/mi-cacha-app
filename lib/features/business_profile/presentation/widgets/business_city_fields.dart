import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/catalogs/domain/entities/catalog_geography.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../bloc/business_city_cubit.dart';

/// «Departamento» y «Ciudad» del negocio: la ciudad se habilita al elegir el
/// departamento. Los dos abren un buscador porque hay muchos municipios.
class BusinessCityFields extends StatelessWidget {
  const BusinessCityFields({super.key, this.showMissingNotice = false});

  /// Negocio anterior sin ciudad: pide completarla.
  final bool showMissingNotice;

  Future<void> _pickDepartment(
    BuildContext context,
    BusinessCityState state,
  ) async {
    final cubit = context.read<BusinessCityCubit>();
    final picked = await showSearchPicker<CatalogDepartment>(
      context,
      title: 'Departamento',
      searchHint: 'Buscar departamento',
      items: state.departments,
      labelOf: (d) => d.name,
      selected: state.department,
    );
    if (picked != null) await cubit.selectDepartment(picked);
  }

  Future<void> _pickCity(BuildContext context, BusinessCityState state) async {
    final cubit = context.read<BusinessCityCubit>();
    final picked = await showSearchPicker<CatalogCity>(
      context,
      title: 'Ciudad · ${state.department?.name ?? ''}',
      searchHint: 'Buscar ciudad o municipio',
      items: state.cities,
      labelOf: (c) => c.name,
      selected: state.city,
    );
    if (picked != null) cubit.selectCity(picked);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BusinessCityCubit, BusinessCityState>(
      builder: (context, state) {
        final cubit = context.read<BusinessCityCubit>();
        final hasDepartment = state.department != null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showMissingNotice && state.city == null) ...[
              const _MissingCityNotice(),
              const SizedBox(height: 12),
            ],
            _PickerField(
              key: const Key('department-field'),
              label: 'Departamento',
              icon: Icons.map_outlined,
              placeholder: 'Selecciona el departamento',
              value: state.department?.name,
              error: state.departmentError,
              status: state.departmentsStatus,
              onTap: state.departmentsStatus == GeographyLoad.ready
                  ? () => _pickDepartment(context, state)
                  : null,
              onRetry: cubit.retryDepartments,
            ),
            const SizedBox(height: 16),
            _PickerField(
              key: const Key('city-field'),
              label: 'Ciudad',
              icon: Icons.location_city_outlined,
              placeholder: hasDepartment
                  ? 'Selecciona la ciudad'
                  : 'Primero elige el departamento',
              value: state.city?.name,
              error: state.cityError,
              status: hasDepartment ? state.citiesStatus : GeographyLoad.idle,
              onTap: hasDepartment && state.citiesStatus == GeographyLoad.ready
                  ? () => _pickCity(context, state)
                  : null,
              onRetry: cubit.retryCities,
            ),
          ],
        );
      },
    );
  }
}

class _MissingCityNotice extends StatelessWidget {
  const _MissingCityNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('missing-city-notice'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: AppColors.onErrorContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Completa tu ciudad. ',
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.onErrorContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text:
                        'Elige el departamento y la ciudad de tu sede y '
                        'guarda los cambios.',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.onErrorContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Campo que abre un selector. Muestra la carga y el error del catálogo con
/// "Reintentar".
class _PickerField extends StatelessWidget {
  const _PickerField({
    super.key,
    required this.label,
    required this.icon,
    required this.placeholder,
    required this.value,
    required this.error,
    required this.status,
    required this.onTap,
    required this.onRetry,
  });

  final String label;
  final IconData icon;
  final String placeholder;
  final String? value;
  final String? error;
  final GeographyLoad status;
  final VoidCallback? onTap;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textStyle = GoogleFonts.spaceGrotesk(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: AppColors.slate900,
    );
    final value = this.value;
    final failed = status == GeographyLoad.failure;
    final borderColor = error != null ? AppColors.error : AppColors.slate200;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
            color: AppColors.slate700,
          ),
        ),
        const SizedBox(height: 6),
        Semantics(
          button: true,
          enabled: onTap != null,
          label: '$label: ${value ?? placeholder}',
          excludeSemantics: true,
          child: Material(
            color: onTap == null && value == null
                ? AppColors.slate100
                : AppColors.slate50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: borderColor),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onTap,
              child: SizedBox(
                height: 50,
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Icon(icon, size: 20, color: AppColors.slate400),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        value ?? placeholder,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: value == null
                            ? textStyle.copyWith(color: AppColors.slate400)
                            : textStyle,
                      ),
                    ),
                    if (status == GeographyLoad.loading)
                      Padding(
                        padding: EdgeInsets.only(right: 14),
                        child: SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.brandTeal,
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: EdgeInsets.only(right: 10),
                        child: Icon(
                          Icons.expand_more_rounded,
                          color: AppColors.slate400,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (failed)
          Row(
            children: [
              Expanded(
                child: Text(
                  'No pudimos cargar la lista.',
                  style: AppTypography.bodySm.copyWith(color: AppColors.error),
                ),
              ),
              TextButton(
                key: Key('${label.toLowerCase()}-retry'),
                onPressed: onRetry,
                child: const Text('Reintentar'),
              ),
            ],
          )
        else if (error case final error?)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12),
            child: Text(
              error,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                color: AppColors.error,
              ),
            ),
          ),
      ],
    );
  }
}

/// Lista con buscador en una hoja inferior. Ignora tildes y mayúsculas al
/// filtrar («bogota» encuentra «Bogotá, D.C.»).
Future<T?> showSearchPicker<T>(
  BuildContext context, {
  required String title,
  required String searchHint,
  required List<T> items,
  required String Function(T) labelOf,
  T? selected,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  ),
  builder: (context) => ConstrainedBox(
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.85,
    ),
    child: _SearchPicker<T>(
      title: title,
      searchHint: searchHint,
      items: items,
      labelOf: labelOf,
      selected: selected,
    ),
  ),
);

class _SearchPicker<T> extends StatefulWidget {
  const _SearchPicker({
    required this.title,
    required this.searchHint,
    required this.items,
    required this.labelOf,
    required this.selected,
  });

  final String title;
  final String searchHint;
  final List<T> items;
  final String Function(T) labelOf;
  final T? selected;

  @override
  State<_SearchPicker<T>> createState() => _SearchPickerState<T>();
}

class _SearchPickerState<T> extends State<_SearchPicker<T>> {
  var _query = '';

  static const _accents = {
    'á': 'a',
    'é': 'e',
    'í': 'i',
    'ó': 'o',
    'ú': 'u',
    'ü': 'u',
    'ñ': 'n',
  };

  static String _normalize(String text) {
    final lower = text.toLowerCase();
    final buffer = StringBuffer();
    for (final char in lower.split('')) {
      buffer.write(_accents[char] ?? char);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final query = _normalize(_query.trim());
    final items = query.isEmpty
        ? widget.items
        : [
            for (final item in widget.items)
              if (_normalize(widget.labelOf(item)).contains(query)) item,
          ];
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(
              widget.title,
              style: AppTypography.headlineSm.copyWith(
                color: AppColors.onSurface,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              key: const Key('search-picker-field'),
              autofocus: true,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: widget.searchHint,
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: AppColors.slate50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.slate200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.slate200),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: items.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Sin resultados para "${_query.trim()}"',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final selected = item == widget.selected;
                      return ListTile(
                        title: Text(widget.labelOf(item)),
                        selected: selected,
                        selectedColor: AppColors.brandTeal,
                        trailing: selected
                            ? const Icon(Icons.check_rounded)
                            : null,
                        onTap: () => Navigator.of(context).pop(item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
