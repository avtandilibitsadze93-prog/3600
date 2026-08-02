import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_service.dart';

/// A banner ad that quietly collapses to nothing if it fails to load
/// (e.g. no network) instead of leaving a broken placeholder on screen.
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
    if (_failed || _banner == null) return const SizedBox.shrink();
    return SizedBox(
      width: _banner!.size.width.toDouble(),
      height: _banner!.size.height.toDouble(),
      child: AdWidget(ad: _banner!),
    );
  }
}
