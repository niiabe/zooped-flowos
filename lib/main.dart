import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/router/app_router.dart';
import 'core/error/error_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    ErrorHandler.logError(details.exception, details.stack);
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    ErrorHandler.logError(error, stack);
    return true;
  };

  try {
    // Parallelize disk I/O and service initialization to halve startup time
    final futures = await Future.wait([
      SharedPreferences.getInstance(),
      NotificationService().init(),
    ]);
    
    final prefs = futures[0] as SharedPreferences;

    runApp(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const ZooPedApp(),
      ),
    );
  } catch (e, stack) {
    ErrorHandler.logError(e, stack);
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Failed to initialize: ${ErrorHandler.getUserFriendlyMessage(e)}'),
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
