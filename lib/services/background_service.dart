import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:record/record.dart';
import 'package:terminus/services/file_service.dart';

const String notificationChannelId = 'terminus_foreground_channel';
const int notificationId = 888;

class BackgroundService {
  static final FlutterBackgroundService _service = FlutterBackgroundService();

  static Future<void> initializeService() async {
    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: notificationChannelId,
        initialNotificationTitle: 'Project Terminus',
        initialNotificationContent: 'Initializing...',
        foregroundServiceNotificationId: notificationId,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
      ),
    );
  }
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  
  final fileService = FileService();
  final audioRecorder = AudioRecorder();
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  
  Map<String, String>? currentFilePaths;

  service.on('stopService').listen((event) async {
    if (await audioRecorder.isRecording()) {
      await audioRecorder.stop();
    }
    service.stopSelf();
  });

  const audioChunkDuration = Duration(minutes: 1);

  Future<void> startNewRecordingChunk() async {
    try {
      currentFilePaths = await fileService.generateAudioFilePaths();
      final audioPath = currentFilePaths!['audioPath'];
      
      // --- THIS IS THE UPGRADE: Maximum detail configuration ---
      const config = RecordConfig(
        encoder: AudioEncoder.flac,
        sampleRate: 44100, // CD Quality sample rate
        numChannels: 1,
      );
      // ----------------------------------------------------

      if (audioPath != null) {
        await audioRecorder.start(config, path: audioPath);
        debugPrint('BACKGROUND SERVICE: Started new audio chunk at $audioPath');
      }
    } catch (e) {
      debugPrint('BACKGROUND SERVICE: Error starting audio chunk: $e');
    }
  }
  
  Timer.periodic(audioChunkDuration, (timer) async {
    if (await audioRecorder.isRecording()) {
      final path = await audioRecorder.stop();
      if (path != null) {
        debugPrint('BACKGROUND SERVICE: Saved audio chunk to $path');

        final metadataPath = currentFilePaths?['metadataPath'];
        if (metadataPath != null) {
          final file = File(path);
          final fileBytes = await file.readAsBytes();
          final checksum = sha256.convert(fileBytes).toString();

          final metadata = {
            'deviceId': 'TERMINUS_DEVICE_01',
            'timestamp': DateTime.now().toIso8601String(),
            'format': 'FLAC',
            'sampleRate': 44100, // Updated to reflect new config
            'channels': 1,
            'checksum_sha256': checksum,
          };
          
          final metaFile = File(metadataPath);
          await metaFile.writeAsString(jsonEncode(metadata));
          debugPrint('BACKGROUND SERVICE: Saved metadata with checksum: $checksum');
        }
      }
    }
    await startNewRecordingChunk();
  });
  
  await startNewRecordingChunk();
  
  Timer.periodic(const Duration(minutes: 1), (timer) {
    flutterLocalNotificationsPlugin.show(
      notificationId,
      'Project Terminus: Service Active',
      '24/7 high-integrity audio recording is active.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          notificationChannelId,
          'Terminus Service',
          icon: 'ic_bg_service_small',
          ongoing: true,
          playSound: false,
          enableVibration: false,
        ),
      ),
    );
  });

  debugPrint('BACKGROUND SERVICE: High-integrity audio module initialized.');
}

