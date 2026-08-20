package com.oxpay.o7lite.utils

import android.annotation.SuppressLint
import android.app.Activity
import android.app.AlertDialog
import android.content.Context
import android.os.Build
import android.view.View
import android.view.Window
import android.widget.ImageView
import com.bumptech.glide.Glide
import com.oxpay.o7lite.R
import com.oxpay.o7lite.entity.TransactionItem
import com.oxpay.o7lite.entity.TransactionSummary
import com.oxpay.o7lite.enums.BrandType
import org.json.JSONObject
import java.io.UnsupportedEncodingException
import java.security.InvalidKeyException
import java.security.NoSuchAlgorithmException
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec


object Utils {

    const val API_URL = "https://gw2.mcpayment.net/api/"

    val CHANNEL = "SHA512"
    private const val HMAC_SHA512 = "HmacSHA512"

    const val CHANNEL_CASTLE = "CHANNEL_CASTLE"
    const val CHANNEL_ANFU = "CHANNEL_ANFU"
    const val CHANNEL_SUNMI = "CHANNEL_SUNMI"
    const val CHANNEL_LANDI = "CHANNEL_LANDI"
    const val CHANNEL_ANDROID_SYSTEM = "CHANNEL_ANDROID_SYSTEM"
    const val CHANNEL_WIZAR_POS = "CHANNEL_WIZAR_POS"
    const val CHANNEL_COHERENT = "CHANNEL_COHERENT"
    const val CHANNEL_MOREFUN = "CHANNEL_MOREFUN"

    private val ISO_8859_1 = Charsets.ISO_8859_1

    fun getDeviceName(): String {
        val manufacturer = Build.MANUFACTURER
        val model = Build.MODEL
        return if (model.lowercase(Locale.getDefault())
                .startsWith(manufacturer.lowercase(Locale.getDefault()))
        ) {
            capitalize(model)
        } else {
            capitalize(manufacturer) + " " + model
        }
    }


    private fun capitalize(s: String?): String {
        if (s.isNullOrEmpty()) {
            return ""
        }
        val first = s[0]
        return if (Character.isUpperCase(first)) {
            s
        } else {
            first.uppercaseChar().toString() + s.substring(1)
        }
    }

    fun isANFU(): Boolean {
        val deviceBrand = Build.BRAND
        return deviceBrand.contains("ANFU", ignoreCase = true)
    }

    fun isLANDI(): Boolean {
        val deviceBrand = Build.BRAND
        return deviceBrand.contains("LANDI", ignoreCase = true)
    }

    fun isSUNMI(): Boolean {
        val deviceBrand = Build.BRAND
        return deviceBrand.contains("SUNMI", ignoreCase = true)
    }

    fun isCASTLE(): Boolean {
        val deviceBrand = Build.BRAND
        val deviceModel = Build.MODEL
        return deviceBrand.contains("CASTLE", ignoreCase = true) || 
               deviceModel.contains("CASTLE", ignoreCase = true)
    }

    fun isWIZAR(): Boolean {
        val deviceModel = Build.MODEL
        return deviceModel.contains("WIZARPOS Q2", ignoreCase = true)
    }

    fun isCOHERENT(): Boolean {
        val deviceBrand = Build.BRAND
        val deviceModel = Build.MODEL
        return deviceBrand.contains("COHERENT", ignoreCase = true) ||
               deviceBrand.contains("CENTERM", ignoreCase = true) ||
               deviceModel.contains("CENTERM", ignoreCase = true)
    }

    fun isMOREFUN(): Boolean {
        val deviceBrand = Build.BRAND
        val deviceModel = Build.MODEL
        val deviceManufacturer = Build.MANUFACTURER
        return deviceBrand.contains("MOREFUN", ignoreCase = true) ||
               deviceManufacturer.contains("MOREFUN", ignoreCase = true) ||
               deviceModel.contains("MOREFUN", ignoreCase = true)
    }

