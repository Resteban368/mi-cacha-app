import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/entities/customer.dart';
import '../bloc/new_reservation/new_reservation_bloc.dart';
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
      icon: Icons.person_outline,
      title: 'Datos del cliente',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: false,
                icon: Icon(Icons.search, size: 18),
                label: Text('Buscar cliente'),
              ),
              ButtonSegment(
                value: true,
                icon: Icon(Icons.person_add_alt, size: 18),
                label: Text('Cliente nuevo'),
              ),
            ],
            selected: {isNewCustomer},
            showSelectedIcon: false,
            onSelectionChanged: (value) => onModeChanged(value.first),
          ),
          const SizedBox(height: 14),
          if (isNewCustomer) ..._newCustomer() else ..._existing(),
        ],
      ),
    );
  }

  List<Widget> _existing() {
    final customer = selectedCustomer;
    if (customer != null) {
      return [
        _CustomerTile(
          customer: customer,
          trailing: TextButton(
            onPressed: () => onCustomerSelected(null),
            child: const Text('Cambiar'),
          ),
          highlighted: true,
        ),
      ];
    }
    return [
      AppTextField(
        key: const Key('customer-search'),
        controller: searchController,
        label: 'Buscar',
        prefixIcon: Icons.search,
        hintText: 'Nombre, teléfono o cédula',
        textInputAction: TextInputAction.search,
        onChanged: onQueryChanged,
      ),
      const SizedBox(height: 8),
      switch (searchStatus) {
        CustomerSearchStatus.loading ||
        CustomerSearchStatus.idle => const Padding(
          padding: EdgeInsets.all(12),
          child: Center(
            child: SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.brandTeal,
              ),
            ),
          ),
        ),
        CustomerSearchStatus.failure => const _Hint(
          'No pudimos buscar clientes. Revisa tu conexión.',
        ),
        CustomerSearchStatus.ready when results.isEmpty => _Hint(
          searchController.text.trim().isEmpty
              ? 'Aún no tienes clientes. Crea uno nuevo.'
              : 'Sin resultados. Revisa el dato o crea un cliente nuevo.',
        ),
        CustomerSearchStatus.ready => Column(
          children: [
            if (searchController.text.trim().isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: _Hint('Clientes recientes'),
              ),
            for (final customer in results)
              _CustomerTile(
                customer: customer,
                onTap: () => onCustomerSelected(customer),
              ),
          ],
        ),
      },
    ];
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
    const SizedBox(height: 12),
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
    const SizedBox(height: 12),
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
    const SizedBox(height: 8),
    const _Hint(
      'Si el teléfono o la cédula ya están registrados, se usa ese cliente '
      'con sus datos.',
    ),
  ];
}

class _CustomerTile extends StatelessWidget {
  const _CustomerTile({
    required this.customer,
    this.onTap,
    this.trailing,
    this.highlighted = false,
  });

  final Customer customer;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool highlighted;

  String get _initials {
    final parts = customer.name.trim().split(RegExp(r'\s+'));
    final first = parts.first.isEmpty ? '?' : parts.first[0];
    final second = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
    return '$first$second'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlighted ? AppColors.brandTealLight : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: CircleAvatar(
          backgroundColor: AppColors.brandTeal,
          foregroundColor: AppColors.onPrimary,
          child: Text(_initials, style: AppTypography.labelMd),
        ),
        title: Text(customer.name, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          [
            if (customer.phone.isNotEmpty) customer.phone,
            if (customer.documentId.isNotEmpty) 'C.C. ${customer.documentId}',
          ].join(' · '),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: trailing,
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
