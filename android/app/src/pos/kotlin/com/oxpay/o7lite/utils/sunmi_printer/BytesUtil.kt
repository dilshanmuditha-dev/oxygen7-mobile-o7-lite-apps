package com.oxpay.o7lite.utils.sunmi_printer

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Matrix
import android.graphics.Paint
import android.util.Log
import android.view.View
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.FileOutputStream
import java.io.IOException
import java.io.ObjectInputStream
import java.io.ObjectOutputStream

/**
 * Created by Koushik on 8/17/2017.
 */
object BytesUtil {
    @Throws(IOException::class)
    fun toByteArray(obj: Any?): ByteArray? {
        var bytes: ByteArray? = null
        var bos: ByteArrayOutputStream? = null
        var oos: ObjectOutputStream? = null
        try {
            bos = ByteArrayOutputStream()
            oos = ObjectOutputStream(bos)
            oos.writeObject(obj)
            oos.flush()
            bytes = bos.toByteArray()
        } finally {
            oos?.close()
            bos?.close()
        }
        return bytes
    }

    @Throws(IOException::class, ClassNotFoundException::class)
    fun toObject(bytes: ByteArray?): Any? {
        var obj: Any? = null
        var bis: ByteArrayInputStream? = null
        var ois: ObjectInputStream? = null
        try {
            bis = ByteArrayInputStream(bytes)
            ois = ObjectInputStream(bis)
            obj = ois.readObject()
        } finally {
            bis?.close()
            ois?.close()
        }
        return obj
    }

    fun convertView(view: View): Bitmap {
        val bitmap = Bitmap.createBitmap(view.width, view.height, Bitmap.Config.RGB_565)
        val c = Canvas(bitmap)
        view.draw(c)
        return bitmap
    }

    fun convertViewToImage(view: View): Bitmap? {
        var b: Bitmap? = null
        try {
            view.isDrawingCacheEnabled = true
            b = view.drawingCache
            Log.v("AfterCache", b.toString())
            b.compress(Bitmap.CompressFormat.PNG, 95, FileOutputStream("/res/drawable/a.png"))
            return b
        } catch (e: Exception) {
            Log.e("BytesUtil", "Bitmap error: ${e.message}")
        }
        Log.v("FinalResult", b.toString())
        return b
    }

    fun setViewToBitmapImage(view: View): Bitmap {
//Define a bitmap with the same size as the view
        val returnedBitmap = Bitmap.createBitmap(view.width, view.height, Bitmap.Config.ARGB_8888)
        //Bind a canvas to it
        val canvas = Canvas(returnedBitmap)
        //Get the view's background
        val bgDrawable = view.background
        if (bgDrawable != null) //has background drawable, then draw it on the canvas
            bgDrawable.draw(canvas)
        else  //does not have background drawable, then draw white background on the canvas
            canvas.drawColor(Color.WHITE)
        // draw the view on the canvas
        view.draw(canvas)
        //return the bitmap
        return returnedBitmap
    }


    //    public static Bitmap SaveImage(Bitmap finalBitmap) {
    //        String root = Environment.getExternalStorageDirectory().toString();
    //        File myDir = new File(root + "/saved_images");
    //        myDir.mkdirs();
    //        Random generator = new Random();
    //        int n = 10000;
    //        n = generator.nextInt(n);
    //        String fname = "Image-" + n + ".jpg";
    //        File file = new File(myDir, fname);
    //        if (file.exists()) file.delete();
    //        try {
    //            FileOutputStream out = new FileOutputStream(file);
    //            finalBitmap.compress(Bitmap.CompressFormat.JPEG, 90, out);
    //            out.flush();
    //            out.close();
    //            return finalBitmap;
    //
    //        } catch (Exception e) {
    //            Log.v("ExceptionOccured","ExceptionOccured");
    //            e.printStackTrace();
    //            return null;
    //        }
    //    }
    fun getBytesFromBitMap(bitmap: Bitmap?): ByteArray {
        val width = bitmap!!.width
        val height = bitmap.height
        val bw = (width - 1) / 8 + 1

        val rv = ByteArray(height * bw + 4)
        rv[0] = bw.toByte() //xL
        rv[1] = (bw shr 8).toByte() //xH
        rv[2] = height.toByte()
        rv[3] = (height shr 8).toByte()

        val pixels = IntArray(width * height)
        bitmap.getPixels(pixels, 0, width, 0, 0, width, height)

        for (i in 0 until height) {
            for (j in 0 until width) {
                val clr = pixels[width * i + j]
                val red = (clr and 0x00ff0000) shr 16
                val green = (clr and 0x0000ff00) shr 8
                val blue = clr and 0x000000ff
                val gray = (RGB2Gray(red, green, blue))
                rv[(width * i + j) / 8 + 4] =
                    (rv[(width * i + j) / 8 + 4].toInt() or (gray.toInt() shl (7 - ((width * i + j) % 8)))).toByte()
            }
        }

        return rv
    }

    private fun RGB2Gray(r: Int, g: Int, b: Int): Byte {
        return if ((if (false) ((0.29900 * r + 0.58700 * g + 0.11400 * b).toInt() > 200)
            else ((0.29900 * r + 0.58700 * g + 0.11400 * b).toInt() < 200))
        ) 1.toByte() else 0.toByte()
    }

