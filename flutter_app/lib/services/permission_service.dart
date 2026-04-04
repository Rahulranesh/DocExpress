import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Request storage permissions based on Android version
  /// Returns true if permission is granted, false otherwise
  static Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid) {
      return true;
    }

    try {
      // Check if permission is already granted
      final status = await Permission.manageExternalStorage.status;
      
      if (status.isGranted) {
        return true;
      }

      // Request permission
      final result = await Permission.manageExternalStorage.request();
      
      return result.isGranted;
    } catch (e) {
      print('❌ Storage permission error: $e');
      return false;
    }
  }

  /// Request camera permission
  static Future<bool> requestCameraPermission() async {
    try {
      final status = await Permission.camera.status;
      
      if (status.isGranted) {
        return true;
      }

      final result = await Permission.camera.request();
      return result.isGranted;
    } catch (e) {
      print('❌ Camera permission error: $e');
      return false;
    }
  }

  /// Request multiple permissions at once
  static Future<Map<Permission, PermissionStatus>> requestMultiplePermissions(
    List<Permission> permissions,
  ) async {
    try {
      final results = await permissions.request();
      return results;
    } catch (e) {
      print('❌ Multiple permissions error: $e');
      return {};
    }
  }

  /// Check if storage permission is granted
  static Future<bool> hasStoragePermission() async {
    if (!Platform.isAndroid) {
      return true;
    }

    try {
      final status = await Permission.manageExternalStorage.status;
      return status.isGranted;
    } catch (e) {
      print('❌ Storage permission check error: $e');
      return false;
    }
  }

  /// Open app settings to allow user to grant permission manually
  static Future<void> openAppSettings() async {
    await openAppSettings();
  }
}
