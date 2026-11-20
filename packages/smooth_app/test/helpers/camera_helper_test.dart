import 'package:flutter_test/flutter_test.dart';
import 'package:scanner_shared/scanner_shared.dart';
import 'package:smooth_app/helpers/camera_helper.dart';
import 'package:smooth_app/helpers/global_vars.dart';

class _BackCameraThrowsScanner extends MockedScanner {
  const _BackCameraThrowsScanner();

  @override
  Future<bool> hasCamera({required bool front}) async {
    if (!front) {
      throw Exception('camera service unavailable');
    }
    return true;
  }
}

class _NoCameraAnswerScanner extends MockedScanner {
  const _NoCameraAnswerScanner();

  @override
  Future<bool> hasCamera({required bool front}) async => false;
}

void main() {
  test('an empty camera answer still shows the scanner', () async {
    GlobalVars.barcodeScanner = const _NoCameraAnswerScanner();

    await CameraHelper.init();

    expect(CameraHelper.hasACamera, isTrue);
    expect(CameraHelper.hasMoreThanOneCamera, isFalse);
  });

  test('a throwing camera query counts as no camera', () async {
    GlobalVars.barcodeScanner = const _BackCameraThrowsScanner();

    await CameraHelper.init();

    expect(CameraHelper.hasACamera, isTrue);
    expect(CameraHelper.hasMoreThanOneCamera, isFalse);
  });
}
