import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/shimmer_box.dart';

/// Shimmer de carga responsivo para la sección de clientes.
/// Muestra un skeleton de tabla en desktop / web y una lista de tarjetas skeleton en móvil.
class ClientsShimmer extends StatelessWidget {
  const ClientsShimmer({
    super.key,
    this.isDesktop,
    this.itemCount = 6,
  });

  /// Si es null, se determina automáticamente según el ancho disponible (>= 840 px).
  final bool? isDesktop;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    if (isDesktop != null) {
      return isDesktop!
          ? ClientsTableShimmer(rowCount: itemCount)
          : ClientsCardListShimmer(itemCount: itemCount);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 840;
        return desktop
            ? ClientsTableShimmer(rowCount: itemCount)
            : ClientsCardListShimmer(itemCount: itemCount);
      },
    );
  }
}

/// Skeleton de lista de tarjetas para móvil/tablet reducida.
class ClientsCardListShimmer extends StatelessWidget {
  const ClientsCardListShimmer({
    super.key,
    this.itemCount = 5,
  });

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, _) => const ClientsCardShimmer(),
    );
  }
}

/// Skeleton individual de tarjeta de cliente.
class ClientsCardShimmer extends StatelessWidget {
  const ClientsCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Avatar + Nombre / Documento + Badge
          Row(
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: ShimmerBox(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 130,
                      height: 16,
                      child: ShimmerBox(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                      ),
                    ),
                    SizedBox(height: 6),
                    SizedBox(
                      width: 90,
                      height: 12,
                      child: ShimmerBox(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                width: 58,
                height: 22,
                child: ShimmerBox(
                  borderRadius: BorderRadius.all(Radius.circular(11)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(
            height: 1,
            thickness: 1,
            color: AppColors.slate100,
          ),
          const SizedBox(height: 12),
          // Métricas pills
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.slate50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 50,
                        height: 10,
                        child: ShimmerBox(
                          borderRadius: BorderRadius.all(Radius.circular(3)),
                        ),
                      ),
                      SizedBox(height: 6),
                      SizedBox(
                        width: 70,
                        height: 12,
                        child: ShimmerBox(
                          borderRadius: BorderRadius.all(Radius.circular(3)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.slate50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 50,
                        height: 10,
                        child: ShimmerBox(
                          borderRadius: BorderRadius.all(Radius.circular(3)),
                        ),
                      ),
                      SizedBox(height: 6),
                      SizedBox(
                        width: 70,
                        height: 12,
                        child: ShimmerBox(
                          borderRadius: BorderRadius.all(Radius.circular(3)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Botones de acción
          Row(
            children: [
              const SizedBox(
                width: 36,
                height: 36,
                child: ShimmerBox(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: ShimmerBox(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const SizedBox(
                width: 80,
                height: 36,
                child: ShimmerBox(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Skeleton de tabla para escritorio / web.
class ClientsTableShimmer extends StatelessWidget {
  const ClientsTableShimmer({
    super.key,
    this.rowCount = 6,
  });

  final int rowCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tableWidth =
              constraints.maxWidth < 980 ? 980.0 : constraints.maxWidth;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                children: [
                  // Cabecera
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.slate50,
                      border: Border(
                        bottom: BorderSide(color: AppColors.slate200),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: _ShimmerHeaderCell('JUGADOR / DOCUMENTO'),
                        ),
                        Expanded(
                          flex: 2,
                          child: _ShimmerHeaderCell('CONTACTO / WHATSAPP'),
                        ),
                        Expanded(
                          flex: 2,
                          child: _ShimmerHeaderCell('NIVEL'),
                        ),
                        Expanded(
                          flex: 2,
                          child: _ShimmerHeaderCell('RESERVAS / ASISTENCIA'),
                        ),
                        Expanded(
                          flex: 2,
                          child: _ShimmerHeaderCell('TOTAL INVERTIDO'),
                        ),
                        Expanded(
                          flex: 2,
                          child: _ShimmerHeaderCell('ÚLTIMA VISITA'),
                        ),
                        SizedBox(
                          width: 180,
                          child: _ShimmerHeaderCell(
                            'ACCIONES',
                            alignment: Alignment.centerRight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Filas skeleton
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: rowCount,
                    separatorBuilder: (_, _) => const Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.slate100,
                    ),
                    itemBuilder: (_, _) => const _ClientTableRowShimmer(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ShimmerHeaderCell extends StatelessWidget {
  const _ShimmerHeaderCell(this.text, {this.alignment = Alignment.centerLeft});

  final String text;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: AppColors.slate400,
        ),
      ),
    );
  }
}

class _ClientTableRowShimmer extends StatelessWidget {
  const _ClientTableRowShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          // Jugador / Documento
          Expanded(
            flex: 3,
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  height: 36,
                  child: ShimmerBox(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 14,
                        child: ShimmerBox(
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                        ),
                      ),
                      SizedBox(height: 5),
                      SizedBox(
                        width: 75,
                        height: 11,
                        child: ShimmerBox(
                          borderRadius: BorderRadius.all(Radius.circular(3)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Contacto / WhatsApp
          const Expanded(
            flex: 2,
            child: Row(
              children: [
                SizedBox(
                  width: 95,
                  height: 13,
                  child: ShimmerBox(
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                  ),
                ),
                SizedBox(width: 8),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: ShimmerBox(
                    borderRadius: BorderRadius.all(Radius.circular(6)),
                  ),
                ),
              ],
            ),
          ),
          // Nivel
          const Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 64,
                height: 22,
                child: ShimmerBox(
                  borderRadius: BorderRadius.all(Radius.circular(11)),
                ),
              ),
            ),
          ),
          // Reservas / Asistencia
          const Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 30,
                  height: 14,
                  child: ShimmerBox(
                    borderRadius: BorderRadius.all(Radius.circular(3)),
                  ),
                ),
                SizedBox(height: 4),
                SizedBox(
                  width: 55,
                  height: 11,
                  child: ShimmerBox(
                    borderRadius: BorderRadius.all(Radius.circular(3)),
                  ),
                ),
              ],
            ),
          ),
          // Total Invertido
          const Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 70,
                  height: 14,
                  child: ShimmerBox(
                    borderRadius: BorderRadius.all(Radius.circular(3)),
                  ),
                ),
                SizedBox(height: 4),
                SizedBox(
                  width: 42,
                  height: 11,
                  child: ShimmerBox(
                    borderRadius: BorderRadius.all(Radius.circular(3)),
                  ),
                ),
              ],
            ),
          ),
          // Última Visita
          const Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 60,
                  height: 13,
                  child: ShimmerBox(
                    borderRadius: BorderRadius.all(Radius.circular(3)),
                  ),
                ),
                SizedBox(height: 4),
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
          // Acciones
          const SizedBox(
            width: 180,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: ShimmerBox(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
                SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  height: 32,
                  child: ShimmerBox(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
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
