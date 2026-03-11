package com.focustrack.app

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.os.Build
import android.os.Bundle
import android.view.Gravity
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

class AppLockActivity : Activity() {

    companion object {
        /** True while this activity is in the resumed (visible and interactive) state. */
        @Volatile
        var isActive = false

        private const val EXTRA_APP_NAME = "app_name"

        fun launch(context: Context, appName: String) {
            val intent = Intent(context, AppLockActivity::class.java).apply {
                putExtra(EXTRA_APP_NAME, appName)
                addFlags(
                    Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
                )
            }
            context.startActivity(intent)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Show even over the lock screen and keep screen on
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            )
        }
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        buildUi(intent?.getStringExtra(EXTRA_APP_NAME) ?: "this app")
    }

    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        setIntent(intent)
        buildUi(intent?.getStringExtra(EXTRA_APP_NAME) ?: "this app")
    }

    override fun onResume() {
        super.onResume()
        isActive = true
    }

    override fun onPause() {
        super.onPause()
        isActive = false
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        // Intercept back — do NOT let user navigate back to the blocked app
        goHome()
    }

    private fun goHome() {
        startActivity(Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_HOME)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        })
    }

    private fun buildUi(appName: String) {
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(Color.parseColor("#0B0B0F"))
            setPadding(80, 0, 80, 0)
        }

        // Lock icon
        root.addView(TextView(this).apply {
            text = "\uD83D\uDD12"   // 🔒
            textSize = 72f
            gravity = Gravity.CENTER
        })

        // Title
        root.addView(TextView(this).apply {
            text = "Time Limit Reached"
            textSize = 26f
            setTextColor(Color.WHITE)
            setTypeface(null, Typeface.BOLD)
            gravity = Gravity.CENTER
            setPadding(0, 48, 0, 20)
        })

        // Subtitle
        root.addView(TextView(this).apply {
            text = "You've reached your daily limit\nfor $appName.\n\nTake a break! \uD83C\uDF31"
            textSize = 15f
            setTextColor(Color.parseColor("#AAAAAA"))
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 72)
        })

        // Go Home button
        root.addView(Button(this).apply {
            text = "Go to Home Screen"
            textSize = 16f
            setTextColor(Color.WHITE)
            setBackgroundColor(Color.parseColor("#6C63FF"))
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).also { it.bottomMargin = 32 }
            setPadding(80, 32, 80, 32)
            setOnClickListener { goHome() }
        })

        // Open FocusTrack button (to change / disable the limit)
        root.addView(Button(this).apply {
            text = "Open FocusTrack to Adjust Limit"
            textSize = 13f
            setTextColor(Color.parseColor("#9090FF"))
            setBackgroundColor(Color.TRANSPARENT)
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
            setOnClickListener {
                packageManager.getLaunchIntentForPackage(packageName)?.also { li ->
                    li.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                    startActivity(li)
                }
            }
        })

        setContentView(root)
    }
}
