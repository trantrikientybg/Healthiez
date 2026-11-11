package com.example.healthiez // <-- Giữ nguyên dòng package đầu tiên hiện có của tệp bạn!

import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar

class MainActivity : FlutterActivity() {
    private val CHANNEL = "healthiez/screen_time"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getTodayScreenOnMinutes") {
                val minutes = getTodayScreenOnMinutes()
                if (minutes == -1) {
                    // Chưa cấp quyền -> mở trang Cài đặt Usage Access
                    startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                    result.success(0)
                } else {
                    result.success(minutes)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getTodayScreenOnMinutes(): Int {
        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val now = System.currentTimeMillis()
        val cal = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val startOfDay = cal.timeInMillis

        val events = usm.queryEvents(startOfDay, now)
        val event = UsageEvents.Event()

        var hasAnyEvent = false
        var totalForegroundMs = 0L
        var currentSessionStart = 0L
        var activePackage: String? = null

        // Loại trừ màn hình chờ (Launcher) và SystemUI
        val ignoredPackages = setOf(
            "com.android.systemui",
            "com.google.android.apps.nexuslauncher",
            "com.sec.android.app.launcher",
            "com.miui.home"
        )

        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            hasAnyEvent = true
            val pkg = event.packageName ?: continue
            if (ignoredPackages.contains(pkg)) continue

            when (event.eventType) {
                UsageEvents.Event.ACTIVITY_RESUMED -> {
                    if (currentSessionStart == 0L) {
                        currentSessionStart = event.timeStamp
                        activePackage = pkg
                    }
                }
                UsageEvents.Event.ACTIVITY_PAUSED,
                UsageEvents.Event.ACTIVITY_STOPPED -> {
                    if (currentSessionStart > 0L && activePackage == pkg) {
                        totalForegroundMs += (event.timeStamp - currentSessionStart)
                        currentSessionStart = 0L
                        activePackage = null
                    }
                }
            }
        }

        // Nếu người dùng đang mở 1 app ngay tại thời điểm hiện tại (chưa thoát app)
        if (currentSessionStart > 0L) {
            totalForegroundMs += (now - currentSessionStart)
        }

        if (!hasAnyEvent) return -1
        return (totalForegroundMs / 1000 / 60).toInt()
    }
}
