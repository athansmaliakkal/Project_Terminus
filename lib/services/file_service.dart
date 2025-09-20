import 'dart:io'; // Corrected import
import 'package:flutter/foundation.dart'; // Added for debugPrint
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class FileService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _deviceIdKey = 'terminus_device_id';
  String? _cachedDeviceId;

  Future<String> _getPersistentDeviceId() async {
    if (_cachedDeviceId != null) return _cachedDeviceId!;

    String? deviceId = await _secureStorage.read(key: _deviceIdKey);
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await _secureStorage.write(key: _deviceIdKey, value: deviceId);
      debugPrint('Generated new persistent device ID: $deviceId');
    }
    _cachedDeviceId = deviceId;
    return deviceId;
  }

  Future<Map<String, String>> generateAudioFilePaths() async {
    final now = DateTime.now();
    final directory = await getApplicationDocumentsDirectory();
    final deviceId = await _getPersistentDeviceId();

    final year = DateFormat('yyyy').format(now);
    final monthNum = DateFormat('MM').format(now);
    final monthName = DateFormat('MMM').format(now);
    final day = DateFormat('dd').format(now);

    final audioPath = '${directory.path}/terminus/audio/$year/${monthNum}_$monthName/$day';
    final verificationPath = '${directory.path}/terminus/verification/audio/$year/${monthNum}_$monthName/$day';

    await Directory(audioPath).create(recursive: true);
    await Directory(verificationPath).create(recursive: true);

    final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(now);
    final uniqueId = now.microsecondsSinceEpoch;
    final baseName = '${timestamp}_${uniqueId}_$deviceId';

    return {
      'audioPath': '$audioPath/$baseName.flac',
      'metadataPath': '$verificationPath/$baseName.meta.json',
    };
  }
}

