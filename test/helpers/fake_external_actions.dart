// ABOUTME: Hand-written fake for ExternalActions used in widget tests.
// ABOUTME: Records call counts so tests can assert tap handlers wire to the right action.

import 'package:udahni/core/services/external_actions.dart';

class FakeExternalActions implements ExternalActions {
  int openPrivacyPolicyCallCount = 0;
  int requestAppReviewCallCount = 0;

  @override
  Future<void> openPrivacyPolicy() async {
    openPrivacyPolicyCallCount++;
  }

  @override
  Future<void> requestAppReview() async {
    requestAppReviewCallCount++;
  }
}
