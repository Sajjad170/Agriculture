import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dashboard/dashboard_screen.dart';
import 'onboarding_screen.dart';
import '../theme/app_theme.dart';
import 'package:hugeicons/hugeicons.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<Color?> _gradientAnimation;

  final List<Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    // Initialize particles
    _initializeParticles();

    // Main animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Multiple animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
      ),
    );

    _rotationAnimation = Tween<double>(begin: -0.1, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _gradientAnimation = ColorTween(
      begin: AppTheme.primaryColor.withOpacity(0.3),
      end: AppTheme.primaryColor,
    ).animate(_animationController);

    // Start animations
    _animationController.forward();

    // Check user session
    _checkUserSession();
  }

  void _initializeParticles() {
    for (int i = 0; i < 15; i++) {
      _particles.add(Particle(
        x: _random.nextDouble() * 400,
        y: _random.nextDouble() * 800,
        radius: _random.nextDouble() * 3 + 1,
        speed: _random.nextDouble() * 0.5 + 0.1,
        alpha: _random.nextDouble() * 0.5 + 0.3,
      ));
    }
  }

  Future<void> _checkUserSession() async {
    bool isLoggedIn = await AuthService().restoreSession();

    // Extended delay for premium animation experience
    await Future.delayed(const Duration(milliseconds: 3500));

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => isLoggedIn ? const DashboardScreen() : const OnboardingScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 1000),
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  isDarkMode ? Colors.grey.shade900 : Colors.blue.shade50,
                  isDarkMode ? Colors.grey.shade800 : Colors.green.shade50,
                  isDarkMode ? Colors.grey.shade900 : Colors.blue.shade50,
                ],
              ),
            ),
            child: Stack(
              children: [
                // Animated Background Elements
                _buildAnimatedBackground(size, isDarkMode),

                // Floating Particles
                ..._buildParticles(size),

                // Main Content
                Positioned.fill(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App Icon with Multiple Animations
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Glow Effect
                          Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AppTheme.primaryColor.withOpacity(0.3 * _animationController.value),
                                  Colors.transparent,
                                ],
                                stops: const [0.1, 1.0],
                              ),
                            ),
                          ),

                          // Rotating Ring
                          Transform.rotate(
                            angle: _rotationAnimation.value * 2 * pi,
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.primaryColor.withOpacity(0.5),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),

                          // Main Icon
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppTheme.primaryColor,
                                      AppTheme.lightGreen,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryColor.withOpacity(0.4),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.eco_rounded,
                                  size: 60,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // App Name with Staggered Animation
                      SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: ShaderMask(
                            shaderCallback: (Rect bounds) {
                              return LinearGradient(
                                colors: [
                                  AppTheme.primaryColor,
                                  AppTheme.lightGreen,
                                ],
                                stops: [0.3, 0.7],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ).createShader(bounds);
                            },
                            child: Text(
                              'Agriculture',
                              style: theme.textTheme.displayLarge?.copyWith(
                                fontSize: 42,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2.0,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Tagline
                      FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _animationController,
                          curve: const Interval(0.5, 1.0),
                        ),
                        child: Text(
                          'Smart Farming Solutions',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),

                      const SizedBox(height: 60),

                      // Loading Indicator
                      FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _animationController,
                          curve: const Interval(0.7, 1.0),
                        ),
                        child: Container(
                          width: 120,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 2000),
                            width: 120 * _animationController.value,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primaryColor,
                                  AppTheme.lightGreen,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Top Right Tech Icon
                Positioned(
                  top: 60,
                  right: 30,
                  child: FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _animationController,
                      curve: const Interval(0.8, 1.0),
                    ),
                    child: const Icon(
                      Icons.fingerprint_rounded,
                      size: 32,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),

                // Bottom Tech Icons
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _animationController,
                      curve: const Interval(0.9, 1.0),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildTechIcon(Icons.analytics_rounded),
                        const SizedBox(width: 20),
                        _buildTechIcon(Icons.eco_rounded),
                        const SizedBox(width: 20),
                        _buildTechIcon(Icons.cloud_rounded),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimatedBackground(Size size, bool isDarkMode) {
    return Stack(
      children: [
        // Animated Clouds
        Positioned(
          top: 80,
          left: -50 + (_animationController.value * 100),
          child: AnimatedCloud(
            animation: CurvedAnimation(
              parent: _animationController,
              curve: const Interval(0.0, 0.5),
            ),
            size: 80,
            color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
          ),
        ),

        Positioned(
          top: 120,
          right: -30 + (_animationController.value * 80),
          child: AnimatedCloud(
            animation: CurvedAnimation(
              parent: _animationController,
              curve: const Interval(0.2, 0.7),
            ),
            size: 100,
            color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400,
          ),
        ),

        // Animated Soil/Sun
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 2000),
            height: 200 * (0.5 + _animationController.value * 0.5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  isDarkMode ? const Color(0xFF3D2314) : const Color(0xFF8B4513),
                  isDarkMode ? const Color(0xFF2A1A0A) : const Color(0xFF654321),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(40),
                topRight: Radius.circular(40),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildParticles(Size size) {
    return _particles.map((particle) {
      return Positioned(
        left: particle.x,
        top: particle.y + (_animationController.value * 50 * particle.speed),
        child: Opacity(
          opacity: particle.alpha * (1 - _animationController.value),
          child: Container(
            width: particle.radius * 2,
            height: particle.radius * 2,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildTechIcon(IconData icon) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          size: 20,
          color: Colors.white.withOpacity(0.8),
        ),
      ),
    );
  }
}

class AnimatedCloud extends StatelessWidget {
  final Animation<double> animation;
  final double size;
  final Color color;

  const AnimatedCloud({
    super.key,
    required this.animation,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, (1 - animation.value) * 20),
            child: Icon(
              Icons.cloud_rounded,
              size: size,
              color: color,
            ),
          ),
        );
      },
    );
  }
}

class Particle {
  final double x;
  final double y;
  final double radius;
  final double speed;
  final double alpha;

  Particle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.alpha,
  });
}