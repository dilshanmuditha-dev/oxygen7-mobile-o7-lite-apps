package com.oxpay.o7lite.utils

import android.content.Context
import android.util.Log

class LogUtil private constructor(private var mContext: Context) {
    companion object {
        const val VERBOSE: Int = 0
        const val DEBUG: Int = 1
        const val INFO: Int = 2
        const val WARN: Int = 3
        const val ERROR: Int = 4
        const val NO_LOG: Int = 5

        private var instance: LogUtil? = null
        private var LOG_LEVEL = VERBOSE
        private lateinit var mContext: Context

        fun init(context: Context): LogUtil? {
            if (instance == null) {
                instance = LogUtil(context)
                mContext = context
            }
            return instance
        }

        /**
         * 设置日志等级
         *
         * @param level 日志等级
         */
        fun setLogLevel(level: Int) {
            LOG_LEVEL = level
        }

        private val functionName: String?
            /**
             * 作为日志的TAG，包括日志接口调用者的当前线程名称、类名称、类所在行数、方法名称。
             *
             * @return
             */
            get() {
                val sts = Thread.currentThread().stackTrace
                for (st in sts) {
                    if (st.isNativeMethod) {
                        continue
                    }
                    if (st.className == Thread::class.java.name) {
                        continue
                    }
                    if (st.className == instance?.javaClass?.name) {
                        continue
                    }
                    return ("[" + Thread.currentThread().name + ": "
                            + st.fileName + ":" + st.lineNumber + " "
                            + st.methodName + "]")
                }
                return null
            }

        fun v(tag: String?, msg: String?) {
            if (VERBOSE < LOG_LEVEL) return
            Log.v(tag, msg!!)
        }

        fun v(msg: String?) {
            v(functionName, msg)
        }

        fun d(tag: String?, msg: String?) {
            if (DEBUG < LOG_LEVEL) return
            Log.d(tag, msg!!)
        }

        fun d(msg: String?) {
            d(functionName, msg)
        }

        fun i(tag: String?, msg: String?) {
            if (INFO < LOG_LEVEL) return
            Log.i(tag, msg!!)
        }

        fun i(msg: String?) {
            i(functionName, msg)
        }

        fun w(tag: String?, msg: String?) {
            if (WARN < LOG_LEVEL) return
            Log.w(tag, msg!!)
        }

        fun w(msg: String?) {
            w(functionName, msg)
        }

        fun w(msg: String, tr: Throwable) {
            w(functionName, msg + tr.message)
        }

        fun w(tag: String?, msg: String, tr: Throwable) {
            w(tag, msg + tr.message)
        }

        fun e(tag: String?, msg: String?) {
            if (ERROR < LOG_LEVEL) return
            Log.e(tag, msg!!)
        }

        fun e(msg: String?) {
            e(functionName, msg)
        }

        fun e(msg: String, tr: Throwable) {
            e(functionName, msg + tr.message)
        }
    }
}
