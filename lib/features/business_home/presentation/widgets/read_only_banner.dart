import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/session/write_access.dart';
import '../../../../core/theme/app_typography.dart';

/// Lee si el negocio puede escribir (plan activo) al abrir el panel y
/// actualiza [WriteAccess]. Si falla la consulta no cambia nada: la API
/// igual responde 403 y el interceptor activa el modo solo lectura.
class WriteAccessRefresher extends StatefulWidget {
  const WriteAccessRefresher({
    super.key,
    required this.writeAccess,
    required this.loadCanWrite,
    required this.child,
  });

  final WriteAccess writeAccess;

  /// `true` si el negocio tiene un plan activo.
  final Future<bool> Function() loadCanWrite;
  final Widget child;

  @override
  State<WriteAccessRefresher> createState() => _WriteAccessRefresherState();
}

class _WriteAccessRefresherState extends State<WriteAccessRefresher> {
  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final canWrite = await widget.loadCanWrite();
      widget.writeAccess.update(canWrite: canWrite);
    } catch (_) {
      // Sin conexión u otro error: se mantiene el último valor conocido.
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Franja inferior del panel en modo solo lectura.
class ReadOnlyBanner extends StatelessWidget {
  const ReadOnlyBanner({super.key});

  static const _background = Color(0xFFFEF3C7);
  static const _foreground = Color(0xFF92400E);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _background,
      child: SafeArea(
        top: false,
        child: Semantics(
          liveRegion: true,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Row(
              children: [
                const Icon(Icons.lock_outline, size: 20, color: _foreground),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tu plan no está activo: solo puedes consultar '
                    'información.',
                    style: AppTypography.bodySm.copyWith(
                      color: _foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => context.go(AppRoutes.businessSettings),
                  style: TextButton.styleFrom(foregroundColor: _foreground),
                  child: const Text('Ver mi plan'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Mensaje para pantallas de escritura abiertas en modo solo lectura.
class ReadOnlyMessage extends StatelessWidget {
  const ReadOnlyMessage({super.key, required this.action});

  /// Qué no se puede hacer, p. ej. "crear reservas".
  final String action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 48,
                color: ReadOnlyBanner._foreground,
              ),
              const SizedBox(height: 12),
              Text(
                'Modo solo lectura',
                style: AppTypography.headlineSm.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tu plan no está activo, así que no puedes $action. '
                'Actívalo para volver a hacerlo.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMd,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go(AppRoutes.businessSettings),
                child: const Text('Ver mi plan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
