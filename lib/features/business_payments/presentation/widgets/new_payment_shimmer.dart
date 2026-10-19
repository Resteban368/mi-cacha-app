import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/shimmer_box.dart';

/// Shimmer de carga para la lista de clientes sugeridos o encontrados.
class NewPaymentCustomerListShimmer extends StatelessWidget {
  const NewPaymentCustomerListShimmer({super.key, this.itemCount = 3});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, _) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.slate200.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: ShimmerBox(borderRadius: BorderRadius.circular(18)),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 120,
                    height: 14,
                    child: ShimmerBox(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                  ),
                  SizedBox(height: 6),
                  SizedBox(
                    width: 80,
                    height: 11,
                    child: ShimmerBox(
                      borderRadius: BorderRadius.all(Radius.circular(3)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              width: 50,
              height: 18,
              child: ShimmerBox(
                borderRadius: BorderRadius.all(Radius.circular(9)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer de carga para las reservas asociadas a un cliente o búsqueda de reservas.
class NewPaymentReservationListShimmer extends StatelessWidget {
  const NewPaymentReservationListShimmer({super.key, this.itemCount = 2});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, _) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.slate200.withValues(alpha: 0.6)),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 130,
                  height: 14,
                  child: ShimmerBox(
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                  ),
                ),
                SizedBox(
                  width: 60,
                  height: 18,
                  child: ShimmerBox(
                    borderRadius: BorderRadius.all(Radius.circular(9)),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 90,
                  height: 12,
                  child: ShimmerBox(
                    borderRadius: BorderRadius.all(Radius.circular(3)),
                  ),
                ),
                Spacer(),
                SizedBox(
                  width: 75,
                  height: 14,
                  child: ShimmerBox(
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