    /* public static byte[] getZXingQRCode(String data, int size) {
        try {
            Hashtable<EncodeHintType, String> hints = new Hashtable<EncodeHintType, String>();
            hints.put(EncodeHintType.CHARACTER_SET, "utf-8");
            //图像数据转换，使用了矩阵转换
            BitMatrix bitMatrix = new QRCodeWriter().encode(data, BarcodeFormat.QR_CODE, size, size, hints);
            //System.out.println("bitmatrix height:" + bitMatrix.getHeight() + " width:" + bitMatrix.getWidth());
            return getBytesFromBitMatrix(bitMatrix);
        } catch (WriterException e) {
            // TODO Auto-generated catch block
            // e.printStackTrace();
        }
        return null;
    }*/
    fun byteMerger(byteList: Array<ByteArray>): ByteArray {
        var length = 0
        for (i in byteList.indices) {
            length += byteList[i].size
        }
        val result = ByteArray(length)

        var index = 0
        for (i in byteList.indices) {
            val nowByte = byteList[i]
            for (k in byteList[i].indices) {
                result[index] = nowByte[k]
                index++
            }
        }
        for (i in 0 until index) {
            // CommonUtils.LogWuwei("", "result[" + i + "] is " + result[i]);
        }
        return result
    }


    fun byteMerger(byte_1: ByteArray, byte_2: ByteArray?): ByteArray {
        val byte_3 = ByteArray(byte_1.size + byte_2!!.size)
        System.arraycopy(byte_1, 0, byte_3, 0, byte_1.size)
        System.arraycopy(byte_2, 0, byte_3, byte_1.size, byte_2.size)
        return byte_3
    }

    fun scaleImage(bitmap1: Bitmap): Bitmap {
        val width = bitmap1.width
        Log.v("Width", width.toString())

        val height = bitmap1.height

        Log.v("Height", height.toString())


        // 设置想要的大小
        val newWidth = (width / 8 + 1) * 8
        Log.v("newWidth", newWidth.toString())


        // 计算缩放比例
        val scaleWidth = (newWidth.toFloat()) / width
        Log.v("scaleWidth", scaleWidth.toString())

        // 取得想要缩放的matrix参数
        val matrix = Matrix()
        matrix.postScale(scaleWidth, 1f)
        // 得到新的图片
        val newbm = Bitmap.createBitmap(
            bitmap1, 0, 0, 384, 384, matrix,
            true
        )
        return newbm
    }

    fun getResizedBitmap(image: Bitmap?, newHeight: Int, newWidth: Int): Bitmap {
        val width = image!!.width
        val height = image.height
        val scaleWidth = (newWidth.toFloat()) / width
        val scaleHeight = (newHeight.toFloat()) / height
        // create a matrix for the manipulation
        val matrix = Matrix()
        // resize the bit map
        matrix.postScale(scaleWidth, scaleHeight)
        // recreate the new Bitmap
        val resizedBitmap = Bitmap.createBitmap(
            image, 0, 0, width, height,
            matrix, false
        )
        return resizedBitmap
    }

    fun initBlackBlock(h: Int, w: Int): ByteArray {
        val hh = h
        val ww = (w - 1) / 8 + 1
        val data = ByteArray(hh * ww + 6)

        data[0] = ww.toByte() //xL
        data[1] = (ww shr 8).toByte() //xH
        data[2] = hh.toByte()
        data[3] = (hh shr 8).toByte()

        var k = 4
        for (i in 0 until hh) {
            for (j in 0 until ww) {
                data[k++] = 0xFF.toByte()
            }
        }
        data[k++] = 0x00
        data[k++] = 0x00
        return data
    }


    fun receiptBuilder(
        merchantName: String,
        address: String,
        sale: String,
        brandName: String,
        currency: String,
        totalAmount: String,
        refernceNo: String
    ): ByteArray {
        val sb = StringBuilder("     $merchantName       ")
        sb.append("\n")
        sb.append(" $address ")
        sb.append("\n")
        sb.append("\n")
        sb.append(" Sale        $sale ")
        sb.append("\n")
        sb.append("-----------------------")
        sb.append("\n")
        sb.append(" BrandName   $brandName")
        sb.append("\n")
        sb.append("-----------------------")
        sb.append("\n")

        sb.append(" Total       $currency $totalAmount")
        sb.append("\n")

        sb.append("-----------------------")
        sb.append("\n")
        sb.append(" Ref no      $refernceNo")
        sb.append("\n")
        sb.append("-----------------------")
        return sb.toString().toByteArray()
    }

    fun printSingleCopy(data: Bitmap): Bitmap {
        val printAreaHeight = 50
        val bmp = Bitmap.createBitmap(
            data.width * 3,
            ((data.height + printAreaHeight) * 1.75).toInt(),
            Bitmap.Config.ARGB_8888
        )
        val c = Canvas(bmp)
        val p = Paint()
        c.drawBitmap(data, 10f, 80f, p)
        c.save()
        return bmp
    }

    fun convertBitMaptoByteArray(receiptBitmap: Bitmap): ByteArray {
        val bStream = ByteArrayOutputStream()
        receiptBitmap.compress(Bitmap.CompressFormat.PNG, 100, bStream)
        val byteArray = bStream.toByteArray()
        return byteArray
    }

    fun toString(bytes: ByteArray?): String {
        return String(bytes!!)
    }
}
