import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smooth_app/pages/navigator/card_to_page_transition.dart';

/// "Don't cut. Carry." — measured with a fake clock, so the numbers are exact.
///
/// A card sits at a known place. Tapping it opens a page: the rectangle that
/// holds the page must start at the card, grow steadily to the whole screen,
/// and, on Back, shrink steadily into the card again.
class _Host extends StatefulWidget {
  const _Host({required this.pageKey, required this.rememberCard});

  final LocalKey pageKey;
  final bool rememberCard;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      pages: <Page<void>>[
        MaterialPage<void>(
          child: Scaffold(
            body: Stack(
              children: <Widget>[
                Positioned(
                  left: 20,
                  top: 100,
                  width: 300,
                  height: 80,
                  child: Builder(
                    builder: (BuildContext cardContext) => GestureDetector(
                      key: const ValueKey<String>('card'),
                      onTap: () {
                        if (widget.rememberCard) {
                          CardOrigin.remember(cardContext);
                        }
                        setState(() => _open = true);
                      },
                      child: const ColoredBox(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_open)
          CardToPage.getTransition<void>(
            key: widget.pageKey,
            child: const Scaffold(body: Center(child: Text('the page'))),
          ),
      ],
      onDidRemovePage: (Page<Object?> page) {
        if (_open) {
          setState(() => _open = false);
        }
      },
    );
  }
}

double _clipHeight(WidgetTester tester) =>
    tester.getRect(find.byKey(CardToPage.clipKey)).height;

Future<List<double>> _sample(
  WidgetTester tester,
  List<int> atMilliseconds,
) async {
  final List<double> heights = <double>[];
  int now = 0;
  for (final int at in atMilliseconds) {
    await tester.pump(Duration(milliseconds: at - now));
    now = at;
    heights.add(_clipHeight(tester));
  }
  return heights;
}

void main() {
  testWidgets('the page grows out of the card, and Back shrinks it into it', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: _Host(pageKey: ValueKey<String>('a'), rememberCard: true),
      ),
    );

    await tester.tap(find.byKey(const ValueKey<String>('card')));
    await tester.pump(); // the page is added, the animation starts
    final List<double> opening = await _sample(tester, <int>[
      1,
      60,
      120,
      240,
      360,
      480,
    ]);
    // ignore: avoid_print
    print('opening heights: $opening');

    expect(opening.first, closeTo(80, 12), reason: 'must start at the card');
    for (int i = 1; i < opening.length; i++) {
      expect(
        opening[i],
        greaterThanOrEqualTo(opening[i - 1]),
        reason: 'must only grow while opening',
      );
    }
    expect(opening[3], greaterThan(150), reason: 'half way it must be bigger');
    expect(opening[3], lessThan(590), reason: 'half way it must not be done');
    expect(opening.last, closeTo(600, 1), reason: 'must fill the screen');
    expect(find.text('the page'), findsOneWidget);

    // Back: the same motion in reverse, into the same card.
    await tester.pumpAndSettle();
    final NavigatorState navigator = tester.state<NavigatorState>(
      find.descendant(
        of: find.byType(_Host),
        matching: find.byType(Navigator),
      ),
    );
    navigator.pop();
    await tester.pump();
    final List<double> closing = await _sample(tester, <int>[
      1,
      80,
      160,
      240,
      320,
      395,
    ]);
    // ignore: avoid_print
    print('closing heights: $closing');

    expect(closing.first, greaterThan(400), reason: 'must start full screen');
    for (int i = 1; i < closing.length; i++) {
      expect(
        closing[i],
        lessThanOrEqualTo(closing[i - 1]),
        reason: 'must only shrink while closing',
      );
    }
    expect(closing.last, closeTo(80, 12), reason: 'must end at the card');

    await tester.pumpAndSettle();
    expect(find.byKey(CardToPage.clipKey), findsNothing);
    expect(find.text('the page'), findsNothing);
  });

  testWidgets('with no card to grow from it rises gently, never crashes', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: _Host(pageKey: ValueKey<String>('b'), rememberCard: false),
      ),
    );
    await tester.tap(find.byKey(const ValueKey<String>('card')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(find.text('the page'), findsOneWidget);
    expect(find.byKey(CardToPage.clipKey), findsNothing);
  });
}
