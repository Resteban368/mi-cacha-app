import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/contact_launcher.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/reservation.dart';

void _notify(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Abre el chat de WhatsApp con el cliente, con un saludo sobre su reserva.
Future<void> openReservationChat(
  BuildContext context,
  Reservation reservation,
) async {
  final name = reservation.customerName.split(' ').first;
  final uri = ContactLauncher.whatsAppChat(
    reservation.phone,
    text:
        'Hola $name, te escribimos de Mi Cancha sobre tu reserva de '
        '${reservation.courtsLabel} el ${AppFormatters.shortDate(reservation.start)} '
        'de ${AppFormatters.timeRange(reservation.start, reservation.end)}.',
  );
  if (uri == null) {
    _notify(context, 'Esta reserva no tiene un teléfono válido.');
    return;
  }
  if (!await ContactLauncher.open(uri) && context.mounted) {
    _notify(context, 'No pudimos abrir WhatsApp.');
  }
}

/// Opciones para llamar al cliente: marcador, llamada por WhatsApp o copiar.
Future<void> showCallOptions(BuildContext context, Reservation reservation) {
  if (ContactLauncher.normalize(reservation.phone) == null) {
    _notify(context, 'Esta reserva no tiene un teléfono válido.');
    return Future.value();
  }
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: AppColors.surfaceContainerLowest,
    constraints: const BoxConstraints(maxWidth: 480),
    builder: (_) => _CallOptions(reservation: reservation),
  );
}

class _CallOptions extends StatelessWidget {
  const _CallOptions({required this.reservation});

  final Reservation reservation;

  /// Cierra la hoja y deja que la acción use el contexto de la pantalla.
  Future<void> _then(
    BuildContext context,
    Future<void> Function(BuildContext screen) action,
  ) async {
    final screen = Navigator.of(context).context;
    Navigator.of(context).pop();
    await action(screen);
  }

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    final name = r.customerName.split(' ').first;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Llamar a $name',
              style: AppTypography.headlineSm.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              ContactLauncher.display(r.phone),
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            _Option(
              icon: Icons.call_outlined,
              color: AppColors.primary,
              title: 'Llamada normal',
              subtitle: 'Abre el marcador del teléfono',
              onTap: () => _then(context, (screen) async {
                final uri = ContactLauncher.dial(r.phone);
                if (uri == null || !await ContactLauncher.open(uri)) {
                  if (screen.mounted) {
                    _notify(screen, 'No pudimos abrir el marcador.');
                  }
                }
              }),
            ),
            _Option(
              icon: Icons.chat_outlined,
              color: AppColors.whatsappDark,
              title: 'Llamar por WhatsApp',
              subtitle: 'Abre el chat: toca el ícono de llamada',
              onTap: () => _then(context, (screen) async {
                final uri = ContactLauncher.whatsAppChat(r.phone);
                if (uri == null || !await ContactLauncher.open(uri)) {
                  if (screen.mounted) {
                    _notify(screen, 'No pudimos abrir WhatsApp.');
                  }
                }
              }),
            ),
            _Option(
              icon: Icons.copy_rounded,
              color: AppColors.slate600,
              title: 'Copiar número',
              subtitle: ContactLauncher.display(r.phone),
              onTap: () => _then(context, (screen) async {
                await Clipboard.setData(
                  ClipboardData(text: '+${ContactLauncher.normalize(r.phone)}'),
                );
                if (screen.mounted) _notify(screen, 'Número copiado.');
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: AppTypography.bodyMd.copyWith(
          color: AppColors.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
      ),
    );
  }
}
