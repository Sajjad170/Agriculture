import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import '../../services/profile_service.dart';
import '../../services/farm_service.dart';
import '../../services/weather_service.dart';
import '../../models/farm.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/weather_card.dart';
import '../notifications/notifications_screen.dart';
import 'home/farm_health.dart';
import 'farm_details_screen.dart';
import 'market_tab.dart';
import '../../services/commodities_service.dart';
import '../../services/task_notification_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_profile.dart';
import 'home/price_card.dart';
import 'home/upcoming_tasks.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with SingleTickerProviderStateMixin {
  // Initialize Services
  final CommoditiesService _commoditiesService = CommoditiesService();
  final NotificationService _notificationService = NotificationService();
  final UserProfileService _profileService = UserProfileService();
  final AuthService _authService = AuthService();
  final FarmService _farmService = FarmService();
  final WeatherService _weatherService = WeatherService();

  // User profile and farm
  UserProfile? _userProfile;
  Farm? _farm;

  // Weather data
  WeatherData? _weatherData;
  bool _isLoadingWeather = true;

  // Keep track of subscriptions to cancel them when widget is disposed
  final List<StreamSubscription> _subscriptions = [];

  // Store crop data
  final Map<String, CropPriceData> _cropData = {};

  // Selected crops to display
  final List<String> _selectedCrops = ['Corn', 'Wheat', 'Soybean'];

  // Farm location
  LatLng _farmLocation = const LatLng(37.7749, -122.4194);

  // Animation Controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _initializeAnimations();

    // Subscribe to price streams for selected crops
    for (final crop in _selectedCrops) {
      _subscribeToPrice(crop);
    }

    // Initialize notification service
    _notificationService.initialize();

    // Load user profile and weather data
    _loadUserProfile();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _slideAnimation = Tween<double>(begin: 0.3, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _colorAnimation = ColorTween(
      begin: Colors.green.shade50,
      end: Colors.transparent,
    ).animate(_animationController);

    _animationController.forward();
  }

  // Load user profile
  Future<void> _loadUserProfile() async {
    final userId = _authService.currentUser?.uid;
    if (userId != null) {
      final profile = await _profileService.getUserProfile(userId, context);
      if (mounted) {
        setState(() {
          _userProfile = profile;
        });

        // After loading profile, load farm data
        if (profile != null && profile.farmId.isNotEmpty) {
          await _loadFarmData(profile.farmId);
        }
      }
    }
  }

  // Load farm data
  Future<void> _loadFarmData(String farmId) async {
    final farm = await _farmService.getFarm(farmId, context);
    if (farm != null && mounted) {
      setState(() {
        _farm = farm;
      });

      // After loading farm data, load weather data
      await _loadWeatherData(farm);
    }
  }

  // Load weather data
  Future<void> _loadWeatherData(Farm farm) async {
    setState(() {
      _isLoadingWeather = true;
    });

    try {
      // Resolve farm location coordinates
      final (lat, lon) = await _weatherService.resolveLocationCoordinates(farm, context);

      // Update farm location for map
      setState(() {
        _farmLocation = LatLng(lat, lon);
      });

      // Get current weather data
      final weatherData = await _weatherService.getCurrentWeather(lat, lon, farm.location);

      if (mounted) {
        setState(() {
          _weatherData = weatherData;
          _isLoadingWeather = false;
        });
      }
    } catch (e) {
      print('Error loading weather data: $e');
      if (mounted) {
        setState(() {
          _isLoadingWeather = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // Cancel all subscriptions
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();

    // Dispose animation controller
    _animationController.dispose();

    // Dispose commodities service
    _commoditiesService.dispose();
    super.dispose();
  }

  // Subscribe to price stream for a crop
  void _subscribeToPrice(String crop) {
    final subscription = _commoditiesService
        .getPriceStream(crop)
        .listen((data) {
      setState(() {
        _cropData[crop] = data;
      });
    });

    _subscriptions.add(subscription);
  }

  // Get user initials for avatar fallback
  String _getUserInitials() {
    if (_userProfile == null || _userProfile!.fullName.isEmpty) {
      return 'VP'; // Default fallback
    }

    final nameParts = _userProfile!.fullName.split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}';
    } else if (nameParts.isNotEmpty) {
      return nameParts[0][0];
    }

    return 'VP';
  }

  void _navigateToFarmDetails() {
    final farmId = _userProfile?.farmId;

    if (farmId == null || farmId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No farm associated with this account')),
      );
      return;
    }

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => FarmDetailsScreen(farmId: farmId),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      drawer: const AppDrawer(),
      body: Builder(
        builder: (context) => AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.green.shade50.withOpacity(0.3),
                    Colors.white.withOpacity(0.1),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.3, 1.0],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // Premium AppBar with Glass Morphism
                    _buildPremiumAppBar(context, isDarkMode),

                    // Main Content Area with Smooth Animations
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Weather Card with Fade Animation
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: Transform.translate(
                                offset: Offset(0, _slideAnimation.value * 20),
                                child: _weatherData != null
                                    ? WeatherCard(
                                  temperature: _weatherData!.temperature,
                                  condition: _weatherData!.condition,
                                  location: _weatherData!.location,
                                  humidity: _weatherData!.humidity,
                                  windSpeed: _weatherData!.windSpeed,
                                  uvIndex: _weatherData!.uvIndex,
                                  isLoading: _isLoadingWeather,
                                )
                                    : WeatherCard(
                                  isLoading: _isLoadingWeather,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Farm Health Overview with Staggered Animation
                            FadeTransition(
                              opacity: CurvedAnimation(
                                parent: _animationController,
                                curve: const Interval(0.2, 0.8),
                              ),
                              child: Transform.translate(
                                offset: Offset(0, _slideAnimation.value * 15),
                                child: FarmHealthWidget(
                                  onViewMoreTap: _navigateToFarmDetails,
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Upcoming Tasks with Staggered Animation
                            FadeTransition(
                              opacity: CurvedAnimation(
                                parent: _animationController,
                                curve: const Interval(0.3, 0.9),
                              ),
                              child: Transform.translate(
                                offset: Offset(0, _slideAnimation.value * 10),
                                child: const UpcomingTasksWidget(),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Market Prices with Staggered Animation
                            FadeTransition(
                              opacity: CurvedAnimation(
                                parent: _animationController,
                                curve: const Interval(0.4, 1.0),
                              ),
                              child: Transform.translate(
                                offset: Offset(0, _slideAnimation.value * 5),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildMarketPricesHeader(context),
                                    const SizedBox(height: 12),
                                    _buildMarketPrices(),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Premium AppBar with Glass Morphism Effect
  Widget _buildPremiumAppBar(BuildContext context, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade100.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: Colors.green.shade100.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Menu Icon with Premium Design
          _buildPremiumIconButton(
            icon: Icons.menu_rounded,
            color: Colors.green.shade700,
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),

          // App Title with Gradient
          ShaderMask(
            shaderCallback: (bounds) {
              return LinearGradient(
                colors: [
                  Colors.green.shade700,
                  Colors.green.shade500,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ).createShader(bounds);
            },
            child: const Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),

          // Notification & Profile with Premium Icons
          Row(
            children: [
              _buildNotificationButton(),
              const SizedBox(width: 12),
              _buildPremiumProfileAvatar(),
            ],
          ),
        ],
      ),
    );
  }

  // Premium Icon Button with Smooth Animation
  Widget _buildPremiumIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: IconButton(
        icon: Icon(icon, size: 22),
        color: color,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  // Premium Notification Button with Badge
  Widget _buildNotificationButton() {
    return ValueListenableBuilder<List<NotificationItem>>(
      valueListenable: _notificationService.notificationsNotifier,
      builder: (context, notifications, _) {
        final unreadCount = _notificationService.unreadCount;

        return Stack(
          children: [
            _buildPremiumIconButton(
              icon: Icons.notifications_outlined,
              color: Colors.green.shade700,
              onPressed: () async {
                await Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => const NotificationsScreen(),
                    transitionsBuilder: (_, animation, __, child) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(1, 0),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeInOut,
                        )),
                        child: child,
                      );
                    },
                  ),
                );
                setState(() {});
              },
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.red.shade500,
                        Colors.red.shade400,
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.shade300.withOpacity(0.5),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // Premium Profile Avatar with Animation
  Widget _buildPremiumProfileAvatar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Colors.green.shade500,
            Colors.green.shade400,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade300.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.8),
          width: 2,
        ),
      ),
      child: _userProfile?.profilePicture.isNotEmpty == true
          ? CircleAvatar(
        radius: 20,
        backgroundImage: NetworkImage(_userProfile!.profilePicture),
      )
          : CircleAvatar(
        radius: 20,
        backgroundColor: Colors.transparent,
        child: Text(
          _getUserInitials(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // Build Market Prices Header with Premium Design
  Widget _buildMarketPricesHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ShaderMask(
            shaderCallback: (bounds) {
              return LinearGradient(
                colors: [
                  Colors.green.shade800,
                  Colors.green.shade600,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ).createShader(bounds);
            },
            child: Text(
              'Market Prices',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.shade500,
                  Colors.green.shade400,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.shade300.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const MarketTab(),
                      transitionsBuilder: (_, animation, __, child) {
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(1, 0),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeInOut,
                          )),
                          child: child,
                        );
                      },
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build Market Prices with Horizontal Scroll
  Widget _buildMarketPrices() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _selectedCrops.asMap().entries.map((entry) {
          final index = entry.key;
          final crop = entry.value;
          final cropData = _cropData[crop];

          return Padding(
            padding: EdgeInsets.only(
              right: 12,
              left: index == 0 ? 0 : 0,
            ),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300 + (index * 100)),
              curve: Curves.easeOutCubic,
              child: cropData == null
                  ? LoadingMarketPriceCard(cropName: crop)
                  : MarketPriceCard(data: cropData),
            ),
          );
        }).toList(),
      ),
    );
  }
}