import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/shimmer_box.dart';

/// Shimmer de carga para la lista de clientes sugeridos / resultados en Crear Reserva.
class CustomerSearchShimmer extends StatelessWidget {
  const CustomerSearchShimmer({super.key, this.itemCount = 3});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < itemCount; i++) ...[
          if (i > 0) const SizedBox(height: 6),
          const _CustomerTileShimmer(),
        ],
      ],
    );
  }
}

class _CustomerTileShimmer extends StatelessWidget {
  const _CustomerTileShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 26,
            child: ShimmerBox(borderRadius: BorderRadius.circular(13)),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 110,
                  height: 12,
                  child: ShimmerBox(
                    borderRadius: BorderRadius.all(Radius.circular(3)),
                  ),
                ),
                SizedBox(height: 4),
                SizedBox(
                  width: 150,
                  height: 10,
                  child: ShimmerBox(
                    borderRadius: BorderRadius.all(Radius.circular(3)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer de carga para los horarios y tarjetas de canchas en Crear Reserva.
class CourtSchedulesShimmer extends StatelessWidget {
  const CourtSchedulesShimmer({super.key, this.courtCount = 2});

  final int courtCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;
        final count = courtCount.clamp(1, 4);

        if (!isWide || count == 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < count; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                const _CourtCardShimmer(),
              ],
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < count; i += 2) ...[
              if (i > 0) const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(child: _CourtCardShimmer()),
                  const SizedBox(width: 10),
                  Expanded(
                    child: i + 1 < count
                        ? const _CourtCardShimmer()
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

class _CourtCardShimmer extends StatelessWidget {
  const _CourtCardShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header de la Cancha: foto, nombre, subtítulo y badge de libres
          Row(
            children: [
              SizedBox.square(
                dimension: 34,
                child: ShimmerBox(borderRadius: BorderRadius.circular(10)),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 100,
                      height: 13,
                      child: ShimmerBox(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                      ),
                    ),
                    SizedBox(height: 4),
                    SizedBox(
                      width: 140,
                      height: 10,
                      child: ShimmerBox(
                        borderRadius: BorderRadius.all(Radius.circular(3)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                width: 58,
                height: 18,
                child: ShimmerBox(
                  borderRadius: BorderRadius.all(Radius.circular(9)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Grilla de slots
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final columns = (width / 92).floor().clamp(3, 6);
              final itemWidth = (width - (columns - 1) * 6) / columns;

              return Wrap(
                spacing: 6,
                runSpacing: 6,
                children: List.generate(
                  columns * 2,
                  (_) => SizedBox(
                    width: itemWidth,
                    height: 44,
                    child: const _SlotChipShimmer(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SlotChipShimmer extends StatelessWidget {
  const _SlotChipShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.slate200),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 42,
              height: 11,
              child: ShimmerBox(
                borderRadius: BorderRadius.all(Radius.circular(3)),
              ),
            ),
            SizedBox(height: 3),
            SizedBox(
              width: 34,
              height: 9,
              child: ShimmerBox(
                borderRadius: BorderRadius.all(Radius.circular(2)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
