import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_service.dart';

/// A banner ad that quietly collapses to nothing if it fails to load
/// (e.g. no network) instead of leaving a broken placeholder on screen.
/// Also collapses to nothing on web outright — google_mobile_ads has no
/// web implementation, so there's nothing to load there in the first
/// place (the web build exists for quick desktop-browser testing, not
/// as a real ad-serving target).
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _banner;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) return;
    _banner = AdService.instance.createBanner(
      onLoadFailed: () {
        if (mounted) setState(() => _failed = true);
      },
    );
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || _failed || _banner == null) return const SizedBox.shrink();
    return SizedBox(
      width: _banner!.size.width.toDouble(),
      height: _banner!.size.height.toDouble(),
      child: AdWidget(ad: _banner!),
    );
  }
}
