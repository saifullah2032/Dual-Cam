package com.example.dual_recorder

import android.content.Context
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.dual_recorder/camera_capability"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasConcurrentCameraSupport" -> {
                    val hasSupport = hasConcurrentCameraSupport()
                    result.success(hasSupport)
                }
                "getCameraIds" -> {
                    val cameraIds = getCameraIds()
                    result.success(cameraIds)
                }
                "getDeviceModel" -> {
                    val model = getDeviceModel()
                    result.success(model)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun hasConcurrentCameraSupport(): Boolean {
        if (android.os.Build.VERSION.SDK_INT < android.os.Build.VERSION_INT_CODES.R) {
            return false // Concurrent camera support was introduced in Android 11 (API 30)
        }
        
        return try {
            val cameraManager = getSystemService(Context.CAMERA_SERVICE) as CameraManager
            val concurrentSets = cameraManager.getConcurrentCameraIds()
            concurrentSets.isNotEmpty()
        } catch (e: Exception) {
            false
        }
    }

    private fun getCameraIds(): List<String> {
        return try {
            val cameraManager = getSystemService(Context.CAMERA_SERVICE) as CameraManager
            cameraManager.cameraIdList.toList()
        } catch (e: Exception) {
            emptyList()
        }
    }

    private fun getDeviceModel(): String {
        return android.os.Build.MODEL
    }
}
