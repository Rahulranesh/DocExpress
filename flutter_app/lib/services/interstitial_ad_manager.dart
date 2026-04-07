import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'admob_service.dart';

class InterstitialAdManager {
  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;
  int _numInterstitialLoadAttempts = 0;
  static const int maxFailedLoadAttempts = 3;

  void loadAd() {
    InterstitialAd.load(
      adUnitId: AdMobService.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isAdLoaded = true;
          _numInterstitialLoadAttempts = 0;

          _interstitialAd!.setImmersiveMode(true);
        },
        onAdFailedToLoad: (error) {
          debugPrint('InterstitialAd failed to load: $error');
          _numInterstitialLoadAttempts += 1;
          _interstitialAd = null;
          _isAdLoaded = false;

          if (_numInterstitialLoadAttempts < maxFailedLoadAttempts) {
            loadAd();
          }
        },
      ),
    );
  }

  void showAd({VoidCallback? onAdDismissed}) {
    if (!_isAdLoaded || _interstitialAd == null) {
      debugPrint('Interstitial ad not ready yet.');
      onAdDismissed?.call();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('InterstitialAd showed fullscreen content.');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('InterstitialAd dismissed.');
        ad.dispose();
        _isAdLoaded = false;
        onAdDismissed?.call();
        loadAd(); // Load next ad
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('InterstitialAd failed to show: $error');
        ad.dispose();
        _isAdLoaded = false;
        onAdDismissed?.call();
        loadAd();
      },
    );

    _interstitialAd!.show();
    _interstitialAd = null;
  }

  void dispose() {
    _interstitialAd?.dispose();
  }
}
