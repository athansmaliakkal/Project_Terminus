import 'package:permission_handler/permission_handler.dart';

// This is our dedicated specialist for all permission-related tasks.
class PermissionService {

  // Requests the core permissions our background service will need.
  Future<bool> requestCorePermissions() async {
    // Request multiple permissions at once.
    Map<Permission, PermissionStatus> statuses = await [
      Permission.notification,
      Permission.microphone,
      // The location permission has been removed.
    ].request();

    // Check if both essential permissions were granted.
    if (statuses[Permission.notification]!.isGranted &&
        statuses[Permission.microphone]!.isGranted) {
      return true;
    }
    
    // You could add logic here to show a dialog explaining why the
    // permissions are essential for the app to function.
    return false;
  }
}

