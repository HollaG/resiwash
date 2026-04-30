import 'package:flutter/material.dart';
import 'package:resiwash/features/onboarding/presentation/sections/Check.dart';
import 'package:resiwash/features/onboarding/presentation/sections/Claim.dart';
import 'package:resiwash/features/onboarding/presentation/sections/Claim_2.dart';
import 'package:resiwash/features/onboarding/presentation/widgets/Overview.dart';
import 'package:resiwash/theme.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

// Note: all back button presses while in OnboardingScreen should return back to the main view
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.onDismiss,
    this.onSwipePastEnd,
  });

  final VoidCallback onDismiss;
  final VoidCallback? onSwipePastEnd;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

enum OnboardingPage { check, claim, claim2, home }

class _OnboardingScreenState extends State<OnboardingScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final PageController _pageViewController = PageController(initialPage: 0);
  static const int _lastPageIndex = 3;
  int _currentPage = 0;
  bool _didHandleEndOverscroll = false;

  @override
  void dispose() {
    _pageViewController.dispose();
    super.dispose();
  }

  void _goToSection(OnboardingPage page) {
    int pageIndex = page.index;
    _pageViewController.animateToPage(
      pageIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  bool _onPageScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification) {
      _didHandleEndOverscroll = false;
      return false;
    }

    if (notification is OverscrollNotification) {
      final metrics = notification.metrics;
      final isHorizontal = metrics.axis == Axis.horizontal;
      final isAtEnd = metrics.pixels >= metrics.maxScrollExtent;
      final draggingForward = notification.overscroll > 0;

      if (isHorizontal &&
          isAtEnd &&
          draggingForward &&
          !_didHandleEndOverscroll) {
        _didHandleEndOverscroll = true;
        widget.onSwipePastEnd?.call();
      }
    }

    if (notification is ScrollEndNotification) {
      _didHandleEndOverscroll = false;
    }

    return false;
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 3:
        return Overview(
          onCheckTap: () {
            _goToSection(OnboardingPage.check);
          },
          onClaimTap: () {
            _goToSection(OnboardingPage.claim);
          },
          onContactTap: () {
            // _goToSection(OnboardingPage.contact);
          },
          onDismiss: widget.onDismiss,
        );
      case 0:
        return Check();
      case 1:
        return Claim();
      case 2:
        return Claim2();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin
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
            colors: [Color(0xff000220), Color(0xCC384171), Color(0xff394379)],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Align(
              //   alignment: Alignment.centerRight,
              //   child: IconButton(
              //     onPressed: widget.onDismiss,
              //     icon: Icon(Icons.close),
              //     color: context.accent.colorContainer,
              //   ),
              // ),
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: _onPageScrollNotification,
                  child: PageView.builder(
                    controller: _pageViewController,
                    itemCount: 4,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) => _buildPage(index),
                  ),
                ),
              ),
              SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 75,
                    child: _currentPage != 0
                        ? IconButton(
                            onPressed: () {
                              if (_currentPage > 0) {
                                _pageViewController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                            },
                            icon: Icon(Icons.arrow_back),
                            color: context.accent.colorContainer,
                          )
                        : null,
                  ),
                  Expanded(child: SizedBox()),
                  // AnimatedSmoothIndicator(
                  //   activeIndex: _currentPage,
                  //   count: 4,
                  //   effect: WormEffect(
                  //     dotColor: context.accent.colorContainer,
                  //     activeDotColor: Theme.of(context).colorScheme.primary,
                  //   ),
                  // ),
                  SmoothPageIndicator(
                    controller: _pageViewController, // PageController
                    count: 4,
                    effect: WormEffect(
                      dotColor: context.accent.onColor,
                      activeDotColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                    ),
                  ),
                  Expanded(child: SizedBox()),
                  SizedBox(
                    width: 75,
                    child: _currentPage == _lastPageIndex
                        ? ElevatedButton(
                            onPressed: () {
                              widget.onDismiss();
                            },
                            child: Icon(Icons.home),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                            ),
                          )
                        //  ElevatedButton(
                        //     style: ButtonStyle(
                        //       backgroundColor: WidgetStateProperty.all(
                        //         Theme.of(context).colorScheme.primaryContainer,
                        //       ),
                        //     ),
                        //     onPressed: widget.onDismiss,
                        //     child: Text("Home"),
                        //   )
                        : IconButton(
                            onPressed: () {
                              if (_currentPage < _lastPageIndex) {
                                _pageViewController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                            },
                            icon: Icon(Icons.arrow_forward),
                            color: context.accent.colorContainer,
                          ),
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
