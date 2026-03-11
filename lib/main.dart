import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focustrack/screens/dashboard_screen.dart';
import 'package:focustrack/screens/mobile/mobile_shell.dart';
import 'package:focustrack/providers/database_provider.dart';
import 'package:focustrack/theme/app_theme.dart';

// Home widget support (Android only)
import 'package:focustrack/services/home_widget_data_service.dart';
import 'package:focustrack/services/android_usage_service.dart';
import 'package:focustrack/services/notification_service.dart';
import 'package:focustrack/services/app_limits_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications
  await NotificationService.init();

  if (Platform.isAndroid) {
    // Populate home widget data
    HomeWidgetDataService.updateWidgetData();

    // Start foreground service for background tracking
    AndroidUsageStatsService.startForegroundService();

    // Start app limits monitoring
    AppLimitsService().startMonitoring();
  }

  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize database
    ref.watch(databaseInitializerProvider);

    final isMobile = Platform.isAndroid || Platform.isIOS;

    return MaterialApp(
      title: 'FocusTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: isMobile ? const MobileShell() : const DashboardScreen(),
    );
  }
}
