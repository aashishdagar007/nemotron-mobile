package com.nemotron.code

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.graphics.Path
import android.graphics.Rect
import android.os.Bundle
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import org.json.JSONArray
import org.json.JSONObject

/**
 * NemotronAccessibilityService
 * Exposes: screen capture (UI tree as JSON), tap, type, swipe, back, home.
 * Controlled by NemotronControlChannel (MethodChannel bridge to Flutter/AI loop).
 */
class NemotronAccessibilityService : AccessibilityService() {

    companion object {
        var instance: NemotronAccessibilityService? = null
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {}
    override fun onInterrupt() {}

    override fun onDestroy() {
        instance = null
        super.onDestroy()
    }

    // ── SCREEN READ ──────────────────────────────────────────
    /** Returns a JSON array describing every visible, actionable element on screen. */
    fun captureScreen(): String {
        val root = rootInActiveWindow ?: return "[]"
        val elements = JSONArray()
        walk(root, elements)
        return elements.toString()
    }

    private fun walk(node: AccessibilityNodeInfo, out: JSONArray, depth: Int = 0) {
        if (depth > 40) return // safety guard against malformed trees

        val isUseful = node.isClickable || node.isEditable ||
                !node.text.isNullOrBlank() || !node.contentDescription.isNullOrBlank()

        if (isUseful) {
            val bounds = Rect()
            node.getBoundsInScreen(bounds)
            val obj = JSONObject()
            obj.put("text", node.text?.toString() ?: "")
            obj.put("desc", node.contentDescription?.toString() ?: "")
            obj.put("class", node.className?.toString() ?: "")
            obj.put("clickable", node.isClickable)
            obj.put("editable", node.isEditable)
            obj.put("checked", node.isChecked)
            obj.put("x", bounds.centerX())
            obj.put("y", bounds.centerY())
            obj.put("w", bounds.width())
            obj.put("h", bounds.height())
            out.put(obj)
        }

        for (i in 0 until node.childCount) {
            node.getChild(i)?.let { walk(it, out, depth + 1) }
        }
    }

    fun currentPackageName(): String =
        rootInActiveWindow?.packageName?.toString() ?: "unknown"

    // ── ACTIONS ──────────────────────────────────────────────
    fun tap(x: Int, y: Int, callback: (Boolean) -> Unit) {
        val path = Path().apply { moveTo(x.toFloat(), y.toFloat()) }
        val gesture = GestureDescription.Builder()
            .addStroke(GestureDescription.StrokeDescription(path, 0, 80))
            .build()
        dispatchGesture(gesture, object : GestureResultCallback() {
            override fun onCompleted(gestureDescription: GestureDescription?) {
                callback(true)
            }
            override fun onCancelled(gestureDescription: GestureDescription?) {
                callback(false)
            }
        }, null)
    }

    fun swipe(x1: Int, y1: Int, x2: Int, y2: Int, durationMs: Long, callback: (Boolean) -> Unit) {
        val path = Path().apply {
            moveTo(x1.toFloat(), y1.toFloat())
            lineTo(x2.toFloat(), y2.toFloat())
        }
        val gesture = GestureDescription.Builder()
            .addStroke(GestureDescription.StrokeDescription(path, 0, durationMs))
            .build()
        dispatchGesture(gesture, object : GestureResultCallback() {
            override fun onCompleted(gestureDescription: GestureDescription?) {
                callback(true)
            }
            override fun onCancelled(gestureDescription: GestureDescription?) {
                callback(false)
            }
        }, null)
    }

    /** Types text into the currently focused editable field. */
    fun typeText(text: String): Boolean {
        val node = findFocusedEditable(rootInActiveWindow) ?: return false
        val args = Bundle()
        args.putCharSequence(
            AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE, text
        )
        return node.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, args)
    }

    private fun findFocusedEditable(node: AccessibilityNodeInfo?): AccessibilityNodeInfo? {
        if (node == null) return null
        if (node.isEditable && node.isFocused) return node
        for (i in 0 until node.childCount) {
            val found = findFocusedEditable(node.getChild(i))
            if (found != null) return found
        }
        return null
    }

    fun pressBack()  { performGlobalAction(GLOBAL_ACTION_BACK) }
    fun pressHome()  { performGlobalAction(GLOBAL_ACTION_HOME) }
    fun openRecents(){ performGlobalAction(GLOBAL_ACTION_RECENTS) }
}
