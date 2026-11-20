import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// "Don't cut. Carry."
///
/// Where a card was on screen when it was tapped, so the page that opens can
/// grow out of that exact spot and, on Back, shrink into it again.
class CardOrigin {
  const CardOrigin._(this.rect, this.radius, this.color);

  /// The card's position and size, in screen coordinates.
  final Rect rect;
  final double radius;

  /// The surface colour the card grows into, so there is no flash.
  final Color color;

  static CardOrigin? _pending;
  static DateTime? _pendingAt;

  /// One answer per page, so a page that is rebuilt never changes its
  /// transition half way through.
  static final Map<LocalKey, CardOrigin?> _byPage = <LocalKey, CardOrigin?>{};

  /// Call just before opening a page from a card. [context] is the card's.
  static void remember(BuildContext context, {double radius = 14.0}) {
    _pending = null;
    _pendingAt = null;
    final RenderObject? box = context.findRenderObject();
    if (box is RenderBox && box.attached && box.hasSize) {
      _pending = CardOrigin._(
        box.localToGlobal(Offset.zero) & box.size,
        radius,
        Theme.of(context).scaffoldBackgroundColor,
      );
      _pendingAt = DateTime.now();
    }
  }

  /// Used by the route when it builds its page.
  static CardOrigin? forPage(LocalKey key) {
    if (_byPage.containsKey(key)) {
      return _byPage[key];
    }
    CardOrigin? origin = _pending;
    final DateTime? at = _pendingAt;
    if (at != null && DateTime.now().difference(at).inSeconds >= 2) {
      origin = null; // an old tap that never opened anything
    }
    _pending = null;
    _pendingAt = null;
    if (_byPage.length > 40) {
      _byPage.remove(_byPage.keys.first);
    }
    _byPage[key] = origin;
    return origin;
  }
}

/// A page that grows out of the card that was tapped.
///
/// Opening: the card's rectangle expands to the whole screen while the page
/// fades in inside it. Back plays the same motion in reverse. Without a known
/// card (a link, a scan) it falls back to a gentle rise.
class CardToPage {
  const CardToPage._();

  static const Curve _curve = Curves.easeInOutCubicEmphasized;

  /// Marks the growing rectangle, so a test can measure the motion.
  static const Key clipKey = ValueKey<String>('card_to_page_clip');

  static CustomTransitionPage<T> getTransition<T>({
    required Widget child,
    required LocalKey key,
  }) {
    final CardOrigin? origin = CardOrigin.forPage(key);
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: const Duration(milliseconds: 480),
      reverseTransitionDuration: const Duration(milliseconds: 400),
      transitionsBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            if (origin == null) {
              return _Rise(animation: animation, child: child);
            }
            return _GrowFromCard(
              animation: animation,
              origin: origin,
              child: child,
            );
          },
    );
  }
}

class _GrowFromCard extends StatelessWidget {
  const _GrowFromCard({
    required this.animation,
    required this.origin,
    required this.child,
  });

  final Animation<double> animation;
  final CardOrigin origin;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size size = constraints.biggest;
        return AnimatedBuilder(
          animation: animation,
          child: child,
          builder: (BuildContext context, Widget? page) {
            final double value = animation.value.clamp(0.0, 1.0);
            final bool closing = animation.status == AnimationStatus.reverse;
            final double t =
                (closing ? CardToPage._curve.flipped : CardToPage._curve)
                    .transform(value);

            final Rect rect = Rect.lerp(origin.rect, Offset.zero & size, t)!;
            final double radius = lerpDouble(
              origin.radius,
              0.0,
              Curves.easeIn.transform(t),
            )!;
            // The card's colour covers the card first, then the page appears
            // inside it: the card and the page feel like one surface.
            final double fill = const Interval(0.0, 0.25).transform(value);
            final double content = const Interval(
              0.3,
              0.75,
              curve: Curves.easeOut,
            ).transform(value);

            return Stack(
              children: <Widget>[
                Positioned.fromRect(
                  rect: rect,
                  child: ClipRRect(
                    key: CardToPage.clipKey,
                    borderRadius: BorderRadius.circular(radius),
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        Opacity(
                          opacity: fill,
                          child: ColoredBox(color: origin.color),
                        ),
                        Opacity(
                          opacity: content,
                          // The page is always laid out at full size and only
                          // revealed by the growing rectangle, so it never
                          // re-flows during the motion.
                          child: OverflowBox(
                            alignment: Alignment.topCenter,
                            minWidth: size.width,
                            maxWidth: size.width,
                            minHeight: size.height,
                            maxHeight: size.height,
                            child: page,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _Rise extends StatelessWidget {
  const _Rise({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (BuildContext context, Widget? page) {
        final bool closing = animation.status == AnimationStatus.reverse;
        final double t = (closing ? CardToPage._curve.flipped : CardToPage._curve)
            .transform(animation.value.clamp(0.0, 1.0));
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0.0, (1.0 - t) * 24.0),
            child: page,
          ),
        );
      },
    );
  }
}
