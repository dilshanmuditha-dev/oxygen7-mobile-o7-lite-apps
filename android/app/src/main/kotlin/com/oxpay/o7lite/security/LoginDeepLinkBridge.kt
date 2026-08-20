package com.oxpay.o7lite.security

import android.content.Intent
import android.net.Uri
import com.oxpay.o7lite.utils.LogUtil
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

object LoginDeepLinkBridge {
    private const val TAG = "LoginDeepLinkBridge"
    private const val CHANNEL = "com.oxpay.o7lite/login_deep_link"
    private const val METHOD_GET_INITIAL = "getInitialLoginCredentials"
    private const val METHOD_ON_LOGIN = "onLoginDeepLink"

    private var channel: MethodChannel? = null
    private var pendingPayload: Map<String, Any>? = null

    fun configure(flutterEngine: FlutterEngine) {
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        channel?.setMethodCallHandler { call, result ->
            when (call.method) {
                METHOD_GET_INITIAL -> {
                    result.success(pendingPayload)
                    pendingPayload = null
                }
                else -> result.notImplemented()
            }
        }
    }

    fun handleDeepLink(intent: Intent?) {
        val payload = extractLoginPayload(intent?.data) ?: return

        pendingPayload = payload
        LogUtil.d(TAG, "Login credential deep link received")
        channel?.invokeMethod(METHOD_ON_LOGIN, payload)
    }

    fun extractLoginPayload(uri: Uri?): Map<String, Any>? {
        if (uri == null || !isLoginDeepLink(uri)) return null

        val operatorId = uri.getQueryParameter("operatorId")?.trim()
        val password = uri.getQueryParameter("pswd")?.trim()
        val missingOperatorId = operatorId.isNullOrEmpty()
        val missingPassword = password.isNullOrEmpty()

        if (missingOperatorId || missingPassword) {
            LogUtil.d(TAG, "Login deep link missing required params")
            return mapOf(
                "missingOperatorId" to missingOperatorId,
                "missingPassword" to missingPassword
            )
        }

        return mapOf(
            "operatorId" to operatorId,
            "pswd" to password
        )
    }

    fun isLoginDeepLink(uri: Uri): Boolean {
        val isCustomScheme = uri.scheme == "o7lite" && uri.host == "login"
        val isHttpsAppLink =
            uri.scheme == "https" && uri.host == "o7lite.com" && uri.path == "/login"

        return isCustomScheme || isHttpsAppLink
    }
}
