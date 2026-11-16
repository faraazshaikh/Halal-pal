import 'package:flutter/material.dart';
import 'package:openfoodfacts/openfoodfacts.dart';
import 'package:smooth_app/generic_lib/design_constants.dart';
import 'package:smooth_app/helpers/halal_checker.dart';

/// Card on the product page showing the result of the local halal check.
///
/// Texts are hardcoded in English on purpose (personal fork).
class HalalCard extends StatelessWidget {
  const HalalCard(this.product, {super.key});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final HalalResult result = checkHalal(
      ingredientsText: product.ingredientsText,
      additiveNames: product.additives?.names,
    );
    final _HalalStyle style = _HalalStyle.of(result.verdict);
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SMALL_SPACE,
        vertical: SMALL_SPACE,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(MEDIUM_SPACE),
        decoration: BoxDecoration(
          color: style.color.withValues(alpha: 0.12),
          border: Border.all(color: style.color, width: 1.5),
          borderRadius: ROUNDED_BORDER_RADIUS,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(style.icon, color: style.color),
                const SizedBox(width: SMALL_SPACE),
                Expanded(
                  child: Text(
                    style.title,
                    style: textTheme.titleMedium?.copyWith(
                      color: style.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            for (final HalalFinding finding in result.findings)
              Padding(
                padding: const EdgeInsets.only(top: SMALL_SPACE),
                child: Text(
                  '• ${finding.term} — ${finding.reason}',
                  style: textTheme.bodyMedium,
                ),
              ),
            const SizedBox(height: SMALL_SPACE),
            Text(
              'Based on the ingredient list only. This is not a halal '
              'certificate: check the pack for a halal mark.',
              style: textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _HalalStyle {
  const _HalalStyle(this.title, this.color, this.icon);

  final String title;
  final Color color;
  final IconData icon;

  static _HalalStyle of(HalalVerdict verdict) => switch (verdict) {
    HalalVerdict.haram => const _HalalStyle(
      'Haram ingredient found',
      Color(0xFFB3261E),
      Icons.dangerous,
    ),
    HalalVerdict.mushbooh => const _HalalStyle(
      'Doubtful (mushbooh) ingredients',
      Color(0xFFB26A00),
      Icons.warning_amber_rounded,
    ),
    HalalVerdict.clear => const _HalalStyle(
      'No haram or doubtful ingredients flagged',
      Color(0xFF2E7D32),
      Icons.check_circle,
    ),
    HalalVerdict.unknown => const _HalalStyle(
      'No ingredient list to check',
      Color(0xFF616161),
      Icons.help_outline,
    ),
  };
}
