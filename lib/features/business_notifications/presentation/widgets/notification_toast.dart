import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/push_message.dart';

/// Mini aviso dentro de la app cuando llega una notificación con la app
/// abierta: ícono, título y texto, con "Ver" para abrir la bandeja.
void showNotificationToast(
  BuildContext context,
  PushMessage message, {
  required VoidCallback onOpen,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  final wide = MediaQuery.sizeOf(context).width >= 600;
  final reservation = message.isNewReservation;
  final title =
      message.title ?? (reservation ? 'Nueva reserva' : 'Nueva notificación');
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        key: const Key('notification-toast'),
        behavior: SnackBarBehavior.floating,
        width: wide ? 400 : null,
        duration: const Duration(seconds: 6),
        backgroundColor: AppColors.surfaceContainerLowest,
        elevation: 6,
        padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppColors.slate200),
        ),
        content: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.brandTealLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                reservation
                    ? Icons.event_available_rounded
                    : Icons.notifications_active_rounded,
                color: AppColors.brandTeal,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelLg.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (message.body case final body? when body.isNotEmpty)
                    Text(
                      body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.slate600,
                      ),
                    ),
                ],
              ),
            ),
            TextButton(
              key: const Key('notification-toast-open'),
              onPressed: () {
                messenger.hideCurrentSnackBar();
                onOpen();
              },
              child: const Text('Ver'),
            ),
          ],
        ),
      ),
    );
}
