import "package:flutter/material.dart";

class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff394379),
      surfaceTint: Color(0xff515b92),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff515b92),
      onPrimaryContainer: Color(0xffd1d6ff),
      secondary: Color(0xff000220),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff141b41),
      onSecondaryContainer: Color(0xff7d83b0),
      tertiary: Color(0xff323940),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff495057),
      onTertiaryContainer: Color(0xffbbc2ca),
      error: Color(0xffbc111c),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffe03131),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfffcf8f8),
      onSurface: Color(0xff1c1b1b),
      onSurfaceVariant: Color(0xff46464b),
      outline: Color(0xff76777c),
      outlineVariant: Color(0xffc6c6cc),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff313030),
      inversePrimary: Color(0xffbac3ff),
      primaryFixed: Color(0xffdee1ff),
      onPrimaryFixed: Color(0xff0a164b),
      primaryFixedDim: Color(0xffbac3ff),
      onPrimaryFixedVariant: Color(0xff394378),
      secondaryFixed: Color(0xffdee0ff),
      onSecondaryFixed: Color(0xff11183e),
      secondaryFixedDim: Color(0xffbdc4f3),
      onSecondaryFixedVariant: Color(0xff3d446c),
      tertiaryFixed: Color(0xffdce3ec),
      onTertiaryFixed: Color(0xff151c22),
      tertiaryFixedDim: Color(0xffc0c7cf),
      onTertiaryFixedVariant: Color(0xff41484e),
      surfaceDim: Color(0xffdcd9d8),
      surfaceBright: Color(0xfffcf8f8),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff6f3f2),
      surfaceContainer: Color(0xfff1edec),
      surfaceContainerHigh: Color(0xffebe7e7),
      surfaceContainerHighest: Color(0xffe5e2e1),
    );
  }

  ThemeData light() {
    return theme(lightScheme());
  }

  static ColorScheme lightMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff283266),
      surfaceTint: Color(0xff515b92),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff515b92),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff000220),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff141b41),
      onSecondaryContainer: Color(0xffa0a7d5),
      tertiary: Color(0xff30373e),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff495057),
      onTertiaryContainer: Color(0xffe9eff8),
      error: Color(0xff730009),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffd22629),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfffcf8f8),
      onSurface: Color(0xff111111),
      onSurfaceVariant: Color(0xff35363b),
      outline: Color(0xff515257),
      outlineVariant: Color(0xff6c6d72),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff313030),
      inversePrimary: Color(0xffbac3ff),
      primaryFixed: Color(0xff606aa2),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff475187),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff646a95),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff4b527b),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff676e75),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff4f565d),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffc9c6c5),
      surfaceBright: Color(0xfffcf8f8),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff6f3f2),
      surfaceContainer: Color(0xffebe7e7),
      surfaceContainerHigh: Color(0xffdfdcdb),
      surfaceContainerHighest: Color(0xffd4d1d0),
    );
  }

  ThemeData lightMediumContrast() {
    return theme(lightMediumContrastScheme());
  }

  static ColorScheme lightHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff1d285c),
      surfaceTint: Color(0xff515b92),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff3b457b),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff000220),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff141b41),
      onSecondaryContainer: Color(0xffcbd1ff),
      tertiary: Color(0xff262d33),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff434a51),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff600006),
      onError: Color(0xffffffff),
      errorContainer: Color(0xff980010),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfffcf8f8),
      onSurface: Color(0xff000000),
      onSurfaceVariant: Color(0xff000000),
      outline: Color(0xff2b2c30),
      outlineVariant: Color(0xff48494e),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff313030),
      inversePrimary: Color(0xffbac3ff),
      primaryFixed: Color(0xff3b457b),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff242e63),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff40476f),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff293057),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff434a51),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff2c333a),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffbbb8b7),
      surfaceBright: Color(0xfffcf8f8),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff3f0ef),
      surfaceContainer: Color(0xffe5e2e1),
      surfaceContainerHigh: Color(0xffd7d4d3),
      surfaceContainerHighest: Color(0xffc9c6c5),
    );
  }

  ThemeData lightHighContrast() {
    return theme(lightHighContrastScheme());
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffbac3ff),
      surfaceTint: Color(0xffbac3ff),
      onPrimary: Color(0xff222c60),
      primaryContainer: Color(0xff515b92),
      onPrimaryContainer: Color(0xffd1d6ff),
      secondary: Color(0xffbdc4f3),
      onSecondary: Color(0xff272e54),
      secondaryContainer: Color(0xff141b41),
      onSecondaryContainer: Color(0xff7d83b0),
      tertiary: Color(0xffc0c7cf),
      onTertiary: Color(0xff2a3138),
      tertiaryContainer: Color(0xff495057),
      onTertiaryContainer: Color(0xffbbc2ca),
      error: Color(0xffffb3ac),
      onError: Color(0xff680008),
      errorContainer: Color(0xffe03131),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xff131313),
      onSurface: Color(0xffe5e2e1),
      onSurfaceVariant: Color(0xffc6c6cc),
      outline: Color(0xff909096),
      outlineVariant: Color(0xff46464b),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe5e2e1),
      inversePrimary: Color(0xff515b92),
      primaryFixed: Color(0xffdee1ff),
      onPrimaryFixed: Color(0xff0a164b),
      primaryFixedDim: Color(0xffbac3ff),
      onPrimaryFixedVariant: Color(0xff394378),
      secondaryFixed: Color(0xffdee0ff),
      onSecondaryFixed: Color(0xff11183e),
      secondaryFixedDim: Color(0xffbdc4f3),
      onSecondaryFixedVariant: Color(0xff3d446c),
      tertiaryFixed: Color(0xffdce3ec),
      onTertiaryFixed: Color(0xff151c22),
      tertiaryFixedDim: Color(0xffc0c7cf),
      onTertiaryFixedVariant: Color(0xff41484e),
      surfaceDim: Color(0xff131313),
      surfaceBright: Color(0xff3a3939),
      surfaceContainerLowest: Color(0xff0e0e0e),
      surfaceContainerLow: Color(0xff1c1b1b),
      surfaceContainer: Color(0xff201f1f),
      surfaceContainerHigh: Color(0xff2a2a2a),
      surfaceContainerHighest: Color(0xff353534),
    );
  }

  ThemeData dark() {
    return theme(darkScheme());
  }

  static ColorScheme darkMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffd6daff),
      surfaceTint: Color(0xffbac3ff),
      onPrimary: Color(0xff162155),
      primaryContainer: Color(0xff838dc8),
      onPrimaryContainer: Color(0xff000000),
      secondary: Color(0xffd6daff),
      onSecondary: Color(0xff1c2349),
      secondaryContainer: Color(0xff888ebb),
      onSecondaryContainer: Color(0xff000000),
      tertiary: Color(0xffd6dde5),
      onTertiary: Color(0xff1f262d),
      tertiaryContainer: Color(0xff8a9199),
      onTertiaryContainer: Color(0xff000000),
      error: Color(0xffffd2cd),
      onError: Color(0xff540005),
      errorContainer: Color(0xffff544d),
      onErrorContainer: Color(0xff000000),
      surface: Color(0xff131313),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffdcdce2),
      outline: Color(0xffb2b1b7),
      outlineVariant: Color(0xff909095),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe5e2e1),
      inversePrimary: Color(0xff3a447a),
      primaryFixed: Color(0xffdee1ff),
      onPrimaryFixed: Color(0xff00093f),
      primaryFixedDim: Color(0xffbac3ff),
      onPrimaryFixedVariant: Color(0xff283266),
      secondaryFixed: Color(0xffdee0ff),
      onSecondaryFixed: Color(0xff060d34),
      secondaryFixedDim: Color(0xffbdc4f3),
      onSecondaryFixedVariant: Color(0xff2d335a),
      tertiaryFixed: Color(0xffdce3ec),
      onTertiaryFixed: Color(0xff0b1218),
      tertiaryFixedDim: Color(0xffc0c7cf),
      onTertiaryFixedVariant: Color(0xff30373e),
      surfaceDim: Color(0xff131313),
      surfaceBright: Color(0xff454444),
      surfaceContainerLowest: Color(0xff070707),
      surfaceContainerLow: Color(0xff1e1d1d),
      surfaceContainer: Color(0xff282827),
      surfaceContainerHigh: Color(0xff333232),
      surfaceContainerHighest: Color(0xff3e3d3d),
    );
  }

  ThemeData darkMediumContrast() {
    return theme(darkMediumContrastScheme());
  }

  static ColorScheme darkHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffefeeff),
      surfaceTint: Color(0xffbac3ff),
      onPrimary: Color(0xff000000),
      primaryContainer: Color(0xffb5bffd),
      onPrimaryContainer: Color(0xff000631),
      secondary: Color(0xffefeeff),
      onSecondary: Color(0xff000000),
      secondaryContainer: Color(0xffb9c0ef),
      onSecondaryContainer: Color(0xff01062e),
      tertiary: Color(0xffeaf1f9),
      onTertiary: Color(0xff000000),
      tertiaryContainer: Color(0xffbcc3cc),
      onTertiaryContainer: Color(0xff060c12),
      error: Color(0xffffece9),
      onError: Color(0xff000000),
      errorContainer: Color(0xffffaea6),
      onErrorContainer: Color(0xff220001),
      surface: Color(0xff131313),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffffffff),
      outline: Color(0xfff0eff5),
      outlineVariant: Color(0xffc2c2c8),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe5e2e1),
      inversePrimary: Color(0xff3a447a),
      primaryFixed: Color(0xffdee1ff),
      onPrimaryFixed: Color(0xff000000),
      primaryFixedDim: Color(0xffbac3ff),
      onPrimaryFixedVariant: Color(0xff00093f),
      secondaryFixed: Color(0xffdee0ff),
      onSecondaryFixed: Color(0xff000000),
      secondaryFixedDim: Color(0xffbdc4f3),
      onSecondaryFixedVariant: Color(0xff060d34),
      tertiaryFixed: Color(0xffdce3ec),
      onTertiaryFixed: Color(0xff000000),
      tertiaryFixedDim: Color(0xffc0c7cf),
      onTertiaryFixedVariant: Color(0xff0b1218),
      surfaceDim: Color(0xff131313),
      surfaceBright: Color(0xff51504f),
      surfaceContainerLowest: Color(0xff000000),
      surfaceContainerLow: Color(0xff201f1f),
      surfaceContainer: Color(0xff313030),
      surfaceContainerHigh: Color(0xff3c3b3b),
      surfaceContainerHighest: Color(0xff474646),
    );
  }

  ThemeData darkHighContrast() {
    return theme(darkHighContrastScheme());
  }

  ThemeData theme(ColorScheme colorScheme) => ThemeData(
    useMaterial3: true,
    brightness: colorScheme.brightness,
    colorScheme: colorScheme,
    textTheme: textTheme.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    ),
    scaffoldBackgroundColor: colorScheme.background,
    canvasColor: colorScheme.surface,
    extensions: [
      AppColors.forBrightness(colorScheme.brightness, contrast: "normal"),
    ],
  );

  /// success
  static const success = ExtendedColor(
    seed: Color(0xff51cf66),
    value: Color(0xff51cf66),
    light: ColorFamily(
      color: Color(0xff006e26),
      onColor: Color(0xffffffff),
      colorContainer: Color(0xff51cf66),
      onColorContainer: Color(0xff00541b),
    ),
    lightMediumContrast: ColorFamily(
      color: Color(0xff006e26),
      onColor: Color(0xffffffff),
      colorContainer: Color(0xff51cf66),
      onColorContainer: Color(0xff00541b),
    ),
    lightHighContrast: ColorFamily(
      color: Color(0xff006e26),
      onColor: Color(0xffffffff),
      colorContainer: Color(0xff51cf66),
      onColorContainer: Color(0xff00541b),
    ),
    dark: ColorFamily(
      color: Color(0xff6fec7f),
      onColor: Color(0xff003910),
      colorContainer: Color(0xff51cf66),
      onColorContainer: Color(0xff00541b),
    ),
    darkMediumContrast: ColorFamily(
      color: Color(0xff6fec7f),
      onColor: Color(0xff003910),
      colorContainer: Color(0xff51cf66),
      onColorContainer: Color(0xff00541b),
    ),
    darkHighContrast: ColorFamily(
      color: Color(0xff6fec7f),
      onColor: Color(0xff003910),
      colorContainer: Color(0xff51cf66),
      onColorContainer: Color(0xff00541b),
    ),
  );

  /// reserved
  static const inUse = ExtendedColor(
    seed: Color(0xfffcc419),
    value: Color(0xfffcc419),
    light: ColorFamily(
      color: Color(0xff775a00),
      onColor: Color(0xffffffff),
      colorContainer: Color(0xfffcc419),
      onColorContainer: Color(0xff6c5200),
    ),
    lightMediumContrast: ColorFamily(
      color: Color(0xff775a00),
      onColor: Color(0xffffffff),
      colorContainer: Color(0xfffcc419),
      onColorContainer: Color(0xff6c5200),
    ),
    lightHighContrast: ColorFamily(
      color: Color(0xff775a00),
      onColor: Color(0xffffffff),
      colorContainer: Color(0xfffcc419),
      onColorContainer: Color(0xff6c5200),
    ),
    dark: ColorFamily(
      color: Color(0xffffe5af),
      onColor: Color(0xff3e2e00),
      colorContainer: Color(0xfffcc419),
      onColorContainer: Color(0xff6c5200),
    ),
    darkMediumContrast: ColorFamily(
      color: Color(0xffffe5af),
      onColor: Color(0xff3e2e00),
      colorContainer: Color(0xfffcc419),
      onColorContainer: Color(0xff6c5200),
    ),
    darkHighContrast: ColorFamily(
      color: Color(0xffffe5af),
      onColor: Color(0xff3e2e00),
      colorContainer: Color(0xfffcc419),
      onColorContainer: Color(0xff6c5200),
    ),
  );

  /// inUse
  static const reserved = ExtendedColor(
    seed: Color(0xffFF6B6B),
    value: Color(0xffFF6B6B),
    light: ColorFamily(
      color: Color(0xffFF6B6B),
      onColor: Color(0xffffffff),
      colorContainer: Color(0xffFF6B6B),
      onColorContainer: Color(0xffffffff),
    ),
    lightMediumContrast: ColorFamily(
      color: Color(0xffFF6B6B),
      onColor: Color(0xffffffff),
      colorContainer: Color(0xffFF6B6B),
      onColorContainer: Color(0xffffffff),
    ),
    lightHighContrast: ColorFamily(
      color: Color(0xffFF6B6B),
      onColor: Color(0xffffffff),
      colorContainer: Color(0xffFF6B6B),
      onColorContainer: Color(0xffffffff),
    ),
    dark: ColorFamily(
      color: Color(0xffFF6B6B),
      onColor: Color(0xffffffff),
      colorContainer: Color(0xffFF6B6B),
      onColorContainer: Color(0xffffffff),
    ),
    darkMediumContrast: ColorFamily(
      color: Color(0xffFF6B6B),
      onColor: Color(0xffffffff),
      colorContainer: Color(0xffFF6B6B),
      onColorContainer: Color(0xffffffff),
    ),
    darkHighContrast: ColorFamily(
      color: Color(0xffFF6B6B),
      onColor: Color(0xffffffff),
      colorContainer: Color(0xffFF6B6B),
      onColorContainer: Color(0xffffffff),
    ),
  );

  List<ExtendedColor> get extendedColors => [success, reserved, inUse];
}

