import 'package:flutter/material.dart';

class Responsive {
  // Breakpoints
  static const double mobileSmall = 320;
  static const double mobileMedium = 375;
  static const double mobileLarge = 414;
  static const double tablet = 600;
  static const double tabletLarge = 720;
  static const double desktop = 1024;
  static const double desktopLarge = 1440;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < tablet;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= tablet && width < desktop;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktop;

  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  static double fontSize(BuildContext context, double base) {
    final width = screenWidth(context);
    if (width < mobileMedium) return base * 0.85;
    if (width < tablet) return base;
    if (width < desktop) return base * 1.1;
    return base * 1.2;
  }

  static double padding(BuildContext context) {
    final width = screenWidth(context);
    if (width < mobileMedium) return 12.0;
    if (width < tablet) return 16.0;
    return 24.0;
  }

  static int gridCrossAxisCount(BuildContext context) {
    final width = screenWidth(context);
    if (width < mobileMedium) return 1;
    if (width < tablet) return 2;
    if (width < desktop) return 3;
    return 4;
  }
}
