import 'package:flutter/material.dart';
import '../models/order.dart';

/// Design system constants following ui-ux.md specification
/// Modern flat-material hybrid with tactile depth
class AppDesign {
  AppDesign._();

  // ===== COLOR PALETTE (strictly from ui-ux.md) =====
  static const Color primaryDark = Color(0xFF5D5C61); // charcoal gray — headers, nav bars
  static const Color accentTeal = Color(0xFF379683); // interactive elements, highlights
  static const Color midBlueGray = Color(0xFF7395AE); // secondary buttons, cards, dividers
  static const Color deepSteelBlue = Color(0xFF557A95); // primary buttons, active states
  static const Color warmTaupe = Color(0xFFB1A296); // backgrounds, subtle fills, placeholders

  // Backgrounds
  static const Color pageBackground = Color(0xFFF4F2F0); // warm off-white
  static const Color darkPageBackground = Color(0xFF2C2C2F);
  static const Color darkCardBackground = Color(0xFF3A3A3E);
  static const Color cardBackground = Color.fromRGBO(255, 255, 255, 0.96);

  // Derived colors
  static const Color steelBlueLight = Color(0xFF6088A0); // +10% lightness
  static const Color tealLight = Color(0xFF3DA690); // +10% lightness
  static const Color appBarDark = Color(0xFF4A4A4E); // appBar gradient bottom

  // Opacity variants
  static Color warmTaupeLight = warmTaupe.withOpacity(0.12);
  static Color warmTaupeBg = warmTaupe.withOpacity(0.08);
  static Color midBlueGrayBorder = midBlueGray.withOpacity(0.12);
  static Color midBlueGraySeparator = midBlueGray.withOpacity(0.15);
  static Color deepSteelBlueShadow = deepSteelBlue.withOpacity(0.18);
  static Color deepSteelBlueCardShadow = deepSteelBlue.withOpacity(0.12);

  // Status colors
  static const Color statusNew = Color(0xFF557A95);
  static const Color statusInProgress = Color(0xFF379683);
  static const Color statusCompleted = Color(0xFF4CAF50);
  static const Color statusCancelled = Color(0xFFE57373);

  // ===== SHADOWS (volumetric appearance with layered shadows) =====
  
