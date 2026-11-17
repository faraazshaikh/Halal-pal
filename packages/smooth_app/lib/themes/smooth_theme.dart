import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smooth_app/generic_lib/design_constants.dart';
import 'package:smooth_app/themes/color_provider.dart';
import 'package:smooth_app/themes/color_schemes.dart';
import 'package:smooth_app/themes/contrast_provider.dart';
import 'package:smooth_app/themes/smooth_theme_colors.dart';
import 'package:smooth_app/themes/theme_provider.dart';

class SmoothTheme {
  const SmoothTheme._();

  static const double ADDITIONAL_OPACITY_FOR_DARK = .3;
  static const double SECONDARY_COLOR_SHADE_VALUE = 0.4;

  static ThemeData getThemeData(
    Brightness brightness,
    ThemeProvider themeProvider,
    ColorProvider Function() colorProvider,
    TextContrastProvider Function() textContrastProvider,
  ) {
    final bool lightTheme = brightness == Brightness.light;
    ColorScheme myColorScheme;

    if (lightTheme) {
      myColorScheme = lightColorScheme;
    } else {
      if (themeProvider.currentTheme == THEME_AMOLED) {
        final ColorProvider colorNotifier = colorProvider();

        myColorScheme = trueDarkColorScheme.copyWith(
          primary: getColorValue(colorNotifier.currentColor),
          secondary: getShade(
            getColorValue(colorNotifier.currentColor),
            darker: true,
            value: SECONDARY_COLOR_SHADE_VALUE,
          ),
        );
      } else {
        myColorScheme = darkColorScheme;
      }
    }

    final SmoothColorsThemeExtension smoothExtension =
        SmoothColorsThemeExtension.defaultValues(lightTheme);

    final TextTheme textTheme = brightness == Brightness.dark
        ? getTextTheme(themeProvider, textContrastProvider)
        : _TEXT_THEME;

    return ThemeData(
      fontFamily: 'Inter',
      // Apple-style: iOS page transitions, no Material ripple, soft shapes.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
      ),
      primaryColor: smoothExtension.primaryBlack,
      extensions: <ThemeExtension<dynamic>>[smoothExtension],
      colorScheme: myColorScheme,
      canvasColor: themeProvider.currentTheme == THEME_AMOLED
          ? myColorScheme.surface
          : null,
      scaffoldBackgroundColor:
          themeProvider.currentTheme == THEME_DARK ||
              (!lightTheme && themeProvider.currentTheme != THEME_AMOLED)
          ? const Color(0xFF000000)
          : (lightTheme ? const Color(0xFFF6F3EA) : null),
      shadowColor: brightness == Brightness.light
          ? Colors.black54
          : Colors.white12,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          elevation: const WidgetStatePropertyAll<double>(0),
          shape: WidgetStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          textStyle: const WidgetStatePropertyAll<TextStyle>(
            TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.2),
          ),
          backgroundColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) => states.contains(WidgetState.disabled)
                ? Colors.grey
                : myColorScheme.primary,
          ),
          foregroundColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) => states.contains(WidgetState.disabled)
                ? Colors.white
                : myColorScheme.onPrimary,
          ),
          iconColor: WidgetStateProperty.all<Color>(myColorScheme.onPrimary),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: lightTheme
            ? smoothExtension.primaryDark
            : myColorScheme.primary,
        foregroundColor: myColorScheme.onPrimary,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: myColorScheme.surface,
        foregroundColor: myColorScheme.onSurface,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: textTheme.titleLarge,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFECECEC),
        space: 1.0,
      ),
      dividerColor: const Color(0xFFDFDFDF),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: myColorScheme.secondary,
      ),
      iconTheme: IconThemeData(color: myColorScheme.onSurface),
      snackBarTheme: SnackBarThemeData(
        contentTextStyle: _TEXT_THEME.bodyMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        actionTextColor: Colors.white,
        actionBackgroundColor: smoothExtension.primaryDark,
        backgroundColor: smoothExtension.primaryBlack,
      ),
      bannerTheme: MaterialBannerThemeData(
        contentTextStyle: TextStyle(color: myColorScheme.onSecondary),
        backgroundColor: myColorScheme.secondary,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.disabled)) {
            return null;
          }
          if (states.contains(WidgetState.selected)) {
            return lightTheme
                ? smoothExtension.primarySemiDark
                : smoothExtension.primaryNormal;
          }
          return null;
        }),
        side: BorderSide(
          color: lightTheme
              ? smoothExtension.primaryBlack
              : smoothExtension.primarySemiDark,
          width: 2.0,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3.0)),
        checkColor: const WidgetStatePropertyAll<Color>(Colors.white),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.disabled)) {
            return null;
          }
          if (states.contains(WidgetState.selected)) {
            return myColorScheme.primary;
          }
          return null;
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll<Color>(Colors.white),
        trackColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF34C759); // iOS system green
          }
          return lightTheme
              ? const Color(0xFFE5E5EA)
              : const Color(0xFF39393D);
        }),
        trackOutlineColor: const WidgetStatePropertyAll<Color>(
          Colors.transparent,
        ),
      ),
    );
  }

  static TextTheme getTextTheme(
    ThemeProvider themeProvider,
    TextContrastProvider Function() textContrastProvider,
  ) {
    final Color contrastLevel = themeProvider.currentTheme == THEME_AMOLED
        ? getTextContrastLevel(textContrastProvider().currentContrastLevel)
        : Colors.white;

    return _TEXT_THEME.copyWith(
      displayMedium: _TEXT_THEME.displayMedium?.copyWith(color: contrastLevel),
      headlineMedium: _TEXT_THEME.headlineMedium?.copyWith(
        color: contrastLevel,
      ),
      bodyMedium: _TEXT_THEME.bodyMedium?.copyWith(color: contrastLevel),
      displaySmall: _TEXT_THEME.bodySmall?.copyWith(color: contrastLevel),
      titleLarge: _TEXT_THEME.titleLarge?.copyWith(color: contrastLevel),
      titleMedium: _TEXT_THEME.titleMedium?.copyWith(color: contrastLevel),
      titleSmall: _TEXT_THEME.titleSmall?.copyWith(color: contrastLevel),
    );
  }

  static const TextTheme _TEXT_THEME = TextTheme(
    displayLarge: TextStyle(
      fontSize: 34.0,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.8,
    ),
    displayMedium: TextStyle(
      fontSize: 26.0,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.6,
      color: Colors.black,
    ),
    displaySmall: TextStyle(
      fontSize: 20.0,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.4,
    ),
    headlineMedium: TextStyle(
      fontSize: 20.0,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
      color: Colors.black,
    ),
    titleLarge: TextStyle(
      fontSize: 17.0,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.4,
    ),
    bodyMedium: TextStyle(fontSize: 15.0, letterSpacing: -0.2),
    titleMedium: TextStyle(fontSize: 15.0, letterSpacing: -0.2),
    titleSmall: TextStyle(fontSize: 13.0, letterSpacing: -0.1),
  );

  static MaterialColor getMaterialColorFromColor(Color color) {
    final Map<int, Color> colorShades = <int, Color>{
      50: getShade(color, value: 0.5),
      100: getShade(color, value: 0.4),
      200: getShade(color, value: 0.3),
      300: getShade(color, value: 0.2),
      400: getShade(color, value: 0.1),
      500: color,
      600: getShade(color, value: 0.1, darker: true),
      700: getShade(color, value: 0.15, darker: true),
      800: getShade(color, value: 0.2, darker: true),
      900: getShade(color, value: 0.25, darker: true),
    };
    return MaterialColor(color.intValue, colorShades);
  }

  //From: https://stackoverflow.com/a/58604669/13313941
  static Color getShade(Color color, {bool darker = false, double value = .1}) {
    assert(value >= 0 && value <= 1);

    final HSLColor hsl = HSLColor.fromColor(color);
    final HSLColor hslDark = hsl.withLightness(
      (darker ? (hsl.lightness - value) : (hsl.lightness + value)).clamp(
        0.0,
        1.0,
      ),
    );

    return hslDark.toColor();
  }
}

extension SmoothColorExtension on Color {
  /// ignore: deprecated_member_use
  /// [Color.value] is deprecated, use [Color.intValue] instead
  int get intValue {
    final int a = (this.a * 255).round();
    final int r = (this.r * 255).round();
    final int g = (this.g * 255).round();
    final int b = (this.b * 255).round();

    // Combine the components into a single int using bit shifting
    return (a << 24) | (r << 16) | (g << 8) | b;
  }
}
