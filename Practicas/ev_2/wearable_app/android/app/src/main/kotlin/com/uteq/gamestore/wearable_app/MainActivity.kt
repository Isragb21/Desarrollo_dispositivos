package com.uteq.gamestore.wearable_app

import android.Manifest
import android.annotation.SuppressLint
import android.bluetooth.*
import android.bluetooth.le.AdvertiseCallback
import android.bluetooth.le.AdvertiseData
import android.bluetooth.le.AdvertiseSettings
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.ParcelUuid
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.UUID

class MainActivity : FlutterActivity() {

    companion object {
        private const val TAG = "GS_Wearable"

        private const val CH_METHOD = "com.uteq.gamestore/ble"
        private const val CH_EVENTS = "com.uteq.gamestore/ble_events"

        private val SERVICE_UUID =
            UUID.fromString("12345678-1234-1234-1234-123456789abc")
        private val CART_TOTAL_UUID =
            UUID.fromString("aaaaaaaa-0001-1234-1234-123456789abc")
        private val AUTH_ALERT_UUID =
            UUID.fromString("aaaaaaaa-0002-1234-1234-123456789abc")
        private val DISCOUNT_ALERT_UUID =
            UUID.fromString("aaaaaaaa-0003-1234-1234-123456789abc")
        private val STEPS_UUID =
            UUID.fromString("aaaaaaaa-0004-1234-1234-123456789abc")
        private val HEART_RATE_UUID =
            UUID.fromString("aaaaaaaa-0005-1234-1234-123456789abc")
        private val CALORIES_UUID =
            UUID.fromString("aaaaaaaa-0006-1234-1234-123456789abc")
        private val USER_RESPONSE_UUID =
            UUID.fromString("aaaaaaaa-0007-1234-1234-123456789abc")
        private val PURCHASE_ALERT_UUID =
            UUID.fromString("aaaaaaaa-0008-1234-1234-123456789abc")
    }

    private var gattServer: BluetoothGattServer? = null
    private var bleManager: BluetoothManager? = null
    private var bluetoothAdapter: BluetoothAdapter? = null
    private var connectedDevice: BluetoothDevice? = null

