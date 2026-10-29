import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../domain/entities/app_notification.dart';
import '../bloc/business_notifications_cubit.dart';
import '../bloc/notifications_inbox_cubit.dart';
import 'push_permission_banner.dart';

/// Abre la bandeja: hoja inferior en el celular, panel en pantallas anchas.
Future<void> showNotificationsInbox(
  BuildContext context,
  NotificationsInboxCubit cubit, {
  BusinessNotificationsCubit? push,
}) {
  cubit.load();
  Widget body(BuildContext _) => BlocProvider.value(
    value: cubit,
    child: push == null
        ? const NotificationsInboxView()
        : BlocProvider.value(
            value: push,
            child: const NotificationsInboxView(showPushBanner: true),
          ),
  );

  if (MediaQuery.sizeOf(context).width >= 600) {
    return showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        alignment: Alignment.topRight,
        insetPadding: const EdgeInsets.fromLTRB(24, 72, 24, 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(width: 420, height: 580, child: body(context)),
      ),
    );
  }
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.surfaceContainerLowest,
    builder: (context) => SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.8,
      child: body(context),
    ),
  );
}

/// Listado de notificaciones con "Marcar todas como leídas".
class NotificationsInboxView extends StatelessWidget {
  const NotificationsInboxView({super.key, this.showPushBanner = false});

  /// Mostrar el aviso para activar las notificaciones del navegador (necesita
  /// un [BusinessNotificationsCubit] arriba).
  final bool showPushBanner;

  /// Tocar una notificación solo muestra su detalle (no navega).
  void _open(BuildContext context, AppNotification notification) {
    context.read<NotificationsInboxCubit>().markRead(notification);
    showNotificationDetail(context, notification);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationsInboxCubit, NotificationsInboxState>(
      builder: (context, state) {
        final cubit = context.read<NotificationsInboxCubit>();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Notificaciones',
                      style: AppTypography.headlineSm.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    key: const Key('inbox-read-all'),
                    onPressed: state.unread > 0 ? cubit.markAllRead : null,
                    child: const Text('Marcar todas como leídas'),
                  ),
                ],
              ),
            ),
            if (showPushBanner) const PushPermissionBanner(),
            Divider(height: 1, color: AppColors.slate200),
            Expanded(
              child: switch (state.status) {
                InboxStatus.initial || InboxStatus.loading => const Center(
                  child: CircularProgressIndicator(),
                ),
                InboxStatus.failure => _Message(
                  icon: Icons.cloud_off_outlined,
                  text: 'No pudimos cargar tus notificaciones.',
                  action: 'Reintentar',
                  onAction: cubit.load,
                ),
                InboxStatus.ready when state.items.isEmpty => const _Message(
                  icon: Icons.notifications_none_rounded,
                  text: 'No tienes notificaciones.',
                ),
                InboxStatus.ready => NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n.metrics.extentAfter < 200) cubit.loadMore();
                    return false;
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: state.items.length + (state.loadingMore ? 1 : 0),
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, indent: 72),
                    itemBuilder: (context, i) {
                      if (i >= state.items.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }
                      final n = state.items[i];
                      return NotificationTile(
                        key: ValueKey(n.id),
                        notification: n,
                        now: DateTime.now(),
                        onTap: () => _open(context, n),
                      );
                    },
                  ),
                ),
              },
            ),
          ],
        );
      },
    );
  }
}

/// Detalle de una notificación: tipo, título, texto completo y fecha.
Future<void> showNotificationDetail(
  BuildContext context,
  AppNotification notification,
) {
  final n = notification;
  final (icon, color, kind) = _kindStyle(n.kind);
  return showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      key: const Key('notification-detail'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        // Con imagen y texto largo, el detalle se desplaza en pantallas bajas.
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                n.title,
                textAlign: TextAlign.center,
                style: AppTypography.headlineSm.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$kind · ${AppFormatters.longDate(n.createdAt)}, '
                '${AppFormatters.time(n.createdAt)}',
                textAlign: TextAlign.center,
                style: AppTypography.labelSm.copyWith(color: AppColors.outline),
              ),
              if (n.imageUrl case final image?) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  key: const Key('notification-detail-image'),
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: AppNetworkImage(image, cacheWidth: 900),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                n.body,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

(IconData, Color, String) _kindStyle(NotificationKind kind) => switch (kind) {
  NotificationKind.newReservation => (
    Icons.event_available_rounded,
    AppColors.brandTeal,
    'Reserva nueva',
  ),
  NotificationKind.adminBroadcast => (
    Icons.campaign_outlined,
    AppColors.statusDeposit,
    'Aviso de Mi Cancha',
  ),
  NotificationKind.other => (
    Icons.notifications_none_rounded,
    AppColors.onSurfaceVariant,
    'Notificación',
  ),
};

class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.notification,
    required this.now,
    required this.onTap,
  });

  final AppNotification notification;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final (icon, color, _) = _kindStyle(n.kind);
    return Material(
      color: n.isUnread
          ? AppColors.brandTealLight.withValues(alpha: 0.35)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            n.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelLg.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: n.isUnread
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppFormatters.relative(n.createdAt, now),
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.outline,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      n.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (n.imageUrl case final image?) ...[
                const SizedBox(width: 8),
                ClipRRect(
                  key: const Key('inbox-thumbnail'),
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox.square(
                    dimension: 48,
                    child: AppNetworkImage(image, cacheWidth: 144),
                  ),
                ),
              ],
              if (n.isUnread) ...[
                const SizedBox(width: 8),
                Container(
                  key: const Key('inbox-unread-dot'),
                  margin: const EdgeInsets.only(top: 6),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.brandTeal,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.text,
    this.action,
    this.onAction,
  });

  final IconData icon;
  final String text;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: AppColors.outline),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: 12),
            FilledButton(onPressed: onAction, child: Text(action!)),
          ],
        ],
      ),
    ),
  );
}
