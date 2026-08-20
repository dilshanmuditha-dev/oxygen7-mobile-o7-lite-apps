package com.oxpay.o7lite.managers

import com.oxpay.o7lite.utils.LogUtil

/**
 * Interface for logging operations, allowing for testable implementations.
 */
interface LandiLogger {
    fun d(tag: String, message: String)
    fun e(tag: String, message: String)
}

/**
 * Default logger implementation using LogUtil.
 */
class DefaultLandiLogger : LandiLogger {
    override fun d(tag: String, message: String) {
        LogUtil.d(tag, message)
    }

    override fun e(tag: String, message: String) {
        LogUtil.e(tag, message)
    }
}

/**
 * No-op logger for testing purposes.
 */
class NoOpLandiLogger : LandiLogger {
    override fun d(tag: String, message: String) { /* No-op */ }
    override fun e(tag: String, message: String) { /* No-op */ }
}

/**
 * Manages the connection state for Landi OmniDriver.
 * 
 * This class encapsulates the state tracking logic for Landi printer initialization,
 * providing a testable interface for state transitions based on OmniConnection callbacks.
 * 
 * **Property 4: State Consistency**
 * For any OmniConnection callback, the isLandiInitSuccess flag SHALL be set to true 
 * after onConnected() and false after onDisconnected().
 * 
 * **Validates: Requirements 2.2, 2.3**
 */
class LandiConnectionStateManager(
    private val maxRetryCount: Int = DEFAULT_MAX_RETRY,
    private val logger: LandiLogger = NoOpLandiLogger()
) {
    companion object {
        private const val TAG = "LandiConnectionStateManager"
        const val DEFAULT_MAX_RETRY = 3
    }

    /**
     * Tracks whether Landi OmniDriver has been successfully initialized.
     * - Set to true when onConnected() is called
     * - Set to false when onDisconnected() is called or after cleanup
     */
    private var _isLandiInitSuccess: Boolean = false
    val isLandiInitSuccess: Boolean
        get() = _isLandiInitSuccess

    /**
     * Tracks the number of retry attempts for OmniDriver initialization.
     */
    private var _retryCount: Int = 0
    val retryCount: Int
        get() = _retryCount

    /**
     * Called when OmniConnection.onConnected() callback is received.
     * Sets the initialization success flag to true and resets retry count.
     * 
     * **Requirement 2.2**: WHEN OmniConnection.onConnected() is called, 
     * THE System SHALL set the initialization flag to true
     */
    fun onConnected() {
        _isLandiInitSuccess = true
        _retryCount = 0
        logger.d(TAG, "OmniDriver connected - isLandiInitSuccess set to true")
    }

    /**
     * Called when OmniConnection.onDisconnected() callback is received.
     * Sets the initialization success flag to false.
     * 
     * **Requirement 2.3**: WHEN OmniConnection.onDisconnected() is called, 
     * THE System SHALL set the initialization flag to false and log the error code
     * 
     * @param errorCode The error code from OmniDriver
     * @return true if retry should be attempted, false otherwise
     */
    fun onDisconnected(errorCode: Int): Boolean {
        _isLandiInitSuccess = false
        logger.e(TAG, "OmniDriver disconnected - error code: $errorCode, isLandiInitSuccess set to false")
        
        return shouldRetry()
    }

    /**
     * Determines if a retry should be attempted based on current retry count.
     * 
     * **Property 3: Retry Limit Enforcement**
     * For any sequence of OmniDriver initialization failures, the retry counter 
     * SHALL increment on each failure and stop retrying when it reaches maxRetryCount.
     * 
     * @return true if retry count is below max, false otherwise
     */
    fun shouldRetry(): Boolean {
        return _retryCount < maxRetryCount
    }

    /**
     * Increments the retry counter.
     * Should be called before each retry attempt.
     */
    fun incrementRetryCount() {
        _retryCount++
        logger.d(TAG, "Retry count incremented to $_retryCount")
    }

    /**
     * Resets the state manager to initial state.
     * Called during cleanup or when activity is destroyed.
     * 
     * **Requirement 4.3**: THE System SHALL reset the initialization flag to false after cleanup
     */
    fun reset() {
        _isLandiInitSuccess = false
        _retryCount = 0
        logger.d(TAG, "State reset - isLandiInitSuccess: false, retryCount: 0")
    }

    /**
     * Checks if the Landi printer is ready for use.
     * 
     * **Requirement 2.4**: THE System SHALL expose a method to check if Landi printer is ready for use
     * 
     * @return true if Landi printer is initialized and ready
     */
    fun isReady(): Boolean = _isLandiInitSuccess
}
