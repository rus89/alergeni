// ABOUTME: Actions that hand control off to platform integrations: web links and Play Store review.
// ABOUTME: Abstracted so widget tests can substitute fakes without touching plugin platform channels.

import 'package:in_app_review/in_app_review.dart';
import 'package:udahni/core/constants/links.dart';
import 'package:url_launcher/url_launcher.dart';

abstract interface class ExternalActions {
  Future<void> openPrivacyPolicy();
  Future<void> requestAppReview();
}

class PlatformExternalActions implements ExternalActions {
  PlatformExternalActions({InAppReview? inAppReview})
    : _inAppReview = inAppReview ?? InAppReview.instance;

  final InAppReview _inAppReview;

  @override
  Future<void> openPrivacyPolicy() async {
    final uri = Uri.parse(Links.privacyPolicy);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Future<void> requestAppReview() async {
    if (await _inAppReview.isAvailable()) {
      await _inAppReview.requestReview();
    } else {
      await _inAppReview.openStoreListing();
    }
  }
}
