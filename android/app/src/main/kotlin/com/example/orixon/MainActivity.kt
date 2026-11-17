package com.example.orixon

import android.Manifest
import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Color
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.media.AudioManager
import android.view.MotionEvent
import android.media.MediaMetadataRetriever
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.net.Uri
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Bundle
import android.app.PictureInPictureParams
import android.util.Rational
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.os.StatFs
import android.os.StrictMode
import android.provider.MediaStore
import android.provider.Settings
import android.view.View
import android.webkit.CookieManager
import android.webkit.WebChromeClient
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.File
import java.util.concurrent.Executors

class MainActivity : FlutterActivity(), SensorEventListener {

    private var wifiLock: WifiManager.WifiLock? = null
    private var netCallback: ConnectivityManager.NetworkCallback? = null
    private val thumbnailExecutor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())
    private var pendingPermissionResult: MethodChannel.Result? = null

    companion object {
        private const val CHANNEL = "com.example.orixon/local_media"
        private const val SYS_CHANNEL = "com.example.orixon/system_tools"
        private const val WEBX_CHANNEL = "com.example.orixon/webx"
        private const val VIDEO_PERMISSION_REQUEST = 4101
        private const val STORAGE_PERMISSION_REQUEST = 4102
    }

    private var sensorManager: SensorManager? = null
    private var vrGyroActive = false
    private var vrYaw = 0.0
    private var vrPitch = 0.0
    private var lastSensorTs = 0L

    private fun startVrGyroTracking() {
        try {
            if (sensorManager == null) {
                sensorManager = getSystemService(Context.SENSOR_SERVICE) as? SensorManager
            }
            val sm = sensorManager ?: return
            if (vrGyroActive) return
            vrYaw = 0.0
            vrPitch = 0.0
            lastSensorTs = 0L
            val gyro = sm.getDefaultSensor(Sensor.TYPE_GYROSCOPE)
            val rot = sm.getDefaultSensor(Sensor.TYPE_GAME_ROTATION_VECTOR)
                ?: sm.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)
            val accel = sm.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
            if (gyro != null) sm.registerListener(this, gyro, SensorManager.SENSOR_DELAY_GAME)
            if (rot != null) sm.registerListener(this, rot, SensorManager.SENSOR_DELAY_GAME)
            if (gyro == null && rot == null && accel != null) {
                sm.registerListener(this, accel, SensorManager.SENSOR_DELAY_GAME)
            }
            vrGyroActive = true
        } catch (_: Throwable) {}
    }

    private fun stopVrGyroTracking() {
        try {
            sensorManager?.unregisterListener(this)
            vrGyroActive = false
        } catch (_: Throwable) {}
    }

    override fun onSensorChanged(event: SensorEvent?) {
        if (event == null || !vrGyroActive) return
        when (event.sensor.type) {
            Sensor.TYPE_GYROSCOPE -> {
                if (lastSensorTs != 0L) {
                    val dt = (event.timestamp - lastSensorTs) * 1e-9
                    if (dt > 0.0 && dt < 0.5) {
                        // Integrate angular velocity for smooth 360 head tracking
                        vrYaw = (vrYaw - event.values[1] * dt * 1.35).coerceIn(-1.25, 1.25)
                        vrPitch = (vrPitch + event.values[0] * dt * 1.15).coerceIn(-0.70, 0.70)
                    }
                }
                lastSensorTs = event.timestamp
            }
            Sensor.TYPE_ACCELEROMETER -> {
                val ax = event.values[0].toDouble()
                val ay = event.values[1].toDouble()
                val az = event.values[2].toDouble()
                vrPitch = (vrPitch * 0.88 + (az / 12.0).coerceIn(-0.65, 0.65) * 0.12)
                vrYaw = (vrYaw * 0.88 + (-ax / 12.0).coerceIn(-1.1, 1.1) * 0.12)
            }
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    // Support external USB / Bluetooth VR Headsets & Gyro AirMice connected to Android TV
    override fun onGenericMotionEvent(event: MotionEvent?): Boolean {
        if (vrGyroActive && event != null) {
            val rx = event.getAxisValue(MotionEvent.AXIS_RX) + event.getAxisValue(MotionEvent.AXIS_Z)
            val ry = event.getAxisValue(MotionEvent.AXIS_RY) + event.getAxisValue(MotionEvent.AXIS_RZ)
            if (Math.abs(rx) > 0.01f || Math.abs(ry) > 0.01f) {
                vrYaw = (vrYaw + rx * 0.08).coerceIn(-1.25, 1.25)
                vrPitch = (vrPitch + ry * 0.08).coerceIn(-0.70, 0.70)
            }
        }
        return super.onGenericMotionEvent(event)
    }

    private fun openUrlExternal(url: String) {
        try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url)).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
        } catch (_: Throwable) {}
    }

    private fun forceStartupVolumeTo75Percent() {
        try {
            val am = applicationContext.getSystemService(Context.AUDIO_SERVICE) as? AudioManager ?: return
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                try {
                    am.adjustStreamVolume(AudioManager.STREAM_MUSIC, AudioManager.ADJUST_UNMUTE, 0)
                } catch (_: Throwable) {}
            }
            val maxVol = am.getStreamMaxVolume(AudioManager.STREAM_MUSIC).coerceAtLeast(1)
            val targetVol = Math.round(maxVol * 0.75f).toInt().coerceIn(1, maxVol)
            am.setStreamVolume(AudioManager.STREAM_MUSIC, targetVol, 0)
        } catch (_: Throwable) {}
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        forceStartupVolumeTo75Percent()
        mainHandler.postDelayed({ forceStartupVolumeTo75Percent() }, 150)
        mainHandler.postDelayed({ forceStartupVolumeTo75Percent() }, 400)
        enableNetworkTurboMode()
    }

    override fun onResume() {
        super.onResume()
        enableNetworkTurboMode()
    }

    override fun onDestroy() {
        stopVrGyroTracking()
        releaseNetworkTurboMode()
        super.onDestroy()
    }

    private fun enableNetworkTurboMode() {
        try {
            val wm = applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager
            if (wm != null && wifiLock == null) {
                val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    WifiManager.WIFI_MODE_FULL_LOW_LATENCY
                } else {
                    @Suppress("DEPRECATION")
                    WifiManager.WIFI_MODE_FULL_HIGH_PERF
                }
                wifiLock = wm.createWifiLock(mode, "Orixon:NetworkTurboLock").apply {
                    setReferenceCounted(false)
                    acquire()
                }
            }
        } catch (_: Throwable) {}

        try {
            val cm = applicationContext.getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager
            if (cm != null && netCallback == null) {
                val req = NetworkRequest.Builder()
                    .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
                    .addCapability(NetworkCapabilities.NET_CAPABILITY_NOT_RESTRICTED)
                    .addTransportType(NetworkCapabilities.TRANSPORT_CELLULAR)
                    .addTransportType(NetworkCapabilities.TRANSPORT_WIFI)
                    .build()
                val cb = object : ConnectivityManager.NetworkCallback() {
                    override fun onAvailable(network: Network) {
                        try { cm.reportNetworkConnectivity(network, true) } catch (_: Throwable) {}
                    }
                }
                netCallback = cb
                cm.requestNetwork(req, cb)
            }
        } catch (_: Throwable) {}
    }

    private fun releaseNetworkTurboMode() {
        try {
            wifiLock?.let { if (it.isHeld) it.release() }
            wifiLock = null
        } catch (_: Throwable) {}
        try {
            val cm = applicationContext.getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager
            netCallback?.let { cm?.unregisterNetworkCallback(it) }
            netCallback = null
        } catch (_: Throwable) {}
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) {
            window.decorView.systemUiVisibility =
                View.SYSTEM_UI_FLAG_FULLSCREEN or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
        }
    }

    private fun getVideoThumbnail(call: MethodCall, result: MethodChannel.Result) {
        val uriValue = call.argument<String>("uri")
        if (uriValue.isNullOrBlank()) {
            result.error("INVALID_URI", "Video URI is required.", null)
            return
        }
        val width = (call.argument<Int>("maxWidth") ?: 320).coerceIn(64, 1280)
        val height = (call.argument<Int>("maxHeight") ?: 180).coerceIn(64, 1280)
        val timeMs = (call.argument<Number>("timeMs")?.toLong() ?: -1L)
        val timeUs = if (timeMs >= 0L) timeMs * 1000L else -1L

        thumbnailExecutor.execute {
            var retriever: MediaMetadataRetriever? = null
            var bitmap: Bitmap? = null
            try {
                retriever = MediaMetadataRetriever()
                if (uriValue.startsWith("content://")) {
                    retriever.setDataSource(this@MainActivity, Uri.parse(uriValue))
                } else {
                    val cleanPath = uriValue.removePrefix("file://")
                    retriever.setDataSource(cleanPath)
                }
                val option = if (timeUs >= 0L) MediaMetadataRetriever.OPTION_CLOSEST else MediaMetadataRetriever.OPTION_CLOSEST_SYNC
                val frame = if (Build.VERSION.SDK_INT >= 27) {
                    retriever.getScaledFrameAtTime(timeUs, option, width, height)
                } else {
                    retriever.getFrameAtTime(timeUs, option)
                } ?: throw IllegalStateException("No video frame")
                bitmap = frame
                val bytes = ByteArrayOutputStream().use { out ->
                    bitmap.compress(Bitmap.CompressFormat.JPEG, 72, out)
                    out.toByteArray()
                }
                mainHandler.post { result.success(bytes) }
            } catch (e: Exception) {
                mainHandler.post { result.error("THUMBNAIL_FAILED", e.message, null) }
            } finally {
                bitmap?.recycle()
                try { retriever?.release() } catch (_: Exception) {}
            }
        }
    }

    private fun requestVideoPermission(result: MethodChannel.Result) {
        if (hasVideoPermission()) {
            result.success(true)
            return
        }
        pendingPermissionResult = result
        val perms = when {
            Build.VERSION.SDK_INT >= 34 -> arrayOf(Manifest.permission.READ_MEDIA_VIDEO, Manifest.permission.READ_MEDIA_VISUAL_USER_SELECTED)
            Build.VERSION.SDK_INT >= 33 -> arrayOf(Manifest.permission.READ_MEDIA_VIDEO)
            else -> arrayOf(Manifest.permission.READ_EXTERNAL_STORAGE)
        }
        requestPermissions(perms, VIDEO_PERMISSION_REQUEST)
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == VIDEO_PERMISSION_REQUEST) {
            pendingPermissionResult?.success(hasVideoPermission())
            pendingPermissionResult = null
        }
    }

    private fun queryInternalVideos(): List<Map<String, Any?>> {
        if (!hasVideoPermission()) throw SecurityException("Permission denied")
        val projection = arrayOf(
            MediaStore.Video.Media._ID,
            MediaStore.Video.Media.DISPLAY_NAME,
            MediaStore.Video.Media.MIME_TYPE,
            MediaStore.Video.Media.SIZE,
            MediaStore.Video.Media.DATE_MODIFIED,
            MediaStore.Video.Media.DURATION,
            MediaStore.Video.Media.BUCKET_DISPLAY_NAME,
            MediaStore.Video.Media.RELATIVE_PATH
        )
        val videos = mutableListOf<Map<String, Any?>>()
        val col = MediaStore.Video.Media.EXTERNAL_CONTENT_URI
        contentResolver.query(col, projection, null, null, "${MediaStore.Video.Media.DATE_MODIFIED} DESC")?.use { c ->
            val idCol = c.getColumnIndexOrThrow(MediaStore.Video.Media._ID)
            val nameCol = c.getColumnIndexOrThrow(MediaStore.Video.Media.DISPLAY_NAME)
            val mimeCol = c.getColumnIndexOrThrow(MediaStore.Video.Media.MIME_TYPE)
            val sizeCol = c.getColumnIndexOrThrow(MediaStore.Video.Media.SIZE)
            val modCol = c.getColumnIndexOrThrow(MediaStore.Video.Media.DATE_MODIFIED)
            val durCol = c.getColumnIndexOrThrow(MediaStore.Video.Media.DURATION)
            val bucketCol = c.getColumnIndexOrThrow(MediaStore.Video.Media.BUCKET_DISPLAY_NAME)
            val pathCol = c.getColumnIndexOrThrow(MediaStore.Video.Media.RELATIVE_PATH)
            while (c.moveToNext()) {
                val id = c.getLong(idCol)
                videos.add(mapOf(
                    "uri" to Uri.withAppendedPath(col, id.toString()).toString(),
                    "fileName" to c.getString(nameCol),
                    "mimeType" to c.getString(mimeCol),
                    "sizeBytes" to c.getLong(sizeCol),
                    "dateModified" to c.getLong(modCol),
                    "durationMs" to c.getLong(durCol),
                    "folderName" to (c.getString(pathCol) ?: c.getString(bucketCol) ?: "")
                ))
            }
        }
        return videos
    }

    private fun hasVideoPermission(): Boolean = when {
        Build.VERSION.SDK_INT >= 34 ->
            checkSelfPermission(Manifest.permission.READ_MEDIA_VIDEO) == PackageManager.PERMISSION_GRANTED ||
            checkSelfPermission(Manifest.permission.READ_MEDIA_VISUAL_USER_SELECTED) == PackageManager.PERMISSION_GRANTED
        Build.VERSION.SDK_INT >= 33 ->
            checkSelfPermission(Manifest.permission.READ_MEDIA_VIDEO) == PackageManager.PERMISSION_GRANTED
        else ->
            checkSelfPermission(Manifest.permission.READ_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED
    }

    private fun hasAllFilesPermission(): Boolean =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) Environment.isExternalStorageManager()
        else checkSelfPermission(Manifest.permission.READ_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED

    private fun requestAllFilesPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            try {
                startActivity(Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION, Uri.parse("package:$packageName")))
            } catch (_: Exception) {
                try { startActivity(Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION)) } catch (_: Exception) {}
            }
        } else {
            requestPermissions(arrayOf(Manifest.permission.READ_EXTERNAL_STORAGE, Manifest.permission.WRITE_EXTERNAL_STORAGE), STORAGE_PERMISSION_REQUEST)
        }
    }

    private fun getStorageRoots(): List<Map<String, Any>> {
        val list = mutableListOf<Map<String, Any>>()
        val seen = mutableSetOf<String>()
        fun addVol(label: String, dir: File?) {
            if (dir == null || !dir.exists()) return
            val can = try { dir.canonicalPath } catch (_: Exception) { dir.absolutePath }
            if (!seen.add(can)) return
            try {
                val st = StatFs(dir.absolutePath)
                list.add(mapOf("name" to label, "path" to dir.absolutePath, "totalBytes" to st.totalBytes, "freeBytes" to st.availableBytes))
            } catch (_: Exception) {}
        }
        addVol("Internal Storage", Environment.getExternalStorageDirectory())
        val extDirs = getExternalFilesDirs(null)
        for (i in extDirs.indices) {
            val root = extDirs[i]?.parentFile?.parentFile?.parentFile?.parentFile
            if (root != null && root.exists()) addVol(if (i == 0) "Internal Storage" else "USB / SD Drive $i", root)
        }
        return list
    }

    private fun shareFilesNative(paths: List<String>, preferNearby: Boolean) {
        if (paths.isEmpty()) return
        StrictMode.setVmPolicy(StrictMode.VmPolicy.Builder().build())
        val uris = ArrayList<Uri>()
        for (p in paths) {
            if (p.startsWith("content://")) {
                uris.add(Uri.parse(p))
            } else {
                val f = File(p.removePrefix("file://"))
                if (f.exists()) uris.add(Uri.fromFile(f))
            }
        }
        if (uris.isEmpty()) return
        val sendIntent = if (uris.size == 1) {
            Intent(Intent.ACTION_SEND).apply {
                type = "*/*"
                putExtra(Intent.EXTRA_STREAM, uris[0])
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
        } else {
            Intent(Intent.ACTION_SEND_MULTIPLE).apply {
                type = "*/*"
                putParcelableArrayListExtra(Intent.EXTRA_STREAM, uris)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
        }
        if (preferNearby) {
            try {
                startActivity(Intent(sendIntent).apply { setPackage("com.google.android.gms") })
                return
            } catch (_: Exception) {}
        }
        startActivity(Intent.createChooser(sendIntent, "Orixon Direct Beam").apply { addFlags(Intent.FLAG_ACTIVITY_NEW_TASK) })
    }

    private fun openFileExternal(path: String, mimeType: String?) {
        val f = File(path)
        if (!f.exists()) return
        StrictMode.setVmPolicy(StrictMode.VmPolicy.Builder().build())
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(Uri.fromFile(f), mimeType ?: "*/*")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(Intent.createChooser(intent, "Open with"))
    }

    private fun getNetworkStatus(): String {
        val cm = getSystemService(ConnectivityManager::class.java)
        val net = cm.activeNetwork ?: return "offline"
        val cap = cm.getNetworkCapabilities(net) ?: return "offline"
        if (!cap.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)) return "offline"
        return when {
            cap.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> "ethernet"
            cap.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> "wifi"
            cap.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> "mobile"
            else -> "offline"
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "ping" -> result.success(true)
                "hasVideoPermission" -> result.success(hasVideoPermission())
                "requestVideoPermission" -> requestVideoPermission(result)
                "getVideoThumbnail" -> getVideoThumbnail(call, result)
                "getNetworkStatus" -> result.success(getNetworkStatus())
                "scanVideos" -> try { result.success(queryInternalVideos()) } catch (e: Exception) { result.error("SCAN_FAILED", e.message, null) }
                else -> result.notImplemented()
            }
        }

        MethodChannel(messenger, SYS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startVrGyro" -> {
                    startVrGyroTracking()
                    result.success(true)
                }
                "stopVrGyro" -> {
                    stopVrGyroTracking()
                    result.success(true)
                }
                "getVrGyroAngles" -> {
                    result.success(mapOf("yaw" to vrYaw, "pitch" to vrPitch))
                }
                "openUrlExternal" -> {
                    val u = call.argument<String>("url") ?: "https://skramjanali.github.io/orixon"
                    openUrlExternal(u)
                    result.success(true)
                }
                "setStartupVolume75" -> {
                    forceStartupVolumeTo75Percent()
                    result.success(true)
                }
                "getDeviceVolumePercent" -> {
                    var pct = 75.0
                    try {
                        val am = applicationContext.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
                        if (am != null) {
                            val maxVol = am.getStreamMaxVolume(AudioManager.STREAM_MUSIC).coerceAtLeast(1)
                            val curVol = am.getStreamVolume(AudioManager.STREAM_MUSIC)
                            pct = (curVol.toDouble() / maxVol.toDouble()) * 100.0
                        }
                    } catch (_: Throwable) {}
                    result.success(pct)
                }
                "setDeviceVolumePercent" -> {
                    val pct = (call.argument<Number>("percent")?.toDouble() ?: 75.0).coerceIn(0.0, 100.0)
                    try {
                        val am = applicationContext.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
                        if (am != null) {
                            if (pct > 0.0 && Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                                try { am.adjustStreamVolume(AudioManager.STREAM_MUSIC, AudioManager.ADJUST_UNMUTE, 0) } catch (_: Throwable) {}
                            }
                            val maxVol = am.getStreamMaxVolume(AudioManager.STREAM_MUSIC).coerceAtLeast(1)
                            val targetVol = Math.round((pct / 100.0) * maxVol.toDouble()).toInt().coerceIn(0, maxVol)
                            am.setStreamVolume(AudioManager.STREAM_MUSIC, targetVol, 0)
                        }
                    } catch (_: Throwable) {}
                    result.success(true)
                }
                "enterPipMode" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            val params = PictureInPictureParams.Builder()
                                .setAspectRatio(Rational(16, 9))
                                .build()
                            val ok = enterPictureInPictureMode(params)
                            result.success(ok)
                        } else {
                            result.success(false)
                        }
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "setWindowBrightness" -> {
                    val b = (call.argument<Number>("brightness")?.toFloat() ?: -1.0f)
                    mainHandler.post {
                        try {
                            val lp = window.attributes
                            lp.screenBrightness = if (b < 0f) -1.0f else b.coerceIn(0.01f, 1.0f)
                            window.attributes = lp
                        } catch (_: Throwable) {}
                    }
                    result.success(true)
                }
                "deleteMediaUri" -> {
                    val uriOrPath = call.argument<String>("uri") ?: ""
                    var deleted = false
                    try {
                        if (uriOrPath.startsWith("content://")) {
                            deleted = contentResolver.delete(Uri.parse(uriOrPath), null, null) > 0
                        } else if (uriOrPath.isNotEmpty()) {
                            val f = File(uriOrPath.removePrefix("file://"))
                            if (f.exists()) deleted = f.delete()
                        }
                    } catch (_: Throwable) {}
                    result.success(deleted)
                }
                "hasAllFilesPermission" -> result.success(hasAllFilesPermission())
                "requestAllFilesPermission" -> { requestAllFilesPermission(); result.success(true) }
                "getStorageRoots" -> result.success(getStorageRoots())
                "shareFiles" -> {
                    val paths = (call.argument<List<*>>("paths"))?.map { it.toString() } ?: emptyList()
                    val preferNearby = call.argument<Boolean>("preferNearby") ?: false
                    shareFilesNative(paths, preferNearby)
                    result.success(true)
                }
                "openFileExternal" -> {
                    openFileExternal(call.argument<String>("path") ?: "", call.argument<String>("mimeType"))
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        val webxChannel = MethodChannel(messenger, WEBX_CHANNEL)
        WebxViewHolder.attachChannel(webxChannel)
        flutterEngine.platformViewsController.registry.registerViewFactory(
            "orixon/webx_webview",
            OrixonWebxFactory(messenger, mainHandler)
        )
    }
}

