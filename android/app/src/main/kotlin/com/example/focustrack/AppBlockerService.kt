package com.focustrack.app

import android.app.*
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat

class AppBlockerService : Service() {

    companion object {
        const val CHANNEL_ID = "focustrack_blocker"
        const val NOTIFICATION_ID = 2001
        const val EXTRA_BLOCKED_APPS = "blocked_apps"
        private var instance: AppBlockerService? = null

        fun start(context: Context, blockedApps: List<String>) {
            val intent = Intent(context, AppBlockerService::class.java)
            intent.putStringArrayListExtra(EXTRA_BLOCKED_APPS, ArrayList(blockedApps))
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, AppBlockerService::class.java))
        }

        fun updateBlockedApps(apps: List<String>) {
            instance?.blockedApps = apps.toMutableList()
        }
    }

    var blockedApps = mutableListOf<String>()
    private val handler = Handler(Looper.getMainLooper())

    /** Timestamp from which the next event batch will be queried (incremental). */
    private var lastCheckedTime = 0L

    /** Package name currently in the foreground, maintained across polling cycles. */
    private var currentForeground: String? = null

    private val checkRunnable = object : Runnable {
        override fun run() {
            checkForegroundApp()
            handler.postDelayed(this, 500) // poll every 500 ms
        }
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
        createNotificationChannel()
        // 60-second look-back so we detect an app that was already open when the service starts
        lastCheckedTime = System.currentTimeMillis() - 60_000L
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val apps = intent?.getStringArrayListExtra(EXTRA_BLOCKED_APPS)
        if (apps != null) {
            blockedApps = apps.toMutableList()
        }

        val notification = buildNotification()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }

        handler.removeCallbacks(checkRunnable)
        handler.post(checkRunnable)

        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        handler.removeCallbacks(checkRunnable)
        instance = null
        super.onDestroy()
    }

    /**
     * Incrementally processes UsageEvents since [lastCheckedTime] to maintain
     * [currentForeground] state.  Then, if the foreground app is blocked and
     * the lock activity is not already showing, launches AppLockActivity.
     */
    private fun checkForegroundApp() {
        if (blockedApps.isEmpty()) return

        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val now = System.currentTimeMillis()

        val events = usm.queryEvents(lastCheckedTime, now)
        val event = UsageEvents.Event()

        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            when (event.eventType) {
                UsageEvents.Event.ACTIVITY_RESUMED ->
                    currentForeground = event.packageName

                UsageEvents.Event.ACTIVITY_PAUSED ->
                    if (currentForeground == event.packageName) currentForeground = null
            }
        }

        lastCheckedTime = now

        val fg = currentForeground ?: return

        // Launch the lock screen only if: blocked app is foreground AND lock isn't already up
        if (blockedApps.contains(fg) && !AppLockActivity.isActive) {
            AppLockActivity.launch(this, getAppLabel(fg))
        }
    }

    private fun getAppLabel(pkg: String): String {
        return try {
            val appInfo = packageManager.getApplicationInfo(pkg, 0)
            packageManager.getApplicationLabel(appInfo).toString()
        } catch (_: PackageManager.NameNotFoundException) {
            pkg.substringAfterLast(".").replaceFirstChar { it.uppercase() }
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "App Blocker",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Monitors apps that have exceeded their time limits"
                setShowBadge(false)
            }
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
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
            .setContentText("App limits active — limits enforced")
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setOngoing(true)
            .setContentIntent(pendingIntent)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .build()
    }
}
