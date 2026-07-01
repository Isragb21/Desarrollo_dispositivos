package com.uteq.wearable_app

import android.bluetooth.*
import android.bluetooth.le.AdvertiseCallback
import android.bluetooth.le.AdvertiseData
import android.bluetooth.le.AdvertiseSettings
import android.bluetooth.le.BluetoothLeAdvertiser
import android.content.Context
import android.os.ParcelUuid
import java.util.*

class GattServerHelper(private val context: Context) {
    private val serviceUUID = UUID.fromString("12345678-1234-1234-1234-123456789abc")
    private val stepsUUID = UUID.fromString("aaaaaaaa-0001-1234-1234-123456789abc")
    private val hrUUID = UUID.fromString("aaaaaaaa-0002-1234-1234-123456789abc")
    private val calUUID = UUID.fromString("aaaaaaaa-0003-1234-1234-123456789abc")
    private val statusUUID = UUID.fromString("aaaaaaaa-0004-1234-1234-123456789abc")

    private var bluetoothManager: BluetoothManager? = null
    private var bluetoothAdapter: BluetoothAdapter? = null
    private var bluetoothLeAdvertiser: BluetoothLeAdvertiser? = null
    private var gattServer: BluetoothGattServer? = null
    private val connectedDevices = mutableListOf<BluetoothDevice>()

    private var stepsChar: BluetoothGattCharacteristic? = null
    private var hrChar: BluetoothGattCharacteristic? = null
    private var calChar: BluetoothGattCharacteristic? = null
    private var statusChar: BluetoothGattCharacteristic? = null

    private var isAdvertising = false

    private val advertiseCallback = object : AdvertiseCallback() {
        override fun onStartSuccess(settingsInEffect: AdvertiseSettings) {
            isAdvertising = true
            android.util.Log.d("[WEARABLE]", "ADVERTISE STARTED SUCCESS")
        }

        override fun onStartFailure(errorCode: Int) {
            isAdvertising = false
            android.util.Log.e("[WEARABLE]", "ADVERTISE FAILED errorCode=$errorCode")
        }
    }

    private val gattServerCallback = object : BluetoothGattServerCallback() {
        override fun onConnectionStateChange(device: BluetoothDevice?, status: Int, newState: Int) {
            if (device == null) return
            when (newState) {
                BluetoothProfile.STATE_CONNECTED -> {
                    if (!connectedDevices.contains(device)) connectedDevices.add(device)
                }
                BluetoothProfile.STATE_DISCONNECTED -> {
                    connectedDevices.remove(device)
                }
            }
        }

        override fun onCharacteristicReadRequest(
            device: BluetoothDevice?,
            requestId: Int,
            offset: Int,
            characteristic: BluetoothGattCharacteristic?
        ) {
            if (device == null || characteristic == null) return
            gattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, offset, characteristic.value)
        }
    }

    fun start(): Boolean {
        val pm = context.packageManager
        if (!pm.hasSystemFeature(android.content.pm.PackageManager.FEATURE_BLUETOOTH_LE)) return false

        bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        bluetoothAdapter = bluetoothManager?.adapter ?: return false
        bluetoothLeAdvertiser = bluetoothAdapter?.bluetoothLeAdvertiser ?: return false

        val service = BluetoothGattService(serviceUUID, BluetoothGattService.SERVICE_TYPE_PRIMARY)

        stepsChar = BluetoothGattCharacteristic(
            stepsUUID, 
            BluetoothGattCharacteristic.PROPERTY_READ or BluetoothGattCharacteristic.PROPERTY_NOTIFY,
            BluetoothGattCharacteristic.PERMISSION_READ
        )
        stepsChar?.value = intToBytes(0, 4)
        service.addCharacteristic(stepsChar)

        hrChar = BluetoothGattCharacteristic(
            hrUUID,
            BluetoothGattCharacteristic.PROPERTY_READ or BluetoothGattCharacteristic.PROPERTY_NOTIFY,
            BluetoothGattCharacteristic.PERMISSION_READ
        )
        hrChar?.value = byteArrayOf(70)
        service.addCharacteristic(hrChar)

        calChar = BluetoothGattCharacteristic(
            calUUID,
            BluetoothGattCharacteristic.PROPERTY_READ or BluetoothGattCharacteristic.PROPERTY_NOTIFY,
            BluetoothGattCharacteristic.PERMISSION_READ
        )
        calChar?.value = intToBytes(0, 2)
        service.addCharacteristic(calChar)

        statusChar = BluetoothGattCharacteristic(
            statusUUID,
            BluetoothGattCharacteristic.PROPERTY_READ or BluetoothGattCharacteristic.PROPERTY_NOTIFY,
            BluetoothGattCharacteristic.PERMISSION_READ
        )
        statusChar?.value = "reposo".toByteArray()
        service.addCharacteristic(statusChar)

        gattServer = bluetoothManager?.openGattServer(context, gattServerCallback)
        gattServer?.addService(service)

        startAdvertising()
        return true
    }

    private fun startAdvertising() {
        val settings = AdvertiseSettings.Builder()
            .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
            .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_HIGH)
            .setConnectable(true)
            .build()

        val data = AdvertiseData.Builder()
            .setIncludeDeviceName(true)
            .build()

        val scanResponse = AdvertiseData.Builder()
            .addServiceUuid(ParcelUuid(serviceUUID))
            .build()

        bluetoothLeAdvertiser?.startAdvertising(settings, data, scanResponse, advertiseCallback)
    }

    fun stop() {
        bluetoothLeAdvertiser?.stopAdvertising(advertiseCallback)
        isAdvertising = false
        gattServer?.close()
        gattServer = null
        connectedDevices.clear()
    }

    fun notifySteps(value: Int) {
        stepsChar?.value = intToBytes(value, 4)
        notifyCharacteristic(stepsChar)
    }

    fun notifyHeartRate(value: Int) {
        hrChar?.value = byteArrayOf(value.toByte())
        notifyCharacteristic(hrChar)
    }

    fun notifyCalories(value: Int) {
        calChar?.value = intToBytes(value, 2)
        notifyCharacteristic(calChar)
    }

    fun notifyStatus(value: String) {
        statusChar?.value = value.toByteArray()
        notifyCharacteristic(statusChar)
    }

    private fun notifyCharacteristic(char: BluetoothGattCharacteristic?) {
        char ?: return
        for (device in connectedDevices) {
            gattServer?.notifyCharacteristicChanged(device, char, false)
        }
    }

    private fun intToBytes(value: Int, byteCount: Int): ByteArray {
        val bytes = ByteArray(byteCount)
        for (i in 0 until byteCount) {
            bytes[i] = (value shr (i * 8)).toByte()
        }
        return bytes
    }
}
