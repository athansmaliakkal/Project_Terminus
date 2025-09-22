package com.terminus.service.core

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import com.terminus.service.R

class VideoRecorderService : Service() {

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Video Service onCreate")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "Video Service onStartCommand")
        createNotificationChannel()
        val notification = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setContentTitle("Terminus Video Service")
            .setContentText("Video recording is active.")
            .setSmallIcon(R.drawable.ic_notification_mic) // Placeholder icon
            .build()

        startForeground(NOTIFICATION_ID, notification)

        startVideoRecording()

        // If the service is killed, it will be automatically restarted.
        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "Video Service onDestroy")
        stopVideoRecording()
    }

    private fun startVideoRecording() {
        Log.d(TAG, "TODO: Start video capture logic here.")
        // We will implement the camera and MediaCodec logic in the next steps.
    }

    private fun stopVideoRecording() {
        Log.d(TAG, "TODO: Stop video capture logic here.")
        // We will implement the cleanup logic here.
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "Terminus Video Service Channel",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(serviceChannel)
        }
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    companion object {
        private const val TAG = "VideoRecorderService"
        private const val NOTIFICATION_ID = 2 // IMPORTANT: Use a different ID from the audio service
        private const val NOTIFICATION_CHANNEL_ID = "TerminusVideoChannel"
    }
}
