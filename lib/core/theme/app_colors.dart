import 'dart:ui' show Brightness;

import 'package:flutter/painting.dart';

import 'app_palette.dart';

/// Tokens de color de Mi Cancha. Los que cambian con el modo de apariencia
/// son getters que leen la paleta activa ([use]); al cambiar de modo la app
/// se reconstruye entera (ver `AppearanceScope`).
abstract final class AppColors {
  static AppPalette _palette = AppPalette.light;

  static AppPalette get palette => _palette;
  static bool get isDark => _palette.brightness == Brightness.dark;

  /// Activa la paleta del modo; `true` si cambió.
  static bool use(Brightness brightness) {
    final next = brightness == Brightness.dark
        ? AppPalette.dark
        : AppPalette.light;
    if (identical(next, _palette)) return false;
    _palette = next;
    return true;
  }

  static Color get brandTeal => _palette.brandTeal;
  static Color get brandTealDeep => _palette.brandTealDeep;
  static Color get brandTealGlow => _palette.brandTealGlow;
  static Color get brandTealLight => _palette.brandTealLight;

  static Color get primary => _palette.primary;
  static Color get primaryContainer => _palette.primaryContainer;
  static const onPrimary = Color(0xFFFFFFFF);

  static Color get secondary => _palette.secondary;
  static const secondaryContainer = Color(0xFFCCF21A);
  static const onSecondaryFixed = Color(0xFF181E00);
  static const secondaryFixed = Color(0xFFCCF21A);
  static const onSecondaryFixedVariant = Color(0xFF3F4C00);

  static Color get tertiary => _palette.tertiary;

  // Lima de acento: igual en los dos modos (va sobre fondos oscuros de marca).
  static const accentLime = Color(0xFFD2F824);
  static const accentLimeSignal = Color(0xFFCCFF00);
  static Color get accentLimeTint => _palette.accentLimeTint;

  static Color get surface => _palette.surface;
  static Color get surfaceTealSubtle => _palette.surfaceTealSubtle;
  static Color get surfaceBright => _palette.surface;
  static Color get surfaceContainerLowest => _palette.surfaceContainerLowest;
  static Color get surfaceContainerLow => _palette.surfaceContainerLow;
  static Color get surfaceContainerHigh => _palette.surfaceContainerHigh;
  static Color get surfaceVariant => _palette.surfaceContainerHighest;
  static Color get surfaceContainer => _palette.surfaceContainer;
  static Color get surfaceContainerHighest => _palette.surfaceContainerHighest;
  static Color get inverseSurface => _palette.inverseSurface;
  static Color get inverseOnSurface => _palette.inverseOnSurface;
  static Color get onSurface => _palette.onSurface;
  static Color get onSurfaceVariant => _palette.onSurfaceVariant;
  static Color get outline => _palette.outline;
  static Color get outlineVariant => _palette.outlineVariant;

  static Color get brandDark => _palette.brandDark;

  // Neutros (slate) y verdes de apoyo usados en formularios.
  static Color get slate50 => _palette.slate[0];
  static Color get slate100 => _palette.slate[1];
  static Color get slate200 => _palette.slate[2];
  static Color get slate300 => _palette.slate[3];
  static Color get slate400 => _palette.slate[4];
  static Color get slate500 => _palette.slate[5];
  static Color get slate600 => _palette.slate[6];
  static Color get slate700 => _palette.slate[7];
  static Color get slate800 => _palette.slate[8];
  static Color get slate900 => _palette.slate[9];
  static Color get emerald50 => _palette.emerald50;
  static Color get emerald100 => _palette.emerald100;
  static Color get emerald200 => _palette.emerald200;
  static Color get emerald600 => _palette.emerald600;
  static Color get emerald800 => _palette.emerald800;
  static Color get emerald950 => _palette.emerald950;

  static Color get error => _palette.error;
  static const onError = Color(0xFFFFFFFF);
  static Color get errorContainer => _palette.errorContainer;
  static Color get onErrorContainer => _palette.onErrorContainer;

  // Acentos por deporte y marcas externas.
  static const orange500 = Color(0xFFF97316);
  static const amber500 = Color(0xFFF59E0B);
  static const whatsapp = Color(0xFF25D366);
  static Color get whatsappDark => _palette.whatsappDark;

  static Color get statusPaid => _palette.statusPaid;
  static Color get statusDeposit => _palette.statusDeposit;
  static Color get statusDue => _palette.statusDue;

  // Tonos semánticos de avisos y etiquetas.
  static Color get dangerTint => _palette.dangerTint;
  static Color get dangerBorder => _palette.dangerBorder;
  static Color get dangerInk => _palette.dangerInk;
  static Color get warningTint => _palette.warningTint;
  static Color get warningBorder => _palette.warningBorder;
  static Color get warningInk => _palette.warningInk;
  static Color get infoTint => _palette.infoTint;
  static Color get infoInk => _palette.infoInk;
  static Color get successTint => _palette.successTint;
  static Color get successBorder => _palette.successBorder;
}
