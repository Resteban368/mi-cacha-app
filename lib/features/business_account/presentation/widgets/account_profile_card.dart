import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../business_profile/domain/entities/business.dart';
import '../../domain/entities/business_account.dart';
import 'account_card.dart';

/// Perfil del administrador, su sede y la acción de editar.
class AccountProfileCard extends StatelessWidget {
  const AccountProfileCard({
    super.key,
    required this.admin,
    required this.venue,
    required this.courtsInUse,
    required this.onVenueTap,
    required this.onEditProfile,
  });

  final AdminProfile admin;

  /// `null` si todavía no registró su sede.
  final Business? venue;
  final int courtsInUse;
  final VoidCallback onVenueTap;
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) {
    return AccountCard(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Círculo decorativo de la esquina.
          Positioned(
            top: -56,
            right: -56,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brandTealLight.withValues(alpha: 0.6),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Avatar(initials: admin.initials, verified: admin.verified),
                  const SizedBox(width: 12),
                  Expanded(child: _AdminInfo(admin: admin)),
                ],
              ),
              const SizedBox(height: 16),
              _VenueTile(
                venue: venue,
                courtsInUse: courtsInUse,
                onTap: onVenueTap,
              ),
              const SizedBox(height: 8),
              Material(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onEditProfile,
                  child: SizedBox(
                    height: 44,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.edit,
                          size: 17,
                          color: AppColors.brandTeal,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Editar perfil y preferencias',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelMd.copyWith(
                              color: AppColors.brandTeal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials, required this.verified});

  final String initials;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 64,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
                colors: [AppColors.brandTealDeep, AppColors.primary],
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x1F000000),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              initials,
              style: AppTypography.headlineMd.copyWith(
                color: AppColors.onPrimary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          if (verified)
            Positioned(
              right: -4,
              bottom: -4,
              child: Tooltip(
                message: 'Cuenta verificada',
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accentLime,
                  ),
                  child: const Icon(
                    Icons.verified,
                    size: 14,
                    color: AppColors.brandTealDeep,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AdminInfo extends StatelessWidget {
  const _AdminInfo({required this.admin});

  final AdminProfile admin;

  @override
  Widget build(BuildContext context) {
    Widget contact(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.brandTeal),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySm.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              admin.fullName,
              style: AppTypography.headlineSm.copyWith(
                color: AppColors.onSurface,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.brandTealLight,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                admin.roleLabel.toUpperCase(),
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.brandTeal,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        contact(Icons.mail_outline, admin.email),
        contact(Icons.call_outlined, admin.phone),
      ],
    );
  }
}

/// Sede del administrador; lleva a "Mi negocio" (o a registrarla).
class _VenueTile extends StatelessWidget {
  const _VenueTile({
    required this.venue,
    required this.courtsInUse,
    required this.onTap,
  });

  final Business? venue;
  final int courtsInUse;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final venue = this.venue;
    final title = venue?.name ?? 'Registra tu sede deportiva';
    final subtitle = venue == null
        ? 'Completa los datos de tu negocio'
        : '${venue.neighborhood} · $courtsInUse '
              '${courtsInUse == 1 ? 'cancha activa' : 'canchas activas'}';

    return Material(
      color: AppColors.surfaceTealSubtle,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(color: Color(0x14000000), blurRadius: 2),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SvgPicture.asset(AppAssets.logo),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.outlineVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
