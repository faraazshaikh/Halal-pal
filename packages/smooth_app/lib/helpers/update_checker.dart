import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Where people go to download the newest Halal Pal.
const String halalPalDownloadPage = 'https://halalpal.intellisenselabs.com';

const String _latestReleaseApi =
    'https://api.github.com/repos/faraazshaikh/halal-pal/releases/tags/latest';

/// Reads the build number from a release name such as
/// "Halal Pal 1.0.0 (build 1034)". Returns null if there is none.
int? parseReleaseBuild(String releaseName) {
  final RegExpMatch? match = RegExp(
    r'(\d+\.\d+\.\d+) \(build (\d+)\)',
  ).firstMatch(releaseName);
  return match == null ? null : int.tryParse(match.group(2)!);
}

/// Reads "1.0.0 (build 1034)" from a release name, or null.
String? parseReleaseLabel(String releaseName) {
  final RegExpMatch? match = RegExp(
    r'(\d+\.\d+\.\d+) \(build (\d+)\)',
  ).firstMatch(releaseName);
  return match == null ? null : '${match.group(1)} (build ${match.group(2)})';
}

/// Checks GitHub once per app start for a newer build of Halal Pal.
///
/// This is the only request the app makes that is not about a product. It
/// sends nothing about the person: just a plain request for the latest
/// release. If anything fails, the app silently carries on.
class UpdateChecker {
  UpdateChecker._() {
    _check();
  }

  static final UpdateChecker instance = UpdateChecker._();

  /// "1.0.0 (build 1034)" when a newer build exists, otherwise null.
  final ValueNotifier<String?> newerVersion = ValueNotifier<String?>(null);

  static Future<void> openDownloadPage() => launchUrl(
    Uri.parse(halalPalDownloadPage),
    mode: LaunchMode.externalApplication,
  );

  Future<void> _check() async {
    final HttpClient client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 8);
    try {
      final PackageInfo info = await PackageInfo.fromPlatform();
      final int? installed = int.tryParse(info.buildNumber);
      if (installed == null) {
        return;
      }
      final HttpClientRequest request = await client.getUrl(
        Uri.parse(_latestReleaseApi),
      );
      request.headers.set('Accept', 'application/vnd.github+json');
      final HttpClientResponse response = await request.close().timeout(
        const Duration(seconds: 10),
      );
      if (response.statusCode != 200) {
        return;
      }
      final String body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 10));
      final Map<String, dynamic> json = jsonDecode(body) as Map<String, dynamic>;
      final String name = (json['name'] as String?) ?? '';
      final int? latest = parseReleaseBuild(name);
      if (latest != null && latest > installed) {
        newerVersion.value = parseReleaseLabel(name);
      }
    } catch (_) {
      // Offline, rate limited, anything: no update message, no problem.
    } finally {
      client.close();
    }
  }
}
