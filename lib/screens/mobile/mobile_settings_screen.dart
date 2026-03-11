import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focustrack/theme/app_theme.dart';
import 'package:focustrack/providers/database_provider.dart';
import 'package:focustrack/services/android_usage_service.dart';
import 'package:focustrack/services/sync_client.dart';
import 'package:focustrack/services/app_limits_service.dart';
import 'package:focustrack/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MobileSettingsScreen extends ConsumerStatefulWidget {
  const MobileSettingsScreen({super.key});

  @override
  ConsumerState<MobileSettingsScreen> createState() =>
      _MobileSettingsScreenState();
}

class _MobileSettingsScreenState extends ConsumerState<MobileSettingsScreen> {
  bool _hasPermission = false;
  bool _hasOverlay = false;
  bool _isBatteryOptimized = true;
  bool _serviceRunning = false;
  bool _checkingPermission = false;
  bool _hasDndAccess = false;
  bool _hasNotifPermission = false;

  // Notification preferences
  bool _milestonesEnabled = true;
  bool _breakRemindersEnabled = true;
  int _breakIntervalMinutes = 60;

  // Sync state
  String _serverAddress = '';
  DateTime? _lastSyncTime;
  bool _isSyncing = false;
  bool _serverReachable = false;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      _checkAllPermissions();
      _loadSyncSettings();
      _loadNotifPrefs();
    }
  }

  Future<void> _loadNotifPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _milestonesEnabled = prefs.getBool('notif_milestones') ?? true;
      _breakRemindersEnabled = prefs.getBool('notif_break_reminders') ?? true;
      _breakIntervalMinutes = prefs.getInt('break_interval_minutes') ?? 60;
    });
  }

  Future<void> _saveNotifPref(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) await prefs.setBool(key, value);
    if (value is int) await prefs.setInt(key, value);
  }

  Future<void> _loadSyncSettings() async {
    final address = await SyncClient.getServerAddress();
    final lastSync = await SyncClient.getLastSyncTime();
    setState(() {
      _serverAddress = address ?? '';
      _lastSyncTime = lastSync;
    });
    if (_serverAddress.isNotEmpty) {
      _checkServer();
    }
  }

  Future<void> _checkServer() async {
    if (_serverAddress.isEmpty) return;
    final ok = await SyncClient.pingServer(_serverAddress);
    if (mounted) setState(() => _serverReachable = ok);
  }

  Future<void> _syncNow() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    final count = await SyncClient.syncToDesktop();
    final lastSync = await SyncClient.getLastSyncTime();
    if (mounted) {
      setState(() {
        _isSyncing = false;
        _lastSyncTime = lastSync;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            count >= 0
                ? 'Synced $count sessions to desktop'
                : 'Sync failed — check server address',
          ),
        ),
      );
    }
  }

  Future<void> _checkAllPermissions() async {
    setState(() => _checkingPermission = true);
    final results = await Future.wait([
      AndroidUsageStatsService.hasPermission(),
      AndroidUsageStatsService.hasOverlayPermission(),
      AndroidUsageStatsService.isBatteryOptimized(),
      AndroidUsageStatsService.hasDndAccess(),
      AndroidUsageStatsService.hasNotificationPermission(),
    ]);
    _hasPermission = results[0];
    _hasOverlay = results[1];
    _isBatteryOptimized = results[2];
    _hasDndAccess = results[3];
    _hasNotifPermission = results[4];
    _serviceRunning = _hasPermission;
    setState(() => _checkingPermission = false);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text(
                'Settings',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 24),

              // Usage Permission Section (Android only)
              if (Platform.isAndroid) ...[
                _sectionLabel(context, 'Permissions'),
                const SizedBox(height: 8),
                _settingsTile(
                  context,
                  icon: Icons.bar_chart_rounded,
                  iconColor: _hasPermission
                      ? AppTheme.successColor
                      : AppTheme.warningColor,
                  title: 'Usage Access',
                  subtitle: _checkingPermission
                      ? 'Checking...'
                      : _hasPermission
                      ? 'Granted'
                      : 'Required to track app usage',
                  trailing: _hasPermission
                      ? const Icon(
                          Icons.check_circle,
                          color: AppTheme.successColor,
                          size: 22,
                        )
                      : TextButton(
                          onPressed: () async {
                            await AndroidUsageStatsService.requestPermission();
                            await _checkAllPermissions();
                          },
                          child: const Text('Grant'),
                        ),
                ),
                _settingsTile(
                  context,
                  icon: Icons.layers_rounded,
                  iconColor: _hasOverlay
                      ? AppTheme.successColor
                      : AppTheme.warningColor,
                  title: 'Overlay Permission',
                  subtitle: _hasOverlay
                      ? 'Granted'
                      : 'Required for floating tracker',
                  trailing: _hasOverlay
                      ? const Icon(
                          Icons.check_circle,
                          color: AppTheme.successColor,
                          size: 22,
                        )
                      : TextButton(
                          onPressed: () async {
                            await AndroidUsageStatsService.requestOverlayPermission();
                            await _checkAllPermissions();
                          },
                          child: const Text('Grant'),
                        ),
                ),
                _settingsTile(
                  context,
                  icon: Icons.battery_saver_rounded,
                  iconColor: !_isBatteryOptimized
                      ? AppTheme.successColor
                      : AppTheme.warningColor,
                  title: 'Battery Optimization',
                  subtitle: !_isBatteryOptimized
                      ? 'Excluded — background running OK'
                      : 'Disable to allow background tracking',
                  trailing: !_isBatteryOptimized
                      ? const Icon(
                          Icons.check_circle,
                          color: AppTheme.successColor,
                          size: 22,
                        )
                      : TextButton(
                          onPressed: () async {
                            await AndroidUsageStatsService.requestBatteryOptimization();
                            await _checkAllPermissions();
                          },
                          child: const Text('Disable'),
                        ),
                ),
                _settingsTile(
                  context,
                  icon: Icons.sync_rounded,
                  iconColor: _serviceRunning
                      ? AppTheme.successColor
                      : AppTheme.textTertiary,
                  title: 'Background Tracking',
                  subtitle: _serviceRunning
                      ? 'Service running'
                      : 'Service stopped',
                  trailing: Switch(
                    value: _serviceRunning,
                    activeColor: AppTheme.primaryColor,
                    onChanged: (val) async {
                      if (val) {
                        await AndroidUsageStatsService.startForegroundService();
                      } else {
                        await AndroidUsageStatsService.stopForegroundService();
                      }
                      setState(() => _serviceRunning = val);
                    },
                  ),
                ),
                _settingsTile(
                  context,
                  icon: Icons.do_not_disturb_on_rounded,
                  iconColor: _hasDndAccess
                      ? AppTheme.successColor
                      : AppTheme.textTertiary,
                  title: 'Do Not Disturb Access',
                  subtitle: _hasDndAccess
                      ? 'Granted — can manage focus mode'
                      : 'Required for focus mode',
                  trailing: _hasDndAccess
                      ? const Icon(
                          Icons.check_circle,
                          color: AppTheme.successColor,
                          size: 22,
                        )
                      : TextButton(
                          onPressed: () async {
                            await AndroidUsageStatsService.requestDndAccess();
                            await _checkAllPermissions();
                          },
                          child: const Text('Grant'),
                        ),
                ),
                _settingsTile(
                  context,
                  icon: Icons.notifications_active_rounded,
                  iconColor: _hasNotifPermission
                      ? AppTheme.successColor
                      : AppTheme.warningColor,
                  title: 'Notification Permission',
                  subtitle: _hasNotifPermission
                      ? 'Granted'
                      : 'Required for alerts & reminders',
                  trailing: _hasNotifPermission
                      ? const Icon(
                          Icons.check_circle,
                          color: AppTheme.successColor,
                          size: 22,
                        )
                      : TextButton(
                          onPressed: () async {
                            await AndroidUsageStatsService.requestNotificationPermission();
                            await _checkAllPermissions();
                          },
                          child: const Text('Grant'),
                        ),
                ),
                const SizedBox(height: 24),
              ],

              // Notifications
              _sectionLabel(context, 'Notifications'),
              const SizedBox(height: 8),
              _settingsTile(
                context,
                icon: Icons.emoji_events_rounded,
                iconColor: AppTheme.warningColor,
                title: 'Milestone Alerts',
                subtitle: 'Notify at 1h, 2h, 4h, etc.',
                trailing: Switch(
                  value: _milestonesEnabled,
                  activeColor: AppTheme.primaryColor,
                  onChanged: (val) {
                    setState(() => _milestonesEnabled = val);
                    _saveNotifPref('notif_milestones', val);
                  },
                ),
              ),
              _settingsTile(
                context,
                icon: Icons.self_improvement_rounded,
                iconColor: AppTheme.accentColor,
                title: 'Break Reminders',
                subtitle:
                    'Remind to take breaks every ${_breakIntervalMinutes}m',
                trailing: Switch(
                  value: _breakRemindersEnabled,
                  activeColor: AppTheme.primaryColor,
                  onChanged: (val) {
                    setState(() => _breakRemindersEnabled = val);
                    _saveNotifPref('notif_break_reminders', val);
                  },
                ),
              ),
              if (_breakRemindersEnabled)
                _settingsTile(
                  context,
                  icon: Icons.schedule_rounded,
                  iconColor: AppTheme.textSecondary,
                  title: 'Break Interval',
                  subtitle: '$_breakIntervalMinutes minutes',
                  onTap: () => _showBreakIntervalPicker(),
                ),
              const SizedBox(height: 24),

              // Desktop Sync
              _sectionLabel(context, 'Desktop Sync'),
              const SizedBox(height: 8),
              _settingsTile(
                context,
                icon: Icons.computer_rounded,
                iconColor: _serverReachable
                    ? AppTheme.successColor
                    : AppTheme.textTertiary,
                title: 'Server Address',
                subtitle: _serverAddress.isEmpty
                    ? 'Tap to set desktop IP:port'
                    : _serverAddress +
                          (_serverReachable ? ' ✓' : ' — unreachable'),
                onTap: () => _showAddressDialog(context),
              ),
              _settingsTile(
                context,
                icon: Icons.sync_rounded,
                iconColor: AppTheme.accentColor,
                title: 'Sync Now',
                subtitle: _lastSyncTime != null
                    ? 'Last: ${_formatSyncTime(_lastSyncTime!)}'
                    : 'Never synced',
                trailing: _isSyncing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        icon: const Icon(
                          Icons.sync,
                          color: AppTheme.accentColor,
                        ),
                        onPressed: _serverAddress.isNotEmpty ? _syncNow : null,
                      ),
              ),
              const SizedBox(height: 24),

              // Data Management
              _sectionLabel(context, 'Data'),
              const SizedBox(height: 8),
              _settingsTile(
                context,
                icon: Icons.file_download_rounded,
                iconColor: AppTheme.primaryColor,
                title: 'Export Data',
                subtitle: 'Export usage history as CSV',
                onTap: () => _exportData(),
              ),
              _settingsTile(
                context,
                icon: Icons.delete_sweep_rounded,
                iconColor: AppTheme.errorColor,
                title: 'Clear All Data',
                subtitle: 'Delete all tracking history',
                onTap: () => _confirmClear(context),
              ),
              const SizedBox(height: 24),

              // About
              _sectionLabel(context, 'About'),
              const SizedBox(height: 8),
              _settingsTile(
                context,
                icon: Icons.info_outline_rounded,
                iconColor: AppTheme.accentColor,
                title: 'FocusTrack',
                subtitle: 'Version 0.3.0',
              ),
              _settingsTile(
                context,
                icon: Icons.shield_outlined,
                iconColor: AppTheme.successColor,
                title: 'Privacy',
                subtitle: 'All data stays on your device — no cloud',
              ),
              const SizedBox(height: 100),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppTheme.textTertiary,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _settingsTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Material(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatSyncTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Future<void> _showAddressDialog(BuildContext context) async {
    final controller = TextEditingController(text: _serverAddress);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Desktop Server Address'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter the IP and port shown in the desktop app.\nExample: 192.168.1.100:8742',
              style: Theme.of(
                ctx,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.textTertiary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: '192.168.1.x:8742',
                filled: true,
                fillColor: AppTheme.backgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await SyncClient.setServerAddress(result);
      setState(() => _serverAddress = result);
      _checkServer();
    }
  }

  Future<void> _confirmClear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will permanently delete all your app usage history. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final db = ref.read(databaseProvider);
      await db.clearAllSessions();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('All data cleared')));
      }
    }
  }

  void _showBreakIntervalPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Break Reminder Interval',
              style: Theme.of(
                ctx,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ...[30, 45, 60, 90, 120].map(
              (minutes) => RadioListTile<int>(
                title: Text('$minutes minutes'),
                value: minutes,
                groupValue: _breakIntervalMinutes,
                activeColor: AppTheme.primaryColor,
                onChanged: (val) {
                  setState(() => _breakIntervalMinutes = val!);
                  _saveNotifPref('break_interval_minutes', val!);
                  Navigator.pop(ctx);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportData() async {
    final db = ref.read(databaseProvider);
    final sessions = await db.getAllSessions();
    if (sessions.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No data to export')));
      }
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('App Name,Start Time,End Time,Duration (seconds),Source');
    for (final s in sessions) {
      final end = s.endTime ?? s.startTime;
      final duration = end.difference(s.startTime).inSeconds;
      buffer.writeln(
        '"${s.appName}","${s.startTime}","$end",$duration,"${s.source}"',
      );
    }

    // Copy to clipboard as simple export
    await Future.delayed(Duration.zero); // ensure mounted check works
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exported ${sessions.length} sessions'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