    fun encryptionHmacSHA512(encryptString: String, key: String): String? {

        try {
            val bytesKey = key.toByteArray()
            val secretKey = SecretKeySpec(bytesKey, HMAC_SHA512)
            val mac = Mac.getInstance(HMAC_SHA512)
            mac.init(secretKey)
            val macData = mac.doFinal(encryptString.toByteArray())
            val hex = macData.joinToString("") { "%02x".format(it) }
            return hex
        } catch (e: NoSuchAlgorithmException) {
            LogUtil.e("Utils", "HMAC encryption error: ${e.message}")
        } catch (e: InvalidKeyException) {
            LogUtil.e("Utils", "HMAC invalid key: ${e.message}")
        } catch (e: UnsupportedEncodingException) {
            LogUtil.e("Utils", "HMAC encoding error: ${e.message}")
        }
        return null
    }

    @SuppressLint("SimpleDateFormat", "NewApi")
    fun convertDDMMYYYY(time: String?): String {
        time?.let {
            val calendar = Calendar.getInstance()
            try {
                calendar.timeInMillis = time.toLong()
            } catch (e: Exception) {
                val df = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ssXXX")
                calendar.timeInMillis = df.parse(time)?.time ?: 0
            }

            calendar.timeZone = TimeZone.getDefault()
            val date = Date(calendar.timeInMillis)
            val format = SimpleDateFormat("dd.MM.yyyy")
            return format.format(date)
        }
        return "-"
    }

    @SuppressLint("SimpleDateFormat", "NewApi")
    fun convertHHMM(time: String?): String {
        time?.let {
            val calendar = Calendar.getInstance()

            try {
                calendar.timeInMillis = time.toLong()
            } catch (e: Exception) {
                val df = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ssXXX")
                calendar.timeInMillis = df.parse(time)?.time ?: 0
            }

            calendar.timeZone = TimeZone.getDefault()
            val date = Date(calendar.timeInMillis)
            val format = SimpleDateFormat("HH:mm")
            return format.format(date)
        }
        return ""
    }

    fun currentTimeToLong(): Long {
        return System.currentTimeMillis()
    }

    @SuppressLint("SimpleDateFormat")
    fun convertDateToLong(date: String): Long {
        val df = SimpleDateFormat("yyyy.MM.dd HH:mm")
        return df.parse(date)?.time ?: 0
    }

    fun Double?.toDollars(): String {
        if (this == null) {
            return "0.00"
        }
        val amt = this.toDouble()
        val result = (amt / 100)
        // toStringAsFixed
        return String.format("%.2f", result)
    }