object WebxViewHolder {
    var activeWebView: OrixonWebxPlatformView? = null
    var channel: MethodChannel? = null

    fun attachChannel(ch: MethodChannel) {
        channel = ch
        ch.setMethodCallHandler { call, result ->
            val view = activeWebView
            if (view == null) {
                result.success(null)
                return@setMethodCallHandler
            }
            when (call.method) {
                "loadUrl" -> { view.loadUrl(call.argument<String>("url") ?: "https://www.google.com"); result.success(true) }
                "goBack" -> { view.goBack(); result.success(true) }
                "goForward" -> { view.goForward(); result.success(true) }
                "reload" -> { view.reload(); result.success(true) }
                "setAdBlock" -> { view.adBlockEnabled = call.argument<Boolean>("enabled") ?: true; result.success(true) }
                "setDesktopMode" -> { view.setDesktopMode(call.argument<Boolean>("desktop") ?: false); result.success(true) }
                "clickAt" -> {
                    val x = (call.argument<Double>("x") ?: 0.0).toFloat()
                    val y = (call.argument<Double>("y") ?: 0.0).toFloat()
                    view.simulateClick(x, y)
                    result.success(true)
                }
                "scrollBy" -> {
                    view.scrollBy(call.argument<Int>("dx") ?: 0, call.argument<Int>("dy") ?: 0)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}

class OrixonWebxFactory(
    private val messenger: BinaryMessenger,
    private val mainHandler: Handler
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val params = args as? Map<*, *>
        val initialUrl = (params?.get("initialUrl") as? String) ?: "https://www.google.com"
        val adBlock = (params?.get("adBlock") as? Boolean) ?: true
        val view = OrixonWebxPlatformView(context, mainHandler, initialUrl, adBlock)
        WebxViewHolder.activeWebView = view
        return view
    }
}

@SuppressLint("SetJavaScriptEnabled")
class OrixonWebxPlatformView(
    context: Context,
    private val mainHandler: Handler,
    initialUrl: String,
    var adBlockEnabled: Boolean
) : PlatformView {

    private val webView: WebView = WebView(context)
    private val adDomains = listOf(
        "doubleclick.net", "googlesyndication.com", "googleadservices.com",
        "popads.net", "popcash.net", "exoclick.com", "propellerads.com",
        "adsterra.com", "juicyads.com", "clickadu.com", "hilltopads.net"
    )

    init {
        webView.setBackgroundColor(Color.parseColor("#080E1A"))
        CookieManager.getInstance().setAcceptCookie(true)
        CookieManager.getInstance().setAcceptThirdPartyCookies(webView, true)

        webView.settings.apply {
            javaScriptEnabled = true
            domStorageEnabled = true
            databaseEnabled = true
            mediaPlaybackRequiresUserGesture = false
            allowFileAccess = true
            allowContentAccess = true
            loadsImagesAutomatically = true
            mixedContentMode = WebSettings.MIXED_CONTENT_ALWAYS_ALLOW
            useWideViewPort = true
            loadWithOverviewMode = true
            builtInZoomControls = true
            displayZoomControls = false
            setSupportMultipleWindows(false)
            userAgentString = "Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36"
        }

        webView.webChromeClient = object : WebChromeClient() {
            override fun onProgressChanged(view: WebView?, newProgress: Int) {
                mainHandler.post { WebxViewHolder.channel?.invokeMethod("onProgress", mapOf("progress" to newProgress)) }
            }
            override fun onReceivedTitle(view: WebView?, title: String?) {
                mainHandler.post { WebxViewHolder.channel?.invokeMethod("onTitleChanged", mapOf("title" to (title ?: ""), "url" to (view?.url ?: ""))) }
            }
        }

        webView.webViewClient = object : WebViewClient() {
            override fun onPageStarted(view: WebView?, url: String?, favicon: Bitmap?) {
                super.onPageStarted(view, url, favicon)
                mainHandler.post { WebxViewHolder.channel?.invokeMethod("onPageStarted", mapOf("url" to (url ?: ""))) }
            }
            override fun onPageFinished(view: WebView?, url: String?) {
                super.onPageFinished(view, url)
                mainHandler.post { WebxViewHolder.channel?.invokeMethod("onPageFinished", mapOf("url" to (url ?: ""), "title" to (view?.title ?: ""))) }
            }
            override fun shouldInterceptRequest(view: WebView?, request: WebResourceRequest?): WebResourceResponse? {
                val reqUrl = request?.url?.toString()?.lowercase() ?: return null
                if (adBlockEnabled && adDomains.any { reqUrl.contains(it) }) {
                    return WebResourceResponse("text/plain", "utf-8", ByteArrayInputStream(ByteArray(0)))
                }
                return super.shouldInterceptRequest(view, request)
            }
        }

        webView.setDownloadListener { url, userAgent, contentDisposition, mimeType, contentLength ->
            mainHandler.post {
                WebxViewHolder.channel?.invokeMethod("onDownloadRequested", mapOf(
                    "url" to (url ?: ""),
                    "userAgent" to (userAgent ?: ""),
                    "contentDisposition" to (contentDisposition ?: ""),
                    "mimeType" to (mimeType ?: ""),
                    "contentLength" to contentLength
                ))
            }
        }

        webView.loadUrl(initialUrl)
    }

    fun loadUrl(url: String) = webView.loadUrl(url)
    fun goBack() { if (webView.canGoBack()) webView.goBack() }
    fun goForward() { if (webView.canGoForward()) webView.goForward() }
    fun reload() = webView.reload()

    fun setDesktopMode(desktop: Boolean) {
        webView.settings.userAgentString = if (desktop) {
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
        } else {
            "Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36"
        }
        webView.reload()
    }

    fun simulateClick(x: Float, y: Float) {
        webView.evaluateJavascript("(function(){var e=document.elementFromPoint($x,$y);if(e){e.focus();e.click();}})();", null)
    }

    fun scrollBy(dx: Int, dy: Int) = webView.scrollBy(dx, dy)
    override fun getView(): View = webView
    override fun dispose() {
        if (WebxViewHolder.activeWebView === this) WebxViewHolder.activeWebView = null
        webView.destroy()
    }
}
