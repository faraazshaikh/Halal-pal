import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Halal Pal launch screen: the icon eases in over the brand colour, a soft
/// chime plays, then the whole overlay fades away to reveal the app.
///
/// Shown once per cold start, on top of [child].
class LaunchAnimation extends StatefulWidget {
  const LaunchAnimation({required this.child, super.key});

  final Widget? child;

  @override
  State<LaunchAnimation> createState() => _LaunchAnimationState();
}

class _LaunchAnimationState extends State<LaunchAnimation>
    with SingleTickerProviderStateMixin {
  static const Color _BRAND = Color(0xFF0F4C4F);
  static DateTime? _startedAt;
  static bool _finished = false;
  static bool _soundStarted = false;
  static AudioPlayer? _player;

  late final AnimationController _controller;
  late final Animation<double> _iconScale;
  late final Animation<double> _iconOpacity;
  late final Animation<double> _titleOpacity;
  late final Animation<double> _overlayOpacity;
  bool _visible = !_finished;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2300),
    );
    _iconOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.25, curve: Curves.easeOut),
    );
    _iconScale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
      ),
    );
    _titleOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.25, 0.5, curve: Curves.easeOut),
    );
    _overlayOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.78, 1.0, curve: Curves.easeInOut),
      ),
    );

    if (_visible) {
      // Time-based, so a rebuilt widget resumes where the animation was.
      _startedAt ??= DateTime.now();
      final double elapsed =
          DateTime.now().difference(_startedAt!).inMilliseconds /
          _controller.duration!.inMilliseconds;
      _controller.forward(from: elapsed.clamp(0.0, 1.0)).whenComplete(() {
        _finished = true;
        if (mounted) {
          setState(() => _visible = false);
        }
      });
      if (!_soundStarted) {
        _soundStarted = true;
        unawaited(_play());
      }
    }
  }

  Future<void> _play() async {
    try {
      HapticFeedback.lightImpact();
      _player = AudioPlayer();
      await _player!.setVolume(0.7);
      await _player!.play(AssetSource('audio/launch.wav'));
    } catch (_) {
      // A missing sound must never block the app.
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
            child: AnimatedBuilder(
              animation: _controller,
              builder: (BuildContext context, Widget? _) {
                return IgnorePointer(
                  ignoring: _overlayOpacity.value < 0.5,
                  child: Opacity(
                    opacity: _overlayOpacity.value,
                    child: ColoredBox(
                      color: _BRAND,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Opacity(
                              opacity: _iconOpacity.value,
                              child: Transform.scale(
                                scale: _iconScale.value,
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
                              opacity: _titleOpacity.value,
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
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
