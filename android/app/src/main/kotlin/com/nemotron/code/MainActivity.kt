package com.nemotron.code

import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "nemotron/control"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            val svc = NemotronAccessibilityService.instance

            when (call.method) {

                "isEnabled" -> result.success(svc != null)

                "openAccessibilitySettings" -> {
                    startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                    result.success(null)
                }

                "captureScreen" -> {
                    if (svc == null) { result.error("NO_SERVICE", "Accessibility service not enabled", null); return@setMethodCallHandler }
                    result.success(svc.captureScreen())
                }

                "currentApp" -> {
                    if (svc == null) { result.error("NO_SERVICE", "Accessibility service not enabled", null); return@setMethodCallHandler }
                    result.success(svc.currentPackageName())
                }

                "tap" -> {
                    if (svc == null) { result.error("NO_SERVICE", "Accessibility service not enabled", null); return@setMethodCallHandler }
                    val x = call.argument<Int>("x") ?: 0
                    val y = call.argument<Int>("y") ?: 0
                    svc.tap(x, y) { ok -> result.success(ok) }
                }

                "swipe" -> {
                    if (svc == null) { result.error("NO_SERVICE", "Accessibility service not enabled", null); return@setMethodCallHandler }
                    val x1 = call.argument<Int>("x1") ?: 0
                    val y1 = call.argument<Int>("y1") ?: 0
                    val x2 = call.argument<Int>("x2") ?: 0
                    val y2 = call.argument<Int>("y2") ?: 0
                    val dur = call.argument<Int>("duration")?.toLong() ?: 300L
                    svc.swipe(x1, y1, x2, y2, dur) { ok -> result.success(ok) }
                }

                "typeText" -> {
                    if (svc == null) { result.error("NO_SERVICE", "Accessibility service not enabled", null); return@setMethodCallHandler }
                    val text = call.argument<String>("text") ?: ""
                    result.success(svc.typeText(text))
                }

                "back"    -> { svc?.pressBack();   result.success(null) }
                "home"    -> { svc?.pressHome();   result.success(null) }
                "recents" -> { svc?.openRecents(); result.success(null) }

                "openApp" -> {
                    val pkg = call.argument<String>("package") ?: ""
                    val launchIntent = packageManager.getLaunchIntentForPackage(pkg)
                    if (launchIntent != null) {
                        startActivity(launchIntent)
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }
}
