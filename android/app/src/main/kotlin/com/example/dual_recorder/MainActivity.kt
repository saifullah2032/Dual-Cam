package com.example.dual_recorder

import android.os.Build
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "com.example.dual_recorder/camera"
        private const val EVENT_CHANNEL = "com.example.dual_recorder/camera_events"
        private const val TAG = "DualRecorder"
    }

    private var dualCameraManager: DualCameraManager? = null
    private var eventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Initialize DualCameraManager with texture registry
        dualCameraManager = DualCameraManager(this, flutterEngine.renderer)

        // Method channel for commands
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            Log.d(TAG, "Method called: ${call.method}")
            
            try {
                when (call.method) {
                    "initialize" -> {
                        dualCameraManager?.initialize { success, error ->
                            runOnUiThread {
                                if (success) {
                                    result.success(mapOf("success" to true))
                                } else {
                                    result.success(mapOf("success" to false, "error" to error))
                                }
                            }
                        }
                    }
                    
                    "openCameras" -> {
                        dualCameraManager?.openCameras { success, error ->
                            runOnUiThread {
                                if (success) {
                                    val textureIds = dualCameraManager?.getTextureIds() ?: emptyMap()
                                    val cameraInfo = dualCameraManager?.getCameraInfo() ?: emptyMap()
                                    result.success(mapOf(
                                        "success" to true,
                                        "textureIds" to textureIds,
                                        "cameraInfo" to cameraInfo
                                    ))
                                } else {
                                    result.success(mapOf("success" to false, "error" to error))
                                }
                            }
                        }
                    }
                    
                    "startRecording" -> {
                        dualCameraManager?.startRecording { success, error ->
                            runOnUiThread {
                                if (success) {
                                    result.success(mapOf("success" to true))
                                    sendEvent("recordingStarted", null)
                                } else {
                                    result.success(mapOf("success" to false, "error" to error))
                                }
                            }
                        }
                    }
                    
                    "stopRecording" -> {
                        dualCameraManager?.stopRecording { paths ->
                            runOnUiThread {
                                result.success(mapOf(
                                    "success" to (paths != null),
                                    "paths" to paths
                                ))
                                sendEvent("recordingStopped", paths)
                            }
                        }
                    }
                    
                    "takePicture" -> {
                        dualCameraManager?.takePicture { paths ->
                            runOnUiThread {
                                result.success(mapOf(
                                    "success" to (paths != null && paths.isNotEmpty()),
                                    "paths" to paths
                                ))
                                sendEvent("photoTaken", paths)
                            }
                        }
                    }
                    
                    "setLayout" -> {
                        val layoutName = call.argument<String>("layout")
                        if (layoutName != null) {
                            val success = dualCameraManager?.setLayout(layoutName) ?: false
                            result.success(mapOf(
                                "success" to success,
                                "currentLayout" to layoutName
                            ))
                            if (success) {
                                sendEvent("layoutChanged", layoutName)
                            }
                        } else {
                            result.success(mapOf("success" to false, "error" to "Layout name required"))
                        }
                    }
                    
                    "setQuality" -> {
                        val qualityName = call.argument<String>("quality")
                        if (qualityName != null) {
                            val success = dualCameraManager?.setQuality(qualityName) ?: false
                            result.success(mapOf(
                                "success" to success,
                                "currentQuality" to qualityName
                            ))
                            if (success) {
                                sendEvent("qualityChanged", qualityName)
                            }
                        } else {
                            result.success(mapOf("success" to false, "error" to "Quality name required"))
                        }
                    }
                    
                    "setAudioEnabled" -> {
                        val enabled = call.argument<Boolean>("enabled") ?: true
                        val success = dualCameraManager?.setAudioEnabled(enabled) ?: false
                        result.success(mapOf(
                            "success" to success,
                            "audioEnabled" to enabled
                        ))
                        if (success) {
                            sendEvent("audioEnabledChanged", enabled)
                        }
                    }
                    
                    "getAvailableLayouts" -> {
                        val layouts = dualCameraManager?.getAvailableLayouts() ?: emptyList()
                        result.success(mapOf(
                            "success" to true,
                            "layouts" to layouts
                        ))
                    }
                    
                    "getAvailableQualities" -> {
                        val qualities = dualCameraManager?.getAvailableQualities() ?: emptyList()
                        result.success(mapOf(
                            "success" to true,
                            "qualities" to qualities
                        ))
                    }
                    
                    "getLayoutInfo" -> {
                        val info = dualCameraManager?.getLayoutInfo() ?: emptyMap()
                        result.success(info)
                    }
                    
                    "getQualityInfo" -> {
                        val info = dualCameraManager?.getQualityInfo() ?: emptyMap()
                        result.success(info)
                    }
                    
                    "swapCameras" -> {
                        val swapped = dualCameraManager?.swapCameras() ?: false
                        result.success(mapOf(
                            "success" to true,
                            "camerasSwapped" to swapped
                        ))
                        sendEvent("camerasSwapped", swapped)
                    }
                    
                    "closeCameras" -> {
                        dualCameraManager?.closeCameras()
                        result.success(mapOf("success" to true))
                    }
                    
                    "dispose" -> {
                        dualCameraManager?.dispose()
                        result.success(mapOf("success" to true))
                    }
                    
                    "getCameraInfo" -> {
                        val info = dualCameraManager?.getCameraInfo() ?: emptyMap()
                        result.success(info)
                    }
                    
                    "getTextureIds" -> {
                        val ids = dualCameraManager?.getTextureIds() ?: emptyMap()
                        result.success(ids)
                    }
                    
                    "getRecordingState" -> {
                        val state = dualCameraManager?.getRecordingState() ?: emptyMap()
                        result.success(state)
                    }
                    
                    "getDeviceInfo" -> {
                        result.success(mapOf(
                            "model" to Build.MODEL,
                            "manufacturer" to Build.MANUFACTURER,
                            "androidVersion" to Build.VERSION.SDK_INT,
                            "release" to Build.VERSION.RELEASE
                        ))
                    }
                    
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error handling method: ${call.method}", e)
                result.success(mapOf("success" to false, "error" to e.message))
            }
        }

        // Event channel for streaming updates
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    Log.d(TAG, "Event channel listening")
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    Log.d(TAG, "Event channel cancelled")
                }
            }
        )
    }

    private fun sendEvent(event: String, data: Any?) {
        runOnUiThread {
            eventSink?.success(mapOf(
                "event" to event,
                "data" to data
            ))
        }
    }

    override fun onPause() {
        super.onPause()
        // Don't close cameras on pause to allow background recording
    }

    override fun onDestroy() {
        super.onDestroy()
        dualCameraManager?.dispose()
        dualCameraManager = null
    }
}
