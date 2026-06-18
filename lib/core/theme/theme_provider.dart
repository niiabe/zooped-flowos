import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize sharedPreferencesProvider in main.dart');
});

class ThemeState {
  final ThemeMode themeMode;
  final Color primaryColor;

  const ThemeState({
    required this.themeMode,
    required this.primaryColor,
  });

  ThemeState copyWith({
    ThemeMode? themeMode,
    Color? primaryColor,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      primaryColor: primaryColor ?? this.primaryColor,
    );
  }
}

class ThemeNotifier extends Notifier<ThemeState> {
  static const _themeModeKey = 'theme_mode';
  static const _primaryColorKey = 'primary_color';

  @override
  ThemeState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    
    // Load ThemeMode
    final modeIndex = prefs.getInt(_themeModeKey) ?? ThemeMode.system.index;
    final themeMode = ThemeMode.values.firstWhere(
      (e) => e.index == modeIndex,
      orElse: () => ThemeMode.system,
    );

    // Load Primary Color
    final colorValue = prefs.getInt(_primaryColorKey);
    final primaryColor = colorValue != null ? Color(colorValue) : AppTheme.defaultPrimaryColor;

    return ThemeState(themeMode: themeMode, primaryColor: primaryColor);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt(_themeModeKey, mode.index);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setPrimaryColor(Color color) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt(_primaryColorKey, color.toARGB32());
    state = state.copyWith(primaryColor: color);
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeState>(() {
  return ThemeNotifier();
});
