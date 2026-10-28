import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/session/write_access.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/cop_input_formatter.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/cash_session.dart';
import '../../domain/entities/inventory.dart';
import '../../domain/entities/product.dart';
import '../bloc/inventory_cubit.dart';
import 'product_category_style.dart';

/// Muestra el resultado de una acción de inventario.
void _snack(ScaffoldMessengerState messenger, String text) => messenger
  ..hideCurrentSnackBar()
  ..showSnackBar(SnackBar(content: Text(text)));

Future<bool> _open(BuildContext context, Widget dialog, String done) async {
  if (!ensureCanWrite(context)) return false;
  final cubit = context.read<InventoryCubit>();
  final messenger = ScaffoldMessenger.of(context);
  final saved =
      await showDialog<bool>(
        context: context,
        builder: (_) => BlocProvider.value(value: cubit, child: dialog),
      ) ??
      false;
  if (saved) _snack(messenger, done);
  return saved;
}

/// Entrada de mercancía. Con [product] llega elegido; si no, se escoge.
Future<bool> showStockEntryDialog(BuildContext context, {Product? product}) =>
    _open(
      context,
      _EntryDialog(product: product),
      'Entrada registrada: el stock se actualizó.',
    );

/// Ajuste por conteo físico de [product].
Future<bool> showStockAdjustDialog(BuildContext context, Product product) =>
    _open(context, _AdjustDialog(product: product), 'Stock ajustado.');

/// Ajuste rápido: si no hay producto seleccionado, permite elegirlo.
Future<bool> showQuickAdjustDialog(
  BuildContext context, {
  Product? product,
}) async {
  if (product != null) {
    return showStockAdjustDialog(context, product);
  }
  if (!ensureCanWrite(context)) return false;
  final products = context.read<InventoryCubit>().state.overview.items;
  if (products.isEmpty) return false;
  final chosen = await showDialog<Product>(
    context: context,
    builder: (ctx) => _SelectProductForAdjustDialog(products: products),
  );
  if (chosen == null || !context.mounted) return false;
  return showStockAdjustDialog(context, chosen);
}

/// Control de stock y alerta de stock bajo de [product].
Future<bool> showStockAlertDialog(BuildContext context, Product product) =>
    _open(context, _AlertDialog(product: product), 'Alerta guardada.');

