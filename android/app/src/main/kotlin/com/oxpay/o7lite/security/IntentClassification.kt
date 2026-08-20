package com.oxpay.o7lite.security

import android.content.Intent

/**
 * Represents the type of intent received by the activity.
 * Used to route intents to appropriate validation logic.
 */
enum class IntentType {
    /** android.intent.action.MAIN with LAUNCHER category - always allowed */
    LAUNCHER,
    
    /** FLUTTER_NOTIFICATION_CLICK action - requires self-origin validation */
    NOTIFICATION,
    
    /** VIEW action with custom scheme (my://native) - requires deep link validation */
    DEEP_LINK,
    
    /** Any other external intent - requires trusted package validation */
    EXTERNAL
}

/**
 * Data class representing the classification of an incoming intent.
 * Provides structured access to intent properties for validation.
 */
data class IntentClassification(
    val type: IntentType,
    val action: String?,
    val categories: Set<String>,
    val dataScheme: String?,
    val dataHost: String?
) {
    companion object {
        /** Action for Flutter notification clicks */
        private const val FLUTTER_NOTIFICATION_ACTION = "FLUTTER_NOTIFICATION_CLICK"
        
        /** Expected scheme for deep links */
        private const val DEEP_LINK_SCHEME = "my"

        private const val LOGIN_DEEP_LINK_SCHEME = "o7lite"
        private const val LOGIN_DEEP_LINK_HOST = "login"
        private const val HTTPS_DEEP_LINK_SCHEME = "https"
        private const val HTTPS_DEEP_LINK_HOST = "o7lite.com"
        private const val HTTPS_DEEP_LINK_PATH = "/login"
        
        /**
         * Creates an IntentClassification from an Android Intent.
         * 
         * @param intent The intent to classify (may be null)
         * @return IntentClassification with type and properties extracted
         */
        fun from(intent: Intent?): IntentClassification {
            return IntentClassification(
                type = classifyType(intent),
                action = intent?.action,
                categories = intent?.categories ?: emptySet(),
                dataScheme = intent?.data?.scheme,
                dataHost = intent?.data?.host
            )
        }
        
        /**
         * Determines the IntentType based on intent properties.
         * 
         * @param intent The intent to classify
         * @return The determined IntentType
         */
        private fun classifyType(intent: Intent?): IntentType {
            if (intent == null) return IntentType.EXTERNAL
            
            return when {
                // Launcher intent: MAIN action with LAUNCHER category
                isLauncherIntent(intent) -> IntentType.LAUNCHER
                
                // Notification intent: FLUTTER_NOTIFICATION_CLICK action
                isNotificationIntent(intent) -> IntentType.NOTIFICATION
                
                // Deep link intent: VIEW action with custom scheme
                isDeepLinkIntent(intent) -> IntentType.DEEP_LINK
                
                // All other intents are treated as external
                else -> IntentType.EXTERNAL
            }
        }
        
        /**
         * Checks if the intent is a launcher intent (from Android home screen).
         */
        private fun isLauncherIntent(intent: Intent): Boolean {
            return intent.action == Intent.ACTION_MAIN &&
                   intent.hasCategory(Intent.CATEGORY_LAUNCHER)
        }
        
        /**
         * Checks if the intent is a Flutter notification click.
         */
        private fun isNotificationIntent(intent: Intent): Boolean {
            return intent.action == FLUTTER_NOTIFICATION_ACTION
        }
        
        /**
         * Checks if the intent is a deep link with our custom scheme.
         */
        private fun isDeepLinkIntent(intent: Intent): Boolean {
            if (intent.action != Intent.ACTION_VIEW) return false

            val uri = intent.data ?: return false
            val isLegacyDeepLink = uri.scheme == DEEP_LINK_SCHEME
            val isLoginDeepLink =
                uri.scheme == LOGIN_DEEP_LINK_SCHEME && uri.host == LOGIN_DEEP_LINK_HOST
            val isHttpsLoginDeepLink =
                uri.scheme == HTTPS_DEEP_LINK_SCHEME &&
                    uri.host == HTTPS_DEEP_LINK_HOST &&
                    uri.path == HTTPS_DEEP_LINK_PATH

            return isLegacyDeepLink || isLoginDeepLink || isHttpsLoginDeepLink
        }
    }
    
    /**
     * Checks if this is a launcher intent that should bypass package validation.
     */
    fun isLauncher(): Boolean = type == IntentType.LAUNCHER
    
    /**
     * Checks if this is a notification intent requiring self-origin validation.
     */
    fun isNotification(): Boolean = type == IntentType.NOTIFICATION
    
    /**
     * Checks if this is a deep link intent requiring URI validation.
     */
    fun isDeepLink(): Boolean = type == IntentType.DEEP_LINK
    
    /**
     * Checks if this is an external intent requiring trusted package validation.
     */
    fun isExternal(): Boolean = type == IntentType.EXTERNAL
}
