import 'package:flutter/material.dart';
import 'package:openfoodfacts/openfoodfacts.dart';
import 'package:provider/provider.dart';
import 'package:smooth_app/cards/product_cards/smooth_product_base_card.dart';
import 'package:smooth_app/cards/product_cards/smooth_product_image.dart';
import 'package:smooth_app/data_models/product_preferences.dart';
import 'package:smooth_app/generic_lib/design_constants.dart';
import 'package:smooth_app/generic_lib/widgets/smooth_back_button.dart';
import 'package:smooth_app/helpers/halal_checker.dart';
import 'package:smooth_app/pages/navigator/app_navigator.dart';
import 'package:smooth_app/pages/product/halal_card.dart';
import 'package:smooth_app/pages/product/product_page/new_product_header.dart';
import 'package:smooth_app/pages/product/summary_card.dart';

class ScanProductCardFound extends StatelessWidget {
  ScanProductCardFound({required this.product, required this.onRemoveProduct})
    : assert(product.barcode!.isNotEmpty),
      super(key: Key(product.barcode!));

  final Product product;
  final OnRemoveCallback? onRemoveProduct;

  @override
  Widget build(BuildContext context) {
    final ProductPreferences productPreferences = context
        .watch<ProductPreferences>();
    final HalalResult halal = checkHalal(
      ingredientsText: product.ingredientsText,
      additiveNames: product.additives?.names,
    );
    final HalalStyle halalStyle = HalalStyle.of(halal.verdict);

    return GestureDetector(
      onTap: () => _openProductPage(context),
      onVerticalDragEnd: (DragEndDetails details) {
        if (details.primaryVelocity == null) {
          return;
        }
        if (details.primaryVelocity! < 0) {
          _openProductPage(context);
        }
      },
      child: ScanProductBaseCard(
        headerLabel: halalStyle.label,
        headerIndicatorColor: Colors.white,
        headerBackgroundColor: halalStyle.color,
        childPadding: EdgeInsets.zero,
        onRemove: onRemoveProduct,
        child: Column(
          children: <Widget>[
            // Halal verdict first, everything else below it.
            HalalCard(product, showDisclaimer: false),
            Expanded(
              child: SummaryCard(
                product,
                productPreferences,
                heroTag: _heroTag,
                margin: EdgeInsetsDirectional.zero,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: LARGE_SPACE,
                  vertical: VERY_SMALL_SPACE,
                ),
                scrollableContent: true,
                isTextSelectable: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _heroTag =>
      ProductPicture.generateHeroTag(product.barcode!, ImageField.FRONT);

  void _openProductPage(BuildContext context) {
    AppNavigator.of(context).push(
      AppRoutes.PRODUCT(
        product.barcode!,
        heroTag: _heroTag,
        backButtonType: BackButtonType.minimize,
        transition: ProductPageTransition.slideUp,
      ),
      extra: product,
    );
  }
}