    fun brandImage(brandName: String?): Int {
        val brandIcons = mapOf(
            BrandType.BRAND_ALIPAY to R.drawable.icon_title_alipay,
            BrandType.BRAND_ALIPAY_NEW to R.drawable.icon_title_alipay,
            BrandType.BRAND_WECHAT to R.drawable.wechatpay,
            BrandType.BRAND_WECHAT_NEW to R.drawable.wechatpay,
            BrandType.BRAND_GRABPAY to R.drawable.grabpay,
            BrandType.BRAND_GRABPAY2 to R.drawable.grabpay,
            BrandType.BRAND_GRABPAY3 to R.drawable.grabpay,
            BrandType.BRAND_VISA to R.drawable.icon_visa,
            BrandType.BRAND_MASTERCARD to R.drawable.img_master_card,
            BrandType.BRAND_AMEX to R.drawable.icon_amex,
            BrandType.BRAND_DINERS to R.drawable.icon_diners,
            BrandType.BRAND_DISCOVER to R.drawable.icon_discover,
            BrandType.BRAND_RUPAY to R.drawable.icon_discover,
            BrandType.BRAND_ATOME to R.drawable.icon_title_atome,
            BrandType.BRAND_THAIQR to R.drawable.thaiqr,
            BrandType.BRAND_PAYNOW to R.drawable.icon_title_paynow,
            BrandType.BRAND_PAYNOW2 to R.drawable.icon_title_paynow,
            BrandType.BRAND_CUP to R.drawable.icon_cup,
            BrandType.BRAND_QUICKPASS to R.drawable.icon_cup,
            BrandType.BRAND_ENETS to R.drawable.icon_mcp,
            BrandType.BRAND_DASH to R.drawable.icon_title_dash,
            BrandType.BRAND_BOOST to R.drawable.boost,
            BrandType.BRAND_TNG to R.drawable.touchngo,
            BrandType.BRAND_SHOPEE to R.drawable.icon_title_shopee,
            BrandType.BRAND_IOUPAY to R.drawable.ioupay,

            // GW3 brands
            // GW3 Wechat
            BrandType.BRAND_GW3_WECHAT to R.drawable.icon_print_wechat,
            // GW3 Shopeepay
            BrandType.BRAND_GW3_SHOPEEPAY to R.drawable.icon_print_shopee,
            // GW3 Paynow
            BrandType.BRAND_GW3_PAYNOW to R.drawable.icon_print_paynow,
            // GW3 Shopback
            BrandType.BRAND_GW3_SHOPBACK to R.drawable.ic_shopback_white_bg,

            // UPI
            BrandType.BRAND_UPI to R.drawable.icon_upi_2
        )

        // Exact match first so existing (legacy) mappings are unchanged.
        brandIcons[brandName]?.let { return it }

        // Fallback: normalized keyword matching. GW3 sends brand-name variants
        // (casing/format) that are not exact keys above, which previously fell
        // through to the default logo on the printout even though the on-screen
        // Flutter list resolves them correctly via its fuzzy matcher. This
        // mirrors that behavior so the printed report shows the correct brand
        // logo instead of the default.
        return brandImageByKeyword(brandName)
    }

    /**
     * Resolves a brand logo drawable from a normalized brand name using keyword
     * matching. Mirrors the Flutter `getBrandImage` fuzzy matcher so the printed
     * summary report logo matches what is shown on screen. Returns the default
     * round logo only when no keyword matches.
     */
    private fun brandImageByKeyword(brandName: String?): Int {
        if (brandName.isNullOrBlank()) return R.drawable.ic_logo_round
        val n = brandName.lowercase().replace(Regex("[^a-z0-9]"), "")
        return when {
            n.contains("alipay") -> R.drawable.icon_title_alipay
            n.contains("wechat") || n.contains("weixin") -> R.drawable.icon_print_wechat
            n.contains("grab") -> R.drawable.grabpay
            n.contains("mastercard") -> R.drawable.img_master_card
            n.contains("visa") -> R.drawable.icon_visa
            n.contains("amex") || n.contains("americanexpress") -> R.drawable.icon_amex
            n.contains("diners") -> R.drawable.icon_diners
            n.contains("discover") || n.contains("rupay") -> R.drawable.icon_discover
            n.contains("atome") -> R.drawable.icon_title_atome
            n.contains("thaiqr") || n.contains("promptpay") -> R.drawable.thaiqr
            n.contains("paynow") -> R.drawable.icon_print_paynow
            n.contains("quickpass") || n.contains("unionpay") || n.contains("cup") -> R.drawable.icon_cup
            n.contains("enets") -> R.drawable.icon_mcp
            n.contains("dash") || n.contains("singtel") -> R.drawable.icon_title_dash
            n.contains("boost") -> R.drawable.boost
            n.contains("shopback") -> R.drawable.ic_shopback_white_bg
            n.contains("shopee") -> R.drawable.icon_print_shopee
            n.contains("ioupay") || n.contains("iou") -> R.drawable.ioupay
            n.contains("touchngo") || n.contains("touchandgo") || n.contains("tng") ->
                R.drawable.touchngo
            n.contains("upi") -> R.drawable.icon_upi_2
            else -> R.drawable.ic_logo_round
        }
    }

