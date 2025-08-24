import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

TextTheme createTextTheme(
  BuildContext context, {
  String bodyFont = 'Open Sans',
  String displayFont = 'Poppins',
}) {
  final baseTextTheme = Theme.of(context).textTheme;
  final bodyTextTheme = GoogleFonts.openSansTextTheme(baseTextTheme);
  // final displayTextTheme = GoogleFonts.poppinsTextTheme(baseTextTheme);

  return baseTextTheme.copyWith(
    // Body text styles (Open Sans)
    bodyLarge: baseTextTheme.bodyLarge?.copyWith(fontFamily: "Open Sans"),
    bodyMedium: bodyTextTheme.bodyMedium?.copyWith(fontFamily: "Open Sans"),
    bodySmall: bodyTextTheme.bodySmall?.copyWith(fontFamily: "Open Sans"),

    // Label styles with consistent bold weights
    labelLarge: bodyTextTheme.labelLarge?.copyWith(
      fontFamily: "Open Sans",
      fontWeight: FontWeight.bold,
      fontSize: 16,
    ),
    labelMedium: bodyTextTheme.labelMedium?.copyWith(
      fontFamily: "Open Sans",
      fontWeight: FontWeight.bold,
      fontSize: 16,
    ),
    labelSmall: bodyTextTheme.labelSmall?.copyWith(
      fontFamily: "Open Sans",
      fontWeight: FontWeight.w600,
      fontSize: 14,
    ),

    // Display styles (Poppins)
    displayLarge: baseTextTheme.displayLarge?.copyWith(fontFamily: "Poppins"),
    displayMedium: baseTextTheme.displayMedium?.copyWith(fontFamily: "Poppins"),
    displaySmall: baseTextTheme.displaySmall?.copyWith(fontFamily: "Poppins"),

    // Headline styles with bold weight by default
    headlineLarge: baseTextTheme.headlineLarge?.copyWith(fontFamily: "Poppins"),
    headlineMedium: baseTextTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.bold, // Bold by default
      fontFamily: "Poppins",
    ),
    headlineSmall: baseTextTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.bold,
      fontFamily: "Poppins",
    ),
  );
}
