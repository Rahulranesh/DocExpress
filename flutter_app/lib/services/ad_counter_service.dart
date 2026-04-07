import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'interstitial_ad_manager.dart';

class AdCounterService {
  static final AdCounterService _instance = AdCounterService._internal();
  factory AdCounterService() => _instance;
  AdCounterService._internal();

  static const String _counterKey = 'ad_action_counter';
  static const int _actionsBeforeAd = 3; // Show ad every 3 actions

  final InterstitialAdManager _adManager = InterstitialAdManager();
  int _actionCounter = 0;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    final prefs = await SharedPreferences.getInstance();
    _actionCounter = prefs.getInt(_counterKey) ?? 0;
    _adManager.loadAd(); // Preload first ad
    _isInitialized = true;
  }

  Future<void> incrementAndShowAd({VoidCallback? onAdDismissed}) async {
    _actionCounter++;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_counterKey, _actionCounter);

    if (_actionCounter >= _actionsBeforeAd) {
      _actionCounter = 0;
      await prefs.setInt(_counterKey, 0);
      
      _adManager.showAd(onAdDismissed: onAdDismissed);
    } else {
      onAdDismissed?.call();
    }
  }

  void dispose() {
    _adManager.dispose();
  }
}
