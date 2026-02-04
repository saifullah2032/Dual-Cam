package com.example.dual_recorder

import android.Manifest
import android.content.ContentValues
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.*
import android.hardware.camera2.*
import android.media.*
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.HandlerThread
import android.provider.MediaStore
import android.util.Log
import android.util.Size
import android.view.Surface
import androidx.core.content.ContextCompat
import io.flutter.view.TextureRegistry
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream
import java.text.SimpleDateFormat
import java.util.*
import java.util.concurrent.Semaphore
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Layout modes for dual camera preview and recording
 */
enum class PreviewLayout {
    SIDE_BY_SIDE_HORIZONTAL,
    SIDE_BY_SIDE_VERTICAL,
    PIP_TOP_LEFT,
    PIP_TOP_RIGHT,
    PIP_BOTTOM_LEFT,
    PIP_BOTTOM_RIGHT,
    SINGLE_BACK,
    SINGLE_FRONT
}

/**
 * Video quality presets
 */
enum class VideoQuality(val width: Int, val height: Int, val bitRate: Int, val frameRate: Int) {
    LOW(640, 480, 2_000_000, 24),
    MEDIUM(1280, 720, 5_000_000, 30),
    HIGH(1920, 1080, 10_000_000, 30),
    ULTRA(1920, 1080, 15_000_000, 60)
}

/**
 * Native dual camera manager using Camera2 API
 * Records composed video from both cameras simultaneously
 */
