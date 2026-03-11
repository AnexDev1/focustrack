package com.focustrack.app

import android.app.*
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.os.Handler
import android.os.Build
import android.os.IBinder
import android.os.Looper
import android.os.Process
import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import androidx.core.app.NotificationCompat
import org.json.JSONArray
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.util.Calendar
import java.util.concurrent.atomic.AtomicBoolean

class TrackingForegroundService : Service() {
    private val syncHandler = Handler(Looper.getMainLooper())
    private val syncInProgress = AtomicBoolean(false)
    private val syncRunnable = object : Runnable {
        override fun run() {
            if (syncInProgress.compareAndSet(false, true)) {
                Thread {
                    try {
                        syncUsageToDesktop()
                    } finally {
                        syncInProgress.set(false)
                    }
                }.start()
            }
            syncHandler.postDelayed(this, 60_000)
        }
    }

    companion object {
        const val CHANNEL_ID = "focustrack_tracking"
        const val NOTIFICATION_ID = 1001
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val SERVER_ADDRESS_KEY = "flutter.sync_server_address"
        private const val LAST_SYNC_KEY = "flutter.sync_last_timestamp"

        fun start(context: Context) {
            val intent = Intent(context, TrackingForegroundService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, TrackingForegroundService::class.java))
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val notification = buildNotification()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }

        syncHandler.removeCallbacks(syncRunnable)
        syncHandler.post(syncRunnable)

        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        syncHandler.removeCallbacks(syncRunnable)
        super.onDestroy()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "FocusTrack Tracking",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Keeps FocusTrack running to track your app usage"
                setShowBadge(false)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("FocusTrack")
            .setContentText("Tracking your screen time")
            .setSmallIcon(android.R.drawable.ic_menu_recent_history)
            .setOngoing(true)
            .setContentIntent(pendingIntent)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .build()
    }

    private fun syncUsageToDesktop() {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val address = prefs.getString(SERVER_ADDRESS_KEY, null)?.trim().orEmpty()
        if (address.isEmpty()) return
        if (!hasUsageStatsPermission()) return

        val events = getTodayUsageEvents()
        if (events.isEmpty()) return

        val payload = JSONArray()
        events.forEach { event ->
            payload.put(
                JSONObject().apply {
                    put("appName", event["appName"])
                    put("windowTitle", JSONObject.NULL)
                    put("startTime", event["startTime"])
                    put("endTime", event["endTime"])
                    put("durationMs", event["durationMs"])
                    put("idleTimeMs", 0)
                }
            )
        }

        var connection: HttpURLConnection? = null
        try {
            connection = (URL("http://$address/sync").openConnection() as HttpURLConnection).apply {
                requestMethod = "POST"
                connectTimeout = 10_000
                readTimeout = 20_000
                doOutput = true
                setRequestProperty("Content-Type", "application/json")
            }

            connection.outputStream.use { output ->
                output.write(payload.toString().toByteArray(Charsets.UTF_8))
                output.flush()
            }

            if (connection.responseCode in 200..299) {
                prefs.edit().putLong(LAST_SYNC_KEY, System.currentTimeMillis()).apply()
            }
        } catch (_: Exception) {
        } finally {
            connection?.disconnect()
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

    private fun getTodayUsageEvents(): List<Map<String, Any>> {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val calendar = Calendar.getInstance()
        val endTime = calendar.timeInMillis
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        calendar.set(Calendar.MILLISECOND, 0)
        val startTime = calendar.timeInMillis

        val usageStatsTotals = usageStatsManager
            .queryUsageStats(UsageStatsManager.INTERVAL_DAILY, startTime, endTime)
            .filter { it.totalTimeInForeground > 0 }
            .associateBy { it.packageName }

        val events = usageStatsManager.queryEvents(startTime, endTime)
        val result = mutableListOf<Map<String, Any>>()
        val event = UsageEvents.Event()
        val seenSessions = mutableMapOf<String, Long>()

        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            if (event.packageName.contains("focustrack")) continue

            when (event.eventType) {
                UsageEvents.Event.ACTIVITY_RESUMED -> {
                    seenSessions[event.packageName] = event.timeStamp
                }
                UsageEvents.Event.ACTIVITY_PAUSED -> {
                    val startTs = seenSessions.remove(event.packageName)
                    if (startTs != null) {
                        val duration = event.timeStamp - startTs
                        if (duration > 1000) {
                            result.add(
                                mapOf(
                                    "packageName" to event.packageName,
                                    "appName" to getAppLabel(event.packageName),
                                    "startTime" to startTs,
                                    "endTime" to event.timeStamp,
                                    "durationMs" to duration
                                )
                            )
                        }
                    }
                }
            }
        }

        val now = System.currentTimeMillis()
        val recordedDurations = mutableMapOf<String, Long>()
        result.forEach { entry ->
            val pkg = entry["packageName"] as String
            val dur = entry["durationMs"] as Long
            recordedDurations[pkg] = (recordedDurations[pkg] ?: 0L) + dur
        }

        seenSessions.forEach { (pkg, startTs) ->
            val rawDuration = now - startTs
            if (rawDuration <= 1000) return@forEach

            val totalFromStats = usageStatsTotals[pkg]?.totalTimeInForeground ?: Long.MAX_VALUE
            val alreadyRecorded = recordedDurations[pkg] ?: 0L
            val remainingBudget = totalFromStats - alreadyRecorded
            val cappedDuration = minOf(rawDuration, maxOf(remainingBudget, 0L))

            if (cappedDuration > 1000) {
                result.add(
                    mapOf(
                        "packageName" to pkg,
                        "appName" to getAppLabel(pkg),
                        "startTime" to startTs,
                        "endTime" to now,
                        "durationMs" to cappedDuration
                    )
                )
            }
        }

        return result
    }

    private fun getAppLabel(packageName: String): String {
        return try {
            val pm = packageManager
            val appInfo = pm.getApplicationInfo(packageName, 0)
            pm.getApplicationLabel(appInfo).toString()
        } catch (_: PackageManager.NameNotFoundException) {
            packageName.substringAfterLast(".")
                .replaceFirstChar { it.uppercase() }
        }
    }
}
