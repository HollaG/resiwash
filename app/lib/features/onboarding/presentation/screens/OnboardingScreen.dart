import 'package:flutter/material.dart';
import 'package:resiwash/features/onboarding/presentation/widgets/Claim.dart';
import 'package:resiwash/features/onboarding/presentation/widgets/Overview.dart';
import 'package:resiwash/theme.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

// Note: all back button presses while in OnboardingScreen should return back to the main view
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

enum OnboardingPage { home, check, claim, contact }

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentPage = 0;

  Widget getCurrentPageWidget() {
    switch (OnboardingPage.values[_currentPage]) {
      case OnboardingPage.home:
        return Overview(); // Show the HomeScreen behind the onboarding overlay
      case OnboardingPage.check:
      //   return _buildCheckPage();
      case OnboardingPage.claim:
      //   return _buildClaimPage();
      case OnboardingPage.contact:
        //   return _buildContactPage();

        return Text("Home");
    }
  }

  bool get showHomePage => _currentPage == 0;
  void _handlePageViewChanged(int index) {
    setState(() {
      _currentPage = index;
    });
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
              // Manage showing the overview home
              AnimatedSize(
                duration: Duration(milliseconds: 300),
                child: SizedBox(
                  height: showHomePage ? null : 0,
                  child: Overview(),
                ),
              ),

              // Manage Check view
              if (_currentPage == 1)
                const Expanded(child: Claim())
              else
                const Spacer(),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // if (_currentPage > 1)
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _currentPage--;
                      });
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
                      setState(() {
                        _currentPage++;
                      });
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