/// Campo de unidades (solo dígitos).
class _UnitsField extends StatelessWidget {
  const _UnitsField({
    required this.controller,
    required this.label,
    required this.fieldKey,
    this.helper,
    this.autofocus = false,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final Key fieldKey;
  final String? helper;
  final bool autofocus;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => TextField(
    key: fieldKey,
    controller: controller,
    autofocus: autofocus,
    keyboardType: TextInputType.number,
    inputFormatters: [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(6),
    ],
    onChanged: onChanged,
    style: AppTypography.headlineSm.copyWith(fontWeight: FontWeight.w800),
    decoration: InputDecoration(
      labelText: label,
      helperText: helper,
      suffixText: 'und',
    ),
  );
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Text(
      text,
      style: AppTypography.bodySm.copyWith(
        color: AppColors.statusDue,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

/// Producto y stock actual, arriba de cada diálogo con diseño refinado.
class _ProductHeader extends StatelessWidget {
  const _ProductHeader(this.product, {this.onChange});

  final Product product;
  final VoidCallback? onChange;

  @override
  Widget build(BuildContext context) {
    final bool isOut = product.trackStock && product.isOut;
    final bool isLow = product.trackStock && product.isLow && !product.isOut;

    final badgeBg = !product.trackStock
        ? AppColors.slate100
        : isOut
        ? const Color(0xFFFFE4E6)
        : isLow
        ? const Color(0xFFFEF3C7)
        : const Color(0xFFD1FAE5);

    final badgeColor = !product.trackStock
        ? AppColors.slate600
        : isOut
        ? const Color(0xFFE11D48)
        : isLow
        ? const Color(0xFFB45309)
        : const Color(0xFF059669);

    final badgeText = !product.trackStock
        ? 'Sin control'
        : isOut
        ? 'Agotado (0 und)'
        : isLow
        ? 'Stock bajo (${product.stock} und)'
        : '${product.stock} und';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: product.category.tint,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: product.category.color.withValues(alpha: 0.25),
              ),
            ),
            child: Icon(
              product.category.icon,
              color: product.category.color,
              size: 20,
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
                    color: AppColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  product.category.label,
                  style: AppTypography.bodySm.copyWith(
                    fontSize: 11,
                    color: AppColors.slate500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              badgeText,
              style: AppTypography.labelSm.copyWith(
                fontWeight: FontWeight.w800,
                color: badgeColor,
                fontSize: 11,
              ),
            ),
          ),
          if (onChange != null) ...[
            const SizedBox(width: 6),
            IconButton(
              icon: const Icon(Icons.swap_horiz_rounded, size: 20),
              tooltip: 'Cambiar producto',
              onPressed: onChange,
              color: AppColors.slate500,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Entrada
// ---------------------------------------------------------------------------

class _EntryDialog extends StatefulWidget {
  const _EntryDialog({this.product});

  final Product? product;

  @override
  State<_EntryDialog> createState() => _EntryDialogState();
}

class _EntryDialogState extends State<_EntryDialog> {
  final _quantity = TextEditingController();
  final _cost = TextEditingController();
  final _note = TextEditingController();
  final _searchProductController = TextEditingController();
  late String? _productId = widget.product?.id;
  String? _supplierId;
  List<Supplier> _suppliers = const [];
  bool _saving = false;
  String? _error;
  String _productQuery = '';

  @override
  void initState() {
    super.initState();
    context
        .read<InventoryCubit>()
        .suppliers()
        .then((s) {
          if (mounted) setState(() => _suppliers = s);
        })
        .catchError((_) {});
  }

  @override
  void dispose() {
    _quantity.dispose();
    _cost.dispose();
    _note.dispose();
    _searchProductController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final productId = _productId;
    if (_saving) return;
    if (productId == null) {
      setState(() => _error = 'Elige el producto.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final cost = CopInputFormatter.parse(_cost.text);
    final error = await context.read<InventoryCubit>().addEntry((
      productId: productId,
      quantity: int.tryParse(_quantity.text) ?? 0,
      unitCost: cost > 0 ? cost : null,
      supplierId: _supplierId,
      note: _note.text,
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
    final products = context.read<InventoryCubit>().state.overview.items;
    final units = int.tryParse(_quantity.text) ?? 0;
    final cost = CopInputFormatter.parse(_cost.text);

    // Producto seleccionado actualmente
    final selectedProduct = _productId != null
        ? products.where((p) => p.id == _productId).firstOrNull ?? widget.product
        : widget.product;

    // Productos filtrados para el buscador
    final filteredProducts = products.where((p) {
      if (_productQuery.isEmpty) return true;
      final q = _productQuery.toLowerCase();
      return p.name.toLowerCase().contains(q) ||
          p.category.label.toLowerCase().contains(q);
    }).toList();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      scrollable: true,
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFD1FAE5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: const Icon(
              Icons.move_to_inbox_rounded,
              size: 20,
              color: Color(0xFF059669),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Entrada de mercancía',
                  style: AppTypography.headlineSm.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Suma existencias al inventario y registra costos.',
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.slate500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sección de selección de producto
            if (selectedProduct != null)
              _ProductHeader(
                selectedProduct,
                onChange: widget.product == null
                    ? () => setState(() {
                        _productId = null;
                        _productQuery = '';
                        _searchProductController.clear();
                      })
                    : null,
              )
            else ...[
              // Buscador de producto
              Text(
                'Selecciona el producto',
                style: AppTypography.labelSm.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.slate700,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                key: const Key('entry-product-search'),
                controller: _searchProductController,
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre o categoría…',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _productQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchProductController.clear();
                            setState(() => _productQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.slate50,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.slate200),
                  ),
                ),
                onChanged: (q) => setState(() => _productQuery = q.trim()),
              ),
              const SizedBox(height: 8),
              // Lista de resultados filtrados
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: filteredProducts.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Text(
                            'No se encontraron productos.',
                            style: AppTypography.bodySm.copyWith(
                              color: AppColors.slate400,
                            ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: filteredProducts.length,
                        separatorBuilder: (_, _) => Divider(
                          height: 1,
                          color: AppColors.slate200,
                        ),
                        itemBuilder: (context, i) {
                          final p = filteredProducts[i];
                          return ListTile(
                            dense: true,
                            leading: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: p.category.tint,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                p.category.icon,
                                color: p.category.color,
                                size: 16,
                              ),
                            ),
                            title: Text(
                              p.name,
                              style: AppTypography.bodyMd.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            subtitle: Text(
                              p.category.label,
                              style: AppTypography.bodySm.copyWith(
                                fontSize: 11,
                                color: AppColors.slate500,
                              ),
                            ),
                            trailing: Text(
                              p.trackStock ? '${p.stock} und' : 'Sin control',
                              style: AppTypography.labelSm.copyWith(
                                fontWeight: FontWeight.w700,
                                color: p.isOut
                                    ? AppColors.statusDue
                                    : p.isLow
                                    ? const Color(0xFFB45309)
                                    : AppColors.slate600,
                              ),
                            ),
                            onTap: () {
                              setState(() {
                                _productId = p.id;
                                _error = null;
                              });
                            },
                          );
                        },
                      ),
              ),
              // Dropdown oculto o accesible para compatibilidad de clave si no hay producto
              Opacity(
                opacity: 0.0,
                child: SizedBox(
                  height: 0,
                  child: DropdownButtonFormField<String>(
                    key: const Key('entry-product'),
                    initialValue: _productId,
                    items: [
                      for (final p in products)
                        DropdownMenuItem(value: p.id, child: Text(p.name)),
                    ],
                    onChanged: (id) => setState(() => _productId = id),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            // Unidades que entran
            _UnitsField(
              fieldKey: const Key('entry-quantity'),
              controller: _quantity,
              label: 'Unidades que entran',
              autofocus: widget.product != null,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            // Costo por unidad
            TextField(
              key: const Key('entry-cost'),
              controller: _cost,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                const CopInputFormatter(),
              ],
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Costo por unidad de compra (opcional)',
                hintText: '0',
                prefixText: r'$ ',
                helperText:
                    'Costo pagado al proveedor para calcular el valor de compra y margen.',
                helperMaxLines: 2,
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
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.brandTeal,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            // Card de Total de la compra
            if (units > 0 && cost > 0) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        size: 18,
                        color: Color(0xFF059669),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total de la compra: ${AppFormatters.cop(units * cost)}',
                            style: AppTypography.labelMd.copyWith(
                              color: const Color(0xFF065F46),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$units und × ${AppFormatters.cop(cost)} cada una',
                            style: AppTypography.bodySm.copyWith(
                              fontSize: 11,
                              color: const Color(0xFF047857),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_suppliers.isNotEmpty) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                key: const Key('entry-supplier'),
                initialValue: _supplierId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Proveedor (opcional)',
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
                items: [
                  const DropdownMenuItem(value: null, child: Text('Ninguno')),
                  for (final s in _suppliers)
                    DropdownMenuItem(
                      value: s.id,
                      child: Text(s.name, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (id) => setState(() => _supplierId = id),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              key: const Key('entry-note'),
              controller: _note,
              maxLength: 200,
              decoration: InputDecoration(
                labelText: 'Nota o referencia de factura (opcional)',
                hintText: 'Ej. Factura #4582 / Distribuidor',
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
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.brandTeal,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            if (_error case final error?) _ErrorText(error),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          key: const Key('entry-save'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF0B382D),
            foregroundColor: const Color(0xFFA3E635),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _saving || units <= 0 ? null : _submit,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFA3E635),
                  ),
                )
              : const Icon(Icons.check_rounded, size: 18),
          label: Text(
            _saving ? 'Registrando…' : 'Registrar entrada',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Ajuste
// ---------------------------------------------------------------------------

class _AdjustDialog extends StatefulWidget {
  const _AdjustDialog({required this.product});

  final Product product;

  @override
  State<_AdjustDialog> createState() => _AdjustDialogState();
}

class _AdjustDialogState extends State<_AdjustDialog> {
  late final _stock = TextEditingController(
    text: widget.product.trackStock ? '${widget.product.stock}' : '',
  );
  final _reason = TextEditingController();
  bool _saving = false;
  String? _error;

  static const _suggestions = [
    'Conteo físico',
    'Producto vencido',
    'Producto dañado',
    'Consumo interno',
  ];

  @override
  void dispose() {
    _stock.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await context.read<InventoryCubit>().adjust((
      productId: widget.product.id,
      stock: int.tryParse(_stock.text) ?? 0,
      reason: _reason.text,
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
    final counted = int.tryParse(_stock.text);
    final current = widget.product.trackStock ? widget.product.stock : 0;
    final delta = counted == null ? null : counted - current;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      scrollable: true,
      title: const Text('Ajustar stock'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ProductHeader(widget.product),
            const SizedBox(height: 12),
            _UnitsField(
              fieldKey: const Key('adjust-stock'),
              controller: _stock,
              label: 'Unidades que hay de verdad',
              autofocus: true,
              helper: switch (delta) {
                null || 0 => null,
                > 0 => 'Sobran $delta respecto al sistema',
                _ => 'Faltan ${-delta} respecto al sistema',
              },
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('adjust-reason'),
              controller: _reason,
              maxLength: 200,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'Motivo'),
            ),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final text in _suggestions)
                  ActionChip(
                    label: Text(text),
                    onPressed: () => setState(() => _reason.text = text),
                  ),
              ],
            ),
            if (_error case final error?) _ErrorText(error),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('adjust-save'),
          onPressed:
              _saving ||
                  counted == null ||
                  delta == 0 ||
                  _reason.text.trim().length < 2
              ? null
              : _submit,
          child: Text(_saving ? 'Guardando…' : 'Guardar ajuste'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Alerta de stock bajo
// ---------------------------------------------------------------------------

class _AlertDialog extends StatefulWidget {
  const _AlertDialog({required this.product});

  final Product product;

  @override
  State<_AlertDialog> createState() => _AlertDialogState();
}

class _AlertDialogState extends State<_AlertDialog> {
  late bool _track = widget.product.trackStock;
  late final _min = TextEditingController(
    text: widget.product.minStock?.toString() ?? '',
  );
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _min.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await context.read<InventoryCubit>().configure((
      productId: widget.product.id,
      trackStock: _track,
      minStock: _min.text.isEmpty ? null : int.tryParse(_min.text),
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
      scrollable: true,
      title: const Text('Control de stock'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ProductHeader(widget.product),
            SwitchListTile(
              key: const Key('alert-track'),
              contentPadding: EdgeInsets.zero,
              value: _track,
              onChanged: (v) => setState(() => _track = v),
              title: const Text('Controlar existencias'),
              subtitle: const Text(
                'Se descuenta al vender y no deja vender más de lo que hay.',
              ),
            ),
            if (_track) ...[
              const SizedBox(height: 4),
              _UnitsField(
                fieldKey: const Key('alert-min'),
                controller: _min,
                label: 'Avisar cuando queden (opcional)',
                helper: 'Vacío = solo avisa cuando se agote',
              ),
            ],
            if (_error case final error?) _ErrorText(error),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('alert-save'),
          onPressed: _saving ? null : _submit,
          child: Text(_saving ? 'Guardando…' : 'Guardar'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Historial
// ---------------------------------------------------------------------------

/// Historial de existencias (de [product] o de todos), paginado.
Future<void> showStockHistory(BuildContext context, {Product? product}) {
  final cubit = context.read<InventoryCubit>();
  return showDialog<void>(
    context: context,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: _HistoryDialog(product: product),
    ),
  );
}

class _HistoryDialog extends StatefulWidget {
  const _HistoryDialog({this.product});

  final Product? product;

  @override
  State<_HistoryDialog> createState() => _HistoryDialogState();
}

class _HistoryDialogState extends State<_HistoryDialog> {
  final _items = <StockMovement>[];
  int _total = 0;
  int _page = 0;
  bool _loading = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _more();
  }

  Future<void> _more() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final result = await context.read<InventoryCubit>().movements(
        widget.product?.id,
        _page + 1,
      );
      if (!mounted) return;
      setState(() {
        _page++;
        _items.addAll(result.items);
        _total = result.total;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final showProduct = widget.product == null;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        widget.product == null
            ? 'Historial de inventario'
            : 'Historial · ${widget.product!.name}',
      ),
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      content: SizedBox(
        width: 520,
        height: 480,
        child: _items.isEmpty && _loading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
            ? Center(
                child: Text(
                  _failed
                      ? 'No pudimos cargar el historial.'
                      : 'Aún no hay movimientos.',
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.slate600,
                  ),
                ),
              )
            : ListView.separated(
                itemCount: _items.length + (_items.length < _total ? 1 : 0),
                separatorBuilder: (_, _) => const SizedBox(height: 6),
                itemBuilder: (context, i) {
                  if (i == _items.length) {
                    return Center(
                      child: TextButton(
                        key: const Key('history-more'),
                        onPressed: _loading ? null : _more,
                        child: Text(_loading ? 'Cargando…' : 'Ver más'),
                      ),
                    );
                  }
                  return _MovementTile(
                    movement: _items[i],
                    showProduct: showProduct,
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}

class _MovementTile extends StatelessWidget {
  const _MovementTile({required this.movement, required this.showProduct});

  final StockMovement movement;
  final bool showProduct;

  @override
  Widget build(BuildContext context) {
    final m = movement;
    final positive = m.quantity > 0;
    final (icon, color) = switch (m.type) {
      StockMovementType.entrada => (
        Icons.move_to_inbox_rounded,
        AppColors.emerald600,
      ),
      StockMovementType.venta => (
        Icons.shopping_bag_outlined,
        AppColors.brandTeal,
      ),
      StockMovementType.anulacion => (Icons.undo_rounded, AppColors.slate600),
      StockMovementType.ajuste => (Icons.tune_rounded, AppColors.amber500),
    };
    final detail = [
      AppFormatters.shortDate(m.createdAt),
      AppFormatters.time(m.createdAt),
      if (m.unitCost case final cost?) '${AppFormatters.cop(cost)} c/u',
      ?m.supplierName,
      ?m.note,
      ?m.createdByName,
    ].join(' · ');
    return Container(
      key: Key('stock-movement-${m.id}'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  showProduct
                      ? '${m.type.label} · ${m.productName}'
                      : m.type.label,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySm.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySm.copyWith(
                    fontSize: 11,
                    color: AppColors.slate500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${positive ? '+' : '−'}${m.quantity.abs()}',
                style: AppTypography.labelLg.copyWith(
                  fontWeight: FontWeight.w800,
                  color: positive ? AppColors.emerald600 : AppColors.statusDue,
                ),
              ),
              Text(
                'Quedan ${m.stockAfter}',
                style: AppTypography.labelSm.copyWith(
                  fontSize: 10,
                  color: AppColors.slate500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SelectProductForAdjustDialog extends StatefulWidget {
  const _SelectProductForAdjustDialog({required this.products});

  final List<Product> products;

  @override
  State<_SelectProductForAdjustDialog> createState() =>
      _SelectProductForAdjustDialogState();
}

class _SelectProductForAdjustDialogState
    extends State<_SelectProductForAdjustDialog> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.products.where((p) {
      if (_query.isEmpty) return true;
      return p.name.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Ajuste Rápido de Stock'),
      content: SizedBox(
        width: 440,
        height: 380,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar producto a ajustar…',
                prefixIcon: const Icon(Icons.search_rounded),
                isDense: true,
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
              onChanged: (q) => setState(() => _query = q.trim()),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No se encontraron productos.',
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.slate500,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 6),
                      itemBuilder: (context, i) {
                        final p = filtered[i];
                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: AppColors.slate200),
                          ),
                          tileColor: AppColors.surfaceContainerLowest,
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.brandTealLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.tune_rounded,
                              color: AppColors.brandTeal,
                              size: 18,
                            ),
                          ),
                          title: Text(
                            p.name,
                            style: AppTypography.bodyMd.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            p.trackStock
                                ? 'Stock actual: ${p.stock} und'
                                : 'Sin control de stock',
                            style: AppTypography.bodySm.copyWith(
                              fontSize: 11,
                              color: AppColors.slate500,
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => Navigator.of(context).pop(p),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}
