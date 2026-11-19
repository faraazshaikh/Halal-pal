# Halal Pal

A personal halal food scanner for Android. Scan a barcode and see **Halal**, **Haram** (with the reason) or **Mushbooh** (doubtful, with the reason) first, with product details below.

Verdicts come from a keyword-based ingredient checker (`halal_rules.dart`, `halal_checker.dart`). It matches English words only and is a helper, not a religious ruling: check the pack yourself when in doubt.

## Build

Debug and release APKs are built by GitHub Actions (`.github/workflows/halal-debug-apk.yml`) on every push to `halalpal-rebrand`. The app code lives in `packages/smooth_app` (Flutter, version in `flutter-version.txt`).

## Credits and licences

- Product data: [Open Food Facts](https://world.openfoodfacts.org/legal) contributors, shared under the [ODbL licence](https://opendatacommons.org/licenses/odbl/1-0/).
- The app is a fork of the Open Food Facts [smooth-app](https://github.com/openfoodfacts/smooth-app), released under the Apache-2.0 licence (see `LICENSE`).
- Halal Pal is an independent project and is not affiliated with or endorsed by Open Food Facts.
- Halal Pal sends no analytics or crash reports.