  // Primary button: 0 4px 12px rgba(85,122,149,0.45) + 0 1px 3px rgba(0,0,0,0.2) + inset highlight
  static List<BoxShadow> primaryButtonShadow = [
    const BoxShadow(
      color: Color.fromRGBO(85, 122, 149, 0.45),
      offset: Offset(0, 4),
      blurRadius: 12,
    ),
    const BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.2),
      offset: Offset(0, 1),
      blurRadius: 3,
    ),
  ];

  // Secondary button: 0 2px 8px rgba(115,149,174,0.35)
  static List<BoxShadow> secondaryButtonShadow = [
    BoxShadow(
      color: midBlueGray.withOpacity(0.35),
      offset: const Offset(0, 2),
      blurRadius: 8,
    ),
  ];

  // Accent button: 0 4px 14px rgba(55,150,131,0.4)
  static List<BoxShadow> accentButtonShadow = [
    const BoxShadow(
      color: Color.fromRGBO(55, 150, 131, 0.4),
      offset: Offset(0, 4),
      blurRadius: 14,
    ),
  ];

  // Card shadow: 0 2px 16px rgba(85,122,149,0.12) + 0 1px 4px rgba(0,0,0,0.06)
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: deepSteelBlueCardShadow,
      offset: const Offset(0, 2),
      blurRadius: 16,
    ),
    const BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.06),
      offset: Offset(0, 1),
      blurRadius: 4,
    ),
  ];

  // Elevated card shadow (8dp)
  static List<BoxShadow> elevatedCardShadow = [
    BoxShadow(
      color: deepSteelBlue.withOpacity(0.22),
      offset: const Offset(0, 4),
      blurRadius: 20,
    ),
    const BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.08),
      offset: Offset(0, 2),
      blurRadius: 6,
    ),
  ];

  // AppBar shadow: 0 2px 12px rgba(0,0,0,0.2)
  static List<BoxShadow> appBarShadow = [
    const BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.2),
      offset: Offset(0, 2),
      blurRadius: 12,
    ),
  ];

  // Input focus glow: 0 0 0 3px rgba(85,122,149,0.18)
  static List<BoxShadow> inputFocusGlow = [
    BoxShadow(
      color: deepSteelBlue.withOpacity(0.18),
      offset: Offset.zero,
      blurRadius: 0,
      spreadRadius: 3,
    ),
  ];

  // Bottom bar shadow
  static List<BoxShadow> bottomBarShadow = [
    const BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.1),
      offset: Offset(0, -2),
      blurRadius: 8,
    ),
  ];

  // FAB shadow
  static List<BoxShadow> fabShadow = [
    const BoxShadow(
      color: Color.fromRGBO(55, 150, 131, 0.4),
      offset: Offset(0, 4),
      blurRadius: 14,
    ),
    const BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.15),
      offset: Offset(0, 2),
      blurRadius: 6,
    ),
  ];

  // ===== GRADIENTS =====
  
  // Primary button: linear-gradient(160deg, #6088A0, #557A95)
  static const LinearGradient primaryButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [steelBlueLight, deepSteelBlue],
    stops: [0.0, 1.0],
  );

  // Accent button: linear-gradient(160deg, #3DA690, #379683)
  static const LinearGradient accentButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [tealLight, accentTeal],
    stops: [0.0, 1.0],
  );

  // AppBar: linear-gradient(180deg, #5D5C61, #4A4A4E)
  static const LinearGradient appBarGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryDark, appBarDark],
  );

  // Shimmer: gradient shimmer from #B1A296 to #7395AE at 30% opacity
  static const LinearGradient shimmerGradient = LinearGradient(
    colors: [warmTaupe, midBlueGray],
    stops: [0.0, 1.0],
  );

  // Card highlight edge (top-left): 1px rgba(255,255,255,0.12)
  static const LinearGradient cardHighlightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.center,
    colors: [
      Color.fromRGBO(255, 255, 255, 0.12),
      Colors.transparent,
    ],
    stops: [0.0, 0.3],
  );

  // ===== BORDER RADIUS =====
  static const double radiusCard = 18;
  static const double radiusListItem = 12;
  static const double radiusButton = 14;
  static const double radiusChip = 8;
  static const double radiusInput = 12;
  static const double radiusPill = 20;

  // ===== SPACING =====
  static const double spacing4 = 4;
  static const double spacing8 = 8;
  static const double spacing12 = 12;
  static const double spacing16 = 16;
  static const double spacing20 = 20;
  static const double spacing24 = 24;

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: spacing20,
    vertical: spacing24,
  );
  static const EdgeInsets cardPadding = EdgeInsets.all(spacing16);
  static const EdgeInsets inputPadding = EdgeInsets.symmetric(
    horizontal: spacing16,
    vertical: spacing12,
  );

  // ===== HEIGHTS =====
  static const double buttonHeight = 52;
  static const double inputHeight = 52;
  static const double bottomBarHeight = 72;
  static const double appBarHeight = 56;

  // ===== TYPOGRAPHY =====
  static const String fontFamily = 'Roboto';

  // Display 28px / Title 20px / Body 15px / Caption 12px
  static const TextStyle displayStyle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: primaryDark,
  );

  static const TextStyle titleStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: primaryDark,
  );

  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: primaryDark,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: primaryDark,
  );

  static const TextStyle captionStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    color: midBlueGray,
  );

  static const TextStyle disabledStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: warmTaupe,
  );

  // ===== INPUT DECORATION =====
  static InputDecoration inputDecoration({
    String? labelText,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    int? maxLines,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: warmTaupe.withOpacity(0.12),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spacing16,
        vertical: spacing12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusInput),
        borderSide: BorderSide(color: midBlueGray.withOpacity(0.2), width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusInput),
        borderSide: BorderSide(color: midBlueGray.withOpacity(0.2), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusInput),
        borderSide: const BorderSide(color: deepSteelBlue, width: 1.5),
      ),
      labelStyle: const TextStyle(color: midBlueGray, fontSize: 15),
      hintStyle: const TextStyle(color: warmTaupe, fontSize: 15),
    );
  }

  // ===== BUTTON STYLES =====
  
  // Primary: gradient + volumetric shadow
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    minimumSize: const Size.fromHeight(buttonHeight),
    backgroundColor: deepSteelBlue,
    foregroundColor: Colors.white,
    elevation: 0,
    shadowColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusButton),
    ),
    padding: const EdgeInsets.symmetric(horizontal: spacing24),
    textStyle: const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    ),
  );

  // Secondary: midBlueGray background
  static ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
    minimumSize: const Size.fromHeight(buttonHeight),
    backgroundColor: midBlueGray,
    foregroundColor: Colors.white,
    elevation: 0,
    shadowColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusButton),
    ),
    padding: const EdgeInsets.symmetric(horizontal: spacing24),
    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
  );

  // Accent: teal background
  static ButtonStyle accentButtonStyle = ElevatedButton.styleFrom(
    minimumSize: const Size.fromHeight(buttonHeight),
    backgroundColor: accentTeal,
    foregroundColor: Colors.white,
    elevation: 0,
    shadowColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusButton),
    ),
    padding: const EdgeInsets.symmetric(horizontal: spacing24),
    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
  );

  // Outlined button
  static ButtonStyle outlinedButtonStyle = OutlinedButton.styleFrom(
    minimumSize: const Size.fromHeight(buttonHeight),
    foregroundColor: deepSteelBlue,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusButton),
    ),
    side: BorderSide(color: midBlueGray.withOpacity(0.3), width: 1.5),
    padding: const EdgeInsets.symmetric(horizontal: spacing24),
    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
  );

  // ===== CARD DECORATION =====
  // Border: 1px solid rgba(115,149,174,0.12)
  // Shadow: 0 2px 16px rgba(85,122,149,0.12), 0 1px 4px rgba(0,0,0,0.06)
  static BoxDecoration cardDecoration = BoxDecoration(
    color: cardBackground,
    borderRadius: BorderRadius.circular(radiusCard),
    border: Border.all(color: midBlueGrayBorder),
    boxShadow: cardShadow,
  );

  static BoxDecoration listItemDecoration = BoxDecoration(
    color: cardBackground,
    borderRadius: BorderRadius.circular(radiusListItem),
    border: Border.all(color: midBlueGrayBorder),
    boxShadow: cardShadow,
  );

  // ===== SEPARATOR =====
  // 1px, rgba(115,149,174,0.15)
  static Widget separator() =>
      Divider(height: 1, thickness: 1, color: midBlueGraySeparator);

  // ===== STATUS COLORS =====
  static Color getStatusColor(String status) {
    switch (status) {
      case 'newOrder':
        return statusNew;
      case 'inProgress':
        return statusInProgress;
      case 'completed':
        return statusCompleted;
      case 'cancelled':
        return statusCancelled;
      default:
        return midBlueGray;
    }
  }

  static Color getOrderStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.newOrder:
        return statusNew;
      case OrderStatus.inProgress:
        return statusInProgress;
      case OrderStatus.completed:
        return statusCompleted;
      case OrderStatus.cancelled:
        return statusCancelled;
    }
  }

  // ===== SKELETON LOADER =====
  // gradient shimmer from #B1A296 to #7395AE at 30% opacity
  static BoxDecoration skeletonDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(radiusListItem),
    gradient: LinearGradient(
      colors: [
        warmTaupe.withOpacity(0.3),
        midBlueGray.withOpacity(0.3),
        warmTaupe.withOpacity(0.3),
      ],
      stops: const [0.0, 0.5, 1.0],
    ),
  );

  // ===== HELPER WIDGETS =====
  
  /// Card with micro-depth: top-left highlight + bottom-right shadow
  static Widget microCard({
    required Widget child,
    Color? backgroundColor,
    double radius = radiusCard,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? cardBackground,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: midBlueGrayBorder),
        boxShadow: cardShadow,
      ),
      child: Stack(
        children: [
          // Top-left highlight edge
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: cardHighlightGradient,
            ),
          ),
          child,
        ],
      ),
    );
  }

  /// Pressed state effect: inset shadow, translateY(1px), brightness(0.94)
  static BoxDecoration pressedDecoration = BoxDecoration(
    color: primaryDark.withOpacity(0.08),
    borderRadius: BorderRadius.circular(radiusListItem),
    boxShadow: [
      const BoxShadow(
        color: Color.fromRGBO(0, 0, 0, 0.15),
        offset: Offset(0, 1),
        blurRadius: 2,
      ),
      BoxShadow(
        color: deepSteelBlue.withOpacity(0.1),
        offset: Offset.zero,
        blurRadius: 0,
        spreadRadius: 0,
      ),
    ],
  );
}
