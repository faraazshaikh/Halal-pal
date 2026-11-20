import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:openfoodfacts/openfoodfacts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:smooth_app/helpers/halal_checker.dart';
import 'package:url_launcher/url_launcher.dart';

/// Where "Report an issue" emails go. Change it here only.
const String halalPalReportEmail = 'hello@intelisenselabs.com';

const int _maxIngredientsChars = 1500;

/// "1.0.0 (build 1023)", shown in Settings and added to every report.
Future<String> halalPalVersionLabel() async {
  final PackageInfo info = await PackageInfo.fromPlatform();
  return '${info.version} (build ${info.buildNumber})';
}

/// Opens the phone's email app with a message to [halalPalReportEmail],
/// prefilled with the barcode, the verdict shown and the ingredients.
///
/// Nothing is sent by the app itself: the person reads the email and presses
/// Send. If there is no email app, the text is copied so it can be pasted.
Future<void> reportProductIssue(
  BuildContext context, {
  required Product product,
  required HalalResult result,
  required String verdictLabel,
}) async {
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  final String version = await halalPalVersionLabel();

  final String barcode = product.barcode ?? '';
  final String name = <String>[
    product.productName ?? '',
    product.brands ?? '',
  ].where((String s) => s.trim().isNotEmpty).join(', ');
  final String ingredients = (product.ingredientsText ?? '').trim();
  final String shownIngredients = ingredients.length > _maxIngredientsChars
      ? '${ingredients.substring(0, _maxIngredientsChars)}...'
      : ingredients;
  final String flagged = result.findings
      .map((HalalFinding f) => '${f.term} (${f.reason})')
      .join('; ');

  final String subject = 'Halal Pal: issue with product $barcode';
  final String body =
      'What is wrong with this product? (write here)\n\n\n'
      '--- Details, please keep ---\n'
      'Barcode: $barcode\n'
      'Product: ${name.isEmpty ? '(no name)' : name}\n'
      'Verdict shown: $verdictLabel\n'
      'Flagged: ${flagged.isEmpty ? '(nothing)' : flagged}\n'
      'Ingredients: ${shownIngredients.isEmpty ? '(none)' : shownIngredients}\n'
      'App: Halal Pal $version\n';

  final Uri uri = Uri.parse(
    'mailto:$halalPalReportEmail'
    '?subject=${Uri.encodeComponent(subject)}'
    '&body=${Uri.encodeComponent(body)}',
  );

  bool launched = false;
  try {
    launched = await launchUrl(uri);
  } catch (_) {
    launched = false;
  }

  if (!launched) {
    await Clipboard.setData(
      ClipboardData(
        text: 'To: $halalPalReportEmail\nSubject: $subject\n\n$body',
      ),
    );
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'No email app found. The details are copied: paste them into an '
          'email to $halalPalReportEmail',
        ),
      ),
    );
  }
}
