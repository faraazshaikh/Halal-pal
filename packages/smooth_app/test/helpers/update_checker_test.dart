import 'package:flutter_test/flutter_test.dart';
import 'package:smooth_app/helpers/update_checker.dart';

void main() {
  test('reads the build number from a release name', () {
    expect(parseReleaseBuild('Halal Pal 1.0.0 (build 1034)'), 1034);
    expect(parseReleaseBuild('Halal Pal 2.3.10 (build 7)'), 7);
  });

  test('returns null when the name has no build number', () {
    expect(parseReleaseBuild(''), isNull);
    expect(parseReleaseBuild('latest'), isNull);
    expect(parseReleaseBuild('Halal Pal 1.0.0'), isNull);
  });

  test('builds a readable version label', () {
    expect(parseReleaseLabel('Halal Pal 1.0.0 (build 1034)'), '1.0.0 (build 1034)');
    expect(parseReleaseLabel('nothing here'), isNull);
  });
}
