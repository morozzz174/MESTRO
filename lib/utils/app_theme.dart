import 'package:flutter/material.dart';
import '../models/order.dart';

/// Modern Material 3 Design System
/// Supports light and dark themes with unified design tokens
class AppDesign {
  AppDesign._();

  // ===== NEW MODERN COLOR PALETTE =====

  // Primary colors - Deep Indigo/Violet scheme
  static const Color primaryLight = Color(0xFF6366F1);
  static const Color primaryDark = Color(0xFF818CF8);
  static const Color primaryContainer = Color(0xFFE0E7FF);
  static const Color onPrimaryContainer = Color(0xFF1E1B4B);

  // Secondary colors - Teal accent
  static const Color secondaryLight = Color(0xFF14B8A6);
  static const Color secondaryDark = Color(0xFF2DD4BF);
  static const Color secondaryContainer = Color(0xFFCCFBF1);

  // Surface colors - Light theme
  static const Color surfaceLight = Color(0xFFFAFAFA);
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color elevatedLight = Color(0xFFFFFFFF);

  // Surface colors - Dark theme
  static const Color surfaceDark = Color(0xFF1E1E2E);
  static const Color backgroundDark = Color(0xFF0F0F17);
  static const Color cardDark = Color(0xFF252536);
  static const Color elevatedDark = Color(0xFF2D2D42);

  // Text colors - Light theme
  static const Color textPrimaryLight = Color(0xFF1E293B);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textTertiaryLight = Color(0xFF94A3B8);

  // Text colors - Dark theme
  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textTertiaryDark = Color(0xFF64748B);

  // Status colors
  static const Color statusNew = Color(0xFF6366F1);
  static const Color statusInProgress = Color(0xFFF59E0B);
  static const Color statusCompleted = Color(0xFF10B981);
  static const Color statusCancelled = Color(0xFFEF4444);
  static const Color statusPaused = Color(0xFF8B5CF6);

  // Gradient colors
  static const Color gradientStart = Color(0xFF6366F1);
  static const Color gradientEnd = Color(0xFF8B5CF6);
  static const Color gradientTealStart = Color(0xFF14B8A6);
  static const Color gradientTealEnd = Color(0xFF06B6D4);

