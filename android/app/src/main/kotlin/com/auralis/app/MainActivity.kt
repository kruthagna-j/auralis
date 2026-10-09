package com.auralis.app

import android.bluetooth.BluetoothA2dp
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.content.ContentUris
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.media.MediaRouter
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.provider.Settings
import android.util.Size
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import java.io.ByteArrayOutputStream

class MainActivity : com.ryanheise.audioservice.AudioServiceActivity() {
    private val CHANNEL = "com.auralis.app/audio_output"
    private val LOCAL_SONGS_CHANNEL = "com.auralis.app/local_songs"
    private val BATTERY_OPTIMIZATION_CHANNEL = "com.auralis.app/battery_optimization"
    private var bluetoothA2dp: BluetoothA2dp? = null
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private val batteryOptimizationHelper by lazy { BatteryOptimizationHelper(this) }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        setupBluetoothProxy()
        setupLocalSongsChannel(flutterEngine)
        setupBatteryOptimizationChannel(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getAudioDevices" -> {
                    result.success(getConnectedOutputDevices())
                }
                "getCurrentOutput" -> {
                    result.success(getCurrentAudioOutput())
                }
                "openSoundSettings" -> {
                    openSoundSettings()
                    result.success(null)
                }
                "setAudioOutput" -> {
                    val deviceId = call.argument<Int>("deviceId")
                    if (deviceId != null) {
                        val success = switchAudioOutput(deviceId)
                        result.success(success)
                    } else {
                        result.error("INVALID_ARG", "deviceId is required", null)
                    }
                }
                "openMediaOutputSwitcher" -> {
                    result.success(openMediaOutputSwitcher())
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun setupBatteryOptimizationChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BATTERY_OPTIMIZATION_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isBatteryOptimizationDisabled" -> {
                        result.success(batteryOptimizationHelper.isBatteryOptimizationDisabled())
                    }
                    "openDisableRestrictionsSettings" -> {
                        result.success(batteryOptimizationHelper.openDisableRestrictionsSettings())
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // ── Local Songs Method Channel ────────────────────────────────────────
    private fun setupLocalSongsChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LOCAL_SONGS_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "querySongs" -> {
                        scope.launch {
                            try {
                                val songs = querySongsFromMediaStore()
                                withContext(Dispatchers.Main) { result.success(songs) }
                            } catch (e: Exception) {
                                withContext(Dispatchers.Main) {
                                    result.error("QUERY_ERROR", e.message, null)
                                }
                            }
                        }
                    }
                    "queryArtwork" -> {
                        val id = call.argument<Int>("id")
                        val size = call.argument<Int>("size") ?: 500
                        if (id == null) {
                            result.error("INVALID_ARG", "id is required", null)
                        } else {
                            scope.launch {
                                try {
                                    val bytes = queryArtworkFromMediaStore(id.toLong(), size)
                                    withContext(Dispatchers.Main) { result.success(bytes) }
                                } catch (e: Exception) {
                                    withContext(Dispatchers.Main) { result.success(null) }
                                }
                            }
                        }
                    }
                    "scanMedia" -> {
                        val path = call.argument<String>("path")
                        if (path != null) {
                            MediaScannerConnection.scanFile(
                                this@MainActivity,
                                arrayOf(path),
                                null
                            ) { _, _ -> }
                            result.success(null)
                        } else {
                            result.error("INVALID_ARG", "path is required", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun querySongsFromMediaStore(): List<Map<String, Any?>> {
        val songs = mutableListOf<Map<String, Any?>>()
        val collection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL)
        } else {
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        }

        val projection = arrayOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.ALBUM,
            MediaStore.Audio.Media.ALBUM_ID,
            MediaStore.Audio.Media.DURATION,
            MediaStore.Audio.Media.DATA,
            MediaStore.Audio.Media.IS_MUSIC,
        )

        val selection = "${MediaStore.Audio.Media.IS_MUSIC} != 0"
        val sortOrder = "${MediaStore.Audio.Media.TITLE} ASC"

        contentResolver.query(collection, projection, selection, null, sortOrder)?.use { cursor ->
            val idCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
            val titleCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)
            val artistCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST)
            val albumCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM)
            val albumIdCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM_ID)
            val durationCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)
            val dataCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA)

            while (cursor.moveToNext()) {
                val id = cursor.getLong(idCol)
                val durationMs = cursor.getLong(durationCol)
                songs.add(
                    mapOf(
                        "id" to id.toInt(),
                        "title" to (cursor.getString(titleCol) ?: "Unknown"),
                        "artist" to (cursor.getString(artistCol) ?: "<unknown>"),
                        "album" to (cursor.getString(albumCol) ?: ""),
                        "albumId" to cursor.getLong(albumIdCol).toInt(),
                        "duration" to (durationMs / 1000).toInt(),
                        "durationMs" to durationMs.toInt(),
                        "data" to (cursor.getString(dataCol) ?: ""),
                    )
                )
            }
        }
        return songs
    }

    private fun queryArtworkFromMediaStore(audioId: Long, size: Int): ByteArray? {
        // API 29+ : use loadThumbnail
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            try {
                val uri = ContentUris.withAppendedId(
                    MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, audioId
                )
                val bmp = contentResolver.loadThumbnail(uri, Size(size, size), null)
                return bitmapToBytes(bmp)
            } catch (_: Exception) {}
        }

        // Fallback: read album art from album art URI
        try {
            // First get the album ID for this audio
            val projection = arrayOf(MediaStore.Audio.Media.ALBUM_ID)
            val selection = "${MediaStore.Audio.Media._ID} = ?"
            val selectionArgs = arrayOf(audioId.toString())
            var albumId: Long? = null

            contentResolver.query(
                MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                projection, selection, selectionArgs, null
            )?.use { cursor ->
                if (cursor.moveToFirst()) {
                    albumId = cursor.getLong(0)
                }
            }

            if (albumId != null) {
                val albumArtUri = ContentUris.withAppendedId(
                    Uri.parse("content://media/external/audio/albumart"),
                    albumId!!
                )
                contentResolver.openInputStream(albumArtUri)?.use { inputStream ->
                    val opts = BitmapFactory.Options().apply {
                        inSampleSize = 1
                    }
                    val bmp = BitmapFactory.decodeStream(inputStream, null, opts)
                    if (bmp != null) {
                        val scaled = Bitmap.createScaledBitmap(bmp, size, size, true)
                        val bytes = bitmapToBytes(scaled)
                        if (scaled != bmp) scaled.recycle()
                        bmp.recycle()
                        return bytes
                    }
                }
            }
        } catch (_: Exception) {}

        return null
    }

    private fun bitmapToBytes(bmp: Bitmap): ByteArray {
        val stream = ByteArrayOutputStream()
        bmp.compress(Bitmap.CompressFormat.JPEG, 80, stream)
        return stream.toByteArray()
    }

    override fun onDestroy() {
        scope.cancel()
        val a2dp = bluetoothA2dp
        if (a2dp != null) {
            try {
                val bm = getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
                bm?.adapter?.closeProfileProxy(BluetoothProfile.A2DP, a2dp)
            } catch (_: Exception) {}
            bluetoothA2dp = null
        }
        super.onDestroy()
    }

    private fun setupBluetoothProxy() {
        try {
            val bm = getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
            bm?.adapter?.getProfileProxy(applicationContext, object : BluetoothProfile.ServiceListener {
                override fun onServiceConnected(profile: Int, proxy: BluetoothProfile) {
                    if (profile == BluetoothProfile.A2DP) {
                        bluetoothA2dp = proxy as BluetoothA2dp
                    }
                }
                override fun onServiceDisconnected(profile: Int) {
                    if (profile == BluetoothProfile.A2DP) {
                        bluetoothA2dp = null
                    }
                }
            }, BluetoothProfile.A2DP)
        } catch (_: Exception) {}
    }

    // ── Accepted output device types ──────────────────────────────────────
    private val connectedOutputTypes = setOf(
        AudioDeviceInfo.TYPE_BUILTIN_SPEAKER,
        AudioDeviceInfo.TYPE_WIRED_HEADSET,
        AudioDeviceInfo.TYPE_WIRED_HEADPHONES,
        AudioDeviceInfo.TYPE_BLUETOOTH_A2DP,
        AudioDeviceInfo.TYPE_BLUETOOTH_SCO,
        AudioDeviceInfo.TYPE_USB_DEVICE,
        AudioDeviceInfo.TYPE_USB_ACCESSORY,
        AudioDeviceInfo.TYPE_USB_HEADSET,
        AudioDeviceInfo.TYPE_HDMI,
        AudioDeviceInfo.TYPE_HDMI_ARC,
        AudioDeviceInfo.TYPE_HDMI_EARC,
        23,  // TYPE_HEARING_AID  (API 28)
        26,  // TYPE_BLE_HEADSET  (API 31)
        27,  // TYPE_BLE_SPEAKER  (API 31)
        30   // TYPE_BLE_BROADCAST (API 33)
    )

    private val preferredBluetoothTypes = setOf(
        AudioDeviceInfo.TYPE_BLUETOOTH_A2DP,
        26, 27 // BLE_HEADSET, BLE_SPEAKER
    )

    // ── List all connected output devices ─────────────────────────────────
    private fun getConnectedOutputDevices(): List<Map<String, Any>> {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val allDevices = audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
        val deviceList = mutableListOf<Map<String, Any>>()
        val seenKeys = mutableSetOf<String>()

        val sorted = allDevices.sortedBy { d ->
            if (d.type in preferredBluetoothTypes) 0
            else if (d.type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO) 1
            else 0
        }

        for (device in sorted) {
            if (device.type !in connectedOutputTypes) continue
            val portType = mapDeviceType(device.type)
            val pName = device.productName?.toString() ?: ""
            val hasRealName = pName.isNotEmpty() && pName != device.type.toString()
            val dedupeKey = when {
                portType == "bluetooth" && hasRealName -> "bt:$pName"
                portType == "bluetooth" -> "bt:${device.id}"
                portType == "speaker" -> "speaker"
                else -> "$portType:${device.id}"
            }
            if (seenKeys.contains(dedupeKey)) continue
            seenKeys.add(dedupeKey)
            deviceList.add(buildDeviceMap(device))
        }

    
        try {
            val a2dp = bluetoothA2dp
            if (a2dp != null) {
                for (btDevice in a2dp.connectedDevices) {
                    val name = btDevice.name ?: "Bluetooth Device"
                    val key = "bt:$name"
                    if (seenKeys.contains(key)) continue
                    seenKeys.add(key)
                    deviceList.add(mapOf(
                        "name" to name,
                        "port" to "bluetooth",
                        "id" to (btDevice.address?.hashCode() ?: 0),
                        "type" to AudioDeviceInfo.TYPE_BLUETOOTH_A2DP
                    ))
                }
            }
        } catch (_: SecurityException) { /* BLUETOOTH_CONNECT not granted */ }
        catch (_: Exception) {}

        return deviceList
    }

    private fun getCurrentAudioOutput(): Map<String, Any> {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val devices = audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS)

  
        try {
            val mediaRouter = getSystemService(Context.MEDIA_ROUTER_SERVICE) as? MediaRouter
            if (mediaRouter != null) {
                val route = mediaRouter.getSelectedRoute(MediaRouter.ROUTE_TYPE_LIVE_AUDIO)
                if (route != null) {
                    val routeName = route.getName(this)?.toString() ?: ""
                    val deviceType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                        route.deviceType
                    } else -1

                    when {
                        // Bluetooth route
                        deviceType == 3 /* DEVICE_TYPE_BLUETOOTH */ -> {
                            return resolveBluetoothCurrent(routeName, devices)
                        }
                        // Speaker / default route (also covers wired headphones on some OEMs)
                        deviceType == 2 /* DEVICE_TYPE_SPEAKER */ || deviceType == -1 -> {
                            return resolveNonBluetoothCurrent(audioManager, devices)
                        }
                        // TV / HDMI route
                        deviceType == 1 /* DEVICE_TYPE_TV */ -> {
                            val hdmi = devices.firstOrNull {
                                it.type == AudioDeviceInfo.TYPE_HDMI ||
                                it.type == AudioDeviceInfo.TYPE_HDMI_ARC ||
                                it.type == AudioDeviceInfo.TYPE_HDMI_EARC
                            }
                            if (hdmi != null) return buildDeviceMap(hdmi)
                        }
                    }
                }
            }
        } catch (_: Exception) {}

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            try {
                val configs = audioManager.activePlaybackConfigurations
                for (config in configs) {
                    val dev = config.audioDeviceInfo
                    if (dev != null && dev.type in connectedOutputTypes) {
                        return buildDeviceMap(dev)
                    }
                }
            } catch (_: Exception) {}
        }

        return resolveNonBluetoothCurrent(audioManager, devices)
    }

    /** Resolve the current BT device by matching the MediaRouter route name. */
    private fun resolveBluetoothCurrent(
        routeName: String,
        devices: Array<AudioDeviceInfo>
    ): Map<String, Any> {
        val allBt = devices.filter { mapDeviceType(it.type) == "bluetooth" }
        if (routeName.isNotEmpty()) {
            val matched = allBt.firstOrNull {
                it.productName?.toString().equals(routeName, ignoreCase = true)
            }
            if (matched != null) return buildDeviceMap(matched)
        }

        try {
            val a2dp = bluetoothA2dp
            if (a2dp != null && routeName.isNotEmpty()) {
                val btMatched = a2dp.connectedDevices.firstOrNull {
                    it.name.equals(routeName, ignoreCase = true)
                }
                if (btMatched != null) {
                    return mapOf(
                        "name" to (btMatched.name ?: "Bluetooth Device"),
                        "port" to "bluetooth",
                        "id" to (btMatched.address?.hashCode() ?: 0),
                        "type" to AudioDeviceInfo.TYPE_BLUETOOTH_A2DP
                    )
                }
            }
        } catch (_: SecurityException) {}
        catch (_: Exception) {}

        if (allBt.isNotEmpty()) return buildDeviceMap(allBt.first())
        return mapOf(
            "name" to routeName.ifEmpty { "Bluetooth Device" },
            "port" to "bluetooth",
            "id" to 0,
            "type" to AudioDeviceInfo.TYPE_BLUETOOTH_A2DP
        )
    }

    /** Resolve non-BT current output: wired > USB > speaker. */
    private fun resolveNonBluetoothCurrent(
        audioManager: AudioManager,
        devices: Array<AudioDeviceInfo>
    ): Map<String, Any> {
        @Suppress("DEPRECATION")
        if (audioManager.isWiredHeadsetOn) {
            val wired = devices.filter {
                it.type == AudioDeviceInfo.TYPE_WIRED_HEADSET ||
                it.type == AudioDeviceInfo.TYPE_WIRED_HEADPHONES
            }
            if (wired.isNotEmpty()) return buildDeviceMap(wired.first())
        }

        val usb = devices.filter {
            it.type == AudioDeviceInfo.TYPE_USB_DEVICE ||
            it.type == AudioDeviceInfo.TYPE_USB_ACCESSORY ||
            it.type == AudioDeviceInfo.TYPE_USB_HEADSET
        }
        if (usb.isNotEmpty()) return buildDeviceMap(usb.first())

        val speakers = devices.filter { it.type == AudioDeviceInfo.TYPE_BUILTIN_SPEAKER }
        if (speakers.isNotEmpty()) return buildDeviceMap(speakers.first())

        return mapOf("name" to "Phone Speaker", "port" to "speaker", "id" to 0, "type" to 0)
    }


    private fun buildDeviceMap(device: AudioDeviceInfo): Map<String, Any> {
        val portType = mapDeviceType(device.type)
        val pName = device.productName?.toString() ?: ""
        val name = if (pName.isNotEmpty() && pName != device.type.toString()) {
            pName
        } else {
            when (portType) {
                "speaker" -> "Phone Speaker"
                "headphones" -> "Wired Headphones"
                "bluetooth" -> "Bluetooth Device"
                "usb" -> "USB Audio"
                "hdmi" -> "HDMI Output"
                "hearing_aid" -> "Hearing Aid"
                else -> "Audio Device"
            }
        }
        return mapOf(
            "name" to name,
            "port" to portType,
            "id" to device.id,
            "type" to device.type
        )
    }

    private fun switchAudioOutput(deviceId: Int): Boolean {
        return openMediaOutputSwitcher()
    }

    private fun openMediaOutputSwitcher(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            try {
                val intent = Intent("com.android.systemui.action.LAUNCH_MEDIA_OUTPUT_DIALOG")
                intent.setPackage("com.android.systemui")
                intent.putExtra("package_name", packageName)
                sendBroadcast(intent)
                return true
            } catch (_: Exception) {}
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            try {
                val panelIntent = Intent(Settings.Panel.ACTION_VOLUME)
                startActivity(panelIntent)
                return true
            } catch (_: Exception) {}
        }
        openSoundSettings()
        return true
    }

    private fun openSoundSettings() {
        try {
            val intent = Intent(Settings.ACTION_SOUND_SETTINGS)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
        } catch (_: Exception) {}
    }

    private fun mapDeviceType(type: Int): String {
        return when (type) {
            AudioDeviceInfo.TYPE_BUILTIN_EARPIECE -> "receiver"
            AudioDeviceInfo.TYPE_BUILTIN_SPEAKER -> "speaker"
            AudioDeviceInfo.TYPE_WIRED_HEADSET,
            AudioDeviceInfo.TYPE_WIRED_HEADPHONES -> "headphones"
            AudioDeviceInfo.TYPE_BLUETOOTH_A2DP,
            AudioDeviceInfo.TYPE_BLUETOOTH_SCO,
            26, 27, 30 -> "bluetooth"
            AudioDeviceInfo.TYPE_USB_DEVICE,
            AudioDeviceInfo.TYPE_USB_ACCESSORY,
            AudioDeviceInfo.TYPE_USB_HEADSET -> "usb"
            AudioDeviceInfo.TYPE_HDMI,
            AudioDeviceInfo.TYPE_HDMI_ARC,
            AudioDeviceInfo.TYPE_HDMI_EARC -> "hdmi"
            23 -> "hearing_aid"
            else -> "unknown"
        }
    }
}
