package com.terminus.service.ui

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.widget.Button
import android.widget.TextView
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import com.terminus.service.R
import com.terminus.service.core.AudioRecorderService

class MainActivity : AppCompatActivity() {

    // --- UI Elements ---
    private lateinit var statusTextView: TextView
    private lateinit var toggleServiceButton: Button
    private lateinit var storageButton: Button
    private lateinit var syncButton: Button

    // --- State Management for the main button ---
    private enum class ServiceState {
        STOPPED, STARTING, RUNNING, STOPPING
    }
    private var currentState = ServiceState.STOPPED

    // --- Permissions ---
    private val requiredPermissions = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
        arrayOf(Manifest.permission.RECORD_AUDIO, Manifest.permission.POST_NOTIFICATIONS)
    } else {
        arrayOf(Manifest.permission.RECORD_AUDIO)
    }

    private val requestMultiplePermissionsLauncher =
        registerForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) { permissions ->
            val allGranted = permissions.entries.all { it.value }
            if (allGranted) {
                startRecordingService()
            } else {
                Toast.makeText(this, "All permissions are required to run the service.", Toast.LENGTH_LONG).show()
                updateUiForState(ServiceState.STOPPED) // Revert to stopped state if permissions denied
            }
        }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        // Find all UI views
        statusTextView = findViewById(R.id.statusTextView)
        toggleServiceButton = findViewById(R.id.toggleServiceButton)
        storageButton = findViewById(R.id.storageButton)
        syncButton = findViewById(R.id.syncButton)

        // --- Set up Click Listeners ---
        toggleServiceButton.setOnClickListener {
            handleToggleClick()
        }

        storageButton.setOnClickListener {
            Toast.makeText(this, "Storage screen not yet implemented.", Toast.LENGTH_SHORT).show()
        }

        syncButton.setOnClickListener {
            Toast.makeText(this, "Manual sync not yet implemented.", Toast.LENGTH_SHORT).show()
        }

        // Set the initial UI state
        updateUiForState(ServiceState.STOPPED)
    }

    private fun handleToggleClick() {
        when (currentState) {
            ServiceState.STOPPED -> {
                updateUiForState(ServiceState.STARTING)
                checkAndRequestPermissions()
            }
            ServiceState.RUNNING -> {
                // MODIFICATION: Show a confirmation dialog instead of stopping immediately.
                showStopConfirmationDialog()
            }
            // Ignore clicks during transition states
            ServiceState.STARTING, ServiceState.STOPPING -> { }
        }
    }

    // --- NEW FUNCTION: Displays a confirmation dialog before stopping ---
    private fun showStopConfirmationDialog() {
        AlertDialog.Builder(this)
            .setTitle("Confirm Stop")
            .setMessage("Are you sure you want to stop the recording service?")
            .setPositiveButton("Stop") { dialog, _ ->
                updateUiForState(ServiceState.STOPPING)
                stopRecordingService()
                dialog.dismiss()
            }
            .setNegativeButton("Cancel") { dialog, _ ->
                // Do nothing, the service continues to run.
                dialog.dismiss()
            }
            .show()
    }
    // --- END NEW FUNCTION ---

    private fun updateUiForState(newState: ServiceState) {
        currentState = newState
        when (newState) {
            ServiceState.STOPPED -> {
                statusTextView.text = "Status: Service Stopped"
                toggleServiceButton.text = "Service Not Started (Click to Start)"
                toggleServiceButton.setBackgroundColor(ContextCompat.getColor(this, R.color.red_500))
                toggleServiceButton.isEnabled = true
            }
            ServiceState.STARTING -> {
                statusTextView.text = "Status: Starting..."
                toggleServiceButton.text = "Starting..."
                toggleServiceButton.setBackgroundColor(ContextCompat.getColor(this, R.color.yellow_500))
                toggleServiceButton.isEnabled = false
            }
            ServiceState.RUNNING -> {
                statusTextView.text = "Status: Service is Active"
                toggleServiceButton.text = "Service Running (Click to Stop)"
                toggleServiceButton.setBackgroundColor(ContextCompat.getColor(this, R.color.green_500))
                toggleServiceButton.isEnabled = true
            }
            ServiceState.STOPPING -> {
                statusTextView.text = "Status: Stopping..."
                toggleServiceButton.text = "Stopping..."
                toggleServiceButton.setBackgroundColor(ContextCompat.getColor(this, R.color.yellow_500))
                toggleServiceButton.isEnabled = false
            }
        }
    }

    private fun checkAndRequestPermissions() {
        val missingPermissions = requiredPermissions.filter {
            ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
        }

        if (missingPermissions.isNotEmpty()) {
            requestMultiplePermissionsLauncher.launch(missingPermissions.toTypedArray())
        } else {
            startRecordingService()
        }
    }

    private fun startRecordingService() {
        val serviceIntent = Intent(this, AudioRecorderService::class.java)
        ContextCompat.startForegroundService(this, serviceIntent)
        updateUiForState(ServiceState.RUNNING)
    }

    private fun stopRecordingService() {
        val serviceIntent = Intent(this, AudioRecorderService::class.java)
        stopService(serviceIntent)
        updateUiForState(ServiceState.STOPPED)
    }
}

