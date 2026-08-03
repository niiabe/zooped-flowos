import 'dart:async';
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
  final bool scheduleEnabled;
  final TimeOfDay sunsetTime;
  final TimeOfDay sunriseTime;

  const ThemeState({
    required this.themeMode,
    required this.primaryColor,
    this.scheduleEnabled = false,
    this.sunsetTime = const TimeOfDay(hour: 19, minute: 0),
    this.sunriseTime = const TimeOfDay(hour: 7, minute: 0),
  });

  ThemeState copyWith({
    ThemeMode? themeMode,
    Color? primaryColor,
    bool? scheduleEnabled,
    TimeOfDay? sunsetTime,
    TimeOfDay? sunriseTime,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      primaryColor: primaryColor ?? this.primaryColor,
      scheduleEnabled: scheduleEnabled ?? this.scheduleEnabled,
      sunsetTime: sunsetTime ?? this.sunsetTime,
      sunriseTime: sunriseTime ?? this.sunriseTime,
    );
  }
}

class ThemeNotifier extends Notifier<ThemeState> {
  static const _themeModeKey = 'theme_mode';
  static const _primaryColorKey = 'primary_color';
  static const _scheduleEnabledKey = 'theme_schedule_enabled';
  static const _sunsetHourKey = 'theme_sunset_hour';
  static const _sunsetMinuteKey = 'theme_sunset_minute';
  static const _sunriseHourKey = 'theme_sunrise_hour';
  static const _sunriseMinuteKey = 'theme_sunrise_minute';
  Timer? _scheduleTimer;

  @override
  ThemeState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    
    final modeIndex = prefs.getInt(_themeModeKey) ?? ThemeMode.light.index;
    final themeMode = ThemeMode.values.firstWhere(
      (e) => e.index == modeIndex,
      orElse: () => ThemeMode.light,
    );

    final colorValue = prefs.getInt(_primaryColorKey);
    final primaryColor = colorValue != null ? Color(colorValue) : AppTheme.defaultPrimaryColor;

    final scheduleEnabled = prefs.getBool(_scheduleEnabledKey) ?? false;
    final sunsetHour = prefs.getInt(_sunsetHourKey) ?? 19;
    final sunsetMinute = prefs.getInt(_sunsetMinuteKey) ?? 0;
    final sunriseHour = prefs.getInt(_sunriseHourKey) ?? 7;
    final sunriseMinute = prefs.getInt(_sunriseMinuteKey) ?? 0;

    if (scheduleEnabled) {
      _startScheduleTimer();
    }

    return ThemeState(
      themeMode: themeMode,
      primaryColor: primaryColor,
      scheduleEnabled: scheduleEnabled,
      sunsetTime: TimeOfDay(hour: sunsetHour, minute: sunsetMinute),
      sunriseTime: TimeOfDay(hour: sunriseHour, minute: sunriseMinute),
    );
  }

  void _startScheduleTimer() {
    _scheduleTimer?.cancel();
    _scheduleTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkSchedule();
    });
    _checkSchedule();
  }

  void _checkSchedule() {
    if (!state.scheduleEnabled) return;

    final now = TimeOfDay.now();
    final isDark = _isTimeBetween(state.sunsetTime, state.sunriseTime, now);

    final targetMode = isDark ? ThemeMode.dark : ThemeMode.light;
    if (state.themeMode != ThemeMode.system && state.themeMode != targetMode) {
      setThemeMode(targetMode);
    }
  }

  bool _isTimeBetween(TimeOfDay start, TimeOfDay end, TimeOfDay current) {
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    final currentMinutes = current.hour * 60 + current.minute;

    if (startMinutes <= endMinutes) {
      return currentMinutes >= startMinutes && currentMinutes < endMinutes;
    } else {
      return currentMinutes >= startMinutes || currentMinutes < endMinutes;
    }
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

  Future<void> setScheduleEnabled(bool enabled) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_scheduleEnabledKey, enabled);
    state = state.copyWith(scheduleEnabled: enabled);
    if (enabled) {
      _startScheduleTimer();
    } else {
      _scheduleTimer?.cancel();
    }
  }

  Future<void> setSunsetTime(TimeOfDay time) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt(_sunsetHourKey, time.hour);
    await prefs.setInt(_sunsetMinuteKey, time.minute);
    state = state.copyWith(sunsetTime: time);
  }

  Future<void> setSunriseTime(TimeOfDay time) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt(_sunriseHourKey, time.hour);
    await prefs.setInt(_sunriseMinuteKey, time.minute);
    state = state.copyWith(sunriseTime: time);
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeState>(() {
  return ThemeNotifier();
});
