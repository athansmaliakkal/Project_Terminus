import 'package:permission_handler/permission_handler.dart';

class PermissionService {

  Future<bool> requestCorePermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.notification,
      Permission.locationWhenInUse,
      Permission.locationAlways,    
    ].request();

    if (statuses[Permission.notification]!.isGranted &&
        (statuses[Permission.locationWhenInUse]!.isGranted || statuses[Permission.locationAlways]!.isGranted)) {
      return true;
    }
    return false;
  }
}

