package com.focustrack.app

import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.net.Uri
import android.app.NotificationManager
import android.app.Activity
import android.os.Build
import android.os.PowerManager
import android.os.Process
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.IOException

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.focustrack/usage_stats"
    private val SAVE_TEXT_FILE_REQUEST_CODE = 1002
    private var pendingSaveResult: MethodChannel.Result? = null
    private var pendingSaveContent: ByteArray? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasUsagePermission" -> {
                    result.success(hasUsageStatsPermission())
                }
                "requestUsagePermission" -> {
                    val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    result.success(true)
                }
                "hasOverlayPermission" -> {
                    result.success(Settings.canDrawOverlays(this))
                }
                "requestOverlayPermission" -> {
                    if (!Settings.canDrawOverlays(this)) {
                        val intent = Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:$packageName")
                        )
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                    }
                    result.success(true)
                }
                "isBatteryOptimized" -> {
                    val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                    result.success(!pm.isIgnoringBatteryOptimizations(packageName))
                }
                "requestBatteryOptimization" -> {
                    val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                    if (!pm.isIgnoringBatteryOptimizations(packageName)) {
                        val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                        intent.data = Uri.parse("package:$packageName")
                        startActivity(intent)
                    }
                    result.success(true)
                }
                "startForegroundService" -> {
                    TrackingForegroundService.start(this)
                    result.success(true)
                }
                "stopForegroundService" -> {
                    TrackingForegroundService.stop(this)
                    result.success(true)
                }
                "getUsageStats" -> {
                    val startTime = call.argument<Long>("startTime") ?: 0L
                    val endTime = call.argument<Long>("endTime") ?: System.currentTimeMillis()
                    val stats = getUsageStats(startTime, endTime)
                    result.success(stats)
                }
                "getTodayUsageEvents" -> {
                    val events = getTodayUsageEvents()
                    result.success(events)
                }
                "getAppDisplayName" -> {
                    val packageName = call.argument<String>("packageName") ?: ""
                    result.success(getAppLabel(packageName))
                }
                "getInstalledApps" -> {
                    result.success(getInstalledApps())
                }
                "hasDndAccess" -> {
                    val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                    result.success(nm.isNotificationPolicyAccessGranted)
                }
                "requestDndAccess" -> {
                    val intent = Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    result.success(true)
                }
                "hasNotificationPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        result.success(checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED)
                    } else {
                        result.success(true)
                    }
                }
                "requestNotificationPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        requestPermissions(arrayOf(android.Manifest.permission.POST_NOTIFICATIONS), 1001)
                    }
                    result.success(true)
                }
                "saveTextFile" -> {
                    if (pendingSaveResult != null) {
                        result.error("save_in_progress", "Another save is already in progress", null)
                    } else {
                        val fileName = call.argument<String>("fileName") ?: "focustrack_export.txt"
                        val content = call.argument<String>("content") ?: ""
                        val mimeType = call.argument<String>("mimeType") ?: "text/plain"
                        pendingSaveResult = result
                        pendingSaveContent = content.toByteArray(Charsets.UTF_8)
                        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = mimeType
                            putExtra(Intent.EXTRA_TITLE, fileName)
                        }
                        startActivityForResult(intent, SAVE_TEXT_FILE_REQUEST_CODE)
                    }
                }
                "startAppBlocker" -> {
                    val blockedApps = call.argument<List<String>>("blockedApps") ?: emptyList()
                    AppBlockerService.start(this, blockedApps)
                    result.success(true)
                }
                "stopAppBlocker" -> {
                    AppBlockerService.stop(this)
                    result.success(true)
                }
                "updateBlockedApps" -> {
                    val blockedApps = call.argument<List<String>>("blockedApps") ?: emptyList()
                    AppBlockerService.updateBlockedApps(blockedApps)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode != SAVE_TEXT_FILE_REQUEST_CODE) {
            return
        }

        val result = pendingSaveResult
        val content = pendingSaveContent
        pendingSaveResult = null
        pendingSaveContent = null

        if (result == null) {
            return
        }

        val uri = if (resultCode == Activity.RESULT_OK) data?.data else null
        if (uri == null || content == null) {
            result.success(null)
            return
        }

        try {
            contentResolver.openOutputStream(uri)?.use { output ->
                output.write(content)
                output.flush()
            } ?: throw IOException("Unable to open output stream")
            result.success(uri.toString())
        } catch (e: Exception) {
            result.error("save_failed", e.message, null)
        }
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.unsafeCheckOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            Process.myUid(),
            packageName
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun getUsageStats(startTime: Long, endTime: Long): List<Map<String, Any>> {
        if (!hasUsageStatsPermission()) return emptyList()

        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val stats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY, startTime, endTime
        )

        return stats
            .filter { it.totalTimeInForeground > 0 }
            .sortedByDescending { it.totalTimeInForeground }
            .map { stat ->
                mapOf(
                    "packageName" to stat.packageName,
                    "appName" to getAppLabel(stat.packageName),
                    "totalTimeMs" to stat.totalTimeInForeground,
                    "lastTimeUsed" to stat.lastTimeUsed,
                    "firstTimeStamp" to stat.firstTimeStamp,
                    "lastTimeStamp" to stat.lastTimeStamp
                )
            }
    }

    private fun getTodayUsageEvents(): List<Map<String, Any>> {
        if (!hasUsageStatsPermission()) return emptyList()

        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val calendar = java.util.Calendar.getInstance()
        val endTime = calendar.timeInMillis
        calendar.set(java.util.Calendar.HOUR_OF_DAY, 0)
        calendar.set(java.util.Calendar.MINUTE, 0)
        calendar.set(java.util.Calendar.SECOND, 0)
        calendar.set(java.util.Calendar.MILLISECOND, 0)
        val startTime = calendar.timeInMillis

        // Get authoritative total times from UsageStats API (ground truth)
        val usageStatsTotals = usageStatsManager
            .queryUsageStats(UsageStatsManager.INTERVAL_DAILY, startTime, endTime)
            .filter { it.totalTimeInForeground > 0 }
            .associateBy { it.packageName }

        val events = usageStatsManager.queryEvents(startTime, endTime)
        val result = mutableListOf<Map<String, Any>>()
        val event = UsageEvents.Event()
        val seenSessions = mutableMapOf<String, Long>() // packageName -> RESUMED timestamp

        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            // Skip our own app
            if (event.packageName.contains("focustrack")) continue
            when (event.eventType) {
                UsageEvents.Event.ACTIVITY_RESUMED -> {
                    seenSessions[event.packageName] = event.timeStamp
                }
                UsageEvents.Event.ACTIVITY_PAUSED -> {
                    val startTs = seenSessions.remove(event.packageName)
                    if (startTs != null) {
                        val duration = event.timeStamp - startTs
                        if (duration > 1000) { // ignore sub-second sessions
                            result.add(mapOf(
                                "packageName" to event.packageName,
                                "appName" to getAppLabel(event.packageName),
                                "startTime" to startTs,
                                "endTime" to event.timeStamp,
                                "durationMs" to duration
                            ))
                        }
                    }
                }
            }
        }

        // Handle still-open sessions (app is currently in foreground, no PAUSED yet)
        val now = System.currentTimeMillis()
        // Sum up durations already recorded for each package from RESUME/PAUSE pairs
        val recordedDurations = mutableMapOf<String, Long>()
        for (entry in result) {
            val pkg = entry["packageName"] as String
            val dur = entry["durationMs"] as Long
            recordedDurations[pkg] = (recordedDurations[pkg] ?: 0L) + dur
        }

        for ((pkg, startTs) in seenSessions) {
            val rawDuration = now - startTs
            if (rawDuration <= 1000) continue

            // Cross-check: the still-open duration cannot exceed what UsageStats reports
            // as total foreground time. This catches phantom "ghost" RESUMED events.
            val totalFromStats = usageStatsTotals[pkg]?.totalTimeInForeground ?: Long.MAX_VALUE
            val alreadyRecorded = recordedDurations[pkg] ?: 0L
            // Remaining budget from UsageStats total minus already-recorded sessions
            val remainingBudget = totalFromStats - alreadyRecorded
            val cappedDuration = minOf(rawDuration, maxOf(remainingBudget, 0L))

            if (cappedDuration > 1000) {
                result.add(mapOf(
                    "packageName" to pkg,
                    "appName" to getAppLabel(pkg),
                    "startTime" to startTs,
                    "endTime" to now,
                    "durationMs" to cappedDuration
                ))
            }
        }

        return result
    }

    private fun getAppLabel(packageName: String): String {
        return try {
            val pm = packageManager
            val appInfo = pm.getApplicationInfo(packageName, 0)
            pm.getApplicationLabel(appInfo).toString()
        } catch (e: PackageManager.NameNotFoundException) {
            packageName.substringAfterLast(".")
                .replaceFirstChar { it.uppercase() }
        }
    }

    private fun getInstalledApps(): List<Map<String, String>> {
        val pm = packageManager
        val apps = pm.getInstalledApplications(PackageManager.GET_META_DATA)
        return apps
            .filter { (it.flags and ApplicationInfo.FLAG_SYSTEM) == 0 }
            .map { appInfo ->
                mapOf(
                    "packageName" to appInfo.packageName,
                    "appName" to pm.getApplicationLabel(appInfo).toString()
                )
            }
            .sortedBy { it["appName"]?.lowercase() }
    }
}