    fun getItemStatus(responseCode: String?): Int {
        if (responseCode.isNullOrEmpty()) {
            return R.drawable.ic_failed
        }

        if (responseCode == "00" || responseCode == "0000") { // 00 is success
            return R.drawable.ic_success
        }
        return R.drawable.ic_failed
    }

    fun getSummaryData(context: Context, summaryJsonData: String): TransactionSummary? {
        LogUtil.d("LANDI_SUMMARY", "getSummaryData: parsing JSON, length=${summaryJsonData.length}")
        val jsonObject = JSONObject(summaryJsonData)
        LogUtil.d("LANDI_SUMMARY", "getSummaryData: JSONObject created, keys=${jsonObject.keys().asSequence().toList()}")
        
        val summaryReportData = TransactionSummary(
            jsonObject.getInt("totalCount"),
            jsonObject.getDouble("totalPayAmount"),
            jsonObject.getInt("totalPayCount"),
            jsonObject.getDouble("totalVoidAmount"),
            jsonObject.getInt("totalVoidCount"),
            jsonObject.getDouble("totalRefundAmount"),
            jsonObject.getInt("totalRefundCount"),
        )
        LogUtil.d("LANDI_SUMMARY", "getSummaryData: TransactionSummary created successfully")

        val transactionList = jsonObject.getJSONArray("transactionList")
        LogUtil.d("LANDI_SUMMARY", "getSummaryData: transactionList size=${transactionList.length()}")

        val transactionItemList = mutableListOf<TransactionItem>()
        for (i in 0 until transactionList.length()) {
            val transactionItem = transactionList.getJSONObject(i)
            LogUtil.d("LANDI_SUMMARY", "getSummaryData: parsing txn[$i], keys=${transactionItem.keys().asSequence().toList()}")
            var responseDate = transactionItem.getString("gatewayResponseDate")
            if (responseDate.isEmpty() || responseDate == "null") {
                responseDate = transactionItem.getString("hostResponseDate")
            }
            LogUtil.d("LANDI_SUMMARY", "getSummaryData: txn[$i] responseDate=$responseDate")
            val item = TransactionItem(
                transactionItem.getString("type"),
                transactionItem.getString("responseCode"),
                transactionItem.getString("currency"),
                transactionItem.getString("brandName"),
                responseDate,
                transactionItem.getString("mcpTerminalId"),
                transactionItem.getDouble("totalAmount"),
            )
            transactionItemList.add(item)
        }

        LogUtil.d("LANDI_SUMMARY", "getSummaryData: parsed ${transactionItemList.size} transaction items")

        summaryReportData.transactionList = transactionItemList

        return summaryReportData
    }

    enum class CastleMethodChannel(val value: String) {
        PRINT_RECEIPT_MANUAL("printCastleReceiptManual"),
        PRINT_BITMAP("printCastle"),
        PRINT_SUMMARY_REPORT("printCastleSummary"),
    }

    fun showErrorDialog(activity: Activity, message: String) {
        activity.runOnUiThread {
            val builder = AlertDialog.Builder(activity)
            builder.setTitle("Error")
            builder.setMessage(message)
            builder.setPositiveButton("OK") { dialog, _ -> dialog.dismiss() }
            val dialog = builder.create()
            dialog.show()
        }
    }

    fun fakeDialog(activity: Activity, bitmap: android.graphics.Bitmap) {
        val view = View.inflate(activity, R.layout.dialog_layout, null)
        val imgRefInflated = view.findViewById<View>(R.id.ivSample)
        Glide.with(activity).load(bitmap).into(imgRefInflated as ImageView)

        val builder: AlertDialog.Builder = AlertDialog.Builder(activity)
        builder.setNegativeButton("Close") { dialog, _ -> dialog.dismiss() }

        val dialog: AlertDialog = builder.create()
        dialog.setView(view)
        dialog.requestWindowFeature(Window.FEATURE_NO_TITLE)
        dialog.show()
    }
}