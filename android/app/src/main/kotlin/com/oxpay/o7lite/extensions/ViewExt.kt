package com.oxpay.o7lite.extensions

import android.view.View
import android.widget.TextView

var TextView.textOrGoneTrimmed: CharSequence?
    get() = text
    set(value) {
        val trimmed = value?.toString()?.trim()
        if (trimmed.isNullOrEmpty()) {
            text = null
            visibility = View.GONE
        } else {
            text = trimmed
            visibility = View.VISIBLE
        }
    }

var TextView.textOrGone: CharSequence?
    get() = text
    set(value) {
        if (value.isNullOrBlank()) {
            text = null
            visibility = View.GONE
        } else {
            text = value
            visibility = View.VISIBLE
        }
    }


// If value == null -> do nothing (keep current text + visibility)
// Else: trim and apply text-or-gone logic
var TextView.textOrGoneIgnoreNull: CharSequence?
    get() = text
    set(value) {
        if (value == null) return

        val trimmed = value.toString().trim()
        if (trimmed.isEmpty()) {
            text = null
            visibility = View.GONE
        } else {
            text = trimmed
            visibility = View.VISIBLE
        }
    }


