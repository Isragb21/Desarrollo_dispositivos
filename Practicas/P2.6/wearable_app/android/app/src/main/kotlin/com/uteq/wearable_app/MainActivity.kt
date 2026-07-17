package com.uteq.wearable_app

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.uteq.wearable_app/ble"
    private var gattServerHelper: GattServerHelper? = null
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startServer" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !hasBlePermissions()) {
                        pendingResult = result
                        requestBlePermissions()
                    } else {
                        result.success(startBleServer())
                    }
                }
                "stopServer" -> {
                    stopBleServer()
                    result.success(true)
                }
                "updateSteps" -> {
                    val value = call.argument<Int>("value") ?: 0
                    gattServerHelper?.notifySteps(value)
                    result.success(true)
                }
                "updateHeartRate" -> {
                    val value = call.argument<Int>("value") ?: 0
                    gattServerHelper?.notifyHeartRate(value)
                    result.success(true)
                }
                "updateCalories" -> {
                    val value = call.argument<Int>("value") ?: 0
                    gattServerHelper?.notifyCalories(value)
                    result.success(true)
                }
                "updateStatus" -> {
                    val value = call.argument<String>("value") ?: ""
                    gattServerHelper?.notifyStatus(value)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 100) {
            pendingResult?.let { result ->
                val allGranted = grantResults.all { it == PackageManager.PERMISSION_GRANTED }
                if (allGranted) {
                    result.success(startBleServer())
                } else {
                    android.util.Log.w("[WEARABLE]", "BLE permissions denied by user")
                    result.success(false)
                }
                pendingResult = null
            }
        }
    }

    private fun startBleServer(): Boolean {
        return try {
            gattServerHelper = GattServerHelper(this)
            gattServerHelper?.start() ?: false
        } catch (e: Exception) {
            android.util.Log.e("[WEARABLE]", "Failed to start BLE server", e)
            false
        }
    }

    private fun stopBleServer() {
        gattServerHelper?.stop()
        gattServerHelper = null
    }

    private fun hasBlePermissions(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            return ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_ADVERTISE) == PackageManager.PERMISSION_GRANTED &&
                   ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED &&
                   ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_SCAN) == PackageManager.PERMISSION_GRANTED
        }
        return true
    }

    private fun requestBlePermissions() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(
                    Manifest.permission.BLUETOOTH_ADVERTISE,
                    Manifest.permission.BLUETOOTH_CONNECT,
                    Manifest.permission.BLUETOOTH_SCAN
                ),
                100
            )
        }
    }

    override fun onDestroy() {
        stopBleServer()
        super.onDestroy()
    }
}
