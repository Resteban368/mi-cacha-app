import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/client_profile.dart';

/// Modal / Side Drawer de detalles del cliente para Web y Móvil.
Future<void> showClientDetailSheet(
  BuildContext context, {
  required ClientProfile client,
  required VoidCallback onNewReservation,
  required VoidCallback onOpenHistory,
  required VoidCallback onWhatsApp,
  required VoidCallback onEdit,
}) {
  final isWide = MediaQuery.sizeOf(context).width >= 800;

  if (isWide) {
    return showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        alignment: Alignment.centerRight,
        insetPadding: const EdgeInsets.only(left: 100),
        child: Container(
          width: 520,
          height: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F000000),
                blurRadius: 24,
                offset: Offset(-4, 0),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: ClientDetailContent(
              client: client,
              onNewReservation: () {
                Navigator.of(context).pop();
                onNewReservation();
              },
              onOpenHistory: () {
                Navigator.of(context).pop();
                onOpenHistory();
              },
              onWhatsApp: onWhatsApp,
              onEdit: () {
                Navigator.of(context).pop();
                onEdit();
              },
              onClose: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
    );
  }

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => FractionallySizedBox(
      heightFactor: 0.88,
      child: ClientDetailContent(
        client: client,
        onNewReservation: () {
          Navigator.of(context).pop();
          onNewReservation();
        },
        onOpenHistory: () {
          Navigator.of(context).pop();
          onOpenHistory();
        },
        onWhatsApp: onWhatsApp,
        onEdit: () {
          Navigator.of(context).pop();
          onEdit();
        },
        onClose: () => Navigator.of(context).pop(),
      ),
    ),
  );
}

class ClientDetailContent extends StatelessWidget {
  const ClientDetailContent({
    super.key,
    required this.client,
    required this.onNewReservation,
    required this.onOpenHistory,
    required this.onWhatsApp,
    required this.onEdit,
    required this.onClose,
  });

  final ClientProfile client;
  final VoidCallback onNewReservation;
  final VoidCallback onOpenHistory;
  final VoidCallback onWhatsApp;
  final VoidCallback onEdit;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
          decoration: BoxDecoration(
            color: AppColors.slate50,
            border: Border(bottom: BorderSide(color: AppColors.slate200)),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: client.isVip
                        ? [const Color(0xFFF59E0B), const Color(0xFFD97706)]
                        : [AppColors.brandTeal, AppColors.brandTealDeep],
                  ),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  client.initials,
                  style: AppTypography.headlineSm.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.name,
                      style: AppTypography.headlineSm.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      client.documentId.isNotEmpty
                          ? 'C.C. ${client.documentId}'
                          : 'Sin documento',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.slate500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Editar',
                icon: Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: AppColors.slate600,
                ),
                onPressed: onEdit,
              ),
              IconButton(
                tooltip: 'Cerrar',
                icon: Icon(
                  Icons.close_rounded,
                  size: 22,
                  color: AppColors.slate600,
                ),
                onPressed: onClose,
              ),
            ],
          ),
        ),

        // Body
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Contact & Fast Communication Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onWhatsApp,
                      icon: Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: AppColors.whatsappDark,
                        size: 18,
                      ),
                      label: Text(
                        client.phone.isNotEmpty ? client.phone : 'Sin teléfono',
                        style: TextStyle(
                          color: AppColors.whatsappDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.whatsapp),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  if (client.email != null && client.email!.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    IconButton(
                      tooltip: client.email,
                      icon: Icon(
                        Icons.email_outlined,
                        color: AppColors.slate600,
                      ),
                      onPressed: () {},
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 20),

              // KPI Stats Grid
              Text(
                'MÉTRICAS Y ACTIVIDAD',
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.slate500,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _DetailStatBox(
                      title: 'Reservas totales',
                      value: '${client.totalBookings}',
                      subtitle: '${client.completedBookings} completadas',
                      icon: Icons.sports_soccer_rounded,
                      color: AppColors.brandTeal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DetailStatBox(
                      title: 'Asistencia',
                      value: '${client.attendanceRate.toStringAsFixed(0)}%',
                      subtitle: '${client.noShows} inasistencias',
                      icon: Icons.check_circle_outline_rounded,
                      color: client.attendanceRate >= 80
                          ? AppColors.brandTeal
                          : AppColors.statusDeposit,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _DetailStatBox(
                      title: 'Total Invertido',
                      value: AppFormatters.cop(client.totalSpentCop),
                      subtitle: 'En tus canchas',
                      icon: Icons.payments_outlined,
                      color: AppColors.slate900,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DetailStatBox(
                      title: 'Saldo pendiente',
                      value: AppFormatters.cop(client.pendingDebtCop),
                      subtitle: client.hasDebt ? 'Cobro pendiente' : 'Al día',
                      icon: Icons.pending_actions_rounded,
                      color: client.hasDebt
                          ? AppColors.statusDue
                          : AppColors.brandTeal,
                      isAlert: client.hasDebt,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Preferences & Tags
              Text(
                'PREFERENCIAS Y NOTAS',
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.slate500,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.sports_rounded,
                          size: 18,
                          color: AppColors.brandTeal,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Deporte habitual: ${client.preferredSport}',
                          style: AppTypography.bodyMd.copyWith(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (client.lastCourtName != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.stadium_outlined,
                            size: 18,
                            color: AppColors.brandTeal,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Cancha frecuente: ${client.lastCourtName}',
                            style: AppTypography.bodyMd.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (client.notes.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Divider(height: 1, color: AppColors.slate200),
                      const SizedBox(height: 12),
                      Text(
                        'Notas operativas:',
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.slate600,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        client.notes,
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.slate700,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        // Sticky Bottom Footer Actions
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            border: Border(top: BorderSide(color: AppColors.slate200)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onOpenHistory,
                  icon: const Icon(Icons.history_rounded, size: 18),
                  label: const Text('Ver Historial'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onNewReservation,
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                  label: const Text('Crear Reserva'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brandTeal,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailStatBox extends StatelessWidget {
  const _DetailStatBox({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.isAlert = false,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isAlert;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isAlert ? AppColors.dangerTint : AppColors.slate50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAlert
              ? AppColors.statusDue.withValues(alpha: 0.3)
              : AppColors.slate200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.slate500,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.headlineSm.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTypography.bodySm.copyWith(
              color: isAlert ? AppColors.statusDue : AppColors.slate500,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
