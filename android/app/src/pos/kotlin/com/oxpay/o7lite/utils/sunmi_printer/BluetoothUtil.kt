package com.oxpay.o7lite.utils.sunmi_printer

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothSocket
import android.content.Context
import android.util.Log
import android.widget.Toast
import java.io.IOException
import java.io.OutputStream
import java.util.UUID

object BluetoothUtil {
    private val PRINTER_UUID: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")

    private const val Innerprinter_Address = "00:11:22:33:44:55"

    private var bluetoothSocket: BluetoothSocket? = null

    private val bTAdapter: BluetoothAdapter?
        get() = BluetoothAdapter.getDefaultAdapter()

    @SuppressLint("MissingPermission")
    private fun getDevice(bluetoothAdapter: BluetoothAdapter?): BluetoothDevice? {
        var innerprinter_device: BluetoothDevice? = null
        val devices = bluetoothAdapter!!.bondedDevices
        for (device in devices) {
            if (device.address == Innerprinter_Address) {
                innerprinter_device = device
                break
            }
        }
        return innerprinter_device
    }

    @SuppressLint("MissingPermission")
    @Throws(IOException::class)
    private fun getSocket(device: BluetoothDevice): BluetoothSocket {
        val socket = device.createRfcommSocketToServiceRecord(PRINTER_UUID)
        socket.connect()
        return socket
    }

    /**
     *
     *
     * @param context
     * @return
     */
    fun connectBlueTooth(context: Context?): Boolean {
        if (bluetoothSocket == null) {
            if (bTAdapter == null) {
                Toast.makeText(context, "蓝牙设备不可用", Toast.LENGTH_SHORT).show()
                return false
            }
            if (!bTAdapter!!.isEnabled) {
                Toast.makeText(context, "Bluetooth Not Enabled", Toast.LENGTH_SHORT).show()
                return false
            }
            var device: BluetoothDevice
            if ((getDevice(bTAdapter).also { device = it!! }) == null) {
                Toast.makeText(context, "未发现InnterPrinter!", Toast.LENGTH_SHORT).show()
                return false
            }

            try {
                bluetoothSocket = getSocket(device)
            } catch (e: IOException) {
                Toast.makeText(context, "Socket Exception!", Toast.LENGTH_SHORT).show()
                return false
            }
        }
        return true
    }

    /**
     *
     */
    fun disconnectBlueTooth(context: Context?) {
        if (bluetoothSocket != null) {
            try {
                val out = bluetoothSocket!!.outputStream
                out.close()
                bluetoothSocket!!.close()
            } catch (e: IOException) {
                Log.e("BluetoothUtil", "Bluetooth error: ${e.message}")
            }
        }
    }

    /**
     *
     *
     * @param bytes
     * @throws IOException
     */
    fun sendData(context: Context?, bytes: ByteArray?): Boolean {
        var dataSentStatus = false
        if (bluetoothSocket != null) {
            val out: OutputStream
            try {
                out = bluetoothSocket!!.outputStream
                out.write(bytes, 0, bytes!!.size)
                dataSentStatus = true
            } catch (e: IOException) {
                dataSentStatus = false
                Log.e("BluetoothUtil", "Send data error: ${e.message}")
                Toast.makeText(context, e.message, Toast.LENGTH_LONG).show()
            }
        } else {
            Toast.makeText(context, "BluetoothSocket is null", Toast.LENGTH_LONG).show()
            Log.i("kaltin", "bluetoothSocketttt null")
        }
        return dataSentStatus
    }
}
