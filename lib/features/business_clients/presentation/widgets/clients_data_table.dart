import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/client_profile.dart';

/// Tabla web/escritorio con diseño operacional para la gestión de clientes.
class ClientsDataTable extends StatelessWidget {
  const ClientsDataTable({
    super.key,
    required this.clients,
    required this.onClientTap,
    required this.onWhatsAppTap,
    required this.onNewReservationTap,
    required this.onHistoryTap,
  });

  final List<ClientProfile> clients;
  final ValueChanged<ClientProfile> onClientTap;
  final ValueChanged<ClientProfile> onWhatsAppTap;
  final ValueChanged<ClientProfile> onNewReservationTap;
  final ValueChanged<ClientProfile> onHistoryTap;

  @override
  Widget build(BuildContext context) {
    if (clients.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(48),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppColors.brandTealLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_search_rounded,
                size: 28,
                color: AppColors.brandTeal,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron clientes',
              style: AppTypography.headlineSm.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Prueba ajustando los filtros o el término de búsqueda.',
              style: AppTypography.bodyMd.copyWith(color: AppColors.slate500),
            ),
          ],
        ),
      );
    }

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
          final tableWidth = constraints.maxWidth < 980
              ? 980.0
              : constraints.maxWidth;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                children: [
                  // Table Header
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
                          child: _HeaderCell('JUGADOR / DOCUMENTO'),
                        ),
                        Expanded(
                          flex: 2,
                          child: _HeaderCell('CONTACTO / WHATSAPP'),
                        ),
                        Expanded(flex: 2, child: _HeaderCell('NIVEL')),
                        Expanded(
                          flex: 2,
                          child: _HeaderCell('RESERVAS / ASISTENCIA'),
                        ),
                        Expanded(
                          flex: 2,
                          child: _HeaderCell('TOTAL INVERTIDO'),
                        ),
                        Expanded(flex: 2, child: _HeaderCell('ÚLTIMA VISITA')),
                        SizedBox(
                          width: 180,
                          child: _HeaderCell(
                            'ACCIONES',
                            alignment: Alignment.centerRight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Rows
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: clients.length,
                    separatorBuilder: (_, _) => const Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.slate100,
                    ),
                    itemBuilder: (context, i) {
                      final client = clients[i];
                      return _ClientTableRow(
                        client: client,
                        onTap: () => onClientTap(client),
                        onWhatsAppTap: () => onWhatsAppTap(client),
                        onNewReservationTap: () => onNewReservationTap(client),
                        onHistoryTap: () => onHistoryTap(client),
                      );
                    },
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

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.text, {this.alignment = Alignment.centerLeft});

  final String text;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Text(
        text,
        style: AppTypography.labelSm.copyWith(
          color: AppColors.slate600,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ClientTableRow extends StatefulWidget {
  const _ClientTableRow({
    required this.client,
    required this.onTap,
    required this.onWhatsAppTap,
    required this.onNewReservationTap,
    required this.onHistoryTap,
  });

  final ClientProfile client;
  final VoidCallback onTap;
  final VoidCallback onWhatsAppTap;
  final VoidCallback onNewReservationTap;
  final VoidCallback onHistoryTap;

  @override
  State<_ClientTableRow> createState() => _ClientTableRowState();
}

class _ClientTableRowState extends State<_ClientTableRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final client = widget.client;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: widget.onTap,
        hoverColor: AppColors.surfaceTealSubtle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          color: _isHovered ? AppColors.surfaceTealSubtle : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              // JUGADOR
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: client.isVip
                              ? [
                                  const Color(0xFFF59E0B),
                                  const Color(0xFFD97706),
                                ]
                              : [AppColors.brandTeal, AppColors.brandTealDeep],
                        ),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        client.initials,
                        style: AppTypography.labelMd.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            client.name,
                            style: AppTypography.bodyMd.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            client.documentId.isNotEmpty
                                ? 'C.C. ${client.documentId}'
                                : 'Sin cédula registrada',
                            style: AppTypography.bodySm.copyWith(
                              color: AppColors.slate500,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // CONTACTO / WHATSAPP
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        client.phone.isNotEmpty ? client.phone : '—',
                        style: AppTypography.bodyMd.copyWith(
                          color: AppColors.slate700,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (client.phone.isNotEmpty)
                      IconButton(
                        tooltip: 'Chatear por WhatsApp',
                        icon: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 18,
                          color: AppColors.whatsappDark,
                        ),
                        splashRadius: 18,
                        onPressed: widget.onWhatsAppTap,
                      ),
                  ],
                ),
              ),

              // NIVEL
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _TierBadge(tier: client.tier),
                ),
              ),

              // RESERVAS / ASISTENCIA
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${client.totalBookings} reservas',
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: client.attendanceRate >= 80
                                ? AppColors.brandTeal
                                : AppColors.statusDeposit,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${client.attendanceRate.toStringAsFixed(0)}% asistencia',
                            style: AppTypography.bodySm.copyWith(
                              color: AppColors.slate500,
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // TOTAL INVERTIDO
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppFormatters.cop(client.totalSpentCop),
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (client.hasDebt) ...[
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Debe ${AppFormatters.cop(client.pendingDebtCop)}',
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.statusDue,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // ÚLTIMA VISITA
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.lastBookingDate != null
                          ? '${client.lastBookingDate!.day}/${client.lastBookingDate!.month}/${client.lastBookingDate!.year}'
                          : 'Nunca',
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.slate700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (client.lastCourtName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        client.lastCourtName!,
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.slate500,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // ACCIONES
              SizedBox(
                width: 180,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      tooltip: 'Ver historial de reservas',
                      icon: const Icon(
                        Icons.history_rounded,
                        size: 20,
                        color: AppColors.slate600,
                      ),
                      onPressed: widget.onHistoryTap,
                    ),
                    const SizedBox(width: 4),
                    FilledButton(
                      onPressed: widget.onNewReservationTap,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brandTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Reservar',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TierBadge extends StatelessWidget {
  const _TierBadge({required this.tier});

  final ClientTier tier;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;

    switch (tier) {
      case ClientTier.vip:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFF92400E);
        icon = Icons.star_rounded;
      case ClientTier.frecuente:
        bg = AppColors.brandTealLight;
        fg = AppColors.brandTealDeep;
        icon = Icons.verified_rounded;
      case ClientTier.recurrente:
        bg = const Color(0xFFE0F2FE);
        fg = const Color(0xFF0369A1);
        icon = Icons.repeat_rounded;
      case ClientTier.nuevo:
        bg = AppColors.slate100;
        fg = AppColors.slate700;
        icon = Icons.fiber_new_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              tier.label,
              style: AppTypography.labelSm.copyWith(
                color: fg,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
