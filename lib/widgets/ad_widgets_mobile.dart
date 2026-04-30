import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../core/theme.dart';
import '../providers/providers.dart';
import '../services/ad_service.dart';

class BriefedBannerAd extends ConsumerStatefulWidget {
  const BriefedBannerAd({super.key});
  @override
  ConsumerState<BriefedBannerAd> createState() => _BriefedBannerAdState();
}

class _BriefedBannerAdState extends ConsumerState<BriefedBannerAd> {
  BannerAd? _ad;
  bool _loaded = false;

  bool get _canShowAds {
    final user = ref.read(userProvider);
    final authUser = ref.read(authStateProvider).valueOrNull;
    return AdIds.hasBanner &&
        AdService.adsEnabled &&
        !(user.isPro && authUser != null && !authUser.isAnonymous);
  }

  void _clearAd() {
    _ad?.dispose();
    _ad = null;
    _loaded = false;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted || !_canShowAds || _ad != null) return;
    final width = MediaQuery.of(context).size.width.truncate();
    final size =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
    if (!mounted || !_canShowAds) return;
    _ad = BannerAd(
      adUnitId: AdIds.banner,
      size: size ?? AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (!_canShowAds) {
            _clearAd();
            return;
          }
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          if (identical(_ad, ad)) _ad = null;
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final authUser = ref.watch(authStateProvider).valueOrNull;
    final isPro = user.isPro && authUser != null && !authUser.isAnonymous;
    if (!AdService.adsEnabled || isPro) {
      if (_ad != null || _loaded) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(_clearAd);
        });
      }
      return const SizedBox.shrink();
    }
    if (_ad == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
    if (!_loaded || _ad == null) return const SizedBox.shrink();
    return SizedBox(
      width: _ad!.size.width.toDouble(),
      height: _ad!.size.height.toDouble(),
      child: AdWidget(ad: _ad!),
    );
  }
}

class BriefedNativeAd extends ConsumerStatefulWidget {
  const BriefedNativeAd({super.key});
  @override
  ConsumerState<BriefedNativeAd> createState() => _BriefedNativeAdState();
}

class _BriefedNativeAdState extends ConsumerState<BriefedNativeAd> {
  NativeAd? _ad;
  bool _loaded = false;

  bool get _canShowAds {
    final user = ref.read(userProvider);
    final authUser = ref.read(authStateProvider).valueOrNull;
    return AdIds.hasNative &&
        AdService.adsEnabled &&
        !(user.isPro && authUser != null && !authUser.isAnonymous);
  }

  void _clearAd() {
    _ad?.dispose();
    _ad = null;
    _loaded = false;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    if (!_canShowAds || _ad != null) return;
    _ad = NativeAd(
      adUnitId: AdIds.native,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (!mounted || !_canShowAds) {
            ad.dispose();
            _ad = null;
            return;
          }
          setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          if (identical(_ad, ad)) _ad = null;
        },
      ),
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small,
        cornerRadius: 20,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: AppColors.accent,
          style: NativeTemplateFontStyle.bold,
          size: 14,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.black87,
          style: NativeTemplateFontStyle.bold,
          size: 14,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.grey,
          style: NativeTemplateFontStyle.normal,
          size: 12,
        ),
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final authUser = ref.watch(authStateProvider).valueOrNull;
    final isPro = user.isPro && authUser != null && !authUser.isAnonymous;
    if (!AdService.adsEnabled || isPro) {
      if (_ad != null || _loaded) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(_clearAd);
        });
      }
      return const SizedBox.shrink();
    }
    if (_ad == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load();
      });
    }
    if (!_loaded || _ad == null) return const SizedBox.shrink();
    return SizedBox(height: 90, child: AdWidget(ad: _ad!));
  }
}