class DualCameraManager(
    private val context: Context,
    private val textureRegistry: TextureRegistry
) {
    companion object {
        private const val TAG = "DualCameraManager"
        private const val CAMERA_OPEN_TIMEOUT = 2500L
    }

    // Camera system
    private val cameraManager: CameraManager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
    
    // Camera IDs
    private var frontCameraId: String? = null
    private var backCameraId: String? = null
    
    // Camera devices and sessions
    private var frontCamera: CameraDevice? = null
    private var backCamera: CameraDevice? = null
    private var frontCaptureSession: CameraCaptureSession? = null
    private var backCaptureSession: CameraCaptureSession? = null
    
    // Textures for Flutter preview
    private var frontTextureEntry: TextureRegistry.SurfaceTextureEntry? = null
    private var backTextureEntry: TextureRegistry.SurfaceTextureEntry? = null
    private var frontSurfaceTexture: SurfaceTexture? = null
    private var backSurfaceTexture: SurfaceTexture? = null
    
    // Image readers for frame capture (for composition)
    private var frontImageReader: ImageReader? = null
    private var backImageReader: ImageReader? = null
    
    // Photo capture image readers
    private var frontPhotoReader: ImageReader? = null
    private var backPhotoReader: ImageReader? = null
    
    // Video composer for merged recording
    private var videoComposer: VideoComposer? = null
    
    // Quality settings
    private var currentQuality = VideoQuality.MEDIUM
    private var enableAudio = true
    
    // Sizes
    private var previewSize = Size(1280, 720)
    private var frameSize = Size(640, 480)  // Frame capture size (optimized for performance)
    private var photoSize = Size(1920, 1080)
    
    // Layout and state
    private var currentLayout = PreviewLayout.SIDE_BY_SIDE_HORIZONTAL
    private var camerasSwapped = false
    private var isRecording = AtomicBoolean(false)
    private var composedVideoPath: String? = null
    
    // Threading
    private var backgroundThread: HandlerThread? = null
    private var backgroundHandler: Handler? = null
    private val cameraOpenCloseLock = Semaphore(1)
    
    // State
    private var isInitialized = false
    private var isDualCameraSupported = false
    private var officialDualCameraSupport = false  // Track official API support separately

    // Photo capture
    private var photoCaptureCallback: ((Map<String, String?>?) -> Unit)? = null
    private var pendingPhotoBitmaps = mutableMapOf<String, Bitmap?>()
    private var photosExpected = 0

    // Frame processing optimization
    private var lastFrontFrameTime = 0L
    private var lastBackFrameTime = 0L
    private val frameIntervalMs = 33L  // ~30fps limit for frame processing

    init {
        findCameras()
    }

    private fun findCameras() {
        try {
            for (cameraId in cameraManager.cameraIdList) {
                val characteristics = cameraManager.getCameraCharacteristics(cameraId)
                val facing = characteristics.get(CameraCharacteristics.LENS_FACING)
                
                when (facing) {
                    CameraCharacteristics.LENS_FACING_FRONT -> {
                        frontCameraId = cameraId
                        Log.d(TAG, "Found front camera: $cameraId")
                    }
                    CameraCharacteristics.LENS_FACING_BACK -> {
                        backCameraId = cameraId
                        Log.d(TAG, "Found back camera: $cameraId")
                    }
                }
            }
            
            // Check if device officially supports concurrent cameras (Android R+)
            // But we'll try to open both anyway since many devices work even without official support
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                val concurrentSets = cameraManager.concurrentCameraIds
                officialDualCameraSupport = concurrentSets.any { set ->
                    set.contains(frontCameraId) && set.contains(backCameraId)
                }
                Log.d(TAG, "Official dual camera support: $officialDualCameraSupport")
            }
            
            // Always enable dual camera if both front and back cameras exist
            // This bypasses the official API check and tries to open both cameras anyway
            isDualCameraSupported = frontCameraId != null && backCameraId != null
            Log.d(TAG, "Dual camera enabled (bypass mode): $isDualCameraSupported")
        } catch (e: Exception) {
            Log.e(TAG, "Error finding cameras", e)
        }
    }

    fun getCameraInfo(): Map<String, Any> {
        return mapOf(
            "frontCameraId" to (frontCameraId ?: ""),
            "backCameraId" to (backCameraId ?: ""),
            "isDualCameraSupported" to isDualCameraSupported,
            "officialDualCameraSupport" to officialDualCameraSupport,
            "androidVersion" to Build.VERSION.SDK_INT,
            "isInitialized" to isInitialized,
            "isRecording" to isRecording.get(),
            "currentLayout" to currentLayout.name,
            "camerasSwapped" to camerasSwapped,
            "currentQuality" to currentQuality.name,
            "enableAudio" to enableAudio
        )
    }

    fun setLayout(layoutName: String): Boolean {
        return try {
            currentLayout = PreviewLayout.valueOf(layoutName)
            Log.d(TAG, "Layout set to: $currentLayout")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Invalid layout: $layoutName", e)
            false
        }
    }

    fun setQuality(qualityName: String): Boolean {
        return try {
            currentQuality = VideoQuality.valueOf(qualityName)
            Log.d(TAG, "Quality set to: $currentQuality")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Invalid quality: $qualityName", e)
            false
        }
    }

    fun setAudioEnabled(enabled: Boolean): Boolean {
        enableAudio = enabled
        Log.d(TAG, "Audio enabled: $enableAudio")
        return true
    }

    fun getAvailableLayouts(): List<String> = PreviewLayout.values().map { it.name }
    
    fun getAvailableQualities(): List<String> = VideoQuality.values().map { it.name }

    fun swapCameras(): Boolean {
        camerasSwapped = !camerasSwapped
        Log.d(TAG, "Cameras swapped: $camerasSwapped")
        return camerasSwapped
    }

    fun initialize(callback: (Boolean, String?) -> Unit) {
        if (isInitialized) {
            callback(true, null)
            return
        }

        startBackgroundThread()

        if (ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
            callback(false, "Camera permission not granted")
            return
        }

        try {
            // Create texture entries for preview
            frontTextureEntry = textureRegistry.createSurfaceTexture()
            backTextureEntry = textureRegistry.createSurfaceTexture()
            
            frontSurfaceTexture = frontTextureEntry?.surfaceTexture()
            backSurfaceTexture = backTextureEntry?.surfaceTexture()
            
            frontSurfaceTexture?.setDefaultBufferSize(previewSize.width, previewSize.height)
            backSurfaceTexture?.setDefaultBufferSize(previewSize.width, previewSize.height)
            
            isInitialized = true
            callback(true, null)
        } catch (e: Exception) {
            Log.e(TAG, "Error initializing", e)
            callback(false, e.message)
        }
    }

    fun openCameras(callback: (Boolean, String?) -> Unit) {
        if (!isInitialized) {
            callback(false, "Not initialized")
            return
        }

        if (ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
            callback(false, "Camera permission not granted")
            return
        }

        try {
            var camerasOpened = 0
            var openError: String? = null
            val totalCameras = if (isDualCameraSupported && frontCameraId != null && backCameraId != null) 2 else 1

            val checkComplete = {
                camerasOpened++
                if (camerasOpened >= totalCameras) {
                    callback(openError == null, openError)
                }
            }

            // Open back camera
            backCameraId?.let { id ->
                openCamera(id, true) { success, error ->
                    if (!success) openError = error
                    checkComplete()
                }
            } ?: run {
                openError = "No back camera"
                checkComplete()
            }

            // Open front camera if supported
            if (isDualCameraSupported && frontCameraId != null) {
                frontCameraId?.let { id ->
                    openCamera(id, false) { success, error ->
                        if (!success && openError == null) openError = error
                        checkComplete()
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error opening cameras", e)
            callback(false, e.message)
        }
    }

    private fun openCamera(cameraId: String, isBack: Boolean, callback: (Boolean, String?) -> Unit) {
        try {
            if (!cameraOpenCloseLock.tryAcquire(CAMERA_OPEN_TIMEOUT, TimeUnit.MILLISECONDS)) {
                callback(false, "Camera lock timeout")
                return
            }

            if (ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
                cameraOpenCloseLock.release()
                callback(false, "Permission denied")
                return
            }

            cameraManager.openCamera(cameraId, object : CameraDevice.StateCallback() {
                override fun onOpened(camera: CameraDevice) {
                    cameraOpenCloseLock.release()
                    if (isBack) {
                        backCamera = camera
                    } else {
                        frontCamera = camera
                    }
                    createPreviewSession(camera, isBack, callback)
                }

                override fun onDisconnected(camera: CameraDevice) {
                    cameraOpenCloseLock.release()
                    camera.close()
                    if (isBack) backCamera = null else frontCamera = null
                }

                override fun onError(camera: CameraDevice, error: Int) {
                    cameraOpenCloseLock.release()
                    camera.close()
                    if (isBack) backCamera = null else frontCamera = null
                    callback(false, "Camera error: $error")
                }
            }, backgroundHandler)
        } catch (e: Exception) {
            cameraOpenCloseLock.release()
            callback(false, e.message)
        }
    }

    private fun createPreviewSession(camera: CameraDevice, isBack: Boolean, callback: (Boolean, String?) -> Unit) {
        try {
            val surfaceTexture = if (isBack) backSurfaceTexture else frontSurfaceTexture
            if (surfaceTexture == null) {
                callback(false, "Surface texture null")
                return
            }

            val previewSurface = Surface(surfaceTexture)
            val surfaces = mutableListOf(previewSurface)
            
            // Create image reader for frame capture during recording
            val imageReader = ImageReader.newInstance(
                frameSize.width, frameSize.height,
                ImageFormat.YUV_420_888, 2  // Reduced buffer count for better performance
            )
            
            imageReader.setOnImageAvailableListener({ reader ->
                val image = reader.acquireLatestImage()
                image?.use {
                    if (isRecording.get()) {
                        processFrameForComposition(it, isBack)
                    }
                }
            }, backgroundHandler)
            
            if (isBack) {
                backImageReader = imageReader
            } else {
                frontImageReader = imageReader
            }
            surfaces.add(imageReader.surface)
            
            // Create photo reader
            val photoReader = ImageReader.newInstance(
                photoSize.width, photoSize.height,
                ImageFormat.JPEG, 2
            )
            if (isBack) {
                backPhotoReader = photoReader
            } else {
                frontPhotoReader = photoReader
            }
            surfaces.add(photoReader.surface)

            val previewBuilder = camera.createCaptureRequest(CameraDevice.TEMPLATE_PREVIEW)
            previewBuilder.addTarget(previewSurface)
            previewBuilder.addTarget(imageReader.surface)

            camera.createCaptureSession(surfaces, object : CameraCaptureSession.StateCallback() {
                override fun onConfigured(session: CameraCaptureSession) {
                    if (isBack) {
                        backCaptureSession = session
                    } else {
                        frontCaptureSession = session
                    }
                    try {
                        previewBuilder.set(CaptureRequest.CONTROL_AF_MODE, CaptureRequest.CONTROL_AF_MODE_CONTINUOUS_VIDEO)
                        previewBuilder.set(CaptureRequest.CONTROL_AE_MODE, CaptureRequest.CONTROL_AE_MODE_ON)
                        session.setRepeatingRequest(previewBuilder.build(), null, backgroundHandler)
                        callback(true, null)
                    } catch (e: Exception) {
                        callback(false, e.message)
                    }
                }

                override fun onConfigureFailed(session: CameraCaptureSession) {
                    callback(false, "Session config failed")
                }
            }, backgroundHandler)
        } catch (e: Exception) {
            callback(false, e.message)
        }
    }

    private fun processFrameForComposition(image: Image, isBack: Boolean) {
        // Rate limit frame processing to reduce CPU load
        val currentTime = System.currentTimeMillis()
        if (isBack) {
            if (currentTime - lastBackFrameTime < frameIntervalMs) return
            lastBackFrameTime = currentTime
        } else {
            if (currentTime - lastFrontFrameTime < frameIntervalMs) return
            lastFrontFrameTime = currentTime
        }

        try {
            val bitmap = yuvToBitmap(image) ?: return
            
            // Apply rotation based on camera orientation
            val rotatedBitmap = rotateBitmap(bitmap, if (isBack) 90 else 270, !isBack)
            bitmap.recycle()  // Safe to recycle original after rotation
            
            // Pass to composer - it will make its own copy
            if (isBack) {
                videoComposer?.updateBackFrameBitmap(rotatedBitmap)
            } else {
                videoComposer?.updateFrontFrameBitmap(rotatedBitmap)
            }
            
            // Don't recycle here - let the VideoComposer handle it after copying
            // The VideoComposer uses AtomicReference and will recycle old frames
            rotatedBitmap.recycle()
        } catch (e: Exception) {
            Log.e(TAG, "Error processing frame", e)
        }
    }

    private fun rotateBitmap(bitmap: Bitmap, degrees: Int, mirror: Boolean): Bitmap {
        val matrix = Matrix()
        matrix.postRotate(degrees.toFloat())
        if (mirror) {
            matrix.postScale(-1f, 1f, bitmap.width / 2f, bitmap.height / 2f)
        }
        return Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
    }

    private fun yuvToBitmap(image: Image): Bitmap? {
        return try {
            val yBuffer = image.planes[0].buffer
            val uBuffer = image.planes[1].buffer
            val vBuffer = image.planes[2].buffer

            val ySize = yBuffer.remaining()
            val uSize = uBuffer.remaining()
            val vSize = vBuffer.remaining()

            val nv21 = ByteArray(ySize + uSize + vSize)

            // Copy Y plane
            yBuffer.get(nv21, 0, ySize)
            
            // Interleave U and V planes for NV21 format
            vBuffer.get(nv21, ySize, vSize)
            uBuffer.get(nv21, ySize + vSize, uSize)

            val yuvImage = YuvImage(nv21, ImageFormat.NV21, image.width, image.height, null)
            val out = ByteArrayOutputStream()
            yuvImage.compressToJpeg(Rect(0, 0, image.width, image.height), 85, out)
            val jpegBytes = out.toByteArray()
            out.close()
            
            BitmapFactory.decodeByteArray(jpegBytes, 0, jpegBytes.size)
        } catch (e: Exception) {
            Log.e(TAG, "YUV to Bitmap conversion failed", e)
            null
        }
    }

    fun startRecording(callback: (Boolean, String?) -> Unit) {
        if (isRecording.get()) {
            callback(false, "Already recording")
            return
        }

        // Check audio permission if audio is enabled
        if (enableAudio && ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            Log.w(TAG, "Audio permission not granted, recording without audio")
            enableAudio = false
        }

        try {
            val timestamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(Date())
            val storageDir = getOutputDirectory()
            composedVideoPath = File(storageDir, "VID_${timestamp}_dual.mp4").absolutePath

            // Determine output size based on layout and quality
            val outputWidth: Int
            val outputHeight: Int
            
            when (currentLayout) {
                PreviewLayout.SIDE_BY_SIDE_HORIZONTAL -> {
                    outputWidth = currentQuality.width
                    outputHeight = currentQuality.height
                }
                else -> {
                    // Portrait layouts
                    outputWidth = currentQuality.height.coerceAtMost(1080)
                    outputHeight = currentQuality.width.coerceAtMost(1920)
                }
            }

            Log.d(TAG, "Starting recording: ${outputWidth}x${outputHeight} @ ${currentQuality.frameRate}fps, bitrate: ${currentQuality.bitRate}")

            // Create video composer with quality settings
            videoComposer = VideoComposer(
                outputPath = composedVideoPath!!,
                outputWidth = outputWidth,
                outputHeight = outputHeight,
                layout = currentLayout,
                frameRate = currentQuality.frameRate,
                bitRate = currentQuality.bitRate,
                enableAudio = enableAudio
            )

            if (!videoComposer!!.start()) {
                callback(false, "Failed to start video composer")
                videoComposer = null
                return
            }

            isRecording.set(true)
            Log.d(TAG, "Recording started: $composedVideoPath")
            callback(true, null)

        } catch (e: Exception) {
            Log.e(TAG, "Error starting recording", e)
            videoComposer = null
            callback(false, e.message)
        }
    }

    fun stopRecording(callback: (Map<String, String?>?) -> Unit) {
        if (!isRecording.getAndSet(false)) {
            callback(null)
            return
        }

        Log.d(TAG, "Stopping recording...")

        backgroundHandler?.post {
            try {
                val videoPath = videoComposer?.stop()
                videoComposer = null

                val result = mutableMapOf<String, String?>()
                
                if (videoPath != null) {
                    // Verify the video file exists and is valid
                    val videoFile = File(videoPath)
                    if (videoFile.exists() && videoFile.length() > 0) {
                        result["composedVideo"] = videoPath
                        
                        // Save to gallery on background thread
                        val savedToGallery = saveVideoToGallery(videoPath)
                        Log.d(TAG, "Recording stopped: $videoPath, saved to gallery: $savedToGallery")
                    } else {
                        Log.e(TAG, "Video file is invalid or empty: $videoPath")
                    }
                }

                // Call back on main thread
                Handler(context.mainLooper).post {
                    if (result.isNotEmpty()) {
                        callback(result)
                    } else {
                        callback(null)
                    }
                }

            } catch (e: Exception) {
                Log.e(TAG, "Error stopping recording", e)
                Handler(context.mainLooper).post {
                    callback(null)
                }
            }
        }
    }

    private fun saveVideoToGallery(videoPath: String): Boolean {
        try {
            val file = File(videoPath)
            if (!file.exists()) {
                Log.e(TAG, "Video file doesn't exist: $videoPath")
                return false
            }
            
            if (file.length() == 0L) {
                Log.e(TAG, "Video file is empty: $videoPath")
                return false
            }

            Log.d(TAG, "Saving video to gallery: ${file.length()} bytes")

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val values = ContentValues().apply {
                    put(MediaStore.Video.Media.DISPLAY_NAME, file.name)
                    put(MediaStore.Video.Media.MIME_TYPE, "video/mp4")
                    put(MediaStore.Video.Media.RELATIVE_PATH, Environment.DIRECTORY_MOVIES + "/DualRecorder")
                    put(MediaStore.Video.Media.IS_PENDING, 1)
                }

                val uri = context.contentResolver.insert(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, values)
                if (uri == null) {
                    Log.e(TAG, "Failed to create MediaStore entry for video")
                    return false
                }
                
                val outputStream = context.contentResolver.openOutputStream(uri)
                if (outputStream == null) {
                    Log.e(TAG, "Failed to open output stream for video")
                    context.contentResolver.delete(uri, null, null)
                    return false
                }
                
                outputStream.use { os ->
                    file.inputStream().use { inputStream ->
                        inputStream.copyTo(os)
                    }
                }
                
                values.clear()
                values.put(MediaStore.Video.Media.IS_PENDING, 0)
                context.contentResolver.update(uri, values, null, null)
                Log.d(TAG, "Video saved to gallery successfully: $uri")
                return true
            } else {
                MediaScannerConnection.scanFile(context, arrayOf(videoPath), arrayOf("video/mp4")) { path, uri ->
                    Log.d(TAG, "Video scanned: $uri")
                }
                return true
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error saving to gallery", e)
            return false
        }
    }

    fun takePicture(callback: (Map<String, String?>?) -> Unit) {
        photoCaptureCallback = callback
        pendingPhotoBitmaps.clear()
        
        val hasBack = backCamera != null && backCaptureSession != null
        val hasFront = frontCamera != null && frontCaptureSession != null && isDualCameraSupported
        
        photosExpected = (if (hasBack) 1 else 0) + (if (hasFront) 1 else 0)
        
        if (photosExpected == 0) {
            callback(null)
            return
        }

        val timestamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(Date())

        if (hasBack) {
            capturePhoto(backCamera!!, backCaptureSession!!, backPhotoReader!!, true, timestamp)
        }
        if (hasFront) {
            capturePhoto(frontCamera!!, frontCaptureSession!!, frontPhotoReader!!, false, timestamp)
        }
    }

    private fun capturePhoto(
        camera: CameraDevice,
        session: CameraCaptureSession,
        imageReader: ImageReader,
        isBack: Boolean,
        timestamp: String
    ) {
        try {
            val captureBuilder = camera.createCaptureRequest(CameraDevice.TEMPLATE_STILL_CAPTURE)
            captureBuilder.addTarget(imageReader.surface)
            captureBuilder.set(CaptureRequest.CONTROL_AF_MODE, CaptureRequest.CONTROL_AF_MODE_CONTINUOUS_PICTURE)
            captureBuilder.set(CaptureRequest.JPEG_ORIENTATION, if (isBack) 90 else 270)

            imageReader.setOnImageAvailableListener({ reader ->
                val image = reader.acquireLatestImage()
                image?.use {
                    processPhotoBitmap(it, isBack, timestamp)
                }
            }, backgroundHandler)

            session.capture(captureBuilder.build(), object : CameraCaptureSession.CaptureCallback() {
                override fun onCaptureFailed(session: CameraCaptureSession, request: CaptureRequest, failure: CaptureFailure) {
                    onPhotoCaptured(if (isBack) "back" else "front", null, timestamp)
                }
            }, backgroundHandler)
        } catch (e: Exception) {
            onPhotoCaptured(if (isBack) "back" else "front", null, timestamp)
        }
    }

    private fun processPhotoBitmap(image: Image, isBack: Boolean, timestamp: String) {
        try {
            val buffer = image.planes[0].buffer
            val bytes = ByteArray(buffer.remaining())
            buffer.get(bytes)
            
            val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
            onPhotoCaptured(if (isBack) "back" else "front", bitmap, timestamp)
        } catch (e: Exception) {
            Log.e(TAG, "Error processing photo", e)
            onPhotoCaptured(if (isBack) "back" else "front", null, timestamp)
        }
    }

    private fun onPhotoCaptured(key: String, bitmap: Bitmap?, timestamp: String) {
        pendingPhotoBitmaps[key] = bitmap
        
        if (pendingPhotoBitmaps.size >= photosExpected) {
            // All photos captured, compose and save
            composeAndSavePhoto(timestamp)
        }
    }

    private fun composeAndSavePhoto(timestamp: String) {
        backgroundHandler?.post {
            try {
                val backBitmap = pendingPhotoBitmaps["back"]
                val frontBitmap = pendingPhotoBitmaps["front"]
                
                val composedBitmap = if (backBitmap != null && frontBitmap != null && isDualCameraSupported) {
                    // Compose both images based on current layout
                    composePhotoBitmaps(backBitmap, frontBitmap)
                } else {
                    // Single camera, use whichever is available
                    backBitmap ?: frontBitmap
                }
                
                if (composedBitmap != null) {
                    val savedPath = saveComposedPhoto(composedBitmap, timestamp)
                    
                    // Recycle bitmaps
                    backBitmap?.recycle()
                    frontBitmap?.recycle()
                    if (composedBitmap != backBitmap && composedBitmap != frontBitmap) {
                        composedBitmap.recycle()
                    }
                    
                    Handler(context.mainLooper).post {
                        photoCaptureCallback?.invoke(mapOf("composedPhoto" to savedPath))
                        photoCaptureCallback = null
                        pendingPhotoBitmaps.clear()
                    }
                } else {
                    Handler(context.mainLooper).post {
                        photoCaptureCallback?.invoke(null)
                        photoCaptureCallback = null
                        pendingPhotoBitmaps.clear()
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error composing photo", e)
                Handler(context.mainLooper).post {
                    photoCaptureCallback?.invoke(null)
                    photoCaptureCallback = null
                    pendingPhotoBitmaps.clear()
                }
            }
        }
    }

    private fun composePhotoBitmaps(backBitmap: Bitmap, frontBitmap: Bitmap): Bitmap {
        // Determine output size based on layout
        val outputWidth: Int
        val outputHeight: Int
        
        when (currentLayout) {
            PreviewLayout.SIDE_BY_SIDE_HORIZONTAL -> {
                outputWidth = 1920
                outputHeight = 1080
            }
            PreviewLayout.SIDE_BY_SIDE_VERTICAL -> {
                outputWidth = 1080
                outputHeight = 1920
            }
            else -> {
                // PiP and single layouts
                outputWidth = 1080
                outputHeight = 1920
            }
        }
        
        val composedBitmap = Bitmap.createBitmap(outputWidth, outputHeight, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(composedBitmap)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG)
        
        // Apply same composition logic as video
        when (currentLayout) {
            PreviewLayout.SIDE_BY_SIDE_HORIZONTAL -> {
                val halfWidth = outputWidth / 2
                // Front on left
                val frontSrc = Rect(0, 0, frontBitmap.width, frontBitmap.height)
                val frontDst = Rect(0, 0, halfWidth, outputHeight)
                canvas.drawBitmap(frontBitmap, frontSrc, frontDst, paint)
                // Back on right
                val backSrc = Rect(0, 0, backBitmap.width, backBitmap.height)
                val backDst = Rect(halfWidth, 0, outputWidth, outputHeight)
                canvas.drawBitmap(backBitmap, backSrc, backDst, paint)
            }
            PreviewLayout.SIDE_BY_SIDE_VERTICAL -> {
                val halfHeight = outputHeight / 2
                // Back on top
                val backSrc = Rect(0, 0, backBitmap.width, backBitmap.height)
                val backDst = Rect(0, 0, outputWidth, halfHeight)
                canvas.drawBitmap(backBitmap, backSrc, backDst, paint)
                // Front on bottom
                val frontSrc = Rect(0, 0, frontBitmap.width, frontBitmap.height)
                val frontDst = Rect(0, halfHeight, outputWidth, outputHeight)
                canvas.drawBitmap(frontBitmap, frontSrc, frontDst, paint)
            }
            PreviewLayout.PIP_TOP_LEFT, PreviewLayout.PIP_TOP_RIGHT,
            PreviewLayout.PIP_BOTTOM_LEFT, PreviewLayout.PIP_BOTTOM_RIGHT -> {
                // Main (back) fullscreen
                val mainBitmap = if (camerasSwapped) frontBitmap else backBitmap
                val pipBitmap = if (camerasSwapped) backBitmap else frontBitmap
                
                val mainSrc = Rect(0, 0, mainBitmap.width, mainBitmap.height)
                val mainDst = Rect(0, 0, outputWidth, outputHeight)
                canvas.drawBitmap(mainBitmap, mainSrc, mainDst, paint)
                
                // PiP overlay
                val pipWidth = outputWidth / 4
                val pipHeight = outputHeight / 4
                val margin = 40
                
                val (left, top) = when (currentLayout) {
                    PreviewLayout.PIP_TOP_LEFT -> Pair(margin, margin)
                    PreviewLayout.PIP_TOP_RIGHT -> Pair(outputWidth - pipWidth - margin, margin)
                    PreviewLayout.PIP_BOTTOM_LEFT -> Pair(margin, outputHeight - pipHeight - margin)
                    else -> Pair(outputWidth - pipWidth - margin, outputHeight - pipHeight - margin)
                }
                
                val pipSrc = Rect(0, 0, pipBitmap.width, pipBitmap.height)
                val pipDst = Rect(left, top, left + pipWidth, top + pipHeight)
                canvas.drawBitmap(pipBitmap, pipSrc, pipDst, paint)
            }
            PreviewLayout.SINGLE_BACK -> {
                val src = Rect(0, 0, backBitmap.width, backBitmap.height)
                val dst = Rect(0, 0, outputWidth, outputHeight)
                canvas.drawBitmap(backBitmap, src, dst, paint)
            }
            PreviewLayout.SINGLE_FRONT -> {
                val src = Rect(0, 0, frontBitmap.width, frontBitmap.height)
                val dst = Rect(0, 0, outputWidth, outputHeight)
                canvas.drawBitmap(frontBitmap, src, dst, paint)
            }
        }
        
        return composedBitmap
    }

    private fun saveComposedPhoto(bitmap: Bitmap, timestamp: String): String? {
        try {
            val filename = "IMG_${timestamp}_dual.jpg"
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val values = ContentValues().apply {
                    put(MediaStore.Images.Media.DISPLAY_NAME, filename)
                    put(MediaStore.Images.Media.MIME_TYPE, "image/jpeg")
                    put(MediaStore.Images.Media.RELATIVE_PATH, Environment.DIRECTORY_PICTURES + "/DualRecorder")
                    put(MediaStore.Images.Media.IS_PENDING, 1)
                }

                val uri = context.contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
                if (uri == null) {
                    Log.e(TAG, "Failed to create MediaStore entry for photo")
                    return null
                }
                
                val outputStream = context.contentResolver.openOutputStream(uri)
                if (outputStream == null) {
                    Log.e(TAG, "Failed to open output stream for photo")
                    context.contentResolver.delete(uri, null, null)
                    return null
                }
                
                val success = outputStream.use { os ->
                    bitmap.compress(Bitmap.CompressFormat.JPEG, 95, os)
                }
                
                if (!success) {
                    Log.e(TAG, "Failed to compress bitmap to JPEG")
                    context.contentResolver.delete(uri, null, null)
                    return null
                }
                
                // Mark as no longer pending
                values.clear()
                values.put(MediaStore.Images.Media.IS_PENDING, 0)
                context.contentResolver.update(uri, values, null, null)
                
                Log.d(TAG, "Composed photo saved successfully: $uri")
                return uri.toString()
            } else {
                val storageDir = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES), "DualRecorder")
                if (!storageDir.exists() && !storageDir.mkdirs()) {
                    Log.e(TAG, "Failed to create storage directory")
                    return null
                }
                
                val photoFile = File(storageDir, filename)
                val success = FileOutputStream(photoFile).use { os ->
                    bitmap.compress(Bitmap.CompressFormat.JPEG, 95, os)
                }
                
                if (!success || !photoFile.exists() || photoFile.length() == 0L) {
                    Log.e(TAG, "Failed to save photo file")
                    photoFile.delete()
                    return null
                }
                
                MediaScannerConnection.scanFile(context, arrayOf(photoFile.absolutePath), arrayOf("image/jpeg"), null)
                Log.d(TAG, "Composed photo saved successfully: ${photoFile.absolutePath}")
                return photoFile.absolutePath
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error saving composed photo", e)
        }
        return null
    }

    private fun getOutputDirectory(): File {
        val mediaDir = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            File(context.getExternalFilesDir(Environment.DIRECTORY_MOVIES), "DualRecorder")
        } else {
            File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MOVIES), "DualRecorder")
        }
        if (!mediaDir.exists()) mediaDir.mkdirs()
        return mediaDir
    }

    fun getTextureIds(): Map<String, Long> = mapOf(
        "frontTextureId" to (frontTextureEntry?.id() ?: -1L),
        "backTextureId" to (backTextureEntry?.id() ?: -1L)
    )

    fun getRecordingState(): Map<String, Any> = mapOf(
        "isRecording" to isRecording.get(),
        "isDualMode" to (isDualCameraSupported && frontCamera != null && backCamera != null),
        "composedVideoPath" to (composedVideoPath ?: ""),
        "currentLayout" to currentLayout.name,
        "camerasSwapped" to camerasSwapped,
        "currentQuality" to currentQuality.name,
        "enableAudio" to enableAudio
    )

    fun getLayoutInfo(): Map<String, Any> = mapOf(
        "currentLayout" to currentLayout.name,
        "availableLayouts" to getAvailableLayouts(),
        "camerasSwapped" to camerasSwapped
    )

    fun getQualityInfo(): Map<String, Any> = mapOf(
        "currentQuality" to currentQuality.name,
        "availableQualities" to getAvailableQualities(),
        "enableAudio" to enableAudio
    )

    private fun startBackgroundThread() {
        backgroundThread = HandlerThread("CameraBackground").apply { start() }
        backgroundHandler = Handler(backgroundThread!!.looper)
    }

    private fun stopBackgroundThread() {
        backgroundThread?.quitSafely()
        try {
            backgroundThread?.join()
            backgroundThread = null
            backgroundHandler = null
        } catch (e: InterruptedException) {
            Log.e(TAG, "Error stopping thread", e)
        }
    }

    fun closeCameras() {
        try {
            cameraOpenCloseLock.acquire()
            
            frontCaptureSession?.close()
            backCaptureSession?.close()
            frontCamera?.close()
            backCamera?.close()
            frontImageReader?.close()
            backImageReader?.close()
            frontPhotoReader?.close()
            backPhotoReader?.close()
            
            frontCaptureSession = null
            backCaptureSession = null
            frontCamera = null
            backCamera = null
            frontImageReader = null
            backImageReader = null
            frontPhotoReader = null
            backPhotoReader = null
            
        } catch (e: Exception) {
            Log.e(TAG, "Error closing cameras", e)
        } finally {
            cameraOpenCloseLock.release()
        }
    }

    fun dispose() {
        if (isRecording.get()) {
            videoComposer?.stop()
            isRecording.set(false)
        }
        closeCameras()
        
        frontTextureEntry?.release()
        backTextureEntry?.release()
        frontTextureEntry = null
        backTextureEntry = null
        
        stopBackgroundThread()
        isInitialized = false
    }
}

// Extension function for Image.use
inline fun <T> Image.use(block: (Image) -> T): T {
    try {
        return block(this)
    } finally {
        close()
    }
}
