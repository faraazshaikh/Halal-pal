import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:matomo_tracker/matomo_tracker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_app/helpers/analytics_helper.dart';

/// Counts every network request the tracker tries to make.
class _CountingClient extends http.BaseClient {
  int requests = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests++;
    return http.StreamedResponse(const Stream<List<int>>.empty(), 200);
  }
}

/// A screen built like the real ones (History, the camera screen, ...): it
/// reports its page view to the tracker when it opens.
class _TrackedScreen extends StatefulWidget {
  const _TrackedScreen();

  @override
  State<_TrackedScreen> createState() => _TrackedScreenState();
}

class _TrackedScreenState extends State<_TrackedScreen>
    with TraceableClientMixin {
  @override
  String get actionName => 'Opened test screen';

  @override
  Widget build(BuildContext context) =>
      const Directionality(textDirection: TextDirection.ltr, child: Text('ok'));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Regression test: the History and camera screens turned into grey boxes
  // because the tracker was never set up and threw when a screen opened.
  // The tracker is a single shared object, so everything runs in one test
  // and in the order the app does it: set up first, then open screens.
  test('tracker is set up, opted out, and screens open without error', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    PackageInfo.setMockInitialValues(
      appName: 'Halal Pal',
      packageName: 'com.intelisenselabs.halalpal',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );

    // The bug: before set-up, a screen opening throws.
    expect(MatomoTracker.instance.initialized, isFalse);
    expect(
      () => MatomoTracker.instance.trackPageViewWithName(actionName: 'x'),
      throwsA(isA<MatomoException>()),
      reason: 'sanity check: this is the crash the fix removes',
    );

    final _CountingClient client = _CountingClient();
    await AnalyticsHelper.initMatomo(false, httpClient: client);

    expect(MatomoTracker.instance.initialized, isTrue);
    expect(
      MatomoTracker.instance.optOut,
      isTrue,
      reason: 'Halal Pal must never record or send analytics',
    );

    // What every screen does when it opens: must not throw.
    MatomoTracker.instance.trackPageViewWithName(actionName: 'History');
    MatomoTracker.instance.trackEvent(
      eventInfo: EventInfo(category: 'c', action: 'a'),
    );

    // Try to send everything that was recorded: nothing may leave the phone.
    await MatomoTracker.instance.dispatchActions();
    expect(
      client.requests,
      0,
      reason: 'the tracker must not make any network request',
    );

    // Nothing may pile up in memory either.
    MatomoTracker.instance.dropActions();
    expect(MatomoTracker.instance.queue, isEmpty);
  });

  testWidgets('a screen with the tracking mixin builds after set-up', (
    WidgetTester tester,
  ) async {
    // Runs after the test above in the same process, so the tracker is ready.
    await tester.pumpWidget(const _TrackedScreen());
    expect(tester.takeException(), isNull);
    expect(find.text('ok'), findsOneWidget);
  });
}
