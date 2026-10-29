package com.willigering.tech_deck

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageInfo
import android.content.pm.PackageInstaller
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.security.MessageDigest

/**
 * Hosts the native half of the TECH//DECK GitHub updater.
 *
 * Everything here is read-only except [installApk], which hands a verified APK
 * to the official Android PackageInstaller. Android itself still shows its own
 * confirmation dialog and enforces package name + signing certificate.
 */
class MainActivity : FlutterActivity() {
    private val channelName = "com.willigering.tech_deck/updater"
    private val installAction = "com.willigering.tech_deck.UPDATE_INSTALL_STATUS"
    private var channel: MethodChannel? = null
    private var receiverRegistered = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val ch = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        channel = ch
        ch.setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "getInstalledInfo" -> result.success(installedInfo())
                    "getNetworkType" -> result.success(networkType())
                    "getUpdateDirectory" -> result.success(updateDir().absolutePath)
                    "getFreeSpace" -> result.success(updateDir().usableSpace)
                    "inspectApk" -> result.success(inspectApk(call.argument<String>("path")!!))
                    "canRequestInstall" -> result.success(canRequestInstall())
                    "openInstallPermissionSettings" -> {
                        openInstallPermissionSettings(); result.success(true)
                    }
                    "installApk" -> result.success(installApk(call.argument<String>("path")!!))
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("UPDATER_ERROR", e.message ?: e.javaClass.simpleName, null)
            }
        }
    }

    override fun onDestroy() {
        if (receiverRegistered) {
            try { unregisterReceiver(statusReceiver) } catch (_: Exception) {}
            receiverRegistered = false
        }
        super.onDestroy()
    }

    /** Only app-private cache storage is used; nothing is exposed to other apps. */
    private fun updateDir(): File = File(cacheDir, "updates").apply { mkdirs() }

    @Suppress("DEPRECATION")
    private fun packageInfo(flags: Int): PackageInfo =
        if (Build.VERSION.SDK_INT >= 33) {
            packageManager.getPackageInfo(packageName, PackageManager.PackageInfoFlags.of(flags.toLong()))
        } else packageManager.getPackageInfo(packageName, flags)

    @Suppress("DEPRECATION")
    private fun versionCodeOf(info: PackageInfo): Long =
        if (Build.VERSION.SDK_INT >= 28) info.longVersionCode else info.versionCode.toLong()

    private fun installedInfo(): Map<String, Any?> {
        val info = packageInfo(signingFlag())
        return mapOf(
            "packageName" to packageName,
            "versionName" to info.versionName,
            "versionCode" to versionCodeOf(info),
            "sdkInt" to Build.VERSION.SDK_INT,
            "abis" to Build.SUPPORTED_ABIS.toList(),
            "signingCertSha256" to certDigests(info),
        )
    }

    @Suppress("DEPRECATION")
    private fun signingFlag(): Int =
        if (Build.VERSION.SDK_INT >= 28) PackageManager.GET_SIGNING_CERTIFICATES else PackageManager.GET_SIGNATURES

    @Suppress("DEPRECATION")
    private fun certDigests(info: PackageInfo?): List<String> {
        if (info == null) return emptyList()
        val sigs = if (Build.VERSION.SDK_INT >= 28) {
            val s = info.signingInfo ?: return emptyList()
            if (s.hasMultipleSigners()) s.apkContentsSigners else s.signingCertificateHistory
        } else info.signatures
        return sigs?.map { sha256(it.toByteArray()) } ?: emptyList()
    }

    private fun sha256(bytes: ByteArray): String =
        MessageDigest.getInstance("SHA-256").digest(bytes).joinToString("") { "%02x".format(it) }

    private fun networkType(): String {
        val cm = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val caps = cm.getNetworkCapabilities(cm.activeNetwork) ?: return "none"
        if (!caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)) return "none"
        return when {
            caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) ||
                caps.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> if (cm.isActiveNetworkMetered) "metered" else "wifi"
            else -> "metered"
        }
    }

    /** Reads the real manifest + signer of a downloaded archive (not the file name). */
    @Suppress("DEPRECATION")
    private fun inspectApk(path: String): Map<String, Any?>? {
        val file = File(path)
        if (!file.isFile || file.parentFile?.canonicalPath != updateDir().canonicalPath) return null
        val flags = signingFlag()
        val info = (if (Build.VERSION.SDK_INT >= 33) {
            packageManager.getPackageArchiveInfo(path, PackageManager.PackageInfoFlags.of(flags.toLong()))
        } else packageManager.getPackageArchiveInfo(path, flags)) ?: return null
        info.applicationInfo?.let { it.sourceDir = path; it.publicSourceDir = path }
        val minSdk = if (Build.VERSION.SDK_INT >= 24) info.applicationInfo?.minSdkVersion ?: 0 else 0
        return mapOf(
            "packageName" to info.packageName,
            "versionName" to info.versionName,
            "versionCode" to versionCodeOf(info),
            "minSdk" to minSdk,
            "signingCertSha256" to certDigests(info),
        )
    }

    private fun canRequestInstall(): Boolean =
        Build.VERSION.SDK_INT < 26 || packageManager.canRequestPackageInstalls()

    private fun openInstallPermissionSettings() {
        if (Build.VERSION.SDK_INT >= 26) {
            startActivity(
                Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES, Uri.parse("package:$packageName"))
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            )
        }
    }

    private val statusReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            val status = intent.getIntExtra(PackageInstaller.EXTRA_STATUS, PackageInstaller.STATUS_FAILURE)
            if (status == PackageInstaller.STATUS_PENDING_USER_ACTION) {
                @Suppress("DEPRECATION")
                val confirm = if (Build.VERSION.SDK_INT >= 33) {
                    intent.getParcelableExtra(Intent.EXTRA_INTENT, Intent::class.java)
                } else intent.getParcelableExtra(Intent.EXTRA_INTENT)
                confirm?.let { startActivity(it.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) }
                channel?.invokeMethod("installStatus", mapOf("status" to "pendingUser"))
                return
            }
            val msg = intent.getStringExtra(PackageInstaller.EXTRA_STATUS_MESSAGE)
            channel?.invokeMethod(
                "installStatus",
                mapOf(
                    "status" to if (status == PackageInstaller.STATUS_SUCCESS) "success" else "failure",
                    "code" to status,
                    "message" to msg,
                ),
            )
        }
    }

    /** Streams the APK into a PackageInstaller session; Android shows its own dialog. */
    private fun installApk(path: String): Boolean {
        val file = File(path)
        require(file.isFile && file.parentFile?.canonicalPath == updateDir().canonicalPath) { "invalid path" }
        if (!receiverRegistered) {
            val filter = IntentFilter(installAction)
            if (Build.VERSION.SDK_INT >= 33) {
                registerReceiver(statusReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
            } else {
                @Suppress("UnspecifiedRegisterReceiverFlag")
                registerReceiver(statusReceiver, filter)
            }
            receiverRegistered = true
        }
        val installer = packageManager.packageInstaller
        val params = PackageInstaller.SessionParams(PackageInstaller.SessionParams.MODE_FULL_INSTALL)
        params.setAppPackageName(packageName)
        params.setSize(file.length())
        if (Build.VERSION.SDK_INT >= 31) {
            params.setRequireUserAction(PackageInstaller.SessionParams.USER_ACTION_REQUIRED)
        }
        val sessionId = installer.createSession(params)
        val session = installer.openSession(sessionId)
        try {
            file.inputStream().use { input ->
                session.openWrite("base.apk", 0, file.length()).use { out ->
                    input.copyTo(out)
                    session.fsync(out)
                }
            }
            var flags = PendingIntent.FLAG_UPDATE_CURRENT
            if (Build.VERSION.SDK_INT >= 31) flags = flags or PendingIntent.FLAG_MUTABLE
            val pending = PendingIntent.getBroadcast(
                this, sessionId, Intent(installAction).setPackage(packageName), flags,
            )
            session.commit(pending.intentSender)
        } catch (e: Exception) {
            session.abandon()
            throw e
        } finally {
            session.close()
        }
        return true
    }
}
