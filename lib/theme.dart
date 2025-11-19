import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 主題模式 provider
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadThemeMode();
  }

  void _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeIndex = prefs.getInt('theme_mode') ?? 0;
      state = ThemeMode.values[themeModeIndex];
    } catch (e) {
      // 如果 SharedPreferences 失敗，使用系統預設
      state = ThemeMode.system;
    }
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
    _saveThemeMode(mode);
  }

  void _saveThemeMode(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('theme_mode', mode.index);
    } catch (e) {
      // 忽略 SharedPreferences 錯誤
    }
  }
}

// Liquid Glass 色彩方案
class LiquidGlassColors {
  // 主色調 - 深藍到紫色的漸變
  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color primaryPurple = Color(0xFF7C3AED);
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color accentPink = Color(0xFFEC4899);
  
  // 玻璃質感色彩
  static const Color glassWhite = Color(0x80FFFFFF);
  static const Color glassDark = Color(0x80000000);
  static const Color glassBorder = Color(0x40FFFFFF);
  static const Color glassShadow = Color(0x20000000);
  
  // 漸變色彩組合
  static const List<Color> primaryGradient = [
    Color(0xFF1E3A8A),
    Color(0xFF7C3AED),
    Color(0xFFEC4899),
  ];
  
  static const List<Color> secondaryGradient = [
    Color(0xFF06B6D4),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
  ];
  
  static const List<Color> glassGradient = [
    Color(0x40FFFFFF),
    Color(0x20FFFFFF),
    Color(0x10FFFFFF),
  ];
}

// 亮色主題 - Liquid Glass 風格
final lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: LiquidGlassColors.primaryPurple,
    brightness: Brightness.light,
    primary: LiquidGlassColors.primaryPurple,
    secondary: LiquidGlassColors.accentCyan,
    surface: LiquidGlassColors.glassWhite,
    background: const Color(0xFFF8FAFC),
  ),
  scaffoldBackgroundColor: const Color(0xFFF8FAFC),
  appBarTheme: AppBarTheme(
    centerTitle: true,
    elevation: 0,
    backgroundColor: Colors.transparent,
    foregroundColor: LiquidGlassColors.primaryBlue,
    surfaceTintColor: Colors.transparent,
  ),
  cardTheme: CardTheme(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
    color: Colors.transparent,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: LiquidGlassColors.glassWhite,
      foregroundColor: LiquidGlassColors.primaryBlue,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: LiquidGlassColors.glassBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: LiquidGlassColors.glassBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: LiquidGlassColors.primaryPurple, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    fillColor: LiquidGlassColors.glassWhite,
    filled: true,
  ),
);

// 暗色主題 - Liquid Glass 風格
final darkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: LiquidGlassColors.primaryPurple,
    brightness: Brightness.dark,
    primary: LiquidGlassColors.accentCyan,
    secondary: LiquidGlassColors.accentPink,
    surface: LiquidGlassColors.glassDark,
    background: const Color(0xFF0F172A),
  ),
  scaffoldBackgroundColor: const Color(0xFF0F172A),
  appBarTheme: AppBarTheme(
    centerTitle: true,
    elevation: 0,
    backgroundColor: Colors.transparent,
    foregroundColor: LiquidGlassColors.glassWhite,
    surfaceTintColor: Colors.transparent,
  ),
  cardTheme: CardTheme(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
    color: Colors.transparent,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: LiquidGlassColors.glassDark,
      foregroundColor: LiquidGlassColors.glassWhite,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: LiquidGlassColors.glassBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: LiquidGlassColors.glassBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: LiquidGlassColors.accentCyan, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    fillColor: LiquidGlassColors.glassDark,
    filled: true,
  ),
);

// 狀態顏色
class StatusColors {
  static const Color onTime = Color(0xFF4CAF50); // 綠色
  static const Color late = Color(0xFFFF9800); // 橘色
  static const Color missed = Color(0xFFF44336); // 紅色
  static const Color warning = Color(0xFFFF9800); // 橘色
  static const Color error = Color(0xFFF44336); // 紅色
  static const Color info = Color(0xFF2196F3); // 藍色
  static const Color success = Color(0xFF4CAF50); // 綠色
  
  // 根據狀態取得顏色
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'ontime':
        return onTime;
      case 'late':
        return late;
      case 'missed':
        return missed;
      case 'warning':
        return warning;
      case 'error':
        return error;
      case 'info':
        return info;
      case 'success':
        return success;
      default:
        return Colors.grey;
    }
  }
}

// 圖表顏色 - Liquid Glass 風格
class ChartColors {
  static const List<Color> primary = [
    LiquidGlassColors.primaryBlue,
    LiquidGlassColors.primaryPurple,
    LiquidGlassColors.accentPink,
  ];
  
  static const List<Color> secondary = [
    LiquidGlassColors.accentCyan,
    LiquidGlassColors.accentPink,
    Color(0xFF10B981),
    Color(0xFFEF4444),
  ];
  
  static const Color heartRate = LiquidGlassColors.accentPink;
  static const Color spo2 = LiquidGlassColors.accentCyan;
  static const Color temperature = Color(0xFFF59E0B);
  static const Color humidity = Color(0xFF10B981);
}
