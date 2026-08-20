package com.oxpay.o7lite.utils.sunmi_printer

import android.content.Context
import android.graphics.Bitmap
import android.view.View
import android.widget.Toast
import com.oxpay.o7lite.utils.LogUtil
import java.io.ByteArrayOutputStream

object SunmiPrinter {
    fun print(context: Context?, isMerchantCopy: Boolean, view: View) {
        Toast.makeText(context, " Image Printing Started", Toast.LENGTH_LONG).show()

        val convertedView = BytesUtil.convertView(view)
        //Log.v("Pixel",Integer.toString(convertedView.getPixel(2229,960)));
        val resizedBitmap =
            BytesUtil.getResizedBitmap(convertedView, (view.height * 384 / view.width), 384)
        //Bitmap resizedBitmap = BytesUtil.getResizedBitmap(convertedView,view.getHeight(),384);
        val stream = ByteArrayOutputStream()
        resizedBitmap!!.compress(Bitmap.CompressFormat.JPEG, 100, stream)
        val imageInByte = stream.toByteArray()
        val lengthbmp = imageInByte.size.toLong()
        try {
            if (BluetoothUtil.connectBlueTooth(context)) {
                // Toast.makeText(context, "Bluetooth Connected", Toast.LENGTH_LONG).show();

                if (BluetoothUtil.sendData(context, ESCUtil.printBitmap(resizedBitmap))) {
                    BluetoothUtil.sendData(context, ESCUtil.nextLine(3))
                    // Toast.makeText(context, "Data Sent to Printer Successfully", Toast.LENGTH_LONG).show();
                } else {
                    //Toast.makeText(context,"Data Sent to Printer Failed",Toast.LENGTH_LONG).show();
                }
            }
        } catch (e: Exception) {
            Toast.makeText(context, "Exception Occured During Data sent", Toast.LENGTH_LONG).show()
            LogUtil.e("SunmiPrinter", "Print error: ${e.message}")
        }
    }

    fun print(context: Context?, bitmap: Bitmap) {
        Toast.makeText(context, " Image Printing Started", Toast.LENGTH_LONG).show()

        val resizedBitmap =
            BytesUtil.getResizedBitmap(bitmap, (bitmap.height * 384 / bitmap.width), 384)
        val stream = ByteArrayOutputStream()
        resizedBitmap!!.compress(Bitmap.CompressFormat.JPEG, 100, stream)
        try {
            if (BluetoothUtil.connectBlueTooth(context)) {
                // Toast.makeText(context, "Bluetooth Connected", Toast.LENGTH_LONG).show();

                if (BluetoothUtil.sendData(context, ESCUtil.printBitmap(resizedBitmap))) {
                    BluetoothUtil.sendData(context, ESCUtil.nextLine(3))
                    // Toast.makeText(context, "Data Sent to Printer Successfully", Toast.LENGTH_LONG).show();
                } else {
                    // Toast.makeText(context, "Data Sent to Printer Failed", Toast.LENGTH_LONG).show();
                }
            }
        } catch (e: Exception) {
            LogUtil.e("SunmiPrinter", "Print bitmap error: ${e.message}")
        }
    }
}
