import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

const Color _LAUNCH_BRAND = Color(0xFF0F4C4F);

/// Minimum time the launch screen stays up, so the animation and the chime
/// can finish even when the app initialises quickly.
const Duration LAUNCH_MIN_DURATION = Duration(milliseconds: 2400);

bool _soundStarted = false;
bool _fadeFinished = false;

Future<void> _playChime() async {
  if (_soundStarted) {
    return;
  }
  _soundStarted = true;
  try {
    HapticFeedback.lightImpact();
    final AudioPlayer player = AudioPlayer();
    await player.setVolume(0.7);
    await player.play(AssetSource('audio/launch.wav'));
  } catch (_) {
    // A missing sound must never block the app.
  }
}

/// The icon + name, laid out identically in [LaunchScreen] and [LaunchFadeOut]
/// so the hand-over between them is invisible.
class _LaunchContent extends StatelessWidget {
  const _LaunchContent({
    this.iconScale = 1.0,
    this.iconOpacity = 1.0,
    this.titleOpacity = 1.0,
  });

  final double iconScale;
  final double iconOpacity;
  final double titleOpacity;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: _LAUNCH_BRAND,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Opacity(
                opacity: iconOpacity,
                child: Transform.scale(
                  scale: iconScale,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: SvgPicture.asset(
                      'assets/app/release_icon.svg',
                      width: 112,
                      height: 112,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Opacity(
                opacity: titleOpacity,
                child: const Text(
                  'Halal Pal',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.8,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown from the very first frame while the app initialises: the icon eases
/// in, the title follows, and the chime plays.
class LaunchScreen extends StatefulWidget {
  const LaunchScreen({super.key});

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _iconScale;
  late final Animation<double> _iconOpacity;
  late final Animation<double> _titleOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
    _iconOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _iconScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _titleOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 1.0, curve: Curves.easeOut),
    );
    unawaited(_playChime());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? _) => _LaunchContent(
        iconScale: _iconScale.value,
        iconOpacity: _iconOpacity.value,
        titleOpacity: _titleOpacity.value,
      ),
    );
  }
}

/// Once the app is ready, the launch screen dissolves to reveal it.
class LaunchFadeOut extends StatefulWidget {
  const LaunchFadeOut({required this.child, super.key});

  final Widget? child;

  @override
  State<LaunchFadeOut> createState() => _LaunchFadeOutState();
}

class _LaunchFadeOutState extends State<LaunchFadeOut>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _visible = !_fadeFinished;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    if (_visible) {
      _controller.forward().whenComplete(() {
        _fadeFinished = true;
        if (mounted) {
          setState(() => _visible = false);
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        if (widget.child != null) Positioned.fill(child: widget.child!),
        if (_visible)
          Positioned.fill(
            child: IgnorePointer(
              child: FadeTransition(
                opacity: ReverseAnimation(
                  CurvedAnimation(
                    parent: _controller,
                    curve: Curves.easeInOut,
                  ),
                ),
                child: const _LaunchContent(),
              ),
            ),
          ),
      ],
    );
  }
}
