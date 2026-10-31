import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/media/photo_picker.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/session/write_access.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_add_fab.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../domain/entities/coupon.dart';
import '../bloc/coupons_cubit.dart';
import '../widgets/coupon_form_dialog.dart';
import '../widgets/coupon_labels.dart';

/// Cupones del negocio. Se desactivan con el interruptor; borrar solo se puede
/// si aún no hay bonos ganados ni redimidos (lo valida la API).
class CouponsPage extends StatelessWidget {
  const CouponsPage({super.key});

  Future<void> _edit(BuildContext context, [Coupon? coupon]) async {
    if (!ensureCanWrite(context)) return;
    final cubit = context.read<CouponsCubit>();
    String? warning;
    final saved = await showCouponFormDialog(
      context,
      coupon: coupon,
      photoPicker: sl<PhotoPicker>(),
      onWarning: (message) => warning = message,
      onSave: (draft, image, {required removeImage}) =>
          cubit.save(draft, image: image, removeImage: removeImage),
    );
    if (!saved || !context.mounted) return;
    if (warning case final message?) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.statusDue,
          ),
        );
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            coupon == null ? 'Cupón creado.' : 'Cupón actualizado.',
          ),
        ),
      );
  }

  Future<void> _toggle(BuildContext context, Coupon coupon, bool active) async {
    if (!ensureCanWrite(context)) return;
    final messenger = ScaffoldMessenger.of(context);
    final error = await context.read<CouponsCubit>().setActive(coupon, active);
    if (error == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.statusDue),
      );
  }

  Future<void> _delete(BuildContext context, Coupon coupon) async {
    if (!ensureCanWrite(context)) return;
    final cubit = context.read<CouponsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Borrar cupón?'),
        content: Text(
          'Se borrará «${coupon.name}» y el avance de tus clientes en él. '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('coupon-delete-confirm'),
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.statusDue,
              foregroundColor: AppColors.onError,
            ),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final error = await cubit.delete(coupon);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        error == null
            ? const SnackBar(content: Text('Cupón borrado.'))
            : SnackBar(
                content: Text(error),
                backgroundColor: AppColors.statusDue,
              ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final canWrite = WriteAccessScope.canWrite(context);
    return Stack(
      children: [
        Column(
          children: [
            const AppTopBar(
              title: 'Cupones',
              subtitle: 'Premia a quienes más reservan',
              icon: Icons.confirmation_number_rounded,
            ),
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: BlocBuilder<CouponsCubit, CouponsState>(
                  builder: (context, state) => switch (state.load) {
                    CouponsLoad.loading => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    CouponsLoad.failure => Center(
                      child: TextButton.icon(
                        onPressed: () => context.read<CouponsCubit>().load(),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text(
                          'No pudimos cargar los cupones. Reintentar',
                        ),
                      ),
                    ),
                    CouponsLoad.ready when state.coupons.isEmpty => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'Crea tu primer cupón: por ejemplo, cada 10 reservas '
                          'jugadas y pagadas, una cancha gratis.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMd.copyWith(
                            color: AppColors.slate600,
                          ),
                        ),
                      ),
                    ),
                    CouponsLoad.ready => ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        bottomInset + 96,
                      ),
                      itemCount: state.coupons.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final coupon = state.coupons[i];
                        return Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 760),
                            child: _CouponTile(
                              coupon: coupon,
                              onOpen: () => context.push(
                                AppRoutes.businessCouponDetailPath(coupon.id),
                              ),
                              onEdit: canWrite
                                  ? () => _edit(context, coupon)
                                  : null,
                              onDelete: canWrite
                                  ? () => _delete(context, coupon)
                                  : null,
                              onToggle: canWrite && !coupon.isClosed
                                  ? (active) => _toggle(context, coupon, active)
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  },
                ),
              ),
            ),
          ],
        ),
        if (canWrite)
          Positioned(
            right: 16,
            bottom: bottomInset + 16,
            child: AppAddFab(
              tooltip: 'Nuevo cupón',
              onPressed: () => _edit(context),
            ),
          ),
      ],
    );
  }
}

class _CouponTile extends StatelessWidget {
  const _CouponTile({
    required this.coupon,
    required this.onOpen,
    this.onEdit,
    this.onDelete,
    this.onToggle,
  });

  final Coupon coupon;
  final VoidCallback onOpen;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final ValueChanged<bool>? onToggle;

  @override
  Widget build(BuildContext context) {
    final open = coupon.state == CouponState.active;
    return Material(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.slate200),
          ),
          child: Row(
            children: [
              if (coupon.imageUrl case final url?)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox.square(
                    dimension: 44,
                    child: AppNetworkImage(url, cacheWidth: 132),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: open ? AppColors.brandTealLight : AppColors.slate100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.confirmation_number_rounded,
                    size: 20,
                    color: open ? AppColors.brandTeal : AppColors.slate600,
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(coupon.name, style: AppTypography.labelLg),
                    const SizedBox(height: 2),
                    Text(
                      'Cada ${coupon.requiredReservations} reservas: '
                      '${coupon.rewardDescription}',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.slate600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${couponStateLabel(coupon.state)} · '
                      '${couponExpiryLabel(coupon)} · '
                      '${couponRedemptionsLabel(coupon)}',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.slate600,
                      ),
                    ),
                  ],
                ),
              ),
              if (!coupon.isClosed)
                Tooltip(
                  message: coupon.isActive ? 'Desactivar' : 'Activar',
                  child: Switch(value: coupon.isActive, onChanged: onToggle),
                ),
              if (onEdit != null || onDelete != null)
                PopupMenuButton<VoidCallback>(
                  key: Key('coupon-menu-${coupon.id}'),
                  tooltip: 'Más opciones',
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (action) => action(),
                  itemBuilder: (_) => [
                    if (onEdit case final edit?)
                      PopupMenuItem(value: edit, child: const Text('Editar')),
                    if (onDelete case final delete?)
                      PopupMenuItem(value: delete, child: const Text('Borrar')),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
