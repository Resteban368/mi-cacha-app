import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/coupon.dart';
import '../../domain/usecases/coupon_usecases.dart';
import 'coupon_labels.dart';

/// Elige y redime un bono del cliente al cobrar la reserva. Devuelve lo
/// descontado, o `null` si no se redimió.
Future<CouponRedemption?> showRedeemCouponDialog(
  BuildContext context, {
  required String reservationId,
  required String customerId,
  required int courts,
  GetCustomerCoupons? getCoupons,
  RedeemCoupon? redeem,
}) => showDialog<CouponRedemption>(
  context: context,
  builder: (_) => _RedeemCouponDialog(
    reservationId: reservationId,
    customerId: customerId,
    courts: courts,
    getCoupons: getCoupons ?? sl<GetCustomerCoupons>(),
    redeem: redeem ?? sl<RedeemCoupon>(),
  ),
);

class _RedeemCouponDialog extends StatefulWidget {
  const _RedeemCouponDialog({
    required this.reservationId,
    required this.customerId,
    required this.courts,
    required this.getCoupons,
    required this.redeem,
  });

  final String reservationId;
  final String customerId;
  final int courts;
  final GetCustomerCoupons getCoupons;
  final RedeemCoupon redeem;

  @override
  State<_RedeemCouponDialog> createState() => _RedeemCouponDialogState();
}

class _RedeemCouponDialogState extends State<_RedeemCouponDialog> {
  List<CustomerCoupon>? _earned;
  CustomerCoupon? _selected;
  late int _courts = widget.courts;
  bool _failed = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final coupons = await widget.getCoupons(widget.customerId);
      if (!mounted) return;
      final earned = [
        for (final c in coupons)
          if (c.status == CouponCardStatus.earned && c.cardId != null) c,
      ];
      setState(() {
        _earned = earned;
        _selected = earned.length == 1 ? earned.first : null;
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  bool get _isFreeCourt =>
      _selected?.coupon.rewardType == CouponRewardType.freeCourt;

  Future<void> _submit() async {
    final selected = _selected;
    if (selected == null || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final result = await widget.redeem((
        reservationId: widget.reservationId,
        cardId: selected.cardId!,
        courts: _isFreeCourt ? _courts : null,
      ));
      if (mounted) Navigator.of(context).pop(result);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.kind == ApiErrorKind.network
            ? 'Sin conexión. Revisa tu internet e intenta de nuevo.'
            : error.message ?? 'No se pudo redimir el bono.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'No se pudo redimir el bono. Intenta de nuevo.';
      });
    }
  }

  Widget _content() {
    if (_failed) {
      return TextButton.icon(
        onPressed: _load,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('No pudimos cargar los bonos. Reintentar'),
      );
    }
    final earned = _earned;
    if (earned == null) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (earned.isEmpty) {
      return Text(
        'Este cliente no tiene bonos para redimir.',
        style: AppTypography.bodyMd.copyWith(color: AppColors.slate600),
      );
    }
    final selected = _selected;
    final subtle = AppTypography.bodySm.copyWith(color: AppColors.slate600);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RadioGroup<String>(
          groupValue: selected?.cardId,
          onChanged: (id) => setState(() {
            _selected = earned.firstWhere((c) => c.cardId == id);
          }),
          child: Column(
            children: [
              for (final coupon in earned)
                RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  value: coupon.cardId!,
                  title: Text(coupon.coupon.name),
                  subtitle: Text(coupon.coupon.rewardDescription),
                ),
            ],
          ),
        ),
        if (selected != null) ...[
          const SizedBox(height: 8),
          Text('Sus reservas', style: AppTypography.labelMd),
          const SizedBox(height: 4),
          for (final stamp in selected.stamps)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${couponDateTime(stamp.playedAt)} · '
                '${stamp.courtNames.join(' + ')} · '
                '${AppFormatters.cop(stamp.amount)}',
                style: subtle,
              ),
            ),
          if (_isFreeCourt && widget.courts > 1) ...[
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              key: const Key('redeem-courts'),
              initialValue: _courts,
              decoration: const InputDecoration(labelText: 'Canchas a regalar'),
              items: [
                for (var n = 1; n <= widget.courts; n++)
                  DropdownMenuItem(
                    value: n,
                    child: Text(n == 1 ? '1 cancha' : '$n canchas'),
                  ),
              ],
              onChanged: (value) => setState(() => _courts = value ?? _courts),
            ),
          ],
          if (_isFreeCourt) ...[
            const SizedBox(height: 8),
            Text(
              'Cubre un turno por cancha. Los consumos se cobran aparte.',
              style: subtle,
            ),
          ],
        ],
        if (_error case final error?) ...[
          const SizedBox(height: 12),
          Text(
            error,
            style: AppTypography.bodySm.copyWith(color: AppColors.statusDue),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      scrollable: true,
      title: const Text('Redimir cupón'),
      content: SizedBox(width: 420, child: _content()),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
        if (_earned?.isNotEmpty ?? false)
          FilledButton(
            key: const Key('redeem-confirm'),
            onPressed: _saving || _selected == null ? null : _submit,
            child: Text(_saving ? 'Redimiendo…' : 'Redimir'),
          ),
      ],
    );
  }
}
