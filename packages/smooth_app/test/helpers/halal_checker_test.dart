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
}
