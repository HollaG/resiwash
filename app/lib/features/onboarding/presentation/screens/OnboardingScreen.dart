import 'package:flutter/material.dart';
import 'package:resiwash/features/onboarding/presentation/widgets/Claim.dart';
import 'package:resiwash/features/onboarding/presentation/widgets/Overview.dart';
import 'package:resiwash/theme.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

// Note: all back button presses while in OnboardingScreen should return back to the main view
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.onFinished});

  final VoidCallback? onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

enum OnboardingPage { home, check, claim, contact }

class _OnboardingScreenState extends State<OnboardingScreen> {
  final GlobalKey<NavigatorState> _onboardingNavigatorKey =
      GlobalKey<NavigatorState>();
  static const List<String> _routeNames = [
    '/overview',
    '/check',
    '/claim',
    '/contact',
  ];

  int _currentPage = 0;

  void _goToIndex(int index) {
    if (index < 0) {
      widget.onFinished?.call();
      return;
    }

    if (index >= OnboardingPage.values.length) {
      widget.onFinished?.call();
      return;
    }

    setState(() {
      _currentPage = index;
    });

    _onboardingNavigatorKey.currentState?.pushNamedAndRemoveUntil(
      _routeNames[index],
      (route) => false,
    );
  }

  Route<dynamic> _onGenerateOnboardingRoute(RouteSettings settings) {
    final String routeName = settings.name ?? _routeNames.first;

    Widget page;
    switch (routeName) {
      case '/overview':
        page = Overview(
          onCheckTap: () => _goToIndex(1),
          onClaimTap: () => _goToIndex(2),
          onContactTap: () => _goToIndex(3),
        );
        break;
      case '/check':
        page = Claim();
        break;
      case '/claim':
        page = const Claim();
        break;
      case '/contact':
        page = const _OnboardingPlaceholder(title: 'Contact');
        break;
      default:
        page = Overview(
          onCheckTap: () => _goToIndex(1),
          onClaimTap: () => _goToIndex(2),
          onContactTap: () => _goToIndex(3),
        );
        break;
    }

    return MaterialPageRoute<void>(settings: settings, builder: (_) => page);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(32),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.6, 1.0],
            colors: [
              Theme.of(context).colorScheme.secondary,
              Color(0xCC384171),
              Theme.of(context).colorScheme.primary,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Navigator(
                  key: _onboardingNavigatorKey,
                  initialRoute: _routeNames.first,
                  onGenerateRoute: _onGenerateOnboardingRoute,
                ),
              ),
              SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {
                      _goToIndex(_currentPage - 1);
                    },
                    icon: Icon(Icons.arrow_back),
                    color: context.accent.colorContainer,
                  ),
                  Expanded(child: SizedBox()),
                  AnimatedSmoothIndicator(
                    activeIndex: _currentPage,
                    count: 4,
                    effect: WormEffect(
                      dotColor: context.accent.colorContainer,
                      activeDotColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Expanded(child: SizedBox()),
                  IconButton(
                    onPressed: () {
                      _goToIndex(_currentPage + 1);
                    },
                    icon: Icon(Icons.arrow_forward),
                    color: context.accent.colorContainer,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPlaceholder extends StatelessWidget {
  const _OnboardingPlaceholder({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$title page',
        style: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(color: Colors.white),
      ),
    );
  }
}
