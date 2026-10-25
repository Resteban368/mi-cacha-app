import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/entities/customer.dart';
import '../bloc/new_reservation/new_reservation_bloc.dart';
import 'create_reservation_shimmer.dart';
import 'reservation_section_card.dart';

/// Cliente de la reserva: uno existente (búsqueda por nombre, teléfono o
/// cédula) o uno nuevo con nombre, teléfono y cédula.
class CreateReservationClientCard extends StatelessWidget {
  const CreateReservationClientCard({
    super.key,
    required this.isNewCustomer,
    required this.onModeChanged,
    required this.selectedCustomer,
    required this.results,
    required this.searchStatus,
    required this.searchController,
    required this.onQueryChanged,
    required this.onCustomerSelected,
    required this.nameController,
    required this.phoneController,
    required this.documentController,
  });

  final bool isNewCustomer;
  final ValueChanged<bool> onModeChanged;
  final Customer? selectedCustomer;
  final List<Customer> results;
  final CustomerSearchStatus searchStatus;
  final TextEditingController searchController;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<Customer?> onCustomerSelected;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController documentController;

  @override
  Widget build(BuildContext context) {
    return ReservationSectionCard(
      compact: true,
      icon: Icons.how_to_reg_outlined,
      title: 'Datos del cliente',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.slate100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _ModeButton(
                    icon: Icons.search,
                    label: 'Buscar cliente',
                    selected: !isNewCustomer,
                    onTap: () => onModeChanged(false),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _ModeButton(
                    icon: Icons.person_add_alt,
                    label: 'Cliente nuevo',
                    selected: isNewCustomer,
                    onTap: () => onModeChanged(true),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (isNewCustomer) ..._newCustomer() else ..._existing(),
        ],
      ),
    );
  }

  List<Widget> _existing() {
    return [
      // Buscador compacto (sin etiqueta encima).
      TextField(
        key: const Key('customer-search'),
        controller: searchController,
        textInputAction: TextInputAction.search,
        style: AppTypography.bodyMd.copyWith(color: AppColors.slate900),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Buscar por nombre, celular o cédula…',
          hintStyle: AppTypography.bodyMd.copyWith(color: AppColors.slate400),
          prefixIcon: Icon(
            Icons.search,
            size: 18,
            color: AppColors.slate400,
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 38),
          filled: true,
          fillColor: AppColors.slate50,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 10,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.slate200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.brandTeal),
          ),
        ),
        onChanged: onQueryChanged,
        // Enter elige el primer resultado.
        onSubmitted: (_) {
          if (results.isNotEmpty &&
              searchStatus == CustomerSearchStatus.ready) {
            onCustomerSelected(results.first);
          }
        },
      ),
      const SizedBox(height: 8),
      // Mientras busca se mantienen los resultados anteriores (sin parpadeo).
      if (searchStatus == CustomerSearchStatus.loading && results.isNotEmpty)
        Padding(
          padding: EdgeInsets.only(bottom: 4),
          child: LinearProgressIndicator(
            minHeight: 2,
            color: AppColors.brandTeal,
            backgroundColor: AppColors.brandTealLight,
          ),
        ),
      switch (searchStatus) {
        CustomerSearchStatus.loading when results.isNotEmpty => _results(),
        CustomerSearchStatus.loading ||
        CustomerSearchStatus.idle =>
          const CustomerSearchShimmer(itemCount: 2),
        CustomerSearchStatus.failure => const _Hint(
          'No pudimos buscar clientes. Revisa tu conexión.',
        ),
        CustomerSearchStatus.ready
            when results.isEmpty && selectedCustomer == null =>
          _Hint(
            searchController.text.trim().isEmpty
                ? 'Aún no tienes clientes. Crea uno nuevo.'
                : 'Sin resultados. Revisa el dato o crea un cliente nuevo.',
          ),
        CustomerSearchStatus.ready => _results(),
      },
    ];
  }

  /// Lista con el elegido marcado (se muestra aunque no esté en los
  /// resultados); tocarlo de nuevo lo quita.
  Widget _results() {
    final selected = selectedCustomer;
    final list = [
      ?selected,
      for (final customer in results)
        if (customer.id != selected?.id) customer,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 4),
          child: Text(
            searchController.text.trim().isEmpty
                ? 'CLIENTES RECIENTES'
                : 'RESULTADOS',
            style: AppTypography.labelSm.copyWith(
              color: AppColors.slate400,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              fontSize: 10,
            ),
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 170),
          child: ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 6),
            itemBuilder: (context, i) {
              final customer = list[i];
              final isSelected = customer.id == selected?.id;
              return _CustomerTile(
                customer: customer,
                highlighted: isSelected,
                onTap: () => onCustomerSelected(isSelected ? null : customer),
              );
            },
          ),
        ),
      ],
    );
  }

  List<Widget> _newCustomer() => [
    AppTextField(
      key: const Key('customer-name'),
      controller: nameController,
      label: 'Nombre completo',
      prefixIcon: Icons.badge_outlined,
      hintText: 'Ej. Laura Gómez',
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.next,
      inputFormatters: [LengthLimitingTextInputFormatter(100)],
      validator: (value) => NewCustomer.validateName(value ?? ''),
    ),
    const SizedBox(height: 8),
    AppTextField(
      key: const Key('customer-phone'),
      controller: phoneController,
      label: 'Teléfono / WhatsApp',
      prefixIcon: Icons.phone_outlined,
      hintText: 'Ej. 311 555 0001',
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d\s()+-]')),
        LengthLimitingTextInputFormatter(20),
      ],
      validator: (value) => NewCustomer.validatePhone(value ?? ''),
    ),
    const SizedBox(height: 8),
    AppTextField(
      key: const Key('customer-document'),
      controller: documentController,
      label: 'Cédula',
      prefixIcon: Icons.credit_card_outlined,
      hintText: 'Ej. 1.075.111.222',
      textInputAction: TextInputAction.next,
      inputFormatters: [LengthLimitingTextInputFormatter(20)],
      validator: (value) => NewCustomer.validateDocument(value ?? ''),
    ),
    const SizedBox(height: 6),
    const _Hint(
      'Si el teléfono o la cédula ya están registrados, se usa ese cliente.',
    ),
  ];
}

class _CustomerTile extends StatelessWidget {
  const _CustomerTile({
    required this.customer,
    this.onTap,
    this.highlighted = false,
  });

  final Customer customer;
  final VoidCallback? onTap;
  final bool highlighted;

  String get _initials {
    final parts = customer.name.trim().split(RegExp(r'\s+'));
    final first = parts.first.isEmpty ? '?' : parts.first[0];
    final second = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
    return '$first$second'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final details = [
      if (customer.phone.isNotEmpty) customer.phone,
      if (customer.documentId.isNotEmpty) 'C.C. ${customer.documentId}',
    ].join(' · ');
    return Material(
      color: highlighted ? AppColors.surface : AppColors.slate50,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: highlighted ? AppColors.brandTeal : AppColors.slate200,
              width: highlighted ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: highlighted ? AppColors.brandTeal : AppColors.slate700,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _initials,
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.slate900,
                        fontWeight: highlighted
                            ? FontWeight.w700
                            : FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (details.isNotEmpty)
                      Text(
                        details,
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.slate500,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (highlighted)
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.brandTeal,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 13,
                    color: AppColors.accentLime,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.accentLime : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: selected ? AppColors.slate900 : AppColors.slate600,
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSm.copyWith(
                      color: selected ? AppColors.slate900 : AppColors.slate600,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
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

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
  );
}
