import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  // Singleton pattern
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  // Observable theme mode
  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.light);

  // Initialize service
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool('isDarkMode') ?? false;
      themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
    } catch (e) {
      debugPrint('Error loading theme preference: $e');
    }
  }

  // Toggle theme
  Future<void> toggleTheme() async {
    final isDark = themeMode.value == ThemeMode.dark;
    themeMode.value = isDark ? ThemeMode.light : ThemeMode.dark;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', !isDark);
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
    }
  }

  // Get current status
  bool get isDarkMode => themeMode.value == ThemeMode.dark;
}
