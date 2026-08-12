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

/// Maps category names and icon keys to Material icons.
class CategoryIcons {
  CategoryIcons._();

  static const Map<String, IconData> _map = {
    // Icon String Keys
    'payments': Icons.payments_outlined,
    'storefront': Icons.storefront_outlined,
    'trending_up': Icons.trending_up_rounded,
    'work': Icons.work_outline_rounded,
    'card_giftcard': Icons.card_giftcard_outlined,
    'add_circle': Icons.add_circle_outline_rounded,
    'restaurant': Icons.restaurant_rounded,
    'directions_car': Icons.directions_car_outlined,
    'shopping_bag': Icons.shopping_bag_outlined,
    'receipt_long': Icons.receipt_long_outlined,
    'home': Icons.home_outlined,
    'movie': Icons.local_movies_outlined,
    'medical_services': Icons.medical_services_outlined,
    'school': Icons.school_outlined,
    'remove_circle': Icons.remove_circle_outline_rounded,
    'category': Icons.category_outlined,

    // Thai Category Names
    'อาหารและเครื่องดื่ม': Icons.restaurant_rounded,
    'ค่าอาหาร': Icons.restaurant_rounded,
    'อาหาร': Icons.restaurant_rounded,
    'เครื่องดื่ม': Icons.local_cafe_rounded,
    'กาแฟ': Icons.local_cafe_rounded,
    'ช้อปปิ้ง': Icons.shopping_bag_outlined,
    'ซื้อของ': Icons.shopping_cart_outlined,
    'การเดินทาง': Icons.directions_car_outlined,
    'ค่าเดินทาง': Icons.directions_subway_rounded,
    'น้ำมัน': Icons.local_gas_station_rounded,
    'เงินเดือน': Icons.payments_rounded,
    'รายได้': Icons.account_balance_wallet_rounded,
    'โบนัส': Icons.stars_rounded,
    'ฟรีแลนซ์': Icons.laptop_mac_rounded,
    'ธุรกิจส่วนตัว': Icons.storefront_rounded,
    'ลงทุน': Icons.trending_up_rounded,
    'การลงทุน': Icons.show_chart_rounded,
    'ปันผล': Icons.pie_chart_outline_rounded,
    'ค่าน้ำค่าไฟ': Icons.bolt_rounded,
    'ค่าบิล': Icons.receipt_long_rounded,
    'บิลและค่าใช้จ่าย': Icons.receipt_long_rounded,
    'ที่อยู่อาศัย': Icons.home_rounded,
    'ค่าเช่า': Icons.apartment_rounded,
    'ความบันเทิง': Icons.local_movies_rounded,
    'หนัง/ซีรีส์': Icons.movie_outlined,
    'เกม': Icons.sports_esports_rounded,
    'สุขภาพ': Icons.medical_services_outlined,
    'การรักษา': Icons.local_hospital_rounded,
    'ยา': Icons.medication_rounded,
    'การศึกษา': Icons.school_rounded,
    'เรียนหนังสือ': Icons.menu_book_rounded,
    'ของขวัญ': Icons.card_giftcard_rounded,
    'บริจาค': Icons.volunteer_activism_rounded,
    'ท่องเที่ยว': Icons.flight_takeoff_rounded,
    'พักผ่อน': Icons.beach_access_rounded,
    'ประกัน': Icons.verified_user_rounded,
    'ผ่อนชำระ': Icons.credit_card_rounded,
    'เงินออม': Icons.savings_rounded,
    'รายรับอื่นๆ': Icons.add_circle_outline_rounded,
    'รายจ่ายอื่นๆ': Icons.remove_circle_outline_rounded,
    'อื่นๆ': Icons.category_rounded,

    // English Category Names
    'food & dining': Icons.restaurant_rounded,
    'food': Icons.restaurant_rounded,
    'dining': Icons.restaurant_rounded,
    'coffee': Icons.local_cafe_rounded,
    'shopping': Icons.shopping_bag_outlined,
    'groceries': Icons.shopping_cart_outlined,
    'transportation': Icons.directions_car_outlined,
    'transport': Icons.directions_subway_rounded,
    'travel': Icons.flight_takeoff_rounded,
    'gas': Icons.local_gas_station_rounded,
    'salary': Icons.payments_rounded,
    'income': Icons.account_balance_wallet_rounded,
    'bonus': Icons.stars_rounded,
    'freelance': Icons.laptop_mac_rounded,
    'business': Icons.storefront_rounded,
    'investment': Icons.trending_up_rounded,
    'utilities': Icons.bolt_rounded,
    'bills': Icons.receipt_long_rounded,
    'housing': Icons.home_rounded,
    'rent': Icons.apartment_rounded,
    'entertainment': Icons.local_movies_rounded,
    'games': Icons.sports_esports_rounded,
    'health': Icons.medical_services_outlined,
    'medical': Icons.local_hospital_rounded,
    'education': Icons.school_rounded,
    'gift': Icons.card_giftcard_rounded,
    'insurance': Icons.verified_user_rounded,
    'savings': Icons.savings_rounded,
    'others': Icons.category_rounded,
  };

