import 'package:flutter/material.dart';
import 'package:openfoodfacts/openfoodfacts.dart';
import 'package:smooth_app/generic_lib/design_constants.dart';
import 'package:smooth_app/helpers/halal_checker.dart';
import 'package:smooth_app/helpers/report_issue.dart';

/// Colours, icon and wording for each halal verdict.
class HalalStyle {
  const HalalStyle({
    required this.label,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  final String label;
  final String subtitle;
  final Color color;
  final IconData icon;

  static HalalStyle of(HalalVerdict verdict) => switch (verdict) {
    HalalVerdict.haram => const HalalStyle(
      label: 'Haram',
      subtitle: 'Contains haram ingredients',
      color: Color(0xFFC62828),
      icon: Icons.close_rounded,
    ),
    HalalVerdict.mushbooh => const HalalStyle(
      label: 'Mushbooh',
      subtitle: 'Doubtful: depends on the source',
      color: Color(0xFFE08A00),
      icon: Icons.warning_amber_rounded,
    ),
    HalalVerdict.clear => const HalalStyle(
      label: 'Halal',
      subtitle: 'No haram or doubtful ingredients found',
      color: Color(0xFF2E7D32),
      icon: Icons.check_rounded,
    ),
    HalalVerdict.unknown => const HalalStyle(
      label: 'No data',
      subtitle: 'No ingredient list: check the pack yourself',
      color: Color(0xFF616161),
      icon: Icons.help_outline_rounded,
    ),
  };
}

/// Verdict banner on the product page: a big coloured status, then the
/// ingredients that caused it.
///
/// Texts are hardcoded in English on purpose (personal fork).
class HalalCard extends StatelessWidget {
  const HalalCard(this.product, {this.showDisclaimer = true, super.key});

  final Product product;
  final bool showDisclaimer;

  @override
  Widget build(BuildContext context) {
    final HalalResult result = checkHalal(
      ingredientsText: product.ingredientsText,
      additiveNames: product.additives?.names,
    );
    final HalalStyle style = HalalStyle.of(result.verdict);
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      color: style.color,
      padding: const EdgeInsets.all(MEDIUM_SPACE),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(style.icon, color: style.color, size: 40),
              ),
              const SizedBox(width: MEDIUM_SPACE),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      style.label,
                      style: textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      style.subtitle,
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (result.findings.isNotEmpty) ...<Widget>[
            const SizedBox(height: MEDIUM_SPACE),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(SMALL_SPACE),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                borderRadius: ROUNDED_BORDER_RADIUS,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  for (final HalalFinding finding in result.findings)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(top: 5, right: 8),
                            child: Icon(
                              Icons.circle,
                              size: 10,
                              color: HalalStyle.of(finding.verdict).color,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${finding.term}: ${finding.reason}',
                              style: textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (showDisclaimer) ...<Widget>[
            const SizedBox(height: SMALL_SPACE),
            Text(
              'Based on the ingredient list only. Not a halal certificate: '
              'check the pack for a halal mark.',
              style: textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: SMALL_SPACE),
            OutlinedButton.icon(
              onPressed: () => reportProductIssue(
                context,
                product: product,
                result: result,
                verdictLabel: style.label,
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white70),
              ),
              icon: const Icon(Icons.flag_outlined, size: 18),
              label: const Text('Report an issue with this product'),
            ),
          ],
        ],
      ),
    );
  }
}
