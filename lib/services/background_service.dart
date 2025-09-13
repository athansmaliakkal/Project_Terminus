import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:location/location.dart';
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
  final location = Location();
  StreamSubscription<LocationData>? locationSubscription;
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  if (service is AndroidServiceInstance) {
    await service.setAsForegroundService();
  }

  service.on('stopService').listen((event) {
    locationSubscription?.cancel();
    service.stopSelf();
  });

  Timer.periodic(const Duration(minutes: 1), (timer) async {
    final lastLocation = await location.getLocation();
    final lat = lastLocation.latitude?.toStringAsFixed(4);
    final lon = lastLocation.longitude?.toStringAsFixed(4);

    flutterLocalNotificationsPlugin.show(
      notificationId,
      'Project Terminus: Service Active',
      'Last location: $lat, $lon',
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

  await location.changeSettings(
    accuracy: LocationAccuracy.high,
    interval: 60000,
    distanceFilter: 50,
  );

  locationSubscription = location.onLocationChanged.listen((locationData) async {
    final now = DateTime.now();
    final logEntry = {
      'latitude': locationData.latitude,
      'longitude': locationData.longitude,
      'timestamp': now.toIso8601String(),
    };

    try {
      final file = await fileService.getLogFileForDate(now);
      String content = await file.readAsString();
      
      List<dynamic> logs = jsonDecode(content);
      logs.add(logEntry);
      await file.writeAsString(jsonEncode(logs));

      debugPrint('BACKGROUND SERVICE: Logged location at ${logEntry['timestamp']}');
    } catch (e) {
      debugPrint('BACKGROUND SERVICE: Error writing to log file: $e');
    }
  });

  debugPrint('BACKGROUND SERVICE: GPS tracking initialized.');
}