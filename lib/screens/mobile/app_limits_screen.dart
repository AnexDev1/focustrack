import 'dart:io' show Platform;
import 'package:flutter/material.dart' hide Icons;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focustrack/services/app_limits_service.dart';
import 'package:focustrack/services/android_usage_service.dart';
import 'package:focustrack/theme/app_icons.dart';
import 'package:focustrack/theme/app_theme.dart';

class AppLimitsScreen extends ConsumerStatefulWidget {
  const AppLimitsScreen({super.key});

  @override
  ConsumerState<AppLimitsScreen> createState() => _AppLimitsScreenState();
}

class _AppLimitsScreenState extends ConsumerState<AppLimitsScreen> {
  List<AppLimit> _limits = [];
  List<AppLimitStatus> _statuses = [];
  List<Map<String, String>> _installedApps = [];
  bool _loading = true;
  int _dailyGoal = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final limits = await AppLimitsService.getLimits();
    final statuses = await AppLimitsService.getLimitStatuses();
    final goal = await AppLimitsService.getDailyGoal();
    List<Map<String, String>> apps = [];
    if (Platform.isAndroid) {
      apps = await AndroidUsageStatsService.getInstalledApps();
    }
    if (mounted) {
      setState(() {
        _limits = limits;
        _statuses = statuses;
        _installedApps = apps;
        _dailyGoal = goal;
        _loading = false;
      });
    }
  }

  String _formatMinutes(int min) {
    if (min >= 60) {
      final h = min ~/ 60;
      final m = min % 60;
      return m > 0 ? '${h}h ${m}m' : '${h}h';
    }
    return '${min}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('App Limits'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildDailyGoalCard(),
                  const SizedBox(height: 20),
                  _buildLimitedAppsSection(),
                  const SizedBox(height: 20),
                  _buildAddLimitButton(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
    );
  }

  Widget _buildDailyGoalCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.15),
            AppTheme.accentColor.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag_rounded, color: AppTheme.primaryColor, size: 22),
              const SizedBox(width: 10),
              Text(
                'Daily Screen Time Goal',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  _dailyGoal > 0
                      ? 'Goal: ${_formatMinutes(_dailyGoal)}'
                      : 'No goal set — tap to set one',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _dailyGoal > 0
                        ? AppTheme.textPrimary
                        : AppTheme.textTertiary,
                  ),
                ),
              ),
              OutlinedButton(
                onPressed: () => _showGoalPicker(),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: AppTheme.primaryColor.withOpacity(0.5),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  _dailyGoal > 0 ? 'Change' : 'Set Goal',
                  style: TextStyle(color: AppTheme.primaryColor),
                ),
              ),
            ],
          ),
          if (_dailyGoal > 0) ...[
            const SizedBox(height: 8),
            Text(
              'You\'ll be notified when you reach this limit',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.textTertiary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLimitedAppsSection() {
    if (_statuses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              Icons.timer_off_outlined,
              size: 48,
              color: AppTheme.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No app limits set',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Set time limits on apps to stay focused and mindful of your usage',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LIMITED APPS',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppTheme.textTertiary,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ..._statuses.map((status) => _buildLimitCard(status)),
      ],
    );
  }

  Widget _buildLimitCard(AppLimitStatus status) {
    final color = status.exceeded
        ? AppTheme.errorColor
        : status.percentage > 80
        ? AppTheme.warningColor
        : AppTheme.successColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: status.exceeded
              ? AppTheme.errorColor.withOpacity(0.3)
              : Colors.white.withOpacity(0.06),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    status.limit.appName.isNotEmpty
                        ? status.limit.appName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status.limit.appName,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_formatMinutes(status.usedMinutes)} / ${_formatMinutes(status.limit.limitMinutes)}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: color),
                    ),
                  ],
                ),
              ),
              Switch(
                value: status.limit.enabled,
                activeThumbColor: AppTheme.primaryColor,
                onChanged: (val) async {
                  await AppLimitsService.toggleLimit(status.limit.appName, val);
                  // Immediately apply change to blocker (no need to wait for 1-min timer)
                  AppLimitsService.syncBlockerNow();
                  _loadData();
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: AppTheme.textTertiary,
                onPressed: () async {
                  await AppLimitsService.removeLimit(status.limit.appName);
                  // Immediately release the lock on this app
                  AppLimitsService.syncBlockerNow();
                  _loadData();
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (status.percentage / 100).clamp(0, 1),
              backgroundColor: color.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
          if (status.exceeded) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: color, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Limit exceeded by ${_formatMinutes(status.usedMinutes - status.limit.limitMinutes)}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: color),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddLimitButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showAddLimitDialog(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add App Limit'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.primaryColor,
          side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.4)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  void _showGoalPicker() {
    int selectedHours = _dailyGoal ~/ 60;
    int selectedMins = _dailyGoal % 60;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Set Daily Screen Time Goal',
                style: Theme.of(
                  ctx,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildNumberPicker(
                    ctx,
                    label: 'Hours',
                    value: selectedHours,
                    max: 12,
                    onChanged: (v) => setSheetState(() => selectedHours = v),
                  ),
                  const SizedBox(width: 24),
                  _buildNumberPicker(
                    ctx,
                    label: 'Minutes',
                    value: selectedMins,
                    max: 59,
                    step: 15,
                    onChanged: (v) => setSheetState(() => selectedMins = v),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  if (_dailyGoal > 0)
                    TextButton(
                      onPressed: () async {
                        await AppLimitsService.setDailyGoal(0);
                        setState(() => _dailyGoal = 0);
                        Navigator.pop(ctx);
                      },
                      child: Text(
                        'Remove Goal',
                        style: TextStyle(color: AppTheme.errorColor),
                      ),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final total = selectedHours * 60 + selectedMins;
                      if (total > 0) {
                        await AppLimitsService.setDailyGoal(total);
                        setState(() => _dailyGoal = total);
                      }
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                    ),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberPicker(
    BuildContext context, {
    required String label,
    required int value,
    required int max,
    int step = 1,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppTheme.textTertiary),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              onPressed: () {
                if (value - step >= 0) onChanged(value - step);
              },
              icon: const Icon(Icons.remove_circle_outline),
              color: AppTheme.textSecondary,
            ),
            SizedBox(
              width: 40,
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                if (value + step <= max) onChanged(value + step);
              },
              icon: const Icon(Icons.add_circle_outline),
              color: AppTheme.primaryColor,
            ),
          ],
        ),
      ],
    );
  }

  void _showAddLimitDialog() {
    String? selectedApp;
    int limitMinutes = 60;

    // Get apps from usage stats that aren't already limited
    final limitedApps = _limits.map((l) => l.appName).toSet();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          // Show installed apps not already limited
          final available = _installedApps
              .where((a) => !limitedApps.contains(a['appName']))
              .toList();

          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            maxChildSize: 0.9,
            minChildSize: 0.4,
            expand: false,
            builder: (ctx, scrollController) => Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.textTertiary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Add App Limit',
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (selectedApp != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              selectedApp!,
                              style: Theme.of(ctx).textTheme.bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                setSheetState(() => selectedApp = null),
                            child: const Text('Change'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Daily Time Limit',
                      style: Theme.of(ctx).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [15, 30, 45, 60, 90, 120, 180, 240].map((m) {
                        final isSelected = limitMinutes == m;
                        return ChoiceChip(
                          label: Text(_formatMinutes(m)),
                          selected: isSelected,
                          selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                          onSelected: (_) =>
                              setSheetState(() => limitMinutes = m),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          await AppLimitsService.setLimit(
                            selectedApp!,
                            limitMinutes,
                          );
                          // Immediately check if the new limit is already exceeded
                          AppLimitsService.syncBlockerNow();
                          Navigator.pop(ctx);
                          _loadData();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Set Limit'),
                      ),
                    ),
                  ] else ...[
                    Text(
                      'Select an app:',
                      style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: available.length,
                        itemBuilder: (ctx, i) {
                          final app = available[i];
                          return ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  (app['appName'] ?? '?')[0].toUpperCase(),
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              app['appName'] ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              app['packageName'] ?? '',
                              style: Theme.of(ctx).textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => setSheetState(
                              () => selectedApp = app['appName'],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
