import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focustrack/screens/enhanced_dashboard_screen.dart';
import 'package:focustrack/providers/database_provider.dart';
import 'package:focustrack/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize database
    ref.watch(databaseInitializerProvider);

    return MaterialApp(
      title: 'FocusTrack - Professional App Usage Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const EnhancedDashboardScreen(),
    );
  }
}
