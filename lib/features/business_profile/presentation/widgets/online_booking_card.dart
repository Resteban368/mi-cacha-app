import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/contact_launcher.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../domain/entities/online_booking_link.dart';
import '../bloc/business_profile_bloc.dart';

/// Link de reservas en línea que el negocio comparte con sus clientes:
/// copiar, enviar por WhatsApp o abrirlo, y si hoy recibe reservas.
class OnlineBookingCard extends StatelessWidget {
  const OnlineBookingCard({
    super.key,
    required this.status,
    required this.onRetry,
    this.link,
    this.businessName,
    this.opener,
  });

  final OnlineBookingStatus status;
  final OnlineBookingLink? link;
  final VoidCallback onRetry;

  /// Para el texto que se comparte por WhatsApp.
  final String? businessName;

  /// Solo para tests: abre los enlaces en lugar de url_launcher.
  final UrlOpener? opener;

  Future<void> _copy(BuildContext context, String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Link copiado')));
  }

  Future<void> _open(BuildContext context, Uri uri) async {
    final opener = this.opener;
    final opened = opener == null
        ? await ContactLauncher.open(uri)
        : await ContactLauncher.open(uri, opener: opener);
    if (opened || !context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('No pudimos abrir el enlace.'),
          backgroundColor: AppColors.statusDue,
        ),
      );
  }

  /// WhatsApp sin número: el negocio elige a quién enviarlo.
  Uri _whatsAppShare(String url) {
    final name = businessName?.trim();
    final text = name == null || name.isEmpty
        ? 'Reserva tu cancha aquí: $url'
        : 'Reserva tu cancha en $name aquí: $url';
    return Uri.https('wa.me', '/', {'text': text});
  }

  @override
  Widget build(BuildContext context) {
    final link = this.link;
    return Container(
      key: const Key('online-booking-card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.brandTeal.withValues(alpha: 0.25)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.link_rounded, size: 20, color: AppColors.brandTeal),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Link de reservas en línea',
                  style: AppTypography.labelLg.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (link != null) _StatusChip(link: link),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Compártelo con tus clientes para que reserven solos.',
            style: AppTypography.bodySm.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          switch ((status, link)) {
            (OnlineBookingStatus.failure, _) => _LoadError(onRetry: onRetry),
            (_, final link?) => _LinkBody(
              link: link,
              onCopy: () => _copy(context, link.url),
              onWhatsApp: () => _open(context, _whatsAppShare(link.url)),
              onOpen: () => _open(context, Uri.parse(link.url)),
            ),
            _ => const SizedBox(
              key: Key('online-booking-loading'),
              height: 44,
              child: ShimmerBox(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
          },
        ],
      ),
    );
  }
}

class _LinkBody extends StatelessWidget {
  const _LinkBody({
    required this.link,
    required this.onCopy,
    required this.onWhatsApp,
    required this.onOpen,
  });

  final OnlineBookingLink link;
  final VoidCallback onCopy;
  final VoidCallback onWhatsApp;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final warning = link.isLive
        ? null
        : link.unavailableReason ??
              (link.enabled
                  ? 'Por ahora el link no recibe reservas.'
                  : 'El link está desactivado: tus clientes no pueden '
                        'reservar con él.');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SelectableText(
            link.url,
            key: const Key('online-booking-url'),
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.brandTealDeep,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (warning != null) ...[
          const SizedBox(height: 10),
          Row(
            key: const Key('online-booking-warning'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: AppColors.onErrorContainer,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  warning,
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              key: const Key('online-booking-copy'),
              onPressed: onCopy,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandTeal,
                foregroundColor: AppColors.onPrimary,
              ),
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('Copiar'),
            ),
            OutlinedButton.icon(
              key: const Key('online-booking-whatsapp'),
              onPressed: onWhatsApp,
              icon: const Icon(Icons.chat_outlined, size: 18),
              label: const Text('WhatsApp'),
            ),
            TextButton.icon(
              key: const Key('online-booking-open'),
              onPressed: onOpen,
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: const Text('Abrir'),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.link});

  final OnlineBookingLink link;

  @override
  Widget build(BuildContext context) {
    final (label, foreground, background) = switch (link) {
      OnlineBookingLink(isLive: true) => (
        'Activo',
        AppColors.brandTealDeep,
        AppColors.brandTealLight,
      ),
      OnlineBookingLink(enabled: false) => (
        'Desactivado',
        AppColors.onSurfaceVariant,
        AppColors.surfaceContainerHigh,
      ),
      _ => (
        'Sin reservas',
        AppColors.onErrorContainer,
        AppColors.errorContainer,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTypography.labelSm.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'No pudimos cargar tu link de reservas.',
            style: AppTypography.bodySm.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
        TextButton(
          key: const Key('online-booking-retry'),
          onPressed: onRetry,
          child: const Text('Reintentar'),
        ),
      ],
    );
  }
}
