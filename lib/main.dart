import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Unhandled error: $error\n$stack');
    return true;
  };

  try {
    final prefs = await SharedPreferences.getInstance();
    runApp(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const ZooPedApp(),
      ),
    );
  } catch (e) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Failed to initialize: $e'),
          ),
        ),
      ),
    );
  }
}

class ZooPedApp extends ConsumerWidget {
  const ZooPedApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'ZooPed',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getLightTheme(themeState.primaryColor),
      darkTheme: AppTheme.getDarkTheme(themeState.primaryColor),
      themeMode: themeState.themeMode,
      routerConfig: AppRouter.router,
    );
  }
}
