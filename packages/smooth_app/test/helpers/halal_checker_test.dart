import 'package:flutter_test/flutter_test.dart';
import 'package:smooth_app/helpers/halal_checker.dart';

void main() {
  HalalVerdict verdictOf(String? text, {List<String>? additives}) =>
      checkHalal(ingredientsText: text, additiveNames: additives).verdict;

  group('checkHalal', () {
    test('no ingredient information is unknown', () {
      expect(verdictOf(null), HalalVerdict.unknown);
      expect(verdictOf('   '), HalalVerdict.unknown);
    });

    test('plain vegetarian ingredients are clear', () {
      expect(
        verdictOf('Wheat flour, sugar, palm oil, salt, citric acid'),
        HalalVerdict.clear,
      );
    });

    test('pork derivatives are haram', () {
      expect(verdictOf('Wheat flour, pork fat, salt'), HalalVerdict.haram);
      expect(verdictOf('Gelatin (pork)'), HalalVerdict.haram);
      expect(verdictOf('Water, ham, spices'), HalalVerdict.haram);
    });

    test('keywords match whole words only', () {
      expect(verdictOf('Shampoo base, pigment, crumbs'), HalalVerdict.clear);
    });

    test('alcohol is haram, but alcohol-free and wine vinegar are not', () {
      expect(verdictOf('Water, alcohol, sugar'), HalalVerdict.haram);
      expect(verdictOf('Water, sugar, alcohol free flavour'), HalalVerdict.clear);
      expect(verdictOf('Salad, white wine vinegar'), HalalVerdict.clear);
    });

    test('carmine and E120 are haram', () {
      expect(verdictOf('Sugar, colour (carmine)'), HalalVerdict.haram);
      expect(verdictOf('Sugar, colour (E120)'), HalalVerdict.haram);
      expect(verdictOf('Sugar', additives: <String>['E120 - Carmine']),
          HalalVerdict.haram);
    });

    test('gelatin with no source is haram, with a source is mushbooh', () {
      expect(verdictOf('Sugar, gelatin'), HalalVerdict.haram);
      expect(verdictOf('Sugar, gelatine (bovine)'), HalalVerdict.mushbooh);
      expect(verdictOf('Sugar, fish gelatin'), HalalVerdict.mushbooh);
    });

    test('source-dependent E-numbers are mushbooh', () {
      expect(verdictOf('Flour, emulsifier (E471)'), HalalVerdict.mushbooh);
      expect(verdictOf('Flour, emulsifier (e 472a)'), HalalVerdict.mushbooh);
      expect(
        verdictOf('Flour', additives: <String>['E631 - Disodium inosinate']),
        HalalVerdict.mushbooh,
      );
    });

    test('haram always wins over mushbooh', () {
      final HalalResult result = checkHalal(
        ingredientsText: 'Flour, E471, pork fat',
      );
      expect(result.verdict, HalalVerdict.haram);
      expect(result.findings.first.verdict, HalalVerdict.haram);
    });
  });

  group('stronger checks', () {
    test('plain flavouring is mushbooh (the Snackrite bag)', () {
      expect(
        verdictOf('Potato, vegetable oil, salt, flavouring'),
        HalalVerdict.mushbooh,
      );
      expect(verdictOf('Sugar, flavourings'), HalalVerdict.mushbooh);
      expect(verdictOf('Sugar, flavor'), HalalVerdict.mushbooh);
    });

    test('natural flavouring is listed once', () {
      final HalalResult result = checkHalal(
        ingredientsText: 'Sugar, natural flavouring',
      );
      expect(result.verdict, HalalVerdict.mushbooh);
      expect(result.findings, hasLength(1));
    });

    test('alcohol-free or halal flavouring is not flagged', () {
      expect(verdictOf('Sugar, alcohol-free flavouring'), HalalVerdict.clear);
      expect(verdictOf('Sugar, halal flavouring'), HalalVerdict.clear);
      expect(verdictOf('Sugar, flavour enhancer (E621)'), HalalVerdict.clear);
    });

    test('blood and hog products are haram', () {
      expect(verdictOf('Water, blood plasma'), HalalVerdict.haram);
      expect(verdictOf('Hog casings, salt'), HalalVerdict.haram);
      expect(verdictOf('Porcine gelatin'), HalalVerdict.haram);
      expect(verdictOf('Sugar, blood orange juice'), HalalVerdict.clear);
    });

    test('meat is mushbooh unless halal is stated', () {
      expect(verdictOf('Chicken, salt'), HalalVerdict.mushbooh);
      expect(verdictOf('Halal chicken, salt'), HalalVerdict.clear);
      expect(verdictOf('Beef (halal), water'), HalalVerdict.clear);
      expect(verdictOf('Goat milk, sugar'), HalalVerdict.clear);
      // "chicken flavour" holds no chicken: only the flavouring is flagged.
      final HalalResult flavoured = checkHalal(
        ingredientsText: 'Potato, chicken flavour',
      );
      expect(
        flavoured.findings.any((HalalFinding f) => f.term == 'chicken'),
        isFalse,
      );
    });

    test('plant source next to a doubtful ingredient clears it', () {
      expect(verdictOf('Flour, microbial rennet'), HalalVerdict.clear);
      expect(verdictOf('Flour, soya lecithin'), HalalVerdict.clear);
      expect(verdictOf('Flour, lecithin (sunflower)'), HalalVerdict.clear);
      expect(verdictOf('Flour, vegetable glycerine'), HalalVerdict.clear);
    });

    test('a nearby unrelated word does not clear it', () {
      expect(verdictOf('Glycerin, palm oil'), HalalVerdict.mushbooh);
      expect(verdictOf('Lecithin, soy sauce'), HalalVerdict.mushbooh);
      expect(verdictOf('Rennet, vegetable oil'), HalalVerdict.mushbooh);
    });

    test('new wine and bone-char E-numbers are mushbooh', () {
      expect(verdictOf('Sugar (E153)'), HalalVerdict.mushbooh);
      expect(verdictOf('Acid (E334)'), HalalVerdict.mushbooh);
    });

    test('halal certified skips source checks but never haram ones', () {
      expect(
        checkHalal(
          ingredientsText: 'Sugar, flavouring, gelatin',
          halalCertified: true,
        ).verdict,
        HalalVerdict.clear,
      );
      expect(
        checkHalal(
          ingredientsText: 'Sugar, pork fat',
          halalCertified: true,
        ).verdict,
        HalalVerdict.haram,
      );
    });

    test('halal labels are recognised', () {
      expect(isHalalCertifiedByLabels(<String>['en:halal']), isTrue);
      expect(isHalalCertifiedByLabels(<String>['en:non-halal']), isFalse);
      expect(isHalalCertifiedByLabels(<String>['en:organic']), isFalse);
      expect(isHalalCertifiedByLabels(null), isFalse);
    });
  });
}
