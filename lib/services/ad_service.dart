import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static const String _adUnitId = 'ca-app-pub-6470338276121414/3561369465';

  static InterstitialAd? _ad;
  static bool _isReady = false;

  // Her 3 yanlış cevapta 1 reklam göster
  static int _wrongCount = 0;
  static const int _adsEvery = 3;

  static Future<void> init() async {
    // Çocuklara yönelik uygulama: child-directed treatment + max G rating
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        tagForChildDirectedTreatment: TagForChildDirectedTreatment.yes,
        maxAdContentRating: MaxAdContentRating.g,
      ),
    );
    await MobileAds.instance.initialize();
    _load();
  }

  static void _load() {
    InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _isReady = true;
        },
        onAdFailedToLoad: (_) {
          _ad = null;
          _isReady = false;
        },
      ),
    );
  }

  // Yanlış cevap sayacını artır; her 3'te bir reklamı göster.
  // Reklam kapatılana kadar bekler.
  static Future<void> onWrongAnswer() async {
    _wrongCount++;
    if (_wrongCount % _adsEvery != 0) return;
    await _showInterstitial();
  }

  static Future<void> _showInterstitial() async {
    if (!_isReady || _ad == null) return;
    _isReady = false;

    final completer = Completer<void>();
    _ad!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _ad = null;
        _load();
        completer.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _ad = null;
        _load();
        completer.complete();
      },
    );
    await _ad!.show();
    await completer.future;
  }
}
