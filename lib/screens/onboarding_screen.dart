import 'package:flutter/material.dart';
import 'auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<OnboardingItem> _items = [
    OnboardingItem(
      title: 'AI Disease Detection',
      description: 'Upload photos of your crops to instantly identify diseases and get treatment recommendations.',
      icon: Icons.auto_awesome_mosaic_rounded,
      gradient: [Color(0xFF667eea), Color(0xFF764ba2)],
    ),
    OnboardingItem(
      title: 'Integrated E-commerce',
      description: 'Purchase recommended agricultural products directly through our platform with secure payments.',
      icon: Icons.shopping_bag_rounded,
      gradient: [Color(0xFFf093fb), Color(0xFFf5576c)],
    ),
    OnboardingItem(
      title: 'Precision Farming',
      description: 'Get real-time weather insights and optimize your resource usage for maximum yield.',
      icon: Icons.agriculture_rounded,
      gradient: [Color(0xFF4facfe), Color(0xFF00f2fe)],
    ),
    OnboardingItem(
      title: 'Market Predictions',
      description: 'Access real-time market prices and AI-powered predictions to maximize your profits.',
      icon: Icons.insights_rounded,
      gradient: [Color(0xFF43e97b), Color(0xFF38f9d7)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.4, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
      _animationController.reset();
      _animationController.forward();
    });
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < _items.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutQuart,
      );
    } else {
      _goToLogin();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 800),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _items[_currentPage].gradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip Button
              _buildSkipButton(colorScheme),

              // Page View
              Expanded(
                flex: 3,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _items.length,
                  onPageChanged: _onPageChanged,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    return AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: child,
                          ),
                        );
                      },
                      child: OnboardingPage(
                        item: _items[index],
                        currentIndex: index,
                        totalItems: _items.length,
                      ),
                    );
                  },
                ),
              ),

              // Bottom Section
              _buildBottomSection(colorScheme, size),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkipButton(ColorScheme colorScheme) {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: _currentPage < _items.length - 1 ? 1.0 : 0.0,
          child: Material(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: _goToLogin,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Skip',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSection(ColorScheme colorScheme, Size size) {
    return Expanded(
      flex: 1,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(40),
            topRight: Radius.circular(40),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              // Progress Dots
              _buildProgressDots(),
              const SizedBox(height: 32),

              // Navigation Button
              _buildNavigationButton(colorScheme, size),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _items.length,
            (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? _items[_currentPage].gradient[0]
                : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButton(ColorScheme colorScheme, Size size) {
    return SizedBox(
      width: size.width * 0.8,
      height: 56,
      child: Material(
        borderRadius: BorderRadius.circular(28),
        elevation: 8,
        shadowColor: _items[_currentPage].gradient[0].withOpacity(0.5),
        child: InkWell(
          onTap: _nextPage,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _items[_currentPage].gradient,
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: _items[_currentPage].gradient[0].withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _currentPage < _items.length - 1 ? 'Continue' : 'Get Started',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    _currentPage < _items.length - 1
                        ? Icons.arrow_forward_rounded
                        : Icons.check_rounded,
                    color: Colors.white,
                    size: 20,
                    key: ValueKey(_currentPage),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OnboardingItem {
  final String title;
  final String description;
  final IconData icon;
  final List<Color> gradient;

  OnboardingItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
  });
}

class OnboardingPage extends StatelessWidget {
  final OnboardingItem item;
  final int currentIndex;
  final int totalItems;

  const OnboardingPage({
    super.key,
    required this.item,
    required this.currentIndex,
    required this.totalItems,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Icon Container
            _buildAnimatedIcon(size),
            const SizedBox(height: 60),

            // Title with fade animation
            _buildTitle(),
            const SizedBox(height: 24),

            // Description
            _buildDescription(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon(Size size) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Background circles
        Container(
          width: size.width * 0.6,
          height: size.width * 0.6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        Container(
          width: size.width * 0.4,
          height: size.width * 0.4,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.2),
          ),
        ),

        // Main icon container
        Container(
          width: size.width * 0.25,
          height: size.width * 0.25,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            item.icon,
            size: 50,
            color: item.gradient[0],
          ),
        ),

        // Floating elements
        Positioned(
          top: size.width * 0.1,
          right: size.width * 0.1,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: size.width * 0.15,
          left: size.width * 0.1,
          child: Container(
            width: 15,
            height: 15,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return Text(
      item.title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 32,
        fontWeight: FontWeight.w800,
        height: 1.2,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildDescription() {
    return Text(
      item.description,
      style: TextStyle(
        color: Colors.white.withOpacity(0.9),
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.6,
      ),
      textAlign: TextAlign.center,
    );
  }
}