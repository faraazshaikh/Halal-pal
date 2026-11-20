import 'package:flutter/material.dart';
import 'package:smooth_app/pages/product/halal_card.dart';
import 'package:smooth_app/helpers/scan_times.dart';
import 'package:smooth_app/helpers/halal_checker.dart';
import 'package:openfoodfacts/openfoodfacts.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:smooth_app/cards/product_cards/smooth_product_image.dart';
import 'package:smooth_app/generic_lib/design_constants.dart';
import 'package:smooth_app/generic_lib/widgets/picture_not_found.dart';
import 'package:smooth_app/helpers/product_cards_helper.dart';
import 'package:smooth_app/l10n/app_localizations.dart';
import 'package:smooth_app/pages/navigator/app_navigator.dart';
import 'package:smooth_app/pages/navigator/card_to_page_transition.dart';
import 'package:smooth_app/pages/product/product_page/new_product_header.dart';

class SmoothProductCardItemFound extends StatelessWidget {
  const SmoothProductCardItemFound({
    required this.product,
    required this.heroTag,
    this.backgroundColor,
    this.onLongPress,
    this.onTap,
  });

  final Product product;
  final String heroTag;
  final Color? backgroundColor;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations appLocalizations = AppLocalizations.of(context);
    final bool light = Theme.of(context).brightness == Brightness.light;
    final HalalResult halal = checkHalal(
      ingredientsText: product.ingredientsText,
      additiveNames: product.additives?.names,
    );
    final HalalStyle style = HalalStyle.of(halal.verdict);
    final Color secondary = light
        ? const Color(0xFF6D6D72)
        : const Color(0xFF98989F);

    final Widget child = Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: LARGE_SPACE,
        vertical: 12.0,
      ),
      child: Row(
        children: <Widget>[
          ProductPicture.fromProduct(
            product: product,
            imageField: ImageField.FRONT,
            fallbackUrl: product.imageFrontUrl,
            allowAlternativeLanguage: true,
            size: const Size(64.0, 64.0),
            borderRadius: const BorderRadius.all(Radius.circular(14.0)),
            noImageBuilder: (_) => const PictureNotFound(),
            blurFilter: false,
          ),
          const SizedBox(width: 14.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  getProductName(product, appLocalizations),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  getProductBrandsList(product, appLocalizations).firstOrNull ??
                      appLocalizations.unknownBrand,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13.5, color: secondary),
                ),
                const SizedBox(height: 6.0),
                Row(
                  children: <Widget>[
                    Container(
                      width: 10.0,
                      height: 10.0,
                      decoration: BoxDecoration(
                        color: style.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6.0),
                    Text(
                      style.label,
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w700,
                        color: style.color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8.0),
          _TimeAgo(barcode: product.barcode!, color: secondary),
        ],
      ),
    );

    return MultiProvider(
      providers: <SingleChildWidget>[
        Provider<Product>(create: (_) => product),
        Provider<String>.value(value: heroTag),
      ],
      child: InkWell(
        onTap:
            onTap ??
            () {
              // The page grows out of this card, and Back shrinks it back.
              CardOrigin.remember(context);
              AppNavigator.of(context).push(
                AppRoutes.PRODUCT(
                  product.barcode!,
                  heroTag: heroTag,
                  transition: ProductPageTransition.fromCard,
                ),
                extra: product,
              );
            },
        onLongPress: () => onLongPress?.call(),
        child: child,
      ),
    );
  }
}

class _TimeAgo extends StatelessWidget {
  const _TimeAgo({required this.barcode, required this.color});

  final String barcode;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: ScanTimes.changes,
      builder: (BuildContext context, int _, Widget? __) {
        final String text = ScanTimes.ago(ScanTimes.of(barcode));
        if (text.isEmpty) {
          return EMPTY_WIDGET;
        }
        return Text(text, style: TextStyle(fontSize: 12.5, color: color));
      },
    );
  }
}
