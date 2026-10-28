import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/session/write_access.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/cop_input_formatter.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_add_fab.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../domain/entities/product.dart';
import '../../domain/usecases/sales_usecases.dart';
import '../bloc/products_cubit.dart';
import '../widgets/product_category_style.dart';

/// Catálogo de lo que vende el negocio por unidad. Los productos no se
/// borran: se desactivan para dejar de ofrecerlos.
class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  Future<void> _edit(BuildContext context, [Product? product]) async {
    if (!ensureCanWrite(context)) return;
    final cubit = context.read<ProductsCubit>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _ProductDialog(
        product: product,
        onSave: (draft) => cubit.save(draft),
      ),
    );
    if (saved != true || !context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            product == null ? 'Producto creado.' : 'Producto actualizado.',
          ),
        ),
      );
  }

  Future<void> _toggle(
    BuildContext context,
    Product product,
    bool active,
  ) async {
    if (!ensureCanWrite(context)) return;
    final messenger = ScaffoldMessenger.of(context);
    final error = await context.read<ProductsCubit>().setActive(
      product,
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
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final canWrite = WriteAccessScope.canWrite(context);

    return Stack(
      children: [
        Column(
          children: [
            AppTopBar(
              title: 'Productos',
              subtitle: 'Lo que vendes por unidad',
              icon: Icons.inventory_2_rounded,
              onBack: () => context.go(AppRoutes.businessSales),
            ),
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: BlocBuilder<ProductsCubit, ProductsState>(
                  builder: (context, state) => switch (state.load) {
                    ProductsLoad.loading => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    ProductsLoad.failure => Center(
                      child: TextButton.icon(
                        onPressed: () => context.read<ProductsCubit>().load(),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text(
                          'No pudimos cargar los productos. Reintentar',
                        ),
                      ),
                    ),
                    ProductsLoad.ready when state.products.isEmpty => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'Agrega lo que vendes: agua, bebidas hidratantes, '
                          'snacks, alquiler de petos o balones…',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMd.copyWith(
                            color: AppColors.slate600,
                          ),
                        ),
                      ),
                    ),
                    ProductsLoad.ready => ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        bottomInset + 96,
                      ),
                      itemCount: state.products.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final product = state.products[i];
                        return Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 760),
                            child: _ProductTile(
                              product: product,
                              onEdit: canWrite
                                  ? () => _edit(context, product)
                                  : null,
                              onToggle: canWrite
                                  ? (active) =>
                                        _toggle(context, product, active)
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
              tooltip: 'Nuevo producto',
              onPressed: () => _edit(context),
            ),
          ),
      ],
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product, this.onEdit, this.onToggle});

  final Product product;
  final VoidCallback? onEdit;
  final ValueChanged<bool>? onToggle;

  @override
  Widget build(BuildContext context) {
    final active = product.isActive;
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
                  color: active ? product.category.tint : AppColors.slate100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  product.category.icon,
                  size: 20,
                  color: active ? product.category.color : AppColors.slate400,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: AppTypography.bodyMd.copyWith(
                        fontWeight: FontWeight.w700,
                        color: active
                            ? AppColors.onSurface
                            : AppColors.slate400,
                      ),
                    ),
                    Text(
                      active
                          ? AppFormatters.cop(product.price)
                          : '${AppFormatters.cop(product.price)} · Desactivado',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.slate500,
                      ),
                    ),
                  ],
                ),
              ),
              Tooltip(
                message: active ? 'Dejar de vender' : 'Volver a vender',
                child: Switch(
                  key: Key('product-active-${product.id}'),
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

class _ProductDialog extends StatefulWidget {
  const _ProductDialog({required this.onSave, this.product});

  final Product? product;
  final Future<String?> Function(ProductDraft draft) onSave;

  @override
  State<_ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<_ProductDialog> {
  late final _name = TextEditingController(text: widget.product?.name);
  late final _price = TextEditingController(
    text: switch (widget.product) {
      final p? => CopInputFormatter.format(p.price),
      null => '',
    },
  );
  late var _category = widget.product?.category ?? ProductCategory.otro;

  /// Mientras no la elijan a mano, la categoría sigue al nombre.
  late var _categoryTouched = widget.product != null;
  bool _saving = false;
  String? _error;

  void _onNameChanged(String name) {
    if (_categoryTouched) return;
    final guess = ProductCategory.guess(name);
    if (guess != _category) setState(() => _category = guess);
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await widget.onSave((
      id: widget.product?.id,
      name: _name.text,
      category: _category,
      price: CopInputFormatter.parse(_price.text),
    ));
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _saving = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        widget.product == null ? 'Nuevo producto' : 'Editar producto',
      ),
      // Con las categorías no cabe en celulares pequeños: se desplaza.
      scrollable: true,
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const Key('product-name'),
              controller: _name,
              autofocus: widget.product == null,
              maxLength: Product.maxName,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                hintText: 'Ej. Agua 600 ml',
              ),
              onChanged: _onNameChanged,
            ),
            const SizedBox(height: 4),
            Text(
              'Categoría',
              style: AppTypography.labelSm.copyWith(
                color: AppColors.slate500,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final category in ProductCategory.values)
                  ChoiceChip(
                    key: Key('category-${category.apiCode}'),
                    avatar: Icon(
                      category.icon,
                      size: 16,
                      color: category.color,
                    ),
                    label: Text(category.label),
                    selected: _category == category,
                    onSelected: (_) => setState(() {
                      _category = category;
                      _categoryTouched = true;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            const SizedBox(height: 8),
            TextField(
              key: const Key('product-price'),
              controller: _price,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                CopInputFormatter(),
              ],
              decoration: const InputDecoration(
                labelText: 'Precio por unidad',
                prefixText: r'$ ',
              ),
              onSubmitted: (_) => _submit(),
            ),
            if (_error case final error?) ...[
              const SizedBox(height: 8),
              Text(
                error,
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.statusDue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('product-save'),
          onPressed: _saving ? null : _submit,
          child: Text(_saving ? 'Guardando…' : 'Guardar'),
        ),
      ],
    );
  }
}
