import 'package:flutter/foundation.dart';

class AdIds {
  static const appId = '';
  static const banner = '';
  static const interstitial = '';
  static const rewarded = '';
  static const native = '';
  static bool get hasAppId => false;
  static bool get hasBanner => false;
  static bool get hasInterstitial => false;
  static bool get hasRewarded => false;
  static bool get hasNative => false;
  static bool get hasAnyAdUnit => false;
}

class AdService {
  static bool get adsEnabled => false;
  static Future<void> init() async {}
  static void configure({required bool adsEnabled}) {}
  static void preload() {}
  static Future<void> loadInterstitial() async {}
  static Future<void> showInterstitial({VoidCallback? then}) async {
    then?.call();
  }
  static Future<void> loadRewarded() async {}
  static bool get rewardedReady => false;
  static bool get rewardedLoading => false;
  static Future<bool> showRewardedAndWait(
          {bool allowDebugFallback = false}) async =>
      allowDebugFallback && kDebugMode;
  static Future<void> showRewarded({
    required VoidCallback onEarned,
    VoidCallback? onDismissed,
  }) async {
    onDismissed?.call();
  }
}
