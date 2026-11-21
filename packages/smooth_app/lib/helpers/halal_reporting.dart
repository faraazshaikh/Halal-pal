import 'dart:async';
import 'dart:convert';
import 'dart:ui' show ErrorCallback, PlatformDispatcher;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:smooth_app/data_models/preferences/user_preferences.dart';

/// Crash reports and anonymous usage counts, sent to Halal Pal's own server.
///
/// The server turns crash reports into an email to the Halal Pal team, so no
/// email address (and no mail password) is stored in the app.
///
/// What is sent: the app version, the platform, the error and its stack
/// (crash reports) or event names such as "tab: history" and the verdict of a
/// scan (usage). Never: names, accounts, locations or barcodes.
///
/// Each of the two kinds is controlled by its own switch in the settings.
/// Debug builds (tests, the emulator) never send anything.
class HalalReporting {
  const HalalReporting._();

  static const String defaultEndpoint =
      'https://n8n.srv1450918.hstgr.cloud/webhook/halalpal-report';

  static Uri _url = Uri.parse(defaultEndpoint);
  static http.Client Function() _clientFactory = http.Client.new;
  static bool _sendInDebug = false;
  static bool _crashOn = false;
  static bool _usageOn = false;
  static String _version = 'unknown';
  static int _crashesSent = 0;
  static final Set<String> _crashKeys = <String>{};
  static final Set<String> _verdictKeys = <String>{};
  static final List<Map<String, Object?>> _queue = <Map<String, Object?>>[];
  static Timer? _timer;
  static bool _hooked = false;

  /// Reads the two switches, installs the crash hooks and starts the timer.
  static Future<void> init(UserPreferences userPreferences) async {
    String version = 'unknown';
    try {
      final PackageInfo info = await PackageInfo.fromPlatform();
      version = '${info.version}+${info.buildNumber}';
    } catch (_) {
      // Keep "unknown".
    }
    configure(
      crash: userPreferences.crashReports,
      usage: userPreferences.userTracking,
      version: version,
    );
    userPreferences.onCrashReportingChanged.addListener(
      () => _crashOn = userPreferences.onCrashReportingChanged.value,
    );
    userPreferences.onAnalyticsChanged.addListener(() {
      _usageOn = userPreferences.onAnalyticsChanged.value;
      if (!_usageOn) {
        _queue.clear();
      }
    });
    _hookErrors();
    _timer ??= Timer.periodic(
      const Duration(seconds: 60),
      (_) => unawaited(flush()),
    );
    WidgetsBinding.instance.addObserver(_Lifecycle());
  }

  /// Sets everything that does not need the preferences. Used by [init] and
  /// by the tests.
  @visibleForTesting
  static void configure({
    required bool crash,
    required bool usage,
    String version = 'test',
    Uri? url,
    http.Client Function()? clientFactory,
    bool sendInDebug = false,
  }) {
    _crashOn = crash;
    _usageOn = usage;
    _version = version;
    _sendInDebug = sendInDebug;
    _url = url ?? Uri.parse(defaultEndpoint);
    _clientFactory = clientFactory ?? http.Client.new;
    _crashesSent = 0;
    _crashKeys.clear();
    _verdictKeys.clear();
    _queue.clear();
  }

  static void _hookErrors() {
    if (_hooked) {
      return;
    }
    _hooked = true;
    final FlutterExceptionHandler? previous = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (previous != null) {
        previous(details);
      } else {
        FlutterError.presentError(details);
      }
      unawaited(reportCrash(details.exception, details.stack));
    };
    final ErrorCallback? previousPlatform = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      unawaited(reportCrash(error, stack));
      return previousPlatform?.call(error, stack) ?? false;
    };
  }

  /// Sends a crash report, if the switch is on. The same error is sent once,
  /// and at most five reports leave the phone per run.
  static Future<void> reportCrash(Object error, StackTrace? stack) async {
    if (!_crashOn) {
      return;
    }
    final String message = error.toString();
    final String key = _cut(message, 200);
    if (_crashesSent >= 5 || !_crashKeys.add(key)) {
      return;
    }
    _crashesSent++;
    await _post(<String, Object?>{
      'kind': 'crash',
      'app': _version,
      'platform': defaultTargetPlatform.name,
      'time': DateTime.now().toUtc().toIso8601String(),
      'error': _cut(message, 1500),
      'stack': _cut(stack?.toString() ?? '', 6000),
    });
  }

  /// Counts one anonymous usage event, if the switch is on.
  static void trackUsage(String name, [Map<String, String>? props]) {
    if (!_usageOn) {
      return;
    }
    if (_queue.length >= 200) {
      _queue.removeAt(0);
    }
    _queue.add(<String, Object?>{
      'e': name,
      if (props != null && props.isNotEmpty) 'p': props,
      't': DateTime.now().toUtc().toIso8601String(),
    });
    if (_queue.length >= 15) {
      unawaited(flush());
    }
  }

  /// The verdict a scan gave. Once per product and verdict, per run, and the
  /// barcode itself is never sent.
  static void trackVerdict(String? barcode, String verdict) {
    if (!_verdictKeys.add('$barcode:$verdict')) {
      return;
    }
    trackUsage('halal_verdict', <String, String>{'verdict': verdict});
  }

  /// Sends the waiting usage events now.
  static Future<void> flush() async {
    if (_queue.isEmpty || !_usageOn) {
      return;
    }
    final List<Map<String, Object?>> batch = List<Map<String, Object?>>.of(
      _queue,
    );
    _queue.clear();
    await _post(<String, Object?>{
      'kind': 'usage',
      'app': _version,
      'platform': defaultTargetPlatform.name,
      'events': batch,
    });
  }

  static Future<void> _post(Map<String, Object?> body) async {
    if (kDebugMode && !_sendInDebug) {
      return;
    }
    final http.Client client = _clientFactory();
    try {
      await client
          .post(
            _url,
            headers: const <String, String>{'content-type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      // Reporting must never break the app, and a lost report is fine.
    } finally {
      client.close();
    }
  }

  static String _cut(String text, int max) =>
      text.length <= max ? text : text.substring(0, max);
}

class _Lifecycle with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      unawaited(HalalReporting.flush());
    }
  }
}
