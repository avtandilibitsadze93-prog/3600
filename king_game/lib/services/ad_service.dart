import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Wraps AdMob banner + interstitial ads behind Google's PUBLIC TEST ad
/// unit IDs. These always serve a test creative and are safe to ship in
/// debug/dev builds, but MUST be replaced with your own AdMob unit IDs
/// (from your AdMob console, matching the App IDs already set in
/// AndroidManifest.xml / Info.plist) before a real release, or the app
/// will never earn real revenue.
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  static String get bannerAdUnitId => Platform.isIOS
      ? 'ca-app-pub-3940256099942544/2934735716'
      : 'ca-app-pub-3940256099942544/6300978111';

  static String get interstitialAdUnitId => Platform.isIOS
      ? 'ca-app-pub-3940256099942544/4411468910'
      : 'ca-app-pub-3940256099942544/1033173712';

  InterstitialAd? _interstitial;

  /// iOS requires asking for App Tracking Transparency *before*
  /// initializing the ads SDK if ads should honor that choice from the
  /// start — a no-op on Android. Must be called after the first frame
  /// (the OS won't show the prompt over a still-launching app).
  Future<void> requestTrackingThenInitialize() async {
    if (Platform.isIOS) {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        await AppTrackingTransparency.requestTrackingAuthorization();
      }
    }
    await MobileAds.instance.initialize();
    preloadInterstitial();
  }

  BannerAd createBanner({required void Function() onLoadFailed}) {
    return BannerAd(
      size: AdSize.banner,
      adUnitId: bannerAdUnitId,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          onLoadFailed();
        },
      ),
    )..load();
  }

  /// Loads an interstitial in the background so it's ready to [showInterstitial]
  /// the moment a round ends. Safe to call again even if one is already loaded.
  void preloadInterstitial() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (_) => _interstitial = null,
      ),
    );
  }

  /// Shows the preloaded interstitial if one is ready, then preloads the
  /// next one. No-ops silently if none is ready — ads should never block
  /// the game from continuing.
  void showInterstitialIfReady() {
    final ad = _interstitial;
    if (ad == null) return;
    _interstitial = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        preloadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        preloadInterstitial();
      },
    );
    ad.show();
  }
}
