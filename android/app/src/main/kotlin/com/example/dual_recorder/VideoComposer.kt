package com.example.dual_recorder

import android.graphics.*
import android.media.*
import android.os.Handler
import android.os.HandlerThread
import android.util.Log
import android.view.Surface
import java.io.File
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicLong

/**
 * Composes two camera feeds into a single video with configurable layout
 * Uses MediaCodec with Surface input for efficient encoding
 */
class VideoComposer(
    private val outputPath: String,
    private val outputWidth: Int,
    private val outputHeight: Int,
    private val layout: PreviewLayout,
    private val frameRate: Int = 30,
    private val bitRate: Int = 8_000_000,
    private val enableAudio: Boolean = true
) {
    companion object {
        private const val TAG = "VideoComposer"
        private const val VIDEO_MIME_TYPE = MediaFormat.MIMETYPE_VIDEO_AVC
        private const val AUDIO_MIME_TYPE = MediaFormat.MIMETYPE_AUDIO_AAC
        private const val I_FRAME_INTERVAL = 1
        private const val TIMEOUT_US = 10000L
        private const val AUDIO_SAMPLE_RATE = 44100
        private const val AUDIO_CHANNEL_COUNT = 1
        private const val AUDIO_BIT_RATE = 128000
    }

    // Video Encoder
    private var videoEncoder: MediaCodec? = null
    private var inputSurface: Surface? = null
    private var videoTrackIndex: Int = -1

    // Audio Encoder
    private var audioEncoder: MediaCodec? = null
    private var audioRecord: AudioRecord? = null
    private var audioTrackIndex: Int = -1

    // Muxer
    private var muxer: MediaMuxer? = null
    private var muxerStarted = false
    private val muxerLock = Object()
    private var tracksAdded = 0
    private val expectedTracks: Int
        get() = if (enableAudio) 2 else 1

    // Frame buffers for each camera
    @Volatile private var frontFrameBitmap: Bitmap? = null
    @Volatile private var backFrameBitmap: Bitmap? = null
    private val frontFrameLock = Object()
    private val backFrameLock = Object()

    // State
    private val isRecording = AtomicBoolean(false)
    private val isStopping = AtomicBoolean(false)
    private val frameCount = AtomicLong(0)
    private var startTimeNs = 0L

    // Threading
    private var compositionThread: HandlerThread? = null
    private var compositionHandler: Handler? = null
    private var videoEncoderThread: HandlerThread? = null
    private var videoEncoderHandler: Handler? = null
    private var audioThread: Thread? = null

    // Paint for drawing
    private val paint = Paint().apply {
        isFilterBitmap = true
        isAntiAlias = true
        isDither = true
    }

    private val borderPaint = Paint().apply {
        color = Color.BLACK
        style = Paint.Style.FILL
    }

    private val whiteBorderPaint = Paint().apply {
        color = Color.WHITE
        style = Paint.Style.FILL
    }

    fun start(): Boolean {
        if (isRecording.get()) {
            Log.w(TAG, "Already recording")
            return false
        }

        return try {
            // Ensure output directory exists
            File(outputPath).parentFile?.mkdirs()

            setupVideoEncoder()
            setupMuxer()
            if (enableAudio) {
                setupAudioEncoder()
            }
            startThreads()
            
            isRecording.set(true)
            isStopping.set(false)
            startTimeNs = System.nanoTime()
            frameCount.set(0)
            
            Log.d(TAG, "VideoComposer started: $outputPath (${outputWidth}x${outputHeight})")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start VideoComposer", e)
            releaseEncoders()
            false
        }
    }

    private fun setupVideoEncoder() {
        val format = MediaFormat.createVideoFormat(VIDEO_MIME_TYPE, outputWidth, outputHeight).apply {
            setInteger(MediaFormat.KEY_COLOR_FORMAT, MediaCodecInfo.CodecCapabilities.COLOR_FormatSurface)
            setInteger(MediaFormat.KEY_BIT_RATE, bitRate)
            setInteger(MediaFormat.KEY_FRAME_RATE, frameRate)
            setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, I_FRAME_INTERVAL)
            // Add profile and level for better compatibility
            setInteger(MediaFormat.KEY_PROFILE, MediaCodecInfo.CodecProfileLevel.AVCProfileBaseline)
            setInteger(MediaFormat.KEY_LEVEL, MediaCodecInfo.CodecProfileLevel.AVCLevel31)
        }

        videoEncoder = MediaCodec.createEncoderByType(VIDEO_MIME_TYPE).apply {
            configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
            inputSurface = createInputSurface()
            start()
        }
        
        Log.d(TAG, "Video encoder setup complete")
    }

    private fun setupAudioEncoder() {
        try {
            val audioFormat = MediaFormat.createAudioFormat(AUDIO_MIME_TYPE, AUDIO_SAMPLE_RATE, AUDIO_CHANNEL_COUNT).apply {
                setInteger(MediaFormat.KEY_BIT_RATE, AUDIO_BIT_RATE)
                setInteger(MediaFormat.KEY_AAC_PROFILE, MediaCodecInfo.CodecProfileLevel.AACObjectLC)
                setInteger(MediaFormat.KEY_MAX_INPUT_SIZE, 16384)
            }

            audioEncoder = MediaCodec.createEncoderByType(AUDIO_MIME_TYPE).apply {
                configure(audioFormat, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
                start()
            }

            val minBufferSize = AudioRecord.getMinBufferSize(
                AUDIO_SAMPLE_RATE,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT
            )

            audioRecord = AudioRecord(
                MediaRecorder.AudioSource.MIC,
                AUDIO_SAMPLE_RATE,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT,
                minBufferSize * 2
            )

            Log.d(TAG, "Audio encoder setup complete")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to setup audio encoder", e)
            // Continue without audio
            audioEncoder?.release()
            audioEncoder = null
            audioRecord?.release()
            audioRecord = null
        }
    }

    private fun setupMuxer() {
        muxer = MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
        muxerStarted = false
        tracksAdded = 0
        Log.d(TAG, "Muxer setup complete")
    }

    private fun startThreads() {
        // Video encoder thread
        videoEncoderThread = HandlerThread("VideoEncoderThread").apply { start() }
        videoEncoderHandler = Handler(videoEncoderThread!!.looper)

        // Composition thread
        compositionThread = HandlerThread("CompositionThread").apply { start() }
        compositionHandler = Handler(compositionThread!!.looper)

        // Start video encoder drain loop
        videoEncoderHandler?.post { drainVideoEncoder(false) }

        // Start composition loop
        startCompositionLoop()

        // Start audio recording
        if (enableAudio && audioEncoder != null && audioRecord != null) {
            startAudioRecording()
        }
    }

    private fun startCompositionLoop() {
        val frameIntervalMs = 1000L / frameRate
        
        compositionHandler?.post(object : Runnable {
            override fun run() {
                if (isRecording.get() && !isStopping.get()) {
                    composeAndSubmitFrame()
                    compositionHandler?.postDelayed(this, frameIntervalMs)
                }
            }
        })
    }

    private fun startAudioRecording() {
        audioThread = Thread {
            try {
                audioRecord?.startRecording()
                val bufferSize = 4096
                val audioBuffer = ByteArray(bufferSize)
                val audioStartTime = System.nanoTime()

                while (isRecording.get() && !isStopping.get()) {
                    val readResult = audioRecord?.read(audioBuffer, 0, bufferSize) ?: -1
                    if (readResult > 0) {
                        feedAudioToEncoder(audioBuffer, readResult, audioStartTime)
                    }
                }
                
                // Send end of stream
                feedAudioToEncoder(ByteArray(0), 0, audioStartTime, true)
                
            } catch (e: Exception) {
                Log.e(TAG, "Audio recording error", e)
            }
        }.apply { 
            name = "AudioRecordThread"
            start() 
        }
    }

    private fun feedAudioToEncoder(data: ByteArray, size: Int, startTime: Long, endOfStream: Boolean = false) {
        val encoder = audioEncoder ?: return
        
        try {
            val inputBufferIndex = encoder.dequeueInputBuffer(TIMEOUT_US)
            if (inputBufferIndex >= 0) {
                val inputBuffer = encoder.getInputBuffer(inputBufferIndex)
                inputBuffer?.clear()
                
                if (!endOfStream && size > 0) {
                    inputBuffer?.put(data, 0, size)
                }
                
                val presentationTimeUs = (System.nanoTime() - startTime) / 1000
                val flags = if (endOfStream) MediaCodec.BUFFER_FLAG_END_OF_STREAM else 0
                
                encoder.queueInputBuffer(inputBufferIndex, 0, if (endOfStream) 0 else size, presentationTimeUs, flags)
            }
            
            // Drain audio encoder
            drainAudioEncoder(endOfStream)
            
        } catch (e: Exception) {
            Log.e(TAG, "Error feeding audio to encoder", e)
        }
    }

    private fun drainAudioEncoder(endOfStream: Boolean) {
        val encoder = audioEncoder ?: return
        val bufferInfo = MediaCodec.BufferInfo()

        while (true) {
            val outputBufferIndex = encoder.dequeueOutputBuffer(bufferInfo, TIMEOUT_US)

            when {
                outputBufferIndex == MediaCodec.INFO_TRY_AGAIN_LATER -> break
                
                outputBufferIndex == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                    synchronized(muxerLock) {
                        if (audioTrackIndex < 0) {
                            audioTrackIndex = muxer?.addTrack(encoder.outputFormat) ?: -1
                            tracksAdded++
                            checkStartMuxer()
                            Log.d(TAG, "Audio track added: $audioTrackIndex")
                        }
                    }
                }
                
                outputBufferIndex >= 0 -> {
                    val outputBuffer = encoder.getOutputBuffer(outputBufferIndex)
                    
                    if (bufferInfo.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG != 0) {
                        bufferInfo.size = 0
                    }

                    if (bufferInfo.size > 0) {
                        synchronized(muxerLock) {
                            if (muxerStarted && audioTrackIndex >= 0) {
                                outputBuffer?.position(bufferInfo.offset)
                                outputBuffer?.limit(bufferInfo.offset + bufferInfo.size)
                                muxer?.writeSampleData(audioTrackIndex, outputBuffer!!, bufferInfo)
                            }
                        }
                    }

                    encoder.releaseOutputBuffer(outputBufferIndex, false)

                    if (bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) {
                        break
                    }
                }
            }
        }
    }

    /**
     * Update the front camera frame
     */
    fun updateFrontFrameBitmap(bitmap: Bitmap) {
        if (!isRecording.get() || isStopping.get()) return
        
        try {
            val copy = bitmap.copy(Bitmap.Config.ARGB_8888, false)
            synchronized(frontFrameLock) {
                frontFrameBitmap?.recycle()
                frontFrameBitmap = copy
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error updating front frame", e)
        }
    }

    /**
     * Update the back camera frame
     */
    fun updateBackFrameBitmap(bitmap: Bitmap) {
        if (!isRecording.get() || isStopping.get()) return
        
        try {
            val copy = bitmap.copy(Bitmap.Config.ARGB_8888, false)
            synchronized(backFrameLock) {
                backFrameBitmap?.recycle()
                backFrameBitmap = copy
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error updating back frame", e)
        }
    }

    private fun composeAndSubmitFrame() {
        val surface = inputSurface ?: return
        if (!surface.isValid) return

        try {
            val canvas = surface.lockCanvas(null)
            if (canvas != null) {
                try {
                    // Clear canvas with black
                    canvas.drawColor(Color.BLACK)
                    
                    // Get frame copies
                    val frontBitmap: Bitmap?
                    val backBitmap: Bitmap?
                    
                    synchronized(frontFrameLock) {
                        frontBitmap = frontFrameBitmap?.let { 
                            if (!it.isRecycled) it else null 
                        }
                    }
                    synchronized(backFrameLock) {
                        backBitmap = backFrameBitmap?.let { 
                            if (!it.isRecycled) it else null 
                        }
                    }
                    
                    // Compose based on layout
                    composeFrames(canvas, frontBitmap, backBitmap)
                    
                    frameCount.incrementAndGet()
                } finally {
                    surface.unlockCanvasAndPost(canvas)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error composing frame", e)
        }
    }

    private fun composeFrames(canvas: Canvas, frontBitmap: Bitmap?, backBitmap: Bitmap?) {
        when (layout) {
            PreviewLayout.SIDE_BY_SIDE_HORIZONTAL -> {
                composeSideBySideHorizontal(canvas, backBitmap, frontBitmap)
            }
            PreviewLayout.SIDE_BY_SIDE_VERTICAL -> {
                composeSideBySideVertical(canvas, backBitmap, frontBitmap)
            }
            PreviewLayout.PIP_TOP_LEFT -> {
                composePiP(canvas, backBitmap, frontBitmap, PipGravity.TOP_LEFT)
            }
            PreviewLayout.PIP_TOP_RIGHT -> {
                composePiP(canvas, backBitmap, frontBitmap, PipGravity.TOP_RIGHT)
            }
            PreviewLayout.PIP_BOTTOM_LEFT -> {
                composePiP(canvas, backBitmap, frontBitmap, PipGravity.BOTTOM_LEFT)
            }
            PreviewLayout.PIP_BOTTOM_RIGHT -> {
                composePiP(canvas, backBitmap, frontBitmap, PipGravity.BOTTOM_RIGHT)
            }
            PreviewLayout.SINGLE_BACK -> {
                composeSingle(canvas, backBitmap)
            }
            PreviewLayout.SINGLE_FRONT -> {
                composeSingle(canvas, frontBitmap)
            }
        }
    }

    private fun composeSideBySideHorizontal(canvas: Canvas, backBitmap: Bitmap?, frontBitmap: Bitmap?) {
        val halfWidth = outputWidth / 2
        
        // Draw front camera on left
        frontBitmap?.let {
            if (!it.isRecycled) {
                val srcRect = Rect(0, 0, it.width, it.height)
                val dstRect = Rect(0, 0, halfWidth, outputHeight)
                canvas.drawBitmap(it, srcRect, dstRect, paint)
            }
        }
        
        // Draw back camera on right
        backBitmap?.let {
            if (!it.isRecycled) {
                val srcRect = Rect(0, 0, it.width, it.height)
                val dstRect = Rect(halfWidth, 0, outputWidth, outputHeight)
                canvas.drawBitmap(it, srcRect, dstRect, paint)
            }
        }
        
        // Draw divider line
        canvas.drawRect(halfWidth.toFloat() - 2, 0f, halfWidth.toFloat() + 2, outputHeight.toFloat(), borderPaint)
    }

    private fun composeSideBySideVertical(canvas: Canvas, backBitmap: Bitmap?, frontBitmap: Bitmap?) {
        val halfHeight = outputHeight / 2
        
        // Draw back camera on top
        backBitmap?.let {
            if (!it.isRecycled) {
                val srcRect = Rect(0, 0, it.width, it.height)
                val dstRect = Rect(0, 0, outputWidth, halfHeight)
                canvas.drawBitmap(it, srcRect, dstRect, paint)
            }
        }
        
        // Draw front camera on bottom
        frontBitmap?.let {
            if (!it.isRecycled) {
                val srcRect = Rect(0, 0, it.width, it.height)
                val dstRect = Rect(0, halfHeight, outputWidth, outputHeight)
                canvas.drawBitmap(it, srcRect, dstRect, paint)
            }
        }
        
        // Draw divider line
        canvas.drawRect(0f, halfHeight.toFloat() - 2, outputWidth.toFloat(), halfHeight.toFloat() + 2, borderPaint)
    }

    private fun composePiP(canvas: Canvas, mainBitmap: Bitmap?, pipBitmap: Bitmap?, gravity: PipGravity) {
        // Draw main camera fullscreen
        mainBitmap?.let {
            if (!it.isRecycled) {
                val srcRect = Rect(0, 0, it.width, it.height)
                val dstRect = Rect(0, 0, outputWidth, outputHeight)
                canvas.drawBitmap(it, srcRect, dstRect, paint)
            }
        }
        
        // Draw PiP camera
        pipBitmap?.let {
            if (!it.isRecycled) {
                val pipWidth = outputWidth / 4
                val pipHeight = outputHeight / 4
                val margin = 32
                val borderWidth = 4
                
                val left = when (gravity) {
                    PipGravity.TOP_LEFT, PipGravity.BOTTOM_LEFT -> margin
                    PipGravity.TOP_RIGHT, PipGravity.BOTTOM_RIGHT -> outputWidth - pipWidth - margin
                }
                
                val top = when (gravity) {
                    PipGravity.TOP_LEFT, PipGravity.TOP_RIGHT -> margin
                    PipGravity.BOTTOM_LEFT, PipGravity.BOTTOM_RIGHT -> outputHeight - pipHeight - margin
                }
                
                // Draw border
                canvas.drawRect(
                    (left - borderWidth).toFloat(),
                    (top - borderWidth).toFloat(),
                    (left + pipWidth + borderWidth).toFloat(),
                    (top + pipHeight + borderWidth).toFloat(),
                    whiteBorderPaint
                )
                
                // Draw PiP
                val srcRect = Rect(0, 0, it.width, it.height)
                val dstRect = Rect(left, top, left + pipWidth, top + pipHeight)
                canvas.drawBitmap(it, srcRect, dstRect, paint)
            }
        }
    }

    private fun composeSingle(canvas: Canvas, bitmap: Bitmap?) {
        bitmap?.let {
            if (!it.isRecycled) {
                val srcRect = Rect(0, 0, it.width, it.height)
                val dstRect = Rect(0, 0, outputWidth, outputHeight)
                canvas.drawBitmap(it, srcRect, dstRect, paint)
            }
        }
    }

    private fun drainVideoEncoder(endOfStream: Boolean) {
        val encoder = videoEncoder ?: return
        
        if (endOfStream) {
            encoder.signalEndOfInputStream()
        }

        val bufferInfo = MediaCodec.BufferInfo()

        while (true) {
            val outputBufferIndex = try {
                encoder.dequeueOutputBuffer(bufferInfo, TIMEOUT_US)
            } catch (e: Exception) {
                Log.e(TAG, "Error dequeuing video buffer", e)
                break
            }

            when {
                outputBufferIndex == MediaCodec.INFO_TRY_AGAIN_LATER -> {
                    if (!endOfStream) break
                }
                
                outputBufferIndex == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                    synchronized(muxerLock) {
                        if (videoTrackIndex < 0) {
                            videoTrackIndex = muxer?.addTrack(encoder.outputFormat) ?: -1
                            tracksAdded++
                            checkStartMuxer()
                            Log.d(TAG, "Video track added: $videoTrackIndex")
                        }
                    }
                }
                
                outputBufferIndex >= 0 -> {
                    val outputBuffer = encoder.getOutputBuffer(outputBufferIndex)

                    if (bufferInfo.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG != 0) {
                        bufferInfo.size = 0
                    }

                    if (bufferInfo.size > 0) {
                        synchronized(muxerLock) {
                            if (muxerStarted && videoTrackIndex >= 0) {
                                outputBuffer?.position(bufferInfo.offset)
                                outputBuffer?.limit(bufferInfo.offset + bufferInfo.size)
                                
                                // Use frame-based timing for more consistent output
                                bufferInfo.presentationTimeUs = (System.nanoTime() - startTimeNs) / 1000
                                
                                muxer?.writeSampleData(videoTrackIndex, outputBuffer!!, bufferInfo)
                            }
                        }
                    }

                    encoder.releaseOutputBuffer(outputBufferIndex, false)

                    if (bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) {
                        Log.d(TAG, "Video encoder end of stream")
                        break
                    }
                }
            }
        }

        // Continue draining if still recording
        if (isRecording.get() && !isStopping.get() && !endOfStream) {
            videoEncoderHandler?.postDelayed({ drainVideoEncoder(false) }, 10)
        }
    }

    private fun checkStartMuxer() {
        if (!muxerStarted && tracksAdded >= expectedTracks) {
            muxer?.start()
            muxerStarted = true
            Log.d(TAG, "Muxer started with $tracksAdded tracks")
        }
    }

    fun stop(): String? {
        if (!isRecording.getAndSet(false)) {
            Log.w(TAG, "Not recording")
            return null
        }

        isStopping.set(true)
        Log.d(TAG, "Stopping VideoComposer, frames: ${frameCount.get()}")

        try {
            // Wait for audio thread to finish
            audioThread?.join(2000)
            audioRecord?.stop()

            // Stop composition
            compositionHandler?.removeCallbacksAndMessages(null)
            
            // Give time for final frames
            Thread.sleep(100)

            // Signal end of video stream and drain
            videoEncoderHandler?.post {
                drainVideoEncoder(true)
            }
            
            // Wait for encoder to finish
            Thread.sleep(500)

            // Stop threads
            compositionThread?.quitSafely()
            videoEncoderThread?.quitSafely()
            
            compositionThread?.join(1000)
            videoEncoderThread?.join(1000)

            // Release resources
            releaseEncoders()

            val file = File(outputPath)
            if (file.exists() && file.length() > 0) {
                Log.d(TAG, "VideoComposer stopped successfully: $outputPath (${file.length()} bytes)")
                return outputPath
            } else {
                Log.e(TAG, "Output file is empty or doesn't exist")
                return null
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping VideoComposer", e)
            releaseEncoders()
            return null
        }
    }

    private fun releaseEncoders() {
        try {
            videoEncoder?.stop()
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping video encoder", e)
        }
        try {
            videoEncoder?.release()
        } catch (e: Exception) {
            Log.e(TAG, "Error releasing video encoder", e)
        }
        videoEncoder = null
        
        try {
            audioEncoder?.stop()
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping audio encoder", e)
        }
        try {
            audioEncoder?.release()
        } catch (e: Exception) {
            Log.e(TAG, "Error releasing audio encoder", e)
        }
        audioEncoder = null
        
        try {
            audioRecord?.release()
        } catch (e: Exception) {
            Log.e(TAG, "Error releasing audio record", e)
        }
        audioRecord = null
        
        try {
            inputSurface?.release()
        } catch (e: Exception) {
            Log.e(TAG, "Error releasing input surface", e)
        }
        inputSurface = null

        synchronized(muxerLock) {
            try {
                if (muxerStarted) {
                    muxer?.stop()
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error stopping muxer", e)
            }
            try {
                muxer?.release()
            } catch (e: Exception) {
                Log.e(TAG, "Error releasing muxer", e)
            }
            muxer = null
            muxerStarted = false
        }

        // Release bitmaps
        synchronized(frontFrameLock) {
            frontFrameBitmap?.recycle()
            frontFrameBitmap = null
        }
        synchronized(backFrameLock) {
            backFrameBitmap?.recycle()
            backFrameBitmap = null
        }

        Log.d(TAG, "Encoders released")
    }

    fun isRecording(): Boolean = isRecording.get()
}

enum class PipGravity {
    TOP_LEFT, TOP_RIGHT, BOTTOM_LEFT, BOTTOM_RIGHT
}
