package com.auralis.app

import android.annotation.SuppressLint
import android.app.Activity
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.util.Log

class BatteryOptimizationHelper(private val activity: Activity) {

    private val TAG = "BatteryOptHelper"

    /**
     * Checks if the app is already whitelisted from battery optimizations.
     * Returns true if optimizations are DISABLED (app can run freely).
     */
    fun isBatteryOptimizationDisabled(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return true
        val powerManager = activity.getSystemService(Context.POWER_SERVICE) as? PowerManager
        return powerManager?.isIgnoringBatteryOptimizations(activity.packageName) ?: false
    }

    /**
     * Attempts to open the system dialog or OEM settings to disable restrictions.
     * Returns true if a settings page was successfully launched.
     */
    @SuppressLint("BatteryLife")
    fun openDisableRestrictionsSettings(): Boolean {
        // 1. Try the standard Android Request (Most direct, might be blocked by Play Store)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                    data = Uri.parse("package:${activity.packageName}")
                }
                if (launchIntent(intent)) return true
            } catch (e: Exception) {
                Log.e(TAG, "Standard request failed: ${e.message}")
            }
        }

        // 2. Try OEM Specific "Autostart" and "Power Management" activities
        val manufacturer = Build.MANUFACTURER.lowercase()
        val oemIntents = mutableListOf<Intent>()

        when {
            // XIAOMI / REDMI / POCO (MIUI & HyperOS)
            manufacturer.contains("xiaomi") || manufacturer.contains("redmi") || manufacturer.contains("poco") -> {
                oemIntents.add(componentIntent("com.miui.securitycenter", "com.miui.permcenter.autostart.AutoStartManagementActivity"))
                oemIntents.add(componentIntent("com.miui.securitycenter", "com.miui.powerkeeper.ui.HiddenAppsConfigActivity").apply {
                    putExtra("package_name", activity.packageName)
                    putExtra("package_label", getAppName())
                })
            }

            // SAMSUNG (One UI 1.0 - 6.x+)
            manufacturer.contains("samsung") -> {
                oemIntents.add(componentIntent("com.samsung.android.lool", "com.samsung.android.sm.ui.battery.BatteryActivity"))
                oemIntents.add(componentIntent("com.samsung.android.sm_cn", "com.samsung.android.sm.ui.battery.BatteryActivity"))
                oemIntents.add(componentIntent("com.samsung.android.sm", "com.samsung.android.sm.ui.battery.BatteryActivity"))
                oemIntents.add(Intent("android.settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS"))
            }

            // OPPO / REALME / ONEPLUS (ColorOS / RealmeUI / OxygenOS)
            manufacturer.contains("oppo") || manufacturer.contains("realme") || manufacturer.contains("oneplus") -> {
                oemIntents.add(componentIntent("com.coloros.safecenter", "com.coloros.safecenter.startupapp.StartupAppListActivity"))
                oemIntents.add(componentIntent("com.oplus.safecenter", "com.oplus.safecenter.startupapp.view.StartupAppListActivity"))
                oemIntents.add(componentIntent("com.coloros.safecenter", "com.coloros.safecenter.permission.startup.StartupAppListActivity"))
                oemIntents.add(componentIntent("com.coloros.lowpower", "com.coloros.lowpower.view.FakeBatteryGraphActivity"))
            }

            // VIVO / IQOO (FuntouchOS / OriginOS)
            manufacturer.contains("vivo") || manufacturer.contains("iqoo") -> {
                oemIntents.add(componentIntent("com.vivo.permissionmanager", "com.vivo.permissionmanager.activity.BgStartUpManagerActivity"))
                oemIntents.add(componentIntent("com.vivo.abe", "com.vivo.applicationbehaviorengine.ui.ExcessivePowerManagerActivity"))
                oemIntents.add(componentIntent("com.iqoo.secure", "com.iqoo.secure.ui.phoneoptimize.BgStartUpManager"))
            }

            // HUAWEI / HONOR (EMUI / MagicOS)
            manufacturer.contains("huawei") || manufacturer.contains("honor") -> {
                oemIntents.add(componentIntent("com.huawei.systemmanager", "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity"))
                oemIntents.add(componentIntent("com.huawei.systemmanager", "com.huawei.systemmanager.optimize.process.ProtectActivity"))
                oemIntents.add(componentIntent("com.huawei.systemmanager", "com.huawei.systemmanager.appcontrol.activity.StartupAppControlActivity"))
            }
        }

        // Try each OEM intent until one works
        for (intent in oemIntents) {
            if (launchIntent(intent)) return true
        }

        // 3. Fallback to standard "Ignore Battery Optimizations" list
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (launchIntent(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))) return true
        }

        // 4. Ultimate Fallback: App Details Screen
        return try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.fromParts("package", activity.packageName, null)
            }
            launchIntent(intent)
        } catch (e: Exception) {
            false
        }
    }

    private fun componentIntent(pkg: String, cls: String): Intent {
        return Intent().apply {
            component = ComponentName(pkg, cls)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
    }

    private fun launchIntent(intent: Intent): Boolean {
        return try {
            if (intent.resolveActivity(activity.packageManager) != null) {
                activity.startActivity(intent)
                true
            } else false
        } catch (e: Exception) {
            false
        }
    }

    private fun getAppName(): String {
        return try {
            activity.applicationInfo.loadLabel(activity.packageManager).toString()
        } catch (e: Exception) {
            "this app"
        }
    }
}