import 'package:flutter/material.dart';

/// Central place for app-wide constants, colors and category icon mapping.
class AppConstants {
  AppConstants._();

  /// Production API base URL (no trailing slash).
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://flutter-backend-iota.vercel.app/api',
  );

  static const Duration requestTimeout = Duration(seconds: 20);

  static const String secureStorageKey = 'finly_jwt_token';
  static const String userCacheKey = 'finly_user';

  static const double radiusS = 12;
  static const double radiusM = 16;
  static const double radiusL = 20;

  static const double pagePadding = 20;
}

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF16A34A);
  static const Color primaryDark = Color(0xFF15803D);
  static const Color primaryLight = Color(0xFFE7F6EC);
  static const Color income = Color(0xFF16A34A);
  static const Color expense = Color(0xFFEA580C);
  static const Color expenseRed = Color(0xFFDC2626);

  // Modern Fintech UI Accent Colors
  static const Color limeAccent = Color(0xFFC6F432); // Vibrant lime green from reference image
  static const Color limeAccentDark = Color(0xFF9ECE0A);
  static const Color purpleBadgeBg = Color(0xFFEDE9FE);
  static const Color purpleBadgeText = Color(0xFF7C3AED);

  static const Color background = Color(0xFFF7F9FA);
  static const Color card = Colors.white;
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color divider = Color(0xFFE5E7EB);

  static const Color gradientStart = Color(0xFF22C55E);
  static const Color gradientEnd = Color(0xFF15803D);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.card,
      ),
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Inter',
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          fontFamily: 'Inter',
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusS),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusS),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusS),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusS),
          borderSide: const BorderSide(color: AppColors.expenseRed, width: 1.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusS),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.divider),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusS),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Inter'),
        ),
      ),
      dividerColor: AppColors.divider,
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontFamily: 'Inter',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusS),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.radiusL)),
        ),
      ),
    );
  }
}

/// Maps category icon names returned by `GET /api/categories` to Material icons.
class CategoryIcons {
  CategoryIcons._();

  static const Map<String, IconData> _icons = {
    'payments': Icons.payments_outlined,
    'storefront': Icons.storefront_outlined,
    'trending_up': Icons.trending_up,
    'work': Icons.work_outline,
    'card_giftcard': Icons.card_giftcard_outlined,
    'add_circle': Icons.add_circle_outline,
    'restaurant': Icons.restaurant_outlined,
    'directions_car': Icons.directions_car_outlined,
    'shopping_bag': Icons.shopping_bag_outlined,
    'receipt_long': Icons.receipt_long_outlined,
    'home': Icons.home_outlined,
    'movie': Icons.movie_outlined,
    'medical_services': Icons.medical_services_outlined,
    'school': Icons.school_outlined,
    'remove_circle': Icons.remove_circle_outline,
    'category': Icons.category_outlined,
  };

  static IconData from(String? name) => _icons[name] ?? Icons.category_outlined;
}