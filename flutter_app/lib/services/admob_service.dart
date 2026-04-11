import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdMobService {
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal();

  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  // Ad Unit IDs - Set to false for production
  static const bool _useTesting = false; // Changed to false for real ads
  
  static String get bannerAdUnitId {
    if (_useTesting) {
      // Test ad IDs that always work
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111' // Android test banner
          : 'ca-app-pub-3940256099942544/2934735716'; // iOS test banner
    }
    
    // Real Ad Unit IDs from AdMob console
    if (Platform.isAndroid) {
      return 'ca-app-pub-1969259760721536/2282923370';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716';
    }
    throw UnsupportedError('Unsupported platform');
  }

  static String get interstitialAdUnitId {
    if (_useTesting) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712' // Android test interstitial
          : 'ca-app-pub-3940256099942544/4411468910'; // iOS test interstitial
    }
    
    if (Platform.isAndroid) {
      return 'ca-app-pub-1969259760721536/4925398589';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910';
    }
    throw UnsupportedError('Unsupported platform');
  }

  static String get rewardedAdUnitId {
    if (_useTesting) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/5224354917' // Android test rewarded
          : 'ca-app-pub-3940256099942544/1712485313'; // iOS test rewarded
    }
    
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/5224354917';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313';
    }
    throw UnsupportedError('Unsupported platform');
  }
}
