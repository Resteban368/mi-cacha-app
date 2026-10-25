import 'dart:ui' show Brightness;

import 'package:flutter/painting.dart';

/// Colores de un modo de apariencia (claro u oscuro). La marca: Verde
/// Esmeralda `#00C853`, Negro Azulado `#0B1F28` y Blanco `#F8FAFC`.
///
/// `onPrimary` es blanco en los dos modos: se usa sobre el verde de marca y
/// sobre fotos o capas oscuras. Por eso el verde de los rellenos es más
/// profundo que `#00C853` (contraste suficiente con el texto blanco).
class AppPalette {
  const AppPalette({
    required this.brightness,
    required this.brandTeal,
    required this.brandTealDeep,
    required this.brandTealGlow,
    required this.brandTealLight,
    required this.primary,
    required this.primaryContainer,
    required this.secondary,
    required this.tertiary,
    required this.accentLimeTint,
    required this.surface,
    required this.surfaceTealSubtle,
    required this.surfaceContainerLowest,
    required this.surfaceContainerLow,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.surfaceContainerHighest,
    required this.inverseSurface,
    required this.inverseOnSurface,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.outline,
    required this.outlineVariant,
    required this.brandDark,
    required this.slate,
    required this.emerald50,
    required this.emerald100,
    required this.emerald200,
    required this.emerald600,
    required this.emerald800,
    required this.emerald950,
    required this.error,
    required this.errorContainer,
    required this.onErrorContainer,
    required this.whatsappDark,
    required this.statusPaid,
    required this.statusDeposit,
    required this.statusDue,
    required this.dangerTint,
    required this.dangerBorder,
    required this.dangerInk,
    required this.warningTint,
    required this.warningBorder,
    required this.warningInk,
    required this.infoTint,
    required this.infoInk,
    required this.successTint,
    required this.successBorder,
  });

  final Brightness brightness;

  final Color brandTeal;
  final Color brandTealDeep;
  final Color brandTealGlow;
  final Color brandTealLight;
  final Color primary;
  final Color primaryContainer;
  final Color secondary;
  final Color tertiary;
  final Color accentLimeTint;

  final Color surface;
  final Color surfaceTealSubtle;
  final Color surfaceContainerLowest;
  final Color surfaceContainerLow;
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color surfaceContainerHighest;
  final Color inverseSurface;
  final Color inverseOnSurface;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color outline;
  final Color outlineVariant;
  final Color brandDark;

  /// Neutros de formularios, de `slate50` a `slate900` (10 tonos).
  final List<Color> slate;

  final Color emerald50;
  final Color emerald100;
  final Color emerald200;
  final Color emerald600;
  final Color emerald800;
  final Color emerald950;

  final Color error;
  final Color errorContainer;
  final Color onErrorContainer;

  final Color whatsappDark;
  final Color statusPaid;
  final Color statusDeposit;
  final Color statusDue;

  // Tonos semánticos de avisos y etiquetas (fondo, borde y texto).
  final Color dangerTint;
  final Color dangerBorder;
  final Color dangerInk;
  final Color warningTint;
  final Color warningBorder;
  final Color warningInk;
  final Color infoTint;
  final Color infoInk;
  final Color successTint;
  final Color successBorder;