class ExtendedColor {
  final Color seed, value;
  final ColorFamily light;
  final ColorFamily lightHighContrast;
  final ColorFamily lightMediumContrast;
  final ColorFamily dark;
  final ColorFamily darkHighContrast;
  final ColorFamily darkMediumContrast;

  const ExtendedColor({
    required this.seed,
    required this.value,
    required this.light,
    required this.lightHighContrast,
    required this.lightMediumContrast,
    required this.dark,
    required this.darkHighContrast,
    required this.darkMediumContrast,
  });
}

class ColorFamily {
  const ColorFamily({
    required this.color,
    required this.onColor,
    required this.colorContainer,
    required this.onColorContainer,
  });

  final Color color;
  final Color onColor;
  final Color colorContainer;
  final Color onColorContainer;
}

/// ---------- 3) ThemeExtension that stores the *active* families ----------
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final ColorFamily success;
  final ColorFamily reserved;
  final ColorFamily inUse;

  const AppColors({
    required this.success,
    required this.reserved,
    required this.inUse,
  });

  /// Create a theme-ready set for a given brightness (and optional contrast).
  factory AppColors.forBrightness(
    Brightness brightness, {
    String contrast = 'normal', // 'normal' | 'medium' | 'high'
  }) {
    ColorFamily pick(ExtendedColor c) {
      if (brightness == Brightness.light) {
        switch (contrast) {
          case 'medium':
            return c.lightMediumContrast;
          case 'high':
            return c.lightHighContrast;
          default:
            return c.light;
        }
      } else {
        switch (contrast) {
          case 'medium':
            return c.darkMediumContrast;
          case 'high':
            return c.darkHighContrast;
          default:
            return c.dark;
        }
      }
    }

    return AppColors(
      success: pick(MaterialTheme.success),
      reserved: pick(MaterialTheme.reserved),
      inUse: pick(MaterialTheme.inUse),
    );
  }

  @override
  AppColors copyWith({
    ColorFamily? success,
    ColorFamily? reserved,
    ColorFamily? inUse,
  }) => AppColors(
    success: success ?? this.success,
    reserved: reserved ?? this.reserved,
    inUse: inUse ?? this.inUse,
  );

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;

    Color lerpC(Color a, Color b) => Color.lerp(a, b, t)!;

    ColorFamily lerpFam(ColorFamily a, ColorFamily b) => ColorFamily(
      color: lerpC(a.color, b.color),
      onColor: lerpC(a.onColor, b.onColor),
      colorContainer: lerpC(a.colorContainer, b.colorContainer),
      onColorContainer: lerpC(a.onColorContainer, b.onColorContainer),
    );

    return AppColors(
      success: lerpFam(success, other.success),
      reserved: lerpFam(reserved, other.reserved),
      inUse: lerpFam(inUse, other.inUse),
    );
  }
}

/// ---------- 5) Convenience getters ----------
extension AppColorsX on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
  ColorFamily get success => appColors.success;
  ColorFamily get reserved => appColors.reserved;
  ColorFamily get inUse => appColors.inUse;
}
