package com.terminus.service.data

import com.google.gson.annotations.SerializedName

/**
 * Data class representing the structure of the .meta.json file.
 * The order of properties here defines the order in the final JSON file.
 */
data class RecordingMetadata(
    @SerializedName("date_utc")
    val dateUtc: String,

    @SerializedName("recording_start_time_utc")
    val recordingStartTimeUtc: String,

    @SerializedName("recording_end_time_utc")
    val recordingEndTimeUtc: String,

    @SerializedName("file_size_bytes")
    val fileSizeBytes: Long,

    @SerializedName("save_timestamp_utc")
    val saveTimestampUtc: String,

    @SerializedName("battery_percentage")
    val batteryPercentage: Int,

    @SerializedName("os_version")
    val osVersion: String,

    @SerializedName("device_id")
    val deviceId: String,
    
    @SerializedName("device_name")
    val deviceName: String?,

    @SerializedName("audio_file_sha256")
    val audioFileSha256: String
)