  static const light = AppPalette(
    brightness: Brightness.light,
    brandTeal: Color(0xFF00853A),
    brandTealDeep: Color(0xFF005C28),
    brandTealGlow: Color(0xFF00C853),
    brandTealLight: Color(0xFFE3F8EB),
    primary: Color(0xFF007A35),
    primaryContainer: Color(0xFF00A344),
    secondary: Color(0xFF546500),
    tertiary: Color(0xFF1F5C3A),
    accentLimeTint: Color(0xFFF6FFE0),
    surface: Color(0xFFF8FAFC),
    surfaceTealSubtle: Color(0xFFF2F6F5),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFEEF3F1),
    surfaceContainer: Color(0xFFE7EEEB),
    surfaceContainerHigh: Color(0xFFDFE8E4),
    surfaceContainerHighest: Color(0xFFD9E3DF),
    inverseSurface: Color(0xFF0B1F28),
    inverseOnSurface: Color(0xFFE6EEF0),
    onSurface: Color(0xFF0B1F28),
    onSurfaceVariant: Color(0xFF3E4F57),
    outline: Color(0xFF6B7C84),
    outlineVariant: Color(0xFFC3CFD4),
    brandDark: Color(0xFF0B1F28),
    slate: [
      Color(0xFFF8FAFC),
      Color(0xFFF1F5F9),
      Color(0xFFE2E8F0),
      Color(0xFFCBD5E1),
      Color(0xFF94A3B8),
      Color(0xFF64748B),
      Color(0xFF475569),
      Color(0xFF334155),
      Color(0xFF1E293B),
      Color(0xFF0B1F28),
    ],
    emerald50: Color(0xFFECFDF3),
    emerald100: Color(0xFFD1FADF),
    emerald200: Color(0xFFA6F4C5),
    emerald600: Color(0xFF00853A),
    emerald800: Color(0xFF05603A),
    emerald950: Color(0xFF052E16),
    error: Color(0xFFBA1A1A),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF93000A),
    whatsappDark: Color(0xFF128C7E),
    statusPaid: Color(0xFF00853A),
    statusDeposit: Color(0xFFD97706),
    statusDue: Color(0xFFDC2626),
    dangerTint: Color(0xFFFEF2F2),
    dangerBorder: Color(0xFFFECACA),
    dangerInk: Color(0xFF991B1B),
    warningTint: Color(0xFFFEF3C7),
    warningBorder: Color(0xFFFCD39D),
    warningInk: Color(0xFF92400E),
    infoTint: Color(0xFFE0F2FE),
    infoInk: Color(0xFF0369A1),
    successTint: Color(0xFFF0FDF4),
    successBorder: Color(0xFFBBF7D0),
  );

  static const dark = AppPalette(
    brightness: Brightness.dark,
    brandTeal: Color(0xFF00A344),
    brandTealDeep: Color(0xFF7BE8A6),
    brandTealGlow: Color(0xFF00C853),
    brandTealLight: Color(0xFF0F3426),
    primary: Color(0xFF00A344),
    primaryContainer: Color(0xFF00853A),
    secondary: Color(0xFFB8D400),
    tertiary: Color(0xFF7FD8A8),
    accentLimeTint: Color(0xFF243008),
    surface: Color(0xFF0B1F28),
    surfaceTealSubtle: Color(0xFF071820),
    surfaceContainerLowest: Color(0xFF0F2630),
    surfaceContainerLow: Color(0xFF132C38),
    surfaceContainer: Color(0xFF173341),
    surfaceContainerHigh: Color(0xFF1B3947),
    surfaceContainerHighest: Color(0xFF21404F),
    inverseSurface: Color(0xFF1C4636),
    inverseOnSurface: Color(0xFFF1F5F9),
    onSurface: Color(0xFFF1F5F9),
    onSurfaceVariant: Color(0xFFA8BAC3),
    outline: Color(0xFF6F8894),
    outlineVariant: Color(0xFF2C4857),
    brandDark: Color(0xFF0E2A35),
    slate: [
      Color(0xFF0F2630),
      Color(0xFF132C38),
      Color(0xFF23404E),
      Color(0xFF345361),
      Color(0xFF7590A0),
      Color(0xFF93A9B4),
      Color(0xFFA8BAC3),
      Color(0xFFC3D1D8),
      Color(0xFFDCE6EA),
      Color(0xFFF1F5F9),
    ],
    emerald50: Color(0xFF0E2E22),
    emerald100: Color(0xFF114030),
    emerald200: Color(0xFF17573F),
    emerald600: Color(0xFF2BD46B),
    emerald800: Color(0xFF7BE8A6),
    emerald950: Color(0xFFD1FADF),
    error: Color(0xFFEF5350),
    errorContainer: Color(0xFF3B1418),
    onErrorContainer: Color(0xFFFFB4AB),
    whatsappDark: Color(0xFF4ADE80),
    statusPaid: Color(0xFF2BD46B),
    statusDeposit: Color(0xFFF59E0B),
    statusDue: Color(0xFFF87171),
    dangerTint: Color(0xFF3B1418),
    dangerBorder: Color(0xFF6B2228),
    dangerInk: Color(0xFFFCA5A5),
    warningTint: Color(0xFF3A2A0A),
    warningBorder: Color(0xFF6B4A12),
    warningInk: Color(0xFFFCD34D),
    infoTint: Color(0xFF0C2E45),
    infoInk: Color(0xFF7DD3FC),
    successTint: Color(0xFF0F3426),
    successBorder: Color(0xFF1E5A3E),
  );
}
