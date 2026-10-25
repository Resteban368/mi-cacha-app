import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Estructura común de cada paso: marca arriba, ilustración, textos y la
/// zona de navegación.
///
/// - Móvil: todo en una columna desplazable con el footer anclado abajo
///   cuando sobra espacio.
/// - Web/escritorio (≥ [wideBreakpoint] × [wideMinHeight]): ilustración a la
///   izquierda y textos + footer a la derecha.
class OnboardingStepLayout extends StatelessWidget {
  const OnboardingStepLayout({
    super.key,
    required this.header,
    required this.media,
    required this.children,
    required this.footer,
    this.mediaSpacing = 16,
    this.horizontalPadding = 16,
  });

  static const wideBreakpoint = 900.0;
  static const wideMinHeight = 560.0;

  static bool isWide(Size size) =>
      size.width >= wideBreakpoint && size.height >= wideMinHeight;

  /// Marca y acción secundaria (Saltar / estado).
  final Widget header;

  /// Ilustración del paso.
  final Widget media;

  /// Píldora, título, descripción y extras.
  final List<Widget> children;
  final Widget footer;
  final double mediaSpacing;
  final double horizontalPadding;

  /// Ancho con el que se diseñaron las ilustraciones (móvil).
  static const _mediaDesignWidth = 440.0;
  static const _wideMediaMaxWidth = 640.0;
  static const _wideTextWidth = 460.0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) =>
            isWide(constraints.biggest) ? _wide() : _narrow(constraints),
      ),
    );
  }

  Widget _narrow(BoxConstraints constraints) {
    // No se usa SliverFillRemaining(hasScrollBody: false): calcula el alto con
    // medidas intrínsecas, que no son fiables con SVG asíncronos y provocaban
    // overflow. Aquí la columna mide lo que ocupa su contenido, con un mínimo
    // igual al viewport; spaceBetween empuja el footer abajo si sobra espacio.
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: (constraints.maxHeight - 24).clamp(0, double.infinity),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                const SizedBox(height: 4),
                media,
                SizedBox(height: mediaSpacing),
                ...children,
              ],
            ),
            Padding(padding: const EdgeInsets.only(top: 24), child: footer),
          ],
        ),
      ),
    );
  }

  Widget _wide() {
    return OnboardingLayoutScope(
      wide: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(40, 8, 40, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            const SizedBox(height: 16),
            Expanded(
              child: Row(
                children: [
                  // La ilustración se arma con su ancho de móvil y se escala
                  // (vectorial) hasta llenar la columna sin deformarse.
                  Expanded(
                    flex: 6,
                    child: LayoutBuilder(
                      builder: (context, box) => Center(
                        // Caja exacta para que FittedBox también agrande.
                        child: SizedBox(
                          width: box.maxWidth.clamp(0, _wideMediaMaxWidth),
                          height: box.maxHeight,
                          child: FittedBox(
                            child: SizedBox(
                              width: _mediaDesignWidth,
                              child: media,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 72),
                  Expanded(
                    flex: 5,
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: _wideTextWidth,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ...children,
                              const SizedBox(height: 40),
                              footer,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Indica a los widgets de un paso si se dibujan en el layout ancho (web),
/// para alinear a la izquierda y agrandar la tipografía.
class OnboardingLayoutScope extends InheritedWidget {
  const OnboardingLayoutScope({
    super.key,
    required this.wide,
    required super.child,
  });

  final bool wide;

  static bool wideOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<OnboardingLayoutScope>()
          ?.wide ??
      false;

  @override
  bool updateShouldNotify(OnboardingLayoutScope oldWidget) =>
      wide != oldWidget.wide;
}

/// Título del paso: centrado en móvil; grande y a la izquierda en web.
class OnboardingTitle extends StatelessWidget {
  const OnboardingTitle(
    this.text, {
    super.key,
    required this.style,
    this.maxWidth = double.infinity,
  });

  final String text;

  /// Estilo en móvil (cada paso usa el del diseño).
  final TextStyle style;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    if (OnboardingLayoutScope.wideOf(context)) {
      return Text(
        text,
        style: AppTypography.displayLg.copyWith(
          fontSize: 44,
          height: 1.1,
          letterSpacing: -1,
          color: AppColors.onSurface,
        ),
      );
    }
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: style.copyWith(color: AppColors.onSurface),
        ),
      ),
    );
  }
}

/// Descripción del paso: centrada en móvil; más grande y a la izquierda en web.
class OnboardingDescription extends StatelessWidget {
  const OnboardingDescription(
    this.text, {
    super.key,
    required this.style,
    this.maxWidth = 290,
  });

  final String text;
  final TextStyle style;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    if (OnboardingLayoutScope.wideOf(context)) {
      return Text(
        text,
        style: AppTypography.bodyLg.copyWith(
          fontSize: 18,
          height: 1.6,
          color: AppColors.onSurfaceVariant,
        ),
      );
    }
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: style.copyWith(color: AppColors.onSurfaceVariant),
        ),
      ),
    );
  }
}

/// Bloque (píldora, fichas) centrado en móvil y alineado a la izquierda en
/// web, con un ancho máximo.
class OnboardingBlock extends StatelessWidget {
  const OnboardingBlock({
    super.key,
    required this.child,
    this.maxWidth = double.infinity,
    this.wideMaxWidth,
  });

  final Widget child;
  final double maxWidth;

  /// Ancho máximo en web; por defecto [maxWidth].
  final double? wideMaxWidth;

  @override
  Widget build(BuildContext context) {
    final wide = OnboardingLayoutScope.wideOf(context);
    return Align(
      alignment: wide ? Alignment.centerLeft : Alignment.center,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: wide ? (wideMaxWidth ?? maxWidth) : maxWidth,
        ),
        child: child,
      ),
    );
  }
}

/// Separación vertical entre textos; en web se amplía.
class OnboardingGap extends StatelessWidget {
  const OnboardingGap(this.height, {super.key});

  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: OnboardingLayoutScope.wideOf(context) ? height + 12 : height,
  );
}

/// Marca "Mi Cancha" con ícono deportivo (varía por paso en el diseño).
class OnboardingBrand extends StatelessWidget {
  const OnboardingBrand({
    super.key,
    required this.icon,
    this.size = 40,
    this.background,
    this.titleColor,
    this.boxShadow,
  });

  final IconData icon;
  final double size;
  final Color? background;

  Color get _background => background ?? AppColors.brandTeal;
  final Color? titleColor;

  Color get _titleColor => titleColor ?? AppColors.onSurface;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: _background,
            borderRadius: BorderRadius.circular(size * 0.3),
            boxShadow:
                boxShadow ??
                const [
                  BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
          ),
          child: Icon(icon, size: size * 0.6, color: AppColors.accentLime),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            'Mi Cancha',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.headlineSm.copyWith(
              color: _titleColor,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.45,
              height: 1,
            ),
          ),
        ),
      ],
    );
  }
}

