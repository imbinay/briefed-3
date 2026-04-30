import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AD UNIT IDs
// Google test IDs for development. Replace with real AdMob IDs before launch.
// ─────────────────────────────────────────────────────────────────────────────
class AdIds {
  static const appId = 'ca-app-pub-2344438801383084~1588876460';
  static const banner = 'ca-app-pub-2344438801383084/4381815901';
  static const interstitial = 'ca-app-pub-2344438801383084/7283311411';
  static const rewarded = 'ca-app-pub-2344438801383084/8456792282';
  static const native = 'ca-app-pub-2344438801383084/2247696110';

  static bool get hasAppId => appId.isNotEmpty;
  static bool get hasBanner => banner.isNotEmpty;
  static bool get hasInterstitial => interstitial.isNotEmpty;
  static bool get hasRewarded => rewarded.isNotEmpty;
  static bool get hasNative => native.isNotEmpty;
  static bool get hasAnyAdUnit =>
      hasBanner || hasInterstitial || hasRewarded || hasNative;
}

class AdService {
  static InterstitialAd? _interstitial;
  static RewardedAd? _rewarded;
  static bool _adsEnabled = true;
  static bool _loadingInterstitial = false;
  static bool _loadingRewarded = false;
  static Completer<void>? _rewardedLoadCompleter;

  static bool get adsEnabled => _adsEnabled;

  static Future<void> init() async {
    if (!AdIds.hasAppId || !AdIds.hasAnyAdUnit) {
      _adsEnabled = false;
      return;
    }
    await MobileAds.instance.initialize();
  }

  static void configure({required bool adsEnabled}) {
    if (_adsEnabled == adsEnabled) return;
    _adsEnabled = adsEnabled;
    if (!_adsEnabled) {
      _interstitial?.dispose();
      _interstitial = null;
      _rewarded?.dispose();
      _rewarded = null;
      return;
    }
    preload();
  }

  // Call once after init — silently preloads both full-screen formats
  static void preload() {
    if (!_adsEnabled) return;
    unawaited(loadInterstitial());
    unawaited(loadRewarded());
  }

  // ── Interstitial ──────────────────────────────────────────────────────────

  static Future<void> loadInterstitial() async {
    if (!AdIds.hasInterstitial) return;
    if (!_adsEnabled) return;
    if (_loadingInterstitial || _interstitial != null) return;
    _loadingInterstitial = true;
    await InterstitialAd.load(
      adUnitId: AdIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          if (!_adsEnabled) {
            ad.dispose();
            _loadingInterstitial = false;
            return;
          }
          _interstitial = ad;
          _loadingInterstitial = false;
        },
        onAdFailedToLoad: (_) {
          _loadingInterstitial = false;
        },
      ),
    );
  }

  // Shows the interstitial if ready, then calls [then]. If not ready, calls
  // [then] immediately so the caller's navigation always completes.
  static Future<void> showInterstitial({VoidCallback? then}) async {
    if (!_adsEnabled) {
      then?.call();
      return;
    }
    final ad = _interstitial;
    if (ad == null) {
      then?.call();
      return;
    }
    _interstitial = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        unawaited(loadInterstitial());
        then?.call();
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        unawaited(loadInterstitial());
        then?.call();
      },
    );
    await ad.show();
  }

  // ── Rewarded ──────────────────────────────────────────────────────────────

  static Future<void> loadRewarded() async {
    if (!AdIds.hasRewarded) return;
    if (!_adsEnabled) return;
    if (_rewarded != null) return;
    if (_loadingRewarded) return _rewardedLoadCompleter?.future;
    _loadingRewarded = true;
    _rewardedLoadCompleter = Completer<void>();
    await RewardedAd.load(
      adUnitId: AdIds.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          if (!_adsEnabled) {
            ad.dispose();
            _loadingRewarded = false;
            _rewardedLoadCompleter?.complete();
            _rewardedLoadCompleter = null;
            return;
          }
          _rewarded = ad;
          _loadingRewarded = false;
          _rewardedLoadCompleter?.complete();
          _rewardedLoadCompleter = null;
        },
        onAdFailedToLoad: (_) {
          _loadingRewarded = false;
          _rewardedLoadCompleter?.complete();
          _rewardedLoadCompleter = null;
        },
      ),
    );
  }

  static bool get rewardedReady => _rewarded != null;
  static bool get rewardedLoading => _loadingRewarded;

  static Future<bool> showRewardedAndWait({
    bool allowDebugFallback = false,
  }) async {
    if (!_adsEnabled) return true;
    await loadRewarded();
    final ad = _rewarded;
    if (ad == null) return allowDebugFallback && kDebugMode;

    _rewarded = null;
    var earned = false;
    final closed = Completer<bool>();

    void complete() {
      if (!closed.isCompleted) closed.complete(earned);
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        unawaited(loadRewarded());
        complete();
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        unawaited(loadRewarded());
        complete();
      },
    );
    await ad.show(onUserEarnedReward: (_, __) => earned = true);
    return closed.future;
  }

  // [onEarned] fires when the user completes the video.
  // [onDismissed] fires when the ad closes (whether rewarded or not).
  static Future<void> showRewarded({
    required VoidCallback onEarned,
    VoidCallback? onDismissed,
  }) async {
    if (!_adsEnabled) {
      onEarned();
      onDismissed?.call();
      return;
    }
    final ad = _rewarded;
    if (ad == null) {
      onDismissed?.call();
      return;
    }
    _rewarded = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        unawaited(loadRewarded());
        onDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        unawaited(loadRewarded());
        onDismissed?.call();
      },
    );
    await ad.show(onUserEarnedReward: (_, __) => onEarned());
  }
}
