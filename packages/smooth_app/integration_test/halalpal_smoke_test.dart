import 'package:app_store_google_play/app_store_google.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:scanner_ml_kit/scanner_ml_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_app/cards/product_cards/smooth_product_card_found.dart';
import 'package:smooth_app/helpers/entry_points_helper.dart';
import 'package:smooth_app/main.dart' as app;
import 'package:smooth_app/pages/navigator/card_to_page_transition.dart';
import 'package:smooth_app/pages/onboarding/onboarding_flow_navigator.dart';
import 'package:smooth_app/widgets/smooth_navigation_bar.dart';

/// Smoke test for the real app on an Android emulator.
///
/// It starts the app exactly as the Play-style entry point does, then opens
/// every main screen and fails if any of them crashes. A crashed screen is
/// painted as a flat grey box in release builds, which is how the History and
/// camera screens broke before. Here a crash fails the test with its message.
///
/// Run by CI via ci/emulator_smoke.sh. Screenshots are taken by that script.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final List<String> failures = <String>[];

  void log(String message) => debugPrint('SMOKE ${DateTime.now()} $message');

  Future<void> wait(WidgetTester tester, int seconds) async {
    final DateTime end = DateTime.now().add(Duration(seconds: seconds));
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  /// Fails the stage if the screen threw or shows the crash message.
  void expectNoCrash(WidgetTester tester, String stage) {
    final Object? thrown = tester.takeException();
    expect(thrown, isNull, reason: '$stage threw: $thrown');
    expect(
      find.textContaining('This screen failed to load'),
      findsNothing,
      reason: '$stage shows the crash screen',
    );
    expect(
      find.byType(ErrorWidget),
      findsNothing,
      reason: '$stage contains an ErrorWidget',
    );
  }

  Future<void> stage(
    WidgetTester tester,
    String name,
    Future<void> Function() body,
  ) async {
    log('STAGE start: $name');
    try {
      await body();
      final List<String> texts = find
          .byType(Text)
          .evaluate()
          .map((Element e) => (e.widget as Text).data ?? '')
          .where((String t) => t.trim().isNotEmpty)
          .take(25)
          .toList();
      log('ON SCREEN after "$name": $texts');
      expectNoCrash(tester, name);
      log('STAGE ok: $name');
    } catch (error) {
      log('STAGE FAILED: $name -> $error');
      failures.add('$name: $error');
      // Drop the recorded exception so the next stage starts clean.
      tester.takeException();
    }
  }

  /// Measures the rectangle that grows out of the card (and shrinks back):
  /// reads its position a few times while the motion runs.
  Future<List<Rect>> sampleMotion(
    WidgetTester tester, {
    required int frames,
    required int everyMs,
  }) async {
    final List<Rect> rects = <Rect>[];
    for (int i = 0; i < frames; i++) {
      await tester.pump(Duration(milliseconds: everyMs));
      final Finder clip = find.byKey(CardToPage.clipKey);
      if (clip.evaluate().isNotEmpty) {
        rects.add(tester.getRect(clip.first));
      }
    }
    return rects;
  }

  Finder navIcon(IconData icon) => find
      .descendant(
        of: find.byType(SmoothNavigationBar),
        matching: find.byIcon(icon),
      )
      .first;

  testWidgets('every main screen opens without crashing', (
    WidgetTester tester,
  ) async {
    // The app installs its own error screen; put the test framework's back at
    // the end, or the framework reports the change as a failure.
    final ErrorWidgetBuilder originalErrorBuilder = ErrorWidget.builder;
    try {
    // Skip the first-run tour: the test is about the screens, not onboarding.
    SharedPreferences.setMockInitialValues(<String, Object>{
      'lastVisitedOnboardingPage': OnboardingPage.ONBOARDING_COMPLETE.index,
    });

    await app.launchSmoothApp(
      barcodeScanner: const ScannerMLKit(),
      appStore: GooglePlayStore(),
      scannerLabel: ScannerLabel.MLKit,
      storeLabel: StoreLabel.GooglePlayStore,
    );

    // Wait for start-up (database, preferences) until the tab bar is there.
    log('waiting for the app to start');
    final DateTime deadline = DateTime.now().add(const Duration(seconds: 120));
    while (DateTime.now().isBefore(deadline) &&
        find.byType(SmoothNavigationBar).evaluate().isEmpty) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(
      find.byType(SmoothNavigationBar),
      findsOneWidget,
      reason: 'the app never reached the main screen with its tab bar',
    );
    tester.takeException();

    await stage(tester, 'Scan screen (opening tab)', () async {
      await wait(tester, 10);
      // Informational: what the camera area shows on this emulator.
      log(
        'camera error text on screen: '
        '${find.textContaining('Camera problem').evaluate().length}',
      );
    });

    await stage(tester, 'History screen', () async {
      await tester.tap(navIcon(Icons.history_rounded));
      await wait(tester, 6);
      expect(
        find.byIcon(Icons.settings_outlined),
        findsWidgets,
        reason: 'the Settings gear is missing from the History screen',
      );
    });

    await stage(tester, 'Settings screen (gear on History)', () async {
      await tester.tap(find.byIcon(Icons.settings_outlined).first);
      await wait(tester, 6);
    });

    await stage(tester, 'Back to History', () async {
      await tester.binding.handlePopRoute();
      await wait(tester, 3);
    });

    await stage(tester, 'History menu grows from its button', () async {
      final Finder button = find.byIcon(Icons.more_vert_rounded);
      expect(button, findsWidgets, reason: 'no menu button on History');
      final Rect buttonRect = tester.getRect(button.first);
      await tester.tap(button.first);
      await wait(tester, 1);
      final Finder items = find.byType(PopupMenuItem<int>);
      expect(items, findsWidgets, reason: 'the menu did not open');
      final Rect menu = tester.getRect(items.first);
      log('menu button $buttonRect, first menu item $menu');
      expect(
        menu.top - buttonRect.bottom,
        inInclusiveRange(-8.0, 80.0),
        reason: 'the menu must open right under its button',
      );
      expect(
        (menu.right - buttonRect.right).abs(),
        lessThan(48.0),
        reason: 'the menu must line up with its button',
      );
      await tester.binding.handlePopRoute();
      await wait(tester, 1);
      expect(find.byType(PopupMenuItem<int>), findsNothing);
    });

    await stage(tester, 'Scan screen (after History)', () async {
      await tester.tap(navIcon(Icons.qr_code_scanner_rounded));
      await wait(tester, 10);
    });

    await stage(tester, 'Search screen', () async {
      await tester.tap(navIcon(Icons.search_rounded));
      await wait(tester, 5);
    });

    await stage(tester, 'Search for a product by barcode', () async {
      final Finder field = find.byType(TextField);
      expect(field, findsWidgets, reason: 'no search box on the Search screen');
      await tester.enterText(field.first, '3017620422003');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      // Needs the internet: the result may be slow or missing, which is fine.
      // A crash is not.
      await wait(tester, 20);
      log(
        'search result mentions Nutella: '
        '${find.textContaining('Nutella').evaluate().length}',
      );
    });

    await stage(tester, 'Product page (only if the search found it)', () async {
      final Finder result = find.textContaining('Nutella');
      if (result.evaluate().isEmpty) {
        log('no result to open (probably no internet); skipping this stage');
        return;
      }
      await tester.tap(result.first);
      await wait(tester, 15);
    });

    await stage(tester, 'Back from the product page', () async {
      await tester.binding.handlePopRoute();
      await wait(tester, 2);
    });

    await stage(tester, 'Search results list', () async {
      final Finder field = find.byType(TextField);
      expect(field, findsWidgets, reason: 'no search box');
      final TextField box = tester.widget<TextField>(field.first);
      box.controller!.text = 'nutella';
      box.onSubmitted!('nutella');
      await wait(tester, 25);
      expect(
        find.byType(SmoothProductCardItemFound),
        findsWidgets,
        reason: 'the search found no product rows (is the internet down?)',
      );
    });

    final Size screen = tester.view.physicalSize / tester.view.devicePixelRatio;

    await stage(tester, 'Card grows into the product page', () async {
      final Rect card = tester.getRect(
        find.byType(SmoothProductCardItemFound).first,
      );
      log('card is $card on a screen of $screen');
      await tester.tap(find.byType(SmoothProductCardItemFound).first);
      final List<Rect> rects = await sampleMotion(
        tester,
        frames: 14,
        everyMs: 50,
      );
      log('growing rectangle heights: '
          '${rects.map((Rect r) => r.height.round()).toList()}');
      expect(rects.length, greaterThan(4), reason: 'no growing rectangle seen');
      expect(
        rects.first.height,
        lessThan(screen.height * 0.6),
        reason: 'the page must start small, at the card',
      );
      for (int i = 1; i < rects.length; i++) {
        expect(
          rects[i].height,
          greaterThanOrEqualTo(rects[i - 1].height - 2),
          reason: 'the rectangle must only grow while opening',
        );
      }
      await wait(tester, 3);
      expect(
        tester.getRect(find.byKey(CardToPage.clipKey).first).height,
        greaterThan(screen.height * 0.97),
        reason: 'the page must end up filling the screen',
      );
    });

    await stage(tester, 'Back shrinks the page into the card', () async {
      await tester.binding.handlePopRoute();
      final List<Rect> rects = await sampleMotion(
        tester,
        frames: 7,
        everyMs: 45,
      );
      log('shrinking rectangle heights: '
          '${rects.map((Rect r) => r.height.round()).toList()}');
      expect(rects.length, greaterThan(2), reason: 'no shrinking seen');
      for (int i = 1; i < rects.length; i++) {
        expect(
          rects[i].height,
          lessThanOrEqualTo(rects[i - 1].height + 2),
          reason: 'the rectangle must only shrink while closing',
        );
      }
      expect(
        rects.last.height,
        lessThan(rects.first.height - 50),
        reason: 'Back must visibly shrink the page',
      );
      await wait(tester, 2);
      expect(
        find.byType(SmoothProductCardItemFound),
        findsWidgets,
        reason: 'the list must be back after Back',
      );
    });

    log('FINISHED with ${failures.length} failed stage(s)');
    expect(
      failures,
      isEmpty,
      reason: 'these screens failed:\n${failures.join('\n')}',
    );
    } finally {
      ErrorWidget.builder = originalErrorBuilder;
    }
  });
}