/// Píldora "Paso X de 3 · ...".
class OnboardingStepPill extends StatelessWidget {
  const OnboardingStepPill({
    super.key,
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    this.iconColor,
    this.textStyle,
    this.boxShadow,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final Color? iconColor;
  final TextStyle? textStyle;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        boxShadow: boxShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: iconColor ?? foreground),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label.toUpperCase(),
              style: (textStyle ?? AppTypography.labelSm).copyWith(
                color: foreground,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Indicador de páginas: la activa es una píldora alargada.
class OnboardingDots extends StatelessWidget {
  const OnboardingDots({
    super.key,
    required this.activeIndex,
    this.count = 3,
    this.spacing = 8,
  });

  final int activeIndex;
  final int count;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Paso ${activeIndex + 1} de $count',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) SizedBox(width: spacing),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: i == activeIndex ? 32 : 10,
              height: 10,
              decoration: BoxDecoration(
                color: i == activeIndex
                    ? AppColors.brandTeal
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Círculo lima con flecha usado dentro de los botones principales.
class LimeArrowBadge extends StatelessWidget {
  const LimeArrowBadge({super.key, this.iconColor});

  final Color? iconColor;

  Color get _iconColor => iconColor ?? AppColors.brandTealDeep;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        color: AppColors.accentLime,
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.arrow_forward, size: 18, color: _iconColor),
    );
  }
}

/// Botón principal teal del onboarding.
class OnboardingPrimaryButton extends StatelessWidget {
  const OnboardingPrimaryButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.height = 52,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
    this.shadowOpacity = 0.12,
  });

  final VoidCallback onPressed;
  final Widget child;
  final double height;
  final EdgeInsets padding;
  final double shadowOpacity;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandTeal.withValues(alpha: shadowOpacity * 2),
            blurRadius: 12,
            offset: const Offset(0, 6),
            spreadRadius: -2,
          ),
        ],
      ),
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          minimumSize: Size(0, height),
          padding: padding,
          backgroundColor: AppColors.brandTeal,
          foregroundColor: AppColors.onPrimary,
          overlayColor: AppColors.brandTealDeep,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTypography.labelLg.copyWith(letterSpacing: 0.7),
        ),
        child: child,
      ),
    );
  }
}

/// Mancha de luz difusa de fondo (equivale a `blur-3xl` sobre un círculo).
class AmbientGlow extends StatelessWidget {
  const AmbientGlow({super.key, required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

/// Tarjeta pequeña con ícono y texto (deportes, beneficios).
class FeatureTile extends StatelessWidget {
  const FeatureTile({
    super.key,
    required this.icon,
    required this.label,
    this.caption,
    this.iconColor,
    this.iconSize = 22,
    this.padding = const EdgeInsets.all(8),
    this.labelStyle,
    this.shadow = true,
  });

  final IconData icon;
  final String label;
  final String? caption;
  final Color? iconColor;

  Color get _iconColor => iconColor ?? AppColors.brandTeal;
  final double iconSize;
  final EdgeInsets padding;
  final TextStyle? labelStyle;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        boxShadow: shadow
            ? const [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: _iconColor),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                labelStyle ??
                AppTypography.labelSm.copyWith(
                  color: AppColors.onSurface,
                  fontSize: 10,
                ),
          ),
          if (caption != null)
            Text(
              caption!,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySm.copyWith(
                fontSize: 10,
                color: AppColors.outline,
              ),
            ),
        ],
      ),
    );
  }
}
