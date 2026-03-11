import 'package:flutter/material.dart' hide Icons;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focustrack/screens/mobile/mobile_dashboard_screen.dart';
import 'package:focustrack/screens/mobile/mobile_analytics_screen.dart';
import 'package:focustrack/screens/mobile/mobile_insights_screen.dart';
import 'package:focustrack/screens/mobile/mobile_settings_screen.dart';
import 'package:focustrack/screens/mobile/app_limits_screen.dart';
import 'package:focustrack/theme/app_icons.dart';
import 'package:focustrack/theme/app_theme.dart';

class MobileShell extends ConsumerStatefulWidget {
  const MobileShell({super.key});

  @override
  ConsumerState<MobileShell> createState() => _MobileShellState();
}

class _MobileShellState extends ConsumerState<MobileShell> {
  int _currentIndex = 0;

  final _screens = const [
    MobileDashboardScreen(),
    MobileAnalyticsScreen(),
    AppLimitsScreen(),
    MobileInsightsScreen(),
    MobileSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Set system UI overlay style for immersive dark look
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppTheme.backgroundColor,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.06), width: 1),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: _buildNavItem(0, Icons.dashboard_rounded, 'Dashboard'),
                ),
                Expanded(
                  child: _buildNavItem(1, Icons.bar_chart_rounded, 'Analytics'),
                ),
                Expanded(
                  child: _buildNavItem(2, Icons.timer_rounded, 'Limits'),
                ),
                Expanded(
                  child: _buildNavItem(
                    3,
                    Icons.auto_awesome_rounded,
                    'Insights',
                  ),
                ),
                Expanded(
                  child: _buildNavItem(4, Icons.settings_rounded, 'Settings'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? AppTheme.primaryColor : AppTheme.textTertiary;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                softWrap: false,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
