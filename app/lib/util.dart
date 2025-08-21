import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

TextTheme createTextTheme(
  BuildContext context,
  String bodyFontString,
  String displayFontString,
) {
  TextTheme baseTextTheme = Theme.of(context).textTheme;
  // TextTheme bodyTextTheme = GoogleFonts.getTextTheme(
  //   bodyFontString,
  //   baseTextTheme,
  // );
  // TextTheme displayTextTheme = GoogleFonts.getTextTheme(
  //   displayFontString,
  //   baseTextTheme,
  // );
  TextTheme bodyTextTheme = GoogleFonts.openSansTextTheme(baseTextTheme);
  TextTheme displayTextTheme = GoogleFonts.poppinsTextTheme(baseTextTheme);
  TextTheme textTheme = displayTextTheme.copyWith(
    bodyLarge: bodyTextTheme.bodyLarge,
    bodyMedium: bodyTextTheme.bodyMedium,
    bodySmall: bodyTextTheme.bodySmall,
    labelLarge: bodyTextTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
    labelMedium: bodyTextTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.bold,
    ),
    labelSmall: bodyTextTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),

    displayLarge: displayTextTheme.displayLarge,
    displayMedium: displayTextTheme.displayMedium,
    displaySmall: displayTextTheme.displaySmall,

    headlineLarge: displayTextTheme.headlineLarge,
    headlineMedium: displayTextTheme.headlineMedium?.copyWith(
      fontSize: 28,
      fontWeight: FontWeight.bold,
    ),
    headlineSmall: displayTextTheme.headlineSmall?.copyWith(
      fontSize: 22,
      fontWeight: FontWeight.bold,
    ),
  );

  return textTheme;
}
