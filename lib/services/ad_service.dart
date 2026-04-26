import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AD UNIT IDs
// All IDs below are Google test IDs. Replace them with your real AdMob IDs
// (from admob.google.com) before submitting to the Play Store.
// ─────────────────────────────────────────────────────────────────────────────
class AdIds {
  // ↓ Replace with your real App ID
  static const appId = 'ca-app-pub-3940256099942544~3347511713';
  // ↓ Replace each with the matching ad unit from your AdMob account
  static const banner = 'ca-app-pub-3940256099942544/6300978111';
  static const interstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const rewarded = 'ca-app-pub-3940256099942544/5224354917';
  static const native = 'ca-app-pub-3940256099942544/2247696110';
}

class AdService {
  static InterstitialAd? _interstitial;
  static RewardedAd? _rewarded;
  static bool _loadingInterstitial = false;
  static bool _loadingRewarded = false;
  static Completer<void>? _rewardedLoadCompleter;

  static Future<void> init() => MobileAds.instance.initialize();

  // Call once after init — silently preloads both full-screen formats
  static void preload() {
    unawaited(loadInterstitial());
    unawaited(loadRewarded());
  }

  // ── Interstitial ──────────────────────────────────────────────────────────

  static Future<void> loadInterstitial() async {
    if (_loadingInterstitial || _interstitial != null) return;
    _loadingInterstitial = true;
    await InterstitialAd.load(
      adUnitId: AdIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
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
    if (_rewarded != null) return;
    if (_loadingRewarded) return _rewardedLoadCompleter?.future;
    _loadingRewarded = true;
    _rewardedLoadCompleter = Completer<void>();
    await RewardedAd.load(
      adUnitId: AdIds.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
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
