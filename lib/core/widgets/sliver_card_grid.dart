import 'package:flutter/material.dart';

/// Medidas de un listado de tarjetas según el ancho disponible: en móvil una
/// columna; en tablet/web las tarjetas se reparten en 2 o 3 columnas.
class CardGridLayout {
  const CardGridLayout({required this.columns, required this.gutter});

  factory CardGridLayout.of(double width) => switch (width) {
    >= 1200 => const CardGridLayout(columns: 3, gutter: 24),
    >= 760 => const CardGridLayout(columns: 2, gutter: 24),
    _ => const CardGridLayout(columns: 1, gutter: 12),
  };

  final int columns;

  /// Margen lateral de secciones y tarjetas.
  final double gutter;

  bool get isWide => columns > 1;

  /// Relleno a sumar a un widget que ya trae [existing] px laterales propios
  /// para alinearlo con [gutter].
  EdgeInsets paddingBeyond(double existing) =>
      EdgeInsets.symmetric(horizontal: gutter - existing);
}

/// Tarjetas en filas de [columns]; arma solo las filas visibles.
class SliverCardGrid extends StatelessWidget {
  const SliverCardGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.columns,
  });

  static const _spacing = 12.0;

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final rows = (itemCount / columns).ceil();
    return SliverList.separated(
      itemCount: rows,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, row) {
        if (columns == 1) return itemBuilder(context, row);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var col = 0; col < columns; col++) ...[
              if (col > 0) const SizedBox(width: _spacing),
              Expanded(
                child: row * columns + col < itemCount
                    ? itemBuilder(context, row * columns + col)
                    : const SizedBox.shrink(),
              ),
            ],
          ],
        );
      },
    );
  }
}