  static IconData from(String? name) {
    if (name == null || name.trim().isEmpty) {
      return Icons.category_rounded;
    }
    final key = name.trim().toLowerCase();

    // 1. Direct match
    if (_map.containsKey(key)) return _map[key]!;

    // 2. Keyword partial match
    if (key.contains('อาหาร') || key.contains('กิน') || key.contains('food') || key.contains('dine')) {
      return Icons.restaurant_rounded;
    }
    if (key.contains('กาแฟ') || key.contains('น้ำ') || key.contains('coffee') || key.contains('drink')) {
      return Icons.local_cafe_rounded;
    }
    if (key.contains('ช้อป') || key.contains('ซื้อ') || key.contains('shop') || key.contains('buy') || key.contains('store')) {
      return Icons.shopping_bag_outlined;
    }
    if (key.contains('เดินทาง') || key.contains('รถ') || key.contains('ขับ') || key.contains('car') || key.contains('bus') || key.contains('taxi')) {
      return Icons.directions_car_outlined;
    }
    if (key.contains('บิน') || key.contains('เที่ยว') || key.contains('flight') || key.contains('trip') || key.contains('hotel')) {
      return Icons.flight_takeoff_rounded;
    }
    if (key.contains('เงินเดือน') || key.contains('ค่าจ้าง') || key.contains('salary') || key.contains('wage')) {
      return Icons.payments_rounded;
    }
    if (key.contains('โบนัส') || key.contains('รางวัล') || key.contains('bonus') || key.contains('award')) {
      return Icons.stars_rounded;
    }
    if (key.contains('บิล') || key.contains('ไฟ') || key.contains('น้ำ') || key.contains('bill') || key.contains('utility')) {
      return Icons.receipt_long_rounded;
    }
    if (key.contains('บ้าน') || key.contains('คอนโด') || key.contains('ห้อง') || key.contains('home') || key.contains('house') || key.contains('rent')) {
      return Icons.home_rounded;
    }
    if (key.contains('หนัง') || key.contains('เกม') || key.contains('บันเทิง') || key.contains('movie') || key.contains('game')) {
      return Icons.local_movies_rounded;
    }
    if (key.contains('ยา') || key.contains('หมอ') || key.contains('ป่วย') || key.contains('health') || key.contains('medical')) {
      return Icons.medical_services_outlined;
    }
    if (key.contains('เรียน') || key.contains('การศึกษา') || key.contains('school') || key.contains('edu') || key.contains('book')) {
      return Icons.school_rounded;
    }
    if (key.contains('หุ้น') || key.contains('กองทุน') || key.contains('ลงทุน') || key.contains('invest') || key.contains('stock')) {
      return Icons.trending_up_rounded;
    }
    if (key.contains('ของขวัญ') || key.contains('gift')) {
      return Icons.card_giftcard_rounded;
    }
    if (key.contains('ออม') || key.contains('ประหยัด') || key.contains('save') || key.contains('saving')) {
      return Icons.savings_rounded;
    }

    return Icons.category_rounded;
  }
}