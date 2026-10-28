import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/session/business_modules.dart';
import '../../../../core/session/write_access.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_add_fab.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../domain/entities/cash_session.dart';
import '../bloc/suppliers_cubit.dart';
import '../widgets/sales_module_locked.dart';
import '../widgets/supplier_dialog.dart';

/// Proveedores del negocio (a quién se le paga desde la caja). No se borran:
/// se desactivan.
class SuppliersPage extends StatelessWidget {
  const SuppliersPage({super.key});

  Future<void> _edit(BuildContext context, [Supplier? supplier]) async {
    if (!ensureCanWrite(context)) return;
    final cubit = context.read<SuppliersCubit>();
    final saved = await showSupplierDialog(
      context,
      supplier: supplier,
      onSave: cubit.save,
    );
    if (!saved || !context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            supplier == null
                ? 'Proveedor registrado.'
                : 'Proveedor actualizado.',
          ),
        ),
      );
  }

  Future<void> _toggle(
    BuildContext context,
    Supplier supplier,
    bool active,
  ) async {
    if (!ensureCanWrite(context)) return;
    final messenger = ScaffoldMessenger.of(context);
    final error = await context.read<SuppliersCubit>().setActive(
      supplier,
      active,
    );
    if (error == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.statusDue),
      );
  }

  @override
  Widget build(BuildContext context) {
    final topBar = AppTopBar(
      title: 'Proveedores',
      subtitle: 'A quién le pagas desde la caja',
      icon: Icons.local_shipping_rounded,
      onBack: () => context.canPop()
          ? context.pop()
          : context.go(AppRoutes.businessInventory),
    );
    if (!BusinessModulesScope.salesOf(context)) {
      return Column(
        children: [
          topBar,
          const Expanded(child: SalesModuleLocked()),
        ],
      );
    }
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final canWrite = WriteAccessScope.canWrite(context);
    return Stack(
      children: [
        Column(
          children: [
            topBar,
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: BlocBuilder<SuppliersCubit, SuppliersState>(
                  builder: (context, state) => switch (state.load) {
                    SuppliersLoad.loading => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    SuppliersLoad.failure => Center(
                      child: TextButton.icon(
                        onPressed: () => context.read<SuppliersCubit>().load(),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text(
                          'No pudimos cargar los proveedores. Reintentar',
                        ),
                      ),
                    ),
                    SuppliersLoad.ready when state.suppliers.isEmpty => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'Registra a quién le compras: bebidas, hielo, aseo, '
                          'mantenimiento… Luego les pagas desde la caja.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMd.copyWith(
                            color: AppColors.slate600,
                          ),
                        ),
                      ),
                    ),
                    SuppliersLoad.ready => ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        bottomInset + 96,
                      ),
                      itemCount: state.suppliers.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final supplier = state.suppliers[i];
                        return Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 760),
                            child: _SupplierTile(
                              supplier: supplier,
                              onEdit: canWrite
                                  ? () => _edit(context, supplier)
                                  : null,
                              onToggle: canWrite
                                  ? (active) =>
                                        _toggle(context, supplier, active)
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  },
                ),
              ),
            ),
          ],
        ),
        if (canWrite)
          Positioned(
            right: 16,
            bottom: bottomInset + 16,
            child: AppAddFab(
              tooltip: 'Nuevo proveedor',
              onPressed: () => _edit(context),
            ),
          ),
      ],
    );
  }
}

class _SupplierTile extends StatelessWidget {
  const _SupplierTile({required this.supplier, this.onEdit, this.onToggle});

  final Supplier supplier;
  final VoidCallback? onEdit;
  final ValueChanged<bool>? onToggle;

  @override
  Widget build(BuildContext context) {
    final active = supplier.isActive;
    final detail = [
      if (supplier.documentId case final doc?) 'NIT/CC $doc',
      ?supplier.phone,
      if (!active) 'Desactivado',
    ].join(' · ');
    return Material(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onEdit,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.slate200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: active ? AppColors.brandTealLight : AppColors.slate100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.local_shipping_outlined,
                  size: 20,
                  color: active ? AppColors.brandTealDeep : AppColors.slate400,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      supplier.name,
                      style: AppTypography.bodyMd.copyWith(
                        fontWeight: FontWeight.w700,
                        color: active
                            ? AppColors.onSurface
                            : AppColors.slate400,
                      ),
                    ),
                    if (detail.isNotEmpty)
                      Text(
                        detail,
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.slate500,
                        ),
                      ),
                  ],
                ),
              ),
              Tooltip(
                message: active ? 'Desactivar' : 'Activar',
                child: Switch(
                  key: Key('supplier-active-${supplier.id}'),
                  value: active,
                  onChanged: onToggle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
