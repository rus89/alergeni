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
  const PlatformExternalActions();

  @override
  Future<void> openPrivacyPolicy() async {
    final uri = Uri.parse(Links.privacyPolicy);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Future<void> requestAppReview() async {
    // Use the Play Store listing as the destination for the explicit Settings
    // action. The in-app review API silently no-ops on builds not installed
    // from Play Store, which is surprising when triggered from an explicit tap.
    await InAppReview.instance.openStoreListing();
  }
}
