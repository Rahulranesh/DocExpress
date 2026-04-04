import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Utility to get and display file storage paths
class StoragePaths {
  /// Get the Downloads directory path
  static Future<String?> getDownloadsPath() async {
    try {
      if (Platform.isAndroid) {
        // First, try to use getDownloadsDirectory() which is the recommended API
        final downloadsDir = await getDownloadsDirectory();
        if (downloadsDir != null && await downloadsDir.exists()) {
          print('✅ Using system Downloads: ${downloadsDir.path}');
          return downloadsDir.path;
        }

        // Fallback: Create Downloads in app's external storage
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) {
          final downloadPath = '${extDir.path}/Downloads';
          final dir = Directory(downloadPath);
          
          if (!await dir.exists()) {
            await dir.create(recursive: true);
            print('📁 Created Downloads folder: $downloadPath');
          }
          
          return downloadPath;
        }
      } else if (Platform.isIOS) {
        // iOS uses app documents directory
        final docDir = await getApplicationDocumentsDirectory();
        print('📱 iOS Documents: ${docDir.path}');
        return docDir.path;
      } else {
        // Desktop/other platforms
        final downloadsDir = await getDownloadsDirectory();
        if (downloadsDir != null) {
          print('💻 Downloads: ${downloadsDir.path}');
          return downloadsDir.path;
        }
      }
    } catch (e) {
      print('❌ Failed to get downloads path: $e');
    }
    
    // Last resort
    try {
      final docDir = await getApplicationDocumentsDirectory();
      print('⚠️ Fallback to app documents: ${docDir.path}');
      return docDir.path;
    } catch (e) {
      print('❌ Failed to get any path: $e');
      return null;
    }
  }

  /// Get human-readable storage path for display
  static Future<String> getDisplayPath() async {
    try {
      if (Platform.isAndroid) {
        final downloadsDir = await getDownloadsDirectory();
        if (downloadsDir != null && await downloadsDir.exists()) {
          return 'System Downloads';
        }
        return 'App Downloads Folder';
      } else if (Platform.isIOS) {
        return 'Files App → DocXpress';
      }
      return 'Downloads Folder';
    } catch (e) {
      return 'Phone Storage';
    }
  }

  /// Get full detailed path info
  static Future<Map<String, String>> getPathInfo() async {
    try {
      final downloadsPath = await getDownloadsPath();
      final displayPath = await getDisplayPath();

      return {
        'fullPath': downloadsPath ?? 'Unable to determine path',
        'friendlyName': displayPath,
        'platform': Platform.isAndroid ? 'Android' : Platform.isIOS ? 'iOS' : 'Other',
      };
    } catch (e) {
      return {
        'fullPath': 'Error: $e',
        'friendlyName': 'Error',
        'platform': 'Unknown',
      };
    }
  }

  /// Verify if the downloads path is accessible
  static Future<bool> isDownloadsAccessible() async {
    try {
      final path = await getDownloadsPath();
      if (path == null) return false;
      
      final dir = Directory(path);
      final isAccessible = await dir.exists();
      
      if (isAccessible) {
        print('✅ Downloads accessible: $path');
      } else {
        print('❌ Downloads not accessible: $path');
      }
      
      return isAccessible;
    } catch (e) {
      print('❌ Error checking downloads access: $e');
      return false;
    }
  }
}
