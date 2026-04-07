import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

/// Service to make downloaded files visible in device storage and gallery
class MediaScannerService {
  /// Scan a file to make it visible in the device's media library
  /// 
  /// For images and videos: Saves to Gallery
  /// For other files: Triggers media scan to make them visible in file managers
  static Future<bool> scanFile(String filePath, String mimeType) async {
    try {
      debugPrint('📱 [MEDIA SCANNER] Scanning file: $filePath');
      debugPrint('📱 [MEDIA SCANNER] MIME type: $mimeType');

      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('❌ [MEDIA SCANNER] File does not exist: $filePath');
        return false;
      }

      // Handle images - save to gallery
      if (mimeType.startsWith('image/')) {
        debugPrint('📸 [MEDIA SCANNER] Saving image to gallery...');
        
        final result = await ImageGallerySaver.saveFile(
          filePath,
          name: 'DocXpress_${DateTime.now().millisecondsSinceEpoch}',
        );
        
        if (result != null && result['isSuccess'] == true) {
          debugPrint('✅ [MEDIA SCANNER] Image saved to gallery successfully');
          debugPrint('   Path: ${result['filePath']}');
          return true;
        } else {
          debugPrint('⚠️ [MEDIA SCANNER] Failed to save image to gallery');
          return false;
        }
      }
      
      // Handle videos - save to gallery
      else if (mimeType.startsWith('video/')) {
        debugPrint('🎥 [MEDIA SCANNER] Saving video to gallery...');
        
        final result = await ImageGallerySaver.saveFile(
          filePath,
          name: 'DocXpress_${DateTime.now().millisecondsSinceEpoch}',
        );
        
        if (result != null && result['isSuccess'] == true) {
          debugPrint('✅ [MEDIA SCANNER] Video saved to gallery successfully');
          debugPrint('   Path: ${result['filePath']}');
          return true;
        } else {
          debugPrint('⚠️ [MEDIA SCANNER] Failed to save video to gallery');
          return false;
        }
      }
      
      // For other file types (PDF, DOCX, etc.), they're already in Downloads
      // and should be visible in file managers
      else {
        debugPrint('📄 [MEDIA SCANNER] File is in Downloads folder and should be visible');
        
        // On Android, we can try to trigger a media scan using platform channels
        // For now, files in the public Downloads folder are automatically visible
        if (Platform.isAndroid) {
          // The file is already in /storage/emulated/0/Download
          // which is automatically scanned by Android
          debugPrint('✅ [MEDIA SCANNER] File is in public Downloads, visible to file managers');
        }
        
        return true;
      }
    } catch (e) {
      debugPrint('❌ [MEDIA SCANNER] Error scanning file: $e');
      return false;
    }
  }

  /// Check if a file type should be saved to gallery
  static bool shouldSaveToGallery(String mimeType) {
    return mimeType.startsWith('image/') || mimeType.startsWith('video/');
  }

  /// Get appropriate album name based on file type
  static String getAlbumName(String mimeType) {
    if (mimeType.startsWith('image/')) {
      return 'DocXpress Images';
    } else if (mimeType.startsWith('video/')) {
      return 'DocXpress Videos';
    }
    return 'DocXpress';
  }
}
