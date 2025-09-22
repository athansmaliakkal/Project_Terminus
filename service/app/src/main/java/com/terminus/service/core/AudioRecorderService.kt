package com.terminus.service.core

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.BatteryManager
import android.os.Build
import android.os.IBinder
import android.provider.Settings
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import androidx.core.content.edit
import com.google.gson.Gson
import com.terminus.service.R
import com.terminus.service.data.RecordingMetadata
import com.terminus.service.security.CryptoUtils
import java.io.File
import java.io.RandomAccessFile
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.UUID
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.concurrent.thread

class AudioRecorderService : Service() {

    private val isRecording = AtomicBoolean(false)
    private var recordingThread: Thread? = null

    // --- Static Device Info ---
    private data class DeviceInfo(
        val deviceId: String,
        val deviceName: String?,
        val osVersion: String
    )
    private lateinit var deviceInfo: DeviceInfo


    // --- Audio Configuration (Forensic Grade) ---
    private val sampleRate = 44100
    private val channelConfig = AudioFormat.CHANNEL_IN_MONO
    private val audioFormat = AudioFormat.ENCODING_PCM_16BIT
    private val bufferSize = AudioRecord.getMinBufferSize(sampleRate, channelConfig, audioFormat)

    // --- File Configuration ---
    private val recordingDurationSeconds = 30
    private val gson = Gson()

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Service onCreate")
        // Fetch static device info only once when the service is created.
        deviceInfo = DeviceInfo(
            deviceId = getOrCreatePersistentDeviceId(),
            deviceName = Settings.Global.getString(contentResolver, Settings.Global.DEVICE_NAME),
            osVersion = "Android ${Build.VERSION.RELEASE} (API ${Build.VERSION.SDK_INT})"
        )
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "Service onStartCommand")
        createNotificationChannel()
        val notification = createNotification()
        startForeground(NOTIFICATION_ID, notification)
        startRecording()
        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "Service onDestroy")
        stopRecording()
    }

    private fun startRecording() {
        if (isRecording.getAndSet(true)) return
        Log.d(TAG, "Starting recording thread...")

        recordingThread = thread {
            android.os.Process.setThreadPriority(android.os.Process.THREAD_PRIORITY_URGENT_AUDIO)
            while (isRecording.get()) {
                recordAndSaveWavChunk()
            }
        }
    }

    private fun stopRecording() {
        if (!isRecording.getAndSet(false)) return
        try {
            recordingThread?.join(1000)
        } catch (e: InterruptedException) {
            Log.e(TAG, "Interrupted while waiting for recording thread.", e)
        }
        recordingThread = null
        Log.d(TAG, "Recording thread stopped.")
    }

    private fun recordAndSaveWavChunk() {
        if (!isRecording.get()) return

        if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            Log.e(TAG, "Permission lost mid-recording. Stopping.")
            stopSelf()
            return
        }

        Log.d(TAG, "--- New WAV Chunk Starting ---")
        val wavFile = createTempOutputFile()
        var audioRecord: AudioRecord? = null
        val recordingStartTime = System.currentTimeMillis()

        try {
            audioRecord = AudioRecord(
                MediaRecorder.AudioSource.MIC, sampleRate, channelConfig, audioFormat, bufferSize * 2
            )
            val randomAccessFile = RandomAccessFile(wavFile, "rw")
            randomAccessFile.setLength(0) // Clear the file
            randomAccessFile.write(ByteArray(44)) // Write placeholder for header

            audioRecord.startRecording()

            val buffer = ByteArray(bufferSize)
            val totalBytesToRecord = sampleRate * recordingDurationSeconds * 2 // 16-bit = 2 bytes
            var totalBytesRead = 0

            while (isRecording.get() && totalBytesRead < totalBytesToRecord) {
                val bytesRead = audioRecord.read(buffer, 0, buffer.size)
                if (bytesRead > 0) {
                    randomAccessFile.write(buffer, 0, bytesRead)
                    totalBytesRead += bytesRead
                }
            }

            val recordingEndTime = System.currentTimeMillis()

            // Go back and write the final header
            randomAccessFile.seek(0)
            writeWavHeader(randomAccessFile, totalBytesRead)
            randomAccessFile.close()

            Log.d(TAG, "Successfully recorded ${totalBytesRead / 1024} KB")

            if (isRecording.get() && wavFile.exists() && wavFile.length() > 44) {
                finalizeForensicPair(wavFile, recordingStartTime, recordingEndTime)
            }

        } catch (e: Exception) {
            Log.e(TAG, "Error during WAV recording.", e)
        } finally {
            audioRecord?.stop()
            audioRecord?.release()
            if (wavFile.exists()) {
                wavFile.delete()
            }
        }
    }

    private fun writeWavHeader(stream: RandomAccessFile, pcmDataSize: Int) {
        val header = ByteBuffer.allocate(44).order(ByteOrder.LITTLE_ENDIAN)
        val totalDataLen = pcmDataSize + 36
        val channels = 1
        val byteRate = sampleRate * channels * 2 // 16-bit
        val bitsPerSample: Short = 16

        header.put("RIFF".toByteArray(Charsets.US_ASCII))
        header.putInt(totalDataLen)
        header.put("WAVE".toByteArray(Charsets.US_ASCII))
        header.put("fmt ".toByteArray(Charsets.US_ASCII))
        header.putInt(16) // Sub-chunk size
        header.putShort(1) // Audio format (1 for PCM)
        header.putShort(channels.toShort())
        header.putInt(sampleRate)
        header.putInt(byteRate)
        header.putShort((channels * bitsPerSample / 8).toShort()) // Block align
        header.putShort(bitsPerSample) // Bits per sample
        header.put("data".toByteArray(Charsets.US_ASCII))
        header.putInt(pcmDataSize)
        stream.write(header.array())
    }

    private fun createTempOutputFile(): File {
        return File.createTempFile("recording_output", ".wav", cacheDir)
    }

    private fun finalizeForensicPair(audioFile: File, recordingStartTime: Long, recordingEndTime: Long) {
        val baseDir = File(filesDir, "vault/service/terminus/audio")
        val audioDir = File(baseDir, "data")
        val metaDir = File(baseDir, "metadata")
        audioDir.mkdirs()
        metaDir.mkdirs()

        val saveTimestamp = System.currentTimeMillis()

        // Filename formatters
        val sdfFilename = SimpleDateFormat("yyyy.MM.dd_HH.mm.ss", Locale.US)

        // Metadata formatters
        val sdfMetaDate = SimpleDateFormat("yyyy/MMM/dd", Locale.US)
        val sdfMetaTime = SimpleDateFormat("HH:mm:ss.SSS", Locale.US)

        val filenameTimestamp = sdfFilename.format(Date(recordingStartTime))

        val finalAudioFilename = "${filenameTimestamp}_${deviceInfo.deviceId}.wav"
        val finalMetaFilename = "${filenameTimestamp}_${deviceInfo.deviceId}.meta.json"

        val finalAudioFile = File(audioDir, finalAudioFilename)
        audioFile.copyTo(finalAudioFile, true)
        Log.d(TAG, "Final WAV file created: ${finalAudioFile.name}")

        val checksum = CryptoUtils.calculateSHA256(finalAudioFile)
        val batteryManager = getSystemService(BATTERY_SERVICE) as BatteryManager
        val batteryPct = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)

        Log.d(TAG, "Checksum: $checksum")

        // Construct the metadata object with the new fields and order
        val metadata = RecordingMetadata(
            dateUtc = sdfMetaDate.format(Date(recordingStartTime)),
            recordingStartTimeUtc = sdfMetaTime.format(Date(recordingStartTime)),
            recordingEndTimeUtc = sdfMetaTime.format(Date(recordingEndTime)),
            fileSizeBytes = finalAudioFile.length(),
            saveTimestampUtc = saveTimestamp.toString(),
            batteryPercentage = batteryPct,
            osVersion = deviceInfo.osVersion,
            deviceId = deviceInfo.deviceId,
            deviceName = deviceInfo.deviceName,
            audioFileSha256 = checksum
        )

        val metaFile = File(metaDir, finalMetaFilename)
        metaFile.writer().use { it.write(gson.toJson(metadata)) }
        Log.d(TAG, "Metadata file written: ${metaFile.name}")
    }

    private fun createNotification() = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
        .setContentTitle("Terminus Service")
        .setContentText("System is active. Recording audio.")
        .setSmallIcon(R.drawable.ic_notification_mic)
        .setPriority(NotificationCompat.PRIORITY_LOW)
        .build()

    private fun createNotificationChannel() {
        val channel = NotificationChannel(
            NOTIFICATION_CHANNEL_ID,
            "Terminus Service Channel",
            NotificationManager.IMPORTANCE_LOW
        )
        val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        manager.createNotificationChannel(channel)
    }

    private fun getOrCreatePersistentDeviceId(): String {
        val sharedPrefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
        var id = sharedPrefs.getString(PREF_DEVICE_ID, null)
        if (id == null) {
            id = UUID.randomUUID().toString()
            sharedPrefs.edit {
                putString(PREF_DEVICE_ID, id)
            }
        }
        return id
    }

    override fun onBind(intent: Intent?): IBinder? = null

    companion object {
        private const val TAG = "AudioRecorderService"
        private const val NOTIFICATION_ID = 1
        private const val NOTIFICATION_CHANNEL_ID = "TerminusServiceChannel"
        private const val PREFS_NAME = "TerminusPrefs"
        private const val PREF_DEVICE_ID = "device_id"
    }
}

