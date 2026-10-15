import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Escala tipográfica: Space Grotesk (display/labels) + Plus Jakarta Sans (body).
abstract final class AppTypography {
  static TextStyle get displayLg => GoogleFonts.spaceGrotesk(
    fontSize: 32,
    height: 40 / 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.64,
  );

  static TextStyle get displayLgMobile => GoogleFonts.spaceGrotesk(
    fontSize: 26,
    height: 34 / 26,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.52,
  );

  static TextStyle get headlineLg => GoogleFonts.spaceGrotesk(
    fontSize: 24,
    height: 32 / 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.24,
  );

  static TextStyle get headlineMd => GoogleFonts.spaceGrotesk(
    fontSize: 20,
    height: 28 / 20,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get headlineSm => GoogleFonts.spaceGrotesk(
    fontSize: 18,
    height: 24 / 18,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get bodyLg => GoogleFonts.plusJakartaSans(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w500,
  );

  static TextStyle get bodyMd => GoogleFonts.plusJakartaSans(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
  );

  static TextStyle get bodySm => GoogleFonts.plusJakartaSans(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w500,
  );

  static TextStyle get labelLg => GoogleFonts.spaceGrotesk(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.28,
  );

  static TextStyle get labelMd => GoogleFonts.spaceGrotesk(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.48,
  );

  static TextStyle get labelSm => GoogleFonts.spaceGrotesk(
    fontSize: 11,
    height: 14 / 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.55,
  );

  /// Texto de botones de acceso (Space Grotesk 16 semibold).
  static TextStyle get button => GoogleFonts.spaceGrotesk(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w600,
  );

  static TextTheme get textTheme => TextTheme(
    displayLarge: displayLg,
    displayMedium: displayLgMobile,
    headlineLarge: headlineLg,
    headlineMedium: headlineMd,
    headlineSmall: headlineSm,
    bodyLarge: bodyLg,
    bodyMedium: bodyMd,
    bodySmall: bodySm,
    labelLarge: labelLg,
    labelMedium: labelMd,
    labelSmall: labelSm,
  );
}
