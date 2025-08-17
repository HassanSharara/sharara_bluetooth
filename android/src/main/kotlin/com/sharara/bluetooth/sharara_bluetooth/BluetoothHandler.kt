package com.sharara.bluetooth.sharara_bluetooth

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothSocket
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.*
import java.io.IOException
import java.util.UUID
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.ConcurrentHashMap

class BluetoothHandler(private val flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {

    // Context and Bluetooth Manager
    private val context: Context get() = flutterPluginBinding.applicationContext
    private val bluetoothManager: BluetoothManager by lazy {
        context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
    }

    // Coroutine management
    private val handlerScope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    private val ioScope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    // Connection state management
    private val isConnecting = AtomicBoolean(false)
    private val isDiscovering = AtomicBoolean(false)
    @Volatile private var bluetoothSocket: BluetoothSocket? = null

    // Event handling
    private val eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "sharara_bluetooth/devices")
    private var currentReceiver: BroadcastReceiver? = null
    private var eventSink: EventChannel.EventSink? = null

    // Thread-safe discovered devices storage
    private val discoveredDevices: ConcurrentHashMap<String, BDevice> = ConcurrentHashMap()

    // Main thread handler for UI updates
    private val mainHandler = Handler(Looper.getMainLooper())

    // Connection timeout
    private companion object {
        const val CONNECTION_TIMEOUT_MS = 10000L
        const val DISCOVERY_CLEANUP_DELAY = 500L
    }

    init {
        setupEventChannel()
    }

    private fun setupEventChannel() {
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
            }

            override fun onCancel(arguments: Any?) {
                bluetoothManager.adapter?.let { cancelDiscovery(it) }
            }
        })
    }

    fun onMethodInvoked(call: MethodCall, result: Result) {
        checkAdapter(result) { bluetoothAdapter ->
            when (call.method) {
                "startDiscovery" -> handleStartDiscovery(bluetoothAdapter, result)
                "isDiscovering" -> result.success(bluetoothAdapter.isDiscovering)
                "cancelDiscovery" -> handleCancelDiscovery(bluetoothAdapter, result)
                "connect" -> handleConnect(call, result)
                "forceConnecting" -> forceConnecting(call, result)
                "disconnect" -> handleDisconnect(call, result)
                "isDeviceConnected" -> handleIsDeviceConnected(call, result)
                "writeToDevice" -> handleWriteToDevice(call, result)
                else -> result.notImplemented()
            }
        }
    }

    private fun handleStartDiscovery(bluetoothAdapter: BluetoothAdapter, result: Result) {
        if (isDiscovering.get()) {
            result.error("30", "Discovery already in progress", "Please wait for current discovery to complete")
            return
        }

        if (bluetoothAdapter.isDiscovering) {
            result.error("30", "Discovery already started", "Cancel it first before starting a new one")
            return
        }

        handlerScope.launch {
            try {
                startDiscovery(bluetoothAdapter, result)
            } catch (e: Exception) {
                result.error("32", "Discovery start failed", e.message ?: "Unknown error")
            }
        }
    }

    private fun handleCancelDiscovery(bluetoothAdapter: BluetoothAdapter, result: Result) {
        cancelDiscovery(bluetoothAdapter)
        result.success(null)
    }

    private fun forceConnecting(call: MethodCall,result: Result){
        if ( bluetoothSocket != null ) {
            bluetoothSocket?.close()
            bluetoothSocket = null
        }
        handleConnect(call,result)
    }
    private fun handleConnect(call: MethodCall, result: Result) {
        if (isConnecting.getAndSet(true)) {
            result.error("40", "Connection already in progress", "Please wait for current connection attempt to complete")
            return
        }

        ioScope.launch {
            try {
                connect(call, result)
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("50", "Connection failed", e.message ?: "Unknown connection error")
                }
            } finally {
                isConnecting.set(false)
            }
        }
    }

    private fun handleDisconnect(call: MethodCall, result: Result) {
        ioScope.launch {
            try {
                disconnect(call, result)
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("51", "Disconnection failed", e.message ?: "Unknown disconnection error")
                }
            }
        }
    }

    private fun handleIsDeviceConnected(call: MethodCall, result: Result) {
        // This can be handled synchronously as it's just a state check
        try {
            val arguments = call.arguments as? Map<*, *>
            val address = arguments?.get("address") as? String

            if (address.isNullOrEmpty()) {
                result.error("41", "Invalid address", "Address parameter is required and cannot be empty")
                return
            }

            val isConnected = bluetoothSocket?.remoteDevice?.address == address &&
                    bluetoothSocket?.isConnected == true
            result.success(isConnected)
        } catch (e: Exception) {
            result.error("42", "Connection check failed", e.message ?: "Unknown error")
        }
    }

    private fun handleWriteToDevice(call: MethodCall, result: Result) {
        ioScope.launch {
            try {
                writeToDevice(call, result)
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("60", "Write failed", e.message ?: "Unknown write error")
                }
            }
        }
    }

    private suspend fun connect(call: MethodCall, result: Result) = withContext(Dispatchers.IO) {
        // Close existing connection if any
        bluetoothSocket?.let { socket ->
            try {
                socket.close()
            } catch (e: IOException) {
                // Ignore close errors
            }
            bluetoothSocket = null
        }

        val arguments = call.arguments as? Map<*, *>
            ?: throw IllegalArgumentException("Arguments cannot be null")

        val address = arguments["address"] as? String
            ?: throw IllegalArgumentException("Address is required")

        val uuid = arguments["uuid"] as? String
            ?: throw IllegalArgumentException("UUID is required")

        val adapter = bluetoothManager.adapter
        val device = adapter.getRemoteDevice(address)
        val serviceUuid = UUID.fromString(uuid)

        // Create socket with proper error handling
        val socket = try {
            device.createRfcommSocketToServiceRecord(serviceUuid)
        } catch (e: Exception) {
            throw IOException("Failed to create RFCOMM socket: ${e.message}", e)
        }

        // Cancel discovery to improve connection performance
        if (adapter.isDiscovering) {
            adapter.cancelDiscovery()
            delay(100) // Small delay to ensure discovery is fully cancelled
        }

        // Connect with timeout
        withTimeout(CONNECTION_TIMEOUT_MS) {
            try {
                socket.connect()
                bluetoothSocket = socket

                withContext(Dispatchers.Main) {
                    result.success(true)
                }
            } catch (e: Exception) {
                socket.close()
                throw IOException("Connection failed: ${e.message}", e)
            }
        }
    }

    private suspend fun disconnect(call: MethodCall, result: Result) = withContext(Dispatchers.IO) {
        val arguments = call.arguments as? Map<*, *>
        val address = arguments?.get("address") as? String

        val currentSocket = bluetoothSocket
        val success = if (currentSocket?.remoteDevice?.address == address) {
            try {
                currentSocket?.close()
                bluetoothSocket = null
                true
            } catch (e: IOException) {
                false
            }
        } else {
            false
        }

        withContext(Dispatchers.Main) {
            result.success(success)
        }
    }

    private suspend fun writeToDevice(call: MethodCall, result: Result) = withContext(Dispatchers.IO) {
        val arguments = call.arguments as? Map<*, *>
            ?: throw IllegalArgumentException("Arguments cannot be null")

        val address = arguments["address"] as? String
            ?: throw IllegalArgumentException("Address is required")

        val data = arguments["data"] as? List<*>
            ?: throw IllegalArgumentException("Data is required")

        val currentSocket = bluetoothSocket

        if (currentSocket?.remoteDevice?.address != address) {
            throw IOException("Device with address $address is not connected")
        }

        if (currentSocket.isConnected.not()) {
            throw IOException("Socket is not connected")
        }

        val bytes = data.filterIsInstance<Int>()
            .map { it.toByte() }
            .toByteArray()

        if (bytes.isEmpty()) {
            throw IllegalArgumentException("No valid data to write")
        }

        println("start writing ")
        val outputStream = currentSocket.outputStream
        outputStream.write(bytes)
        outputStream.flush()
        withContext(Dispatchers.Main) {
            result.success(true)
        }
    }

    private suspend fun startDiscovery(bluetoothAdapter: BluetoothAdapter, result: Result) {
        if (!hasRequiredPermissions()) {
            result.error("33", "Missing permissions", "Required Bluetooth/Location permissions not granted")
            return
        }

        isDiscovering.set(true)
        discoveredDevices.clear()

        val intentFilter = IntentFilter().apply {
            addAction(BluetoothDevice.ACTION_FOUND)
            addAction(BluetoothDevice.ACTION_UUID)
            addAction(BluetoothAdapter.ACTION_DISCOVERY_FINISHED)
        }

        currentReceiver = createDiscoveryReceiver()

        try {
            context.registerReceiver(currentReceiver, intentFilter)
        } catch (e: Exception) {
            cleanupDiscovery()
            result.error("34", "Failed to register receiver", e.message ?: "Unknown error")
            return
        }

        // Ensure discovery is stopped before starting new one
        if (bluetoothAdapter.isDiscovering) {
            bluetoothAdapter.cancelDiscovery()
            delay(DISCOVERY_CLEANUP_DELAY)
        }

        if (bluetoothAdapter.startDiscovery()) {
            result.success("Discovery started")
        } else {
            cleanupDiscovery()
            result.error("31", "Failed to start discovery",
                "BluetoothAdapter.startDiscovery() returned false")
        }
    }

    private fun createDiscoveryReceiver() = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                BluetoothDevice.ACTION_FOUND -> handleDeviceFound(intent)
                BluetoothDevice.ACTION_UUID -> handleUuidReceived(intent)
                BluetoothAdapter.ACTION_DISCOVERY_FINISHED -> handleDiscoveryFinished()
            }
        }

        private fun handleDeviceFound(intent: Intent) {
            val device = getBluetoothDeviceFromIntent(intent) ?: return
            if (!discoveredDevices.containsKey(device.address)) {
                val bDevice = device.toB()
                discoveredDevices[device.address] = bDevice
                // Trigger UUID fetch in background
                ioScope.launch {
                    try {
                        device.fetchUuidsWithSdp()
                    } catch (e: Exception) {
                        // Ignore UUID fetch errors
                    }
                }

                sendDevices()
            }
        }

        private fun handleUuidReceived(intent: Intent) {
            val device = getBluetoothDeviceFromIntent(intent)
            if (device != null && discoveredDevices.containsKey(device.address)) {
                sendDevices()
            }
        }

        private fun handleDiscoveryFinished() {
            isDiscovering.set(false)
            cleanupDiscovery()
        }
    }

    private fun getBluetoothDeviceFromIntent(intent: Intent): BluetoothDevice? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE, BluetoothDevice::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
        }
    }

    private fun sendDevices() {
        mainHandler.post {
            eventSink?.success(discoveredDevices.values
                .sortedByDescending { bluetoothSocket?.remoteDevice?.address == it.address }
                .map { it.toMap() })
        }
    }

    private fun cancelDiscovery(bluetoothAdapter: BluetoothAdapter?) {
        bluetoothAdapter?.let {
            if (it.isDiscovering) {
                it.cancelDiscovery()
            }
        }
        isDiscovering.set(false)
        cleanupDiscovery()
    }

    private fun cleanupDiscovery() {
        currentReceiver?.let { receiver ->
            try {
                context.unregisterReceiver(receiver)
            } catch (e: IllegalArgumentException) {
                // Receiver was not registered
            }
            currentReceiver = null
        }
        discoveredDevices.clear()
    }

    private inline fun checkAdapter(result: Result, callback: (BluetoothAdapter) -> Unit) {
        val adapter = bluetoothManager.adapter
        if (adapter == null) {
            result.error("20", "Invalid BluetoothAdapter", "Device has no Bluetooth adapter")
            return
        }
        if (!adapter.isEnabled) {
            result.error("21", "Bluetooth is not enabled", "Please enable Bluetooth from settings")
            return
        }
        callback(adapter)
    }

    private fun hasRequiredPermissions(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            context.checkSelfPermission(Manifest.permission.BLUETOOTH_SCAN) == PackageManager.PERMISSION_GRANTED &&
                    context.checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            context.checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
    }

    fun cleanup() {
        // Clean up resources when the plugin is detached
        handlerScope.cancel()
        ioScope.cancel()
        bluetoothSocket?.let {
            try {
                it.close()
            } catch (e: IOException) {
                // Ignore
            }
            bluetoothSocket = null
        }

        cleanupDiscovery()
    }
}

// Extension function for BluetoothDevice
fun BluetoothDevice.toB(): BDevice {
    return BDevice(
        name = try { this.name } catch (e: SecurityException) { null },
        address = this.address,
        type = this.type
    )
}

data class BDevice(val name: String?, val address: String, val type: Int) {
    fun toMap(): Map<String, Any?> {
        return mapOf(
            "name" to name,
            "address" to address,
            "type" to type,
        )
    }
}