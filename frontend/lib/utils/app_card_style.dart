import 'package:flutter/material.dart';

/// AppCardStyle
/// ────────────
/// Standardized card styling parameters, paddings, borders, shadows, and margins
/// to maintain 100% visual consistency across all screens and cards in the app.
class AppCardStyle {
  AppCardStyle._();

  static const double borderRadiusValue = 16.0;
  static const BorderRadius borderRadius = BorderRadius.all(
    Radius.circular(borderRadiusValue),
  );

  static const Color borderColor = Color(0xFFE2E8F0);
  static const BorderSide borderSide = BorderSide(
    color: borderColor,
    width: 1.2,
  );

  static const EdgeInsets cardMargin = EdgeInsets.symmetric(
    vertical: 6.0,
    horizontal: 16.0,
  );
  static const EdgeInsets cardPadding = EdgeInsets.all(14.0);
  static const EdgeInsets cardInnerPadding = EdgeInsets.all(16.0);

  static const double chipSpacing = 6.0;
  static const double chipRunSpacing = 6.0;

  static BoxDecoration defaultCardDecoration({
    Color backgroundColor = Colors.white,
    Color borderColor = borderColor,
    double borderRadius = borderRadiusValue,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: borderColor, width: 1.2),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
