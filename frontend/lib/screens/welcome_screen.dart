import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth/sign_in_screen.dart';

class WelcomeScreen extends StatefulWidget {
  final VoidCallback? onGetStarted;
  const WelcomeScreen({super.key, this.onGetStarted});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      title: 'AI-Powered Investment Advisor',
      description: 'Get personalized investment advice powered by advanced AI algorithms.',
      lottieAsset: 'assets/animations/placeholder.json',
      imageAsset: 'assets/onboarding/onboarding1.png',
    ),
    _OnboardingPageData(
      title: 'Voice-based Q&A',
      description: 'Ask questions and get instant answers using voice commands.',
      lottieAsset: 'assets/animations/placeholder.json',
      imageAsset: 'assets/onboarding/onboarding2.png',
    ),
    _OnboardingPageData(
      title: 'Forecast Insights',
      description: 'Visualize your financial future with smart forecasting tools.',
      lottieAsset: 'assets/animations/placeholder.json',
      imageAsset: 'assets/onboarding/onboarding3.png',
    ),
  ];

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4A1B4A), // Deep purple background
      body: SafeArea(
        child: Column(
          children: [
            // Skip button at top right
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: () {
                    if (widget.onGetStarted != null) widget.onGetStarted!();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const SignInScreen()),
                    );
                  },
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
            // Main content area
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Column(
                    children: [
                      // Illustration area (top half)
                      Expanded(
                        flex: 2,
                        child: Container(
                          width: double.infinity,
                          child: Center(
                            child: page.imageAsset != null
                                ? Image.asset(
                                    page.imageAsset!,
                                    width: MediaQuery.of(context).size.width * 0.7,
                                    height: MediaQuery.of(context).size.height * 0.3,
                                    fit: BoxFit.contain,
                                  )
                                : Lottie.asset(
                                    page.lottieAsset,
                                    width: 180,
                                    height: 180,
                                    fit: BoxFit.contain,
                                    repeat: true,
                                  ),
                          ),
                        ),
                      ),
                      // Content card (bottom half)
                      Expanded(
                        flex: 3,
                        child: Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(30),
                              topRight: Radius.circular(30),
                            ),
                          ),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 20),
                                Text(
                                  page.title,
                                  style: GoogleFonts.poppins(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF231124),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  page.description,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                    height: 1.4,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                // Page indicators
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(_pages.length, (index) {
                                    return AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                      width: _currentPage == index ? 20 : 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: _currentPage == index 
                                            ? const Color(0xFF6B2B6B) 
                                            : Colors.grey[300],
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    );
                                  }),
                                ),
                                const SizedBox(height: 24),
                                // Next/Get Started button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      if (_currentPage == _pages.length - 1) {
                                        if (widget.onGetStarted != null) widget.onGetStarted!();
                                        Navigator.of(context).pushReplacement(
                                          MaterialPageRoute(builder: (context) => const SignInScreen()),
                                        );
                                      } else {
                                        _pageController.nextPage(
                                          duration: const Duration(milliseconds: 400),
                                          curve: Curves.easeInOut,
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF231124),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _currentPage == _pages.length - 1 ? 'Get Started' : 'Continue',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        if (_currentPage != _pages.length - 1) ...[
                                          const SizedBox(width: 6),
                                          const Icon(Icons.arrow_forward, size: 18),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  final String title;
  final String description;
  final String lottieAsset;
  final String? imageAsset;
  const _OnboardingPageData({
    required this.title,
    required this.description,
    required this.lottieAsset,
    this.imageAsset,
  });
}