    private var eventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CH_METHOD)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startServer" -> {
                        val ok = startGattServer()
                        result.success(ok)
                    }
                    "stopServer" -> {
                        stopGattServer()
                        result.success(null)
                    }
                    "notifyResponse" -> {
                        val payload = call.arguments as? String ?: ""
                        notifyUserResponse(payload)
                        result.success(null)
                    }
                    "notifySensor" -> {
                        val args = call.arguments as? Map<*, *> ?: emptyMap<Any, Any>()
                        notifySensorData(
                            (args["steps"] as? Number)?.toInt() ?: 0,
                            (args["heartRate"] as? Number)?.toInt() ?: 0,
                            (args["calories"] as? Number)?.toDouble() ?: 0.0
                        )
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, CH_EVENTS)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })
    }

    @SuppressLint("MissingPermission")
    private fun startGattServer(): Boolean {
        return try {
            if (!hasBlePermissions()) {
                Log.i(TAG, "Faltan permisos BLE, solicitando...")
                requestBluetoothPermissionsIfNeeded()
                return false
            }

            bleManager =
                getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
            bluetoothAdapter = bleManager?.adapter
            if (bluetoothAdapter == null || !bluetoothAdapter!!.isEnabled) {
                Log.w(TAG, "Bluetooth no disponible")
                return false
            }

            gattServer = bleManager?.openGattServer(this, gattServerCallback) ?: run {
                Log.e(TAG, "openGattServer falló")
                return false
            }

            val service = BluetoothGattService(
                SERVICE_UUID, BluetoothGattService.SERVICE_TYPE_PRIMARY
            )

            service.addCharacteristic(
                BluetoothGattCharacteristic(
                    CART_TOTAL_UUID,
                    BluetoothGattCharacteristic.PROPERTY_READ or
                        BluetoothGattCharacteristic.PROPERTY_WRITE or
                        BluetoothGattCharacteristic.PROPERTY_NOTIFY,
                    BluetoothGattCharacteristic.PERMISSION_READ or
                        BluetoothGattCharacteristic.PERMISSION_WRITE
                ).apply { addDescriptor(getClientCharacteristicConfigDescriptor()) }
            )
            service.addCharacteristic(
                BluetoothGattCharacteristic(
                    AUTH_ALERT_UUID,
                    BluetoothGattCharacteristic.PROPERTY_WRITE or
                        BluetoothGattCharacteristic.PROPERTY_NOTIFY,
                    BluetoothGattCharacteristic.PERMISSION_WRITE
                ).apply { addDescriptor(getClientCharacteristicConfigDescriptor()) }
            )
            service.addCharacteristic(
                BluetoothGattCharacteristic(
                    DISCOUNT_ALERT_UUID,
                    BluetoothGattCharacteristic.PROPERTY_WRITE or
                        BluetoothGattCharacteristic.PROPERTY_NOTIFY,
                    BluetoothGattCharacteristic.PERMISSION_WRITE
                ).apply { addDescriptor(getClientCharacteristicConfigDescriptor()) }
            )
            service.addCharacteristic(
                BluetoothGattCharacteristic(
                    STEPS_UUID,
                    BluetoothGattCharacteristic.PROPERTY_READ or
                        BluetoothGattCharacteristic.PROPERTY_NOTIFY,
                    BluetoothGattCharacteristic.PERMISSION_READ
                ).apply { addDescriptor(getClientCharacteristicConfigDescriptor()) }
            )
            service.addCharacteristic(
                BluetoothGattCharacteristic(
                    HEART_RATE_UUID,
                    BluetoothGattCharacteristic.PROPERTY_READ or
                        BluetoothGattCharacteristic.PROPERTY_NOTIFY,
                    BluetoothGattCharacteristic.PERMISSION_READ
                ).apply { addDescriptor(getClientCharacteristicConfigDescriptor()) }
            )
            service.addCharacteristic(
                BluetoothGattCharacteristic(
                    CALORIES_UUID,
                    BluetoothGattCharacteristic.PROPERTY_READ or
                        BluetoothGattCharacteristic.PROPERTY_NOTIFY,
                    BluetoothGattCharacteristic.PERMISSION_READ
                ).apply { addDescriptor(getClientCharacteristicConfigDescriptor()) }
            )
            service.addCharacteristic(
                BluetoothGattCharacteristic(
                    USER_RESPONSE_UUID,
                    BluetoothGattCharacteristic.PROPERTY_NOTIFY,
                    BluetoothGattCharacteristic.PERMISSION_READ
                ).apply { addDescriptor(getClientCharacteristicConfigDescriptor()) }
            )
            service.addCharacteristic(
                BluetoothGattCharacteristic(
                    PURCHASE_ALERT_UUID,
                    BluetoothGattCharacteristic.PROPERTY_WRITE or
                        BluetoothGattCharacteristic.PROPERTY_NOTIFY,
                    BluetoothGattCharacteristic.PERMISSION_WRITE
                ).apply { addDescriptor(getClientCharacteristicConfigDescriptor()) }
            )

            gattServer?.addService(service)

            startAdvertising()
            Log.i(TAG, "GATT server listo, UUID: $SERVICE_UUID")
            true
        } catch (e: Exception) {
            Log.e(TAG, "startGattServer: ${e.message}")
            false
        }
    }

    private fun getClientCharacteristicConfigDescriptor(): BluetoothGattDescriptor {
        return BluetoothGattDescriptor(
            UUID.fromString("00002902-0000-1000-8000-00805f9b34fb"),
            BluetoothGattDescriptor.PERMISSION_READ or
                BluetoothGattDescriptor.PERMISSION_WRITE
        )
    }

    private fun notifyUserResponse(payload: String) {
        val characteristic =
            gattServer?.getService(SERVICE_UUID)?.getCharacteristic(USER_RESPONSE_UUID)
                ?: return
        characteristic.value = payload.toByteArray(Charsets.UTF_8)
        val device = connectedDevice ?: return
        try {
            gattServer?.notifyCharacteristicChanged(device, characteristic, false)
        } catch (e: Exception) {
            Log.e(TAG, "notify error: ${e.message}")
        }
    }

    /// Notifica cada métrica del simulador en su característica GATT (NOTIFY).
    private fun notifySensorData(steps: Int, heartRate: Int, calories: Double) {
        val device = connectedDevice ?: return
        val service = gattServer?.getService(SERVICE_UUID) ?: return
        val payloads = mapOf(
            STEPS_UUID to steps.toString(),
            HEART_RATE_UUID to heartRate.toString(),
            CALORIES_UUID to String.format("%.2f", calories)
        )
        payloads.forEach { (uuid, value) ->
            val characteristic = service.getCharacteristic(uuid) ?: return@forEach
            characteristic.value = value.toByteArray(Charsets.UTF_8)
            try {
                gattServer?.notifyCharacteristicChanged(device, characteristic, false)
            } catch (e: Exception) {
                Log.e(TAG, "notify $uuid error: ${e.message}")
            }
        }
    }

    @SuppressLint("MissingPermission")
    private fun startAdvertising() {
        val settings = AdvertiseSettings.Builder()
            .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
            .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_HIGH)
            .setConnectable(true)
            .build()

        val data = AdvertiseData.Builder()
            .setIncludeDeviceName(true)
            .addServiceUuid(ParcelUuid(SERVICE_UUID))
            .build()

        bluetoothAdapter?.bluetoothLeAdvertiser?.startAdvertising(
            settings, data, advertiseCallback
        )
    }

    private val advertiseCallback = object : AdvertiseCallback() {
        override fun onStartSuccess(settings: AdvertiseSettings) {
            Log.i(TAG, "Advertising iniciado")
        }

        override fun onStartFailure(errorCode: Int) {
            Log.e(TAG, "Advertising falló: $errorCode")
        }
    }

    private val gattServerCallback = object : BluetoothGattServerCallback() {
        override fun onConnectionStateChange(
            device: BluetoothDevice,
            status: Int,
            newState: Int
        ) {
            if (newState == BluetoothProfile.STATE_CONNECTED) {
                connectedDevice = device
                Log.i(TAG, "Dispositivo conectado: ${device.address}")
            } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                connectedDevice = null
                Log.i(TAG, "Dispositivo desconectado")
            }
        }

        @SuppressLint("MissingPermission")
        override fun onCharacteristicWriteRequest(
            device: BluetoothDevice,
            requestId: Int,
            characteristic: BluetoothGattCharacteristic,
            preparedWrite: Boolean,
            responseNeeded: Boolean,
            offset: Int,
            value: ByteArray?
        ) {
            try {
                gattServer?.sendResponse(
                    device, requestId, BluetoothGatt.GATT_SUCCESS, 0, null
                )
            } catch (_: Exception) {}

            val payload = value?.toString(Charsets.UTF_8) ?: ""
            Log.i(TAG, "Write en ${characteristic.uuid}: $payload")

            val eventType = when (characteristic.uuid) {
                CART_TOTAL_UUID -> "cart"
                AUTH_ALERT_UUID -> "session"
                DISCOUNT_ALERT_UUID -> "discount"
                PURCHASE_ALERT_UUID -> "purchase"
                else -> null
            }
            if (eventType == null) return

            val event = mutableMapOf<String, Any>("type" to eventType)
            parsePayload(payload, event)
            eventSink?.success(event)
        }
    }

    private fun parsePayload(payload: String, event: MutableMap<String, Any>) {
        if (payload.isEmpty()) return
        try {
            val json = org.json.JSONObject(payload)
            json.keys().forEach { key ->
                event[key] = json.opt(key)
            }
        } catch (_: Exception) {
            // Payload no JSON: se usa tal cual como texto simple
            event["message"] = payload
        }
    }

    private fun requestBluetoothPermissionsIfNeeded() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            requestPermissions(
                arrayOf(
                    Manifest.permission.BLUETOOTH_CONNECT,
                    Manifest.permission.BLUETOOTH_SCAN,
                    Manifest.permission.BLUETOOTH_ADVERTISE
                ),
                100
            )
        } else {
            requestPermissions(
                arrayOf(Manifest.permission.ACCESS_FINE_LOCATION),
                100
            )
        }
    }

    private fun hasBlePermissions(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            return checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) ==
                PackageManager.PERMISSION_GRANTED
        }
        return checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT) ==
            PackageManager.PERMISSION_GRANTED &&
            checkSelfPermission(Manifest.permission.BLUETOOTH_SCAN) ==
            PackageManager.PERMISSION_GRANTED &&
            checkSelfPermission(Manifest.permission.BLUETOOTH_ADVERTISE) ==
            PackageManager.PERMISSION_GRANTED
    }

    private fun stopGattServer() {
        try {
            bluetoothAdapter?.bluetoothLeAdvertiser?.stopAdvertising(advertiseCallback)
            gattServer?.close()
            gattServer = null
        } catch (e: Exception) {
            Log.e(TAG, "stop error: ${e.message}")
        }
    }

    @SuppressLint("MissingPermission")
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 100 && grantResults.isNotEmpty() &&
            grantResults.all { it == PackageManager.PERMISSION_GRANTED }
        ) {
            Log.i(TAG, "Permisos BLE concedidos, iniciando servidor")
            startGattServer()
        }
    }

    override fun onDestroy() {
        stopGattServer()
        super.onDestroy()
    }
}
