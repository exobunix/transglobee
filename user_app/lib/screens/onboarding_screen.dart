import 'package:flutter/material.dart';
import '../core/theme.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'icon': Icons.local_taxi_rounded,
      'title': 'Premium Cab Rides',
      'description':
          "Book standard or premium cabs for your daily commute. Fast, comfortable, and reliable.",
      'color': Color(0xFF1A2B48), // Navy Blue for Cab
      'type': 'cab',
    },
    {
      'icon': Icons.local_shipping_rounded,
      'title': 'Logistics & Trucks',
      'description':
          'Move goods with ease. From small packages to heavy loads, hire trucks instantly.',
      'color': Color(0xFFE94560), // Red/Pink accent for Logistics
      'type': 'truck',
    },
    {
      'icon': Icons.directions_bus_rounded,
      'title': 'Seamless Bus Commute',
      'description':
          'Track and book seats on office or route-based buses. Affordable and on-time.',
      'color': Color(0xFF11998E), // Green accent for Bus
      'type': 'bus',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Skip Button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: widget.onComplete,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: context.colors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

            // Page View
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return _buildPage(page);
                },
              ),
            ),

            // Dots Indicator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? context.theme.primaryColor
                          : context.theme.dividerColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),

            // Button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.theme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _currentPage == _pages.length - 1
                        ? 'Get Started'
                        : 'Continue',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(Map<String, dynamic> page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2), // Top spacing
          // Main Hero Image
          Expanded(flex: 12, child: _buildVisual(page['type'], page['color'])),

          const Spacer(flex: 1),

          // Title
          Text(
            page['title'],
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: context.colors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Description
          Text(
            page['description'],
            style: TextStyle(
              fontSize: 16,
              color: context.colors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const Spacer(flex: 3), // Bottom spacing for buttons
        ],
      ),
    );
  }

  Widget _buildVisual(String type, Color color) {
    String assetName;
    if (type == 'cab') {
      assetName = 'assets/images/cab.png';
    } else if (type == 'truck') {
      assetName = 'assets/images/truck.png';
    } else {
      assetName = 'assets/images/bus.png';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      child: Image.asset(assetName, fit: BoxFit.contain),
    );
  }
}
