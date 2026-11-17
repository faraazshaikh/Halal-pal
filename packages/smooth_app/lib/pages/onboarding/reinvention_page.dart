import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:smooth_app/data_models/onboarding_loader.dart';
import 'package:smooth_app/data_models/preferences/user_preferences.dart';
import 'package:smooth_app/database/local_database.dart';
import 'package:smooth_app/pages/onboarding/onboarding_flow_navigator.dart';
import 'package:smooth_app/pages/onboarding/v2/onboarding_bottom_hills.dart';
import 'package:smooth_app/widgets/smooth_scaffold.dart';

/// Onboarding page: "reinvention"
class OnboardingHomePage extends StatelessWidget {
  const OnboardingHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SmoothBrightnessOverride(
      brightness: Brightness.dark,
      child: SmoothScaffold(
        backgroundColor: const Color(0xFFF6F1E4),
        body: Provider<OnboardingConfig>.value(
          value: OnboardingConfig._(MediaQuery.sizeOf(context)),
          child: Stack(
            children: <Widget>[
              const _OnboardingWelcomePageContent(),
              OnboardingBottomHills(
                onTap: () async {
                  final UserPreferences userPreferences = context
                      .read<UserPreferences>();
                  final LocalDatabase localDatabase = context
                      .read<LocalDatabase>();

                  /// Enable crash reports and user tracking by default
                  /// (Can be disabled by the user later in the settings)
                  await userPreferences.setCrashReports(true);
                  await userPreferences.setUserTracking(true);

                  /// Consent now exists, so the first open can be reported.
                  await userPreferences.trackFirstOpenAfterConsent();

                  if (context.mounted) {
                    await OnboardingLoader(
                      localDatabase,
                    ).runAtNextTime(OnboardingPage.HOME_PAGE, context);
                  }

                  if (context.mounted) {
                    await OnboardingFlowNavigator(
                      userPreferences,
                    ).navigateToPage(
                      context,
                      OnboardingPage.HOME_PAGE.getNextPage(),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingWelcomePageContent extends StatelessWidget {
  const _OnboardingWelcomePageContent();

  @override
  Widget build(BuildContext context) {
    final double fontMultiplier = OnboardingConfig.of(context).fontMultiplier;
    final double hillsHeight = OnboardingBottomHills.height(context);

    return Padding(
      padding: EdgeInsetsDirectional.only(
        top: hillsHeight * 0.5 + MediaQuery.viewPaddingOf(context).top,
        bottom: hillsHeight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            flex: 15,
            child: Text(
              'Welcome to\nHalal Pal',
              style: TextStyle(
                fontSize: 38 * fontMultiplier,
                fontWeight: FontWeight.bold,
                height: 1.15,
                color: const Color(0xFF0B2A2B),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 37,
            child: Center(
              child: SvgPicture.asset('assets/app/release_icon.svg', width: 170),
            ),
          ),
          Expanded(
            flex: 45,
            child: FractionallySizedBox(
              widthFactor: 0.75,
              child: Align(
                alignment: const Alignment(0, -0.2),
                child: Text(
                  'Scan any packaged food and see at once whether it is halal, doubtful or haram.',
                  style: TextStyle(
                    fontSize: 22 * fontMultiplier,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0B2A2B),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// TODO(g123k): Move elsewhere when the onboarding will be redesigned
class OnboardingConfig {
  OnboardingConfig._(Size screenSize)
    : fontMultiplier = computeFontMultiplier(screenSize);
  final double fontMultiplier;

  static double computeFontMultiplier(Size screenSize) =>
      ((screenSize.width * 45) / 428) / 45;

  static OnboardingConfig of(BuildContext context) =>
      context.watch<OnboardingConfig>();
}