  // Divider/Border colors
  static const Color dividerLight = Color(0xFFE2E8F0);
  static const Color dividerDark = Color(0xFF334155);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF475569);

  // ===== SHADOWS =====

  static List<BoxShadow> get cardShadowLight => [
    const BoxShadow(
      color: Color(0x0A000000),
      offset: Offset(0, 1),
      blurRadius: 3,
    ),
    const BoxShadow(
      color: Color(0x0A000000),
      offset: Offset(0, 4),
      blurRadius: 6,
    ),
  ];

  static List<BoxShadow> get cardShadowDark => [
    const BoxShadow(
      color: Color(0x40000000),
      offset: Offset(0, 1),
      blurRadius: 3,
    ),
    const BoxShadow(
      color: Color(0x20000000),
      offset: Offset(0, 4),
      blurRadius: 6,
    ),
  ];

  static List<BoxShadow> get elevatedShadowLight => [
    const BoxShadow(
      color: Color(0x1A6366F1),
      offset: Offset(0, 4),
      blurRadius: 12,
    ),
    const BoxShadow(
      color: Color(0x0A000000),
      offset: Offset(0, 2),
      blurRadius: 4,
    ),
  ];

  static List<BoxShadow> get elevatedShadowDark => [
    const BoxShadow(
      color: Color(0x406366F1),
      offset: Offset(0, 4),
      blurRadius: 12,
    ),
    const BoxShadow(
      color: Color(0x40000000),
      offset: Offset(0, 2),
      blurRadius: 4,
    ),
  ];

  static List<BoxShadow> get fabShadowLight => [
    const BoxShadow(
      color: Color(0x406366F1),
      offset: Offset(0, 6),
      blurRadius: 16,
    ),
    const BoxShadow(
      color: Color(0x20000000),
      offset: Offset(0, 3),
      blurRadius: 8,
    ),
  ];

  static List<BoxShadow> get fabShadowDark => [
    const BoxShadow(
      color: Color(0x60818CF8),
      offset: Offset(0, 6),
      blurRadius: 16,
    ),
    const BoxShadow(
      color: Color(0x40000000),
      offset: Offset(0, 3),
      blurRadius: 8,
    ),
  ];

  static List<BoxShadow> get fabShadow => fabShadowLight;

  // Simple decorations without isDark parameter for backward compatibility
  static BoxDecoration get cardDecorationSimple => BoxDecoration(
    color: cardLight,
    borderRadius: BorderRadius.circular(radiusLg),
    border: Border.all(color: dividerLight, width: 1),
    boxShadow: cardShadowLight,
  );

  static BoxDecoration get listItemDecorationSimple => BoxDecoration(
    color: cardLight,
    borderRadius: BorderRadius.circular(radiusMd),
    border: Border.all(color: dividerLight, width: 1),
  );

  // Button styles for backward compatibility
  static ButtonStyle get accentButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: secondaryLight,
    foregroundColor: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusMd),
    ),
    padding: const EdgeInsets.symmetric(horizontal: spacing6),
  );

  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: primaryLight,
    foregroundColor: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusMd),
    ),
    padding: const EdgeInsets.symmetric(horizontal: spacing6),
  );

  // ===== GRADIENTS =====

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientStart, gradientEnd],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientTealStart, gradientTealEnd],
  );

  static const LinearGradient subtleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryContainer, Color(0xFFF1F5F9)],
  );

  // ===== BORDER RADIUS =====
  static const double radiusXs = 6;
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radius2xl = 24;
  static const double radiusFull = 999;

  // ===== SPACING =====
  static const double spacing1 = 4;
  static const double spacing2 = 8;
  static const double spacing3 = 12;
  static const double spacing4 = 16;
  static const double spacing5 = 20;
  static const double spacing6 = 24;
  static const double spacing8 = 32;
  static const double spacing10 = 40;

  // Old spacing values for backward compatibility
  static const double spacing16 = 16;
  static const double spacing12 = 12;
  static const double spacing20 = 20;
  static const double spacing24 = 24;

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: spacing5,
    vertical: spacing6,
  );
  static const EdgeInsets cardPadding = EdgeInsets.all(spacing4);
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: spacing4,
    vertical: spacing3,
  );

  // ===== COMPONENT HEIGHTS =====
  static const double buttonHeight = 52;
  static const double buttonHeightSm = 40;
  static const double inputHeight = 52;
  static const double bottomNavHeight = 80;
  static const double appBarHeight = 60;
  static const double chipHeight = 32;

  // ===== LIGHT THEME =====

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.light(
      primary: primaryLight,
      onPrimary: Colors.white,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      secondary: secondaryLight,
      onSecondary: Colors.white,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: const Color(0xFF134E4A),
      surface: surfaceLight,
      onSurface: textPrimaryLight,
      surfaceContainerHighest: cardLight,
      onSurfaceVariant: textSecondaryLight,
      error: statusCancelled,
      onError: Colors.white,
      outline: borderLight,
      shadow: Colors.black,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundLight,
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundLight,
        foregroundColor: textPrimaryLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimaryLight,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardLight,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: dividerLight, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryLight,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: spacing6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryLight,
          minimumSize: const Size(double.infinity, buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: spacing6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          side: const BorderSide(color: borderLight, width: 1.5),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryLight,
          padding: const EdgeInsets.symmetric(horizontal: spacing4),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: secondaryLight,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacing4,
          vertical: spacing3,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: dividerLight, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: dividerLight, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: statusCancelled, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textSecondaryLight, fontSize: 15),
        hintStyle: const TextStyle(color: textTertiaryLight, fontSize: 15),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceLight,
        selectedColor: primaryContainer,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(
          horizontal: spacing2,
          vertical: spacing1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
        side: const BorderSide(color: dividerLight, width: 1),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardLight,
        elevation: 0,
        indicatorColor: primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: primaryLight,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textSecondaryLight,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryLight, size: 24);
          }
          return const IconThemeData(color: textSecondaryLight, size: 24);
        }),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardLight,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radius2xl)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: dividerLight,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: listItemPadding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1E293B),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ===== DARK THEME =====

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.dark(
      primary: primaryDark,
      onPrimary: const Color(0xFF1E1B4B),
      primaryContainer: const Color(0xFF312E81),
      onPrimaryContainer: primaryDark,
      secondary: secondaryDark,
      onSecondary: const Color(0xFF042F2E),
      secondaryContainer: const Color(0xFF134E4A),
      onSecondaryContainer: secondaryDark,
      surface: surfaceDark,
      onSurface: textPrimaryDark,
      surfaceContainerHighest: cardDark,
      onSurfaceVariant: textSecondaryDark,
      error: statusCancelled,
      onError: Colors.white,
      outline: borderDark,
      shadow: Colors.black,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundDark,
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundDark,
        foregroundColor: textPrimaryDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimaryDark,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: dividerDark, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDark,
          foregroundColor: const Color(0xFF1E1B4B),
          elevation: 0,
          minimumSize: const Size(double.infinity, buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: spacing6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryDark,
          minimumSize: const Size(double.infinity, buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: spacing6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          side: const BorderSide(color: borderDark, width: 1.5),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryDark,
          padding: const EdgeInsets.symmetric(horizontal: spacing4),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: secondaryDark,
        foregroundColor: const Color(0xFF042F2E),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacing4,
          vertical: spacing3,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: dividerDark, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: dividerDark, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: primaryDark, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: statusCancelled, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textSecondaryDark, fontSize: 15),
        hintStyle: const TextStyle(color: textTertiaryDark, fontSize: 15),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceDark,
        selectedColor: const Color(0xFF312E81),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(
          horizontal: spacing2,
          vertical: spacing1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
        side: const BorderSide(color: dividerDark, width: 1),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardDark,
        elevation: 0,
        indicatorColor: const Color(0xFF312E81),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: primaryDark,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textSecondaryDark,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryDark, size: 24);
          }
          return const IconThemeData(color: textSecondaryDark, size: 24);
        }),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardDark,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radius2xl)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: dividerDark,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: listItemPadding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: elevatedDark,
        contentTextStyle: const TextStyle(color: textPrimaryDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ===== DECORATIONS =====

  static BoxDecoration cardDecoration({bool isDark = false}) => BoxDecoration(
    color: isDark ? cardDark : cardLight,
    borderRadius: BorderRadius.circular(radiusLg),
    border: Border.all(color: isDark ? dividerDark : dividerLight, width: 1),
    boxShadow: isDark ? cardShadowDark : cardShadowLight,
  );

  static BoxDecoration elevatedCardDecoration({bool isDark = false}) =>
      BoxDecoration(
        color: isDark ? elevatedDark : elevatedLight,
        borderRadius: BorderRadius.circular(radiusLg),
        boxShadow: isDark ? elevatedShadowDark : elevatedShadowLight,
      );

  static BoxDecoration listItemDecoration({bool isDark = false}) =>
      BoxDecoration(
        color: isDark ? cardDark : cardLight,
        borderRadius: BorderRadius.circular(radiusMd),
        border: Border.all(
          color: isDark ? dividerDark : dividerLight,
          width: 1,
        ),
      );

  static BoxDecoration chipDecoration({
    required Color color,
    bool isDark = false,
  }) => BoxDecoration(
    color: color.withOpacity(isDark ? 0.2 : 0.12),
    borderRadius: BorderRadius.circular(radiusSm),
  );

  // ===== STATUS HELPERS =====

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
      case 'paused':
        return statusPaused;
      default:
        return textSecondaryLight;
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

  static String getStatusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.newOrder:
        return 'Новый';
      case OrderStatus.inProgress:
        return 'В работе';
      case OrderStatus.completed:
        return 'Завершён';
      case OrderStatus.cancelled:
        return 'Отменён';
    }
  }

  static IconData getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.newOrder:
        return Icons.fiber_new_rounded;
      case OrderStatus.inProgress:
        return Icons.pending_rounded;
      case OrderStatus.completed:
        return Icons.check_circle_rounded;
      case OrderStatus.cancelled:
        return Icons.cancel_rounded;
    }
  }

  // ===== TYPOGRAPHY =====

  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );
  static const TextStyle displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
  );
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
  );
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
  );
  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );
  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
  );
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
  );

  // ===== BACKWARD COMPATIBILITY =====

  static const Color accentTeal = secondaryLight;
  static const Color deepSteelBlue = primaryLight;
  static const Color warmTaupe = Color(0xFFB1A296);
  static const Color cardBackground = cardLight;
  static const Color pageBackground = backgroundLight;
  static const Color midBlueGray = textSecondaryLight;
  static const Color steelBlueLight = primaryLight;
  static const Color tealLight = secondaryLight;

  static const double radiusCard = radiusLg;
  static const double radiusListItem = radiusMd;
  static const double radiusButton = radiusMd;
  static const double radiusChip = radiusSm;
  static const double radiusInput = radiusMd;
  static const double radiusPill = radiusFull;

  // Backward compatibility spacing aliases (old names)
  static double get spacing8old => spacing2;
  static double get spacing12old => spacing3;
  static double get spacing16old => spacing4;
  static double get spacing20old => spacing5;
  static double get spacing24old => spacing6;

  static const double bottomBarHeight = bottomNavHeight;

  static const TextStyle displayStyle = displayMedium;
  static const TextStyle titleStyle = titleLarge;
  static const TextStyle subtitleStyle = titleMedium;
  static const TextStyle bodyStyle = bodyLarge;
  static const TextStyle captionStyle = caption;
  static const TextStyle disabledStyle = labelLarge;

  static const LinearGradient appBarGradient = primaryGradient;
  static const LinearGradient primaryButtonGradient = primaryGradient;
  static const LinearGradient accentButtonGradient = secondaryGradient;

  static List<BoxShadow> get appBarShadow => cardShadowLight;
  static List<BoxShadow> get bottomBarShadow => cardShadowLight;
  static List<BoxShadow> get primaryButtonShadow => elevatedShadowLight;
  static List<BoxShadow> get secondaryButtonShadow => cardShadowLight;
  static List<BoxShadow> get accentButtonShadow => elevatedShadowLight;
  static List<BoxShadow> get cardShadow => cardShadowLight;
  static List<BoxShadow> get elevatedCardShadow => elevatedShadowLight;

  static Color warmTaupeLight = warmTaupe.withOpacity(0.12);
  static Color warmTaupeBg = warmTaupe.withOpacity(0.08);
  static Color midBlueGrayBorder = midBlueGray.withOpacity(0.12);
  static Color midBlueGraySeparator = midBlueGray.withOpacity(0.15);
  static Color deepSteelBlueShadow = deepSteelBlue.withOpacity(0.18);
  static Color deepSteelBlueCardShadow = deepSteelBlue.withOpacity(0.12);

  static BoxDecoration skeletonDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(radiusMd),
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

  static Widget statusChip({
    required String label,
    required Color color,
    IconData? icon,
    bool isDark = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: spacing2,
        vertical: spacing1,
      ),
      decoration: chipDecoration(color: color, isDark: isDark),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static Widget primaryButton({
    required String label,
    VoidCallback? onPressed,
    IconData? icon,
    bool isLoading = false,
    bool isDark = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: primaryGradient,
        borderRadius: BorderRadius.circular(radiusMd),
        boxShadow: isDark ? elevatedShadowDark : elevatedShadowLight,
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          disabledBackgroundColor: primaryLight.withOpacity(0.6),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: spacing2),
                  ],
                  Text(label),
                ],
              ),
      ),
    );
  }

  static Widget secondaryButton({
    required String label,
    VoidCallback? onPressed,
    IconData? icon,
    bool isDark = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? surfaceDark : primaryContainer,
        borderRadius: BorderRadius.circular(radiusMd),
      ),
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? primaryDark : primaryLight,
          side: BorderSide(
            color: isDark ? borderDark : primaryLight,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20),
              const SizedBox(width: spacing2),
            ],
            Text(label),
          ],
        ),
      ),
    );
  }

  static Widget separator({bool isDark = false}) => Divider(
    height: 1,
    thickness: 1,
    color: isDark ? dividerDark : dividerLight,
  );

  static Widget emptyState({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? action,
    bool isDark = false,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(spacing8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(spacing5),
              decoration: BoxDecoration(
                color: (isDark ? primaryDark : primaryLight).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: isDark ? primaryDark : primaryLight,
              ),
            ),
            const SizedBox(height: spacing5),
            Text(
              title,
              style: (isDark ? titleLarge : headlineMedium).copyWith(
                color: isDark ? textPrimaryDark : textPrimaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: spacing2),
              Text(
                subtitle,
                style: bodyMedium.copyWith(
                  color: isDark ? textSecondaryDark : textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[const SizedBox(height: spacing5), action],
          ],
        ),
      ),
    );
  }
}
