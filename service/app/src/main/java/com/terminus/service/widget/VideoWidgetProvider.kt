package com.terminus.service.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import com.terminus.service.R
import com.terminus.service.core.VideoRecorderService

class VideoWidgetProvider : AppWidgetProvider() {

    // A flag to keep track of the service state.
    // In a real app, you'd use a more robust method like a BroadcastReceiver
    // to get the true state from the service.
    companion object {
        var isServiceRunning = false
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        // There may be multiple widgets active, so update all of them
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        super.onReceive(context, intent)
        // This is where we would handle broadcasts from the service to update the widget UI
        // For now, we'll handle the toggle here for simplicity.
    }
}

internal fun updateAppWidget(
    context: Context,
    appWidgetManager: AppWidgetManager,
    appWidgetId: Int
) {
    // Construct the RemoteViews object
    val views = RemoteViews(context.packageName, R.layout.video_widget_layout)

    // Create an Intent to toggle the VideoRecorderService
    val intent = Intent(context, VideoRecorderService::class.java)
    val pendingIntent = PendingIntent.getService(
        context,
        0, // Using 0 as the request code
        intent,
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
    )

    // Set the click handler for the button
    views.setOnClickPendingIntent(R.id.widget_button, pendingIntent)

    // TODO: We will later add logic here to change the button color and icon
    // based on whether the service is running.

    // Instruct the widget manager to update the widget
    appWidgetManager.updateAppWidget(appWidgetId, views)
}

