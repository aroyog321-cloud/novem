package com.anonymous.nove_mobile_flutter

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.view.accessibility.AccessibilityEvent
import io.flutter.plugin.common.EventChannel

object AppLaunchStreamHandler : EventChannel.StreamHandler {
    private var eventSink: EventChannel.EventSink? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    fun sendEvent(eventString: String) {
        Handler(Looper.getMainLooper()).post {
            eventSink?.success(eventString)
        }
    }
}

class NoveAccessibilityService : AccessibilityService() {
    // Keeps track of the linked app currently open
    private var currentlyLinkedApp: String? = null

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        if (event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val openedPackageName = event.packageName?.toString() ?: return
            val prefs = getSharedPreferences("nove_links", Context.MODE_PRIVATE)

            if (prefs.contains(openedPackageName)) {
                // 1. A linked app was opened! 
                currentlyLinkedApp = openedPackageName
                AppLaunchStreamHandler.sendEvent("open:$openedPackageName")
                
            } else if (currentlyLinkedApp != null) {
                // 2. We were in a linked app, but now we switched to something else.
                // We ignore System UI and our own NOVE app so the bubble doesn't accidentally close itself when clicked.
                if (openedPackageName != packageName && openedPackageName != "com.android.systemui") {
                     AppLaunchStreamHandler.sendEvent("close")
                     currentlyLinkedApp = null
                }
            }
        }
    }

    override fun onInterrupt() {}
}