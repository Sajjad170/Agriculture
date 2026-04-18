import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../models/user_profile.dart';
import '../models/crop.dart';
import '../screens/dashboard/market_tab.dart';
import '../screens/orders/orders_screen.dart';
import '../screens/tasks/tasks_screen.dart';
import '../theme/app_theme.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/dashboard/disease_detection_tab.dart';
import '../screens/treatments/treatment_shop_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/auth/login_screen.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> with SingleTickerProviderStateMixin {
  final UserProfileService _profileService = UserProfileService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  UserProfile? _userProfile;
  List<Crop> _userCrops = [];
  bool _isLoading = true;
  bool _isDisposed = false;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserData();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (_isDisposed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        final profile = await _profileService.getUserProfile(userId, context);
        if (profile != null && !_isDisposed) {
          final querySnapshot = await _firestore
              .collection('crops')
              .where('farm_id', isEqualTo: profile.farmId)
              .get();

          final crops = querySnapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Crop.fromJson(data);
          }).toList();

          if (!_isDisposed) {
            setState(() {
              _userProfile = profile;
              _userCrops = crops;
              _isLoading = false;
            });
          }
        } else if (!_isDisposed) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (!_isDisposed) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getCropsDescription() {
    if (_userCrops.isEmpty) {
      return 'No crops added yet';
    }

    final cropTypes = _userCrops.map((crop) => crop.type).toSet().toList();
    if (cropTypes.length <= 2) {
      return '${cropTypes.join(' & ')} Farmer';
    } else {
      return 'Mixed Crop Farmer';
    }
  }

  Widget _buildUserProfileHeader() {
    final theme = Theme.of(context);

    if (_isLoading) {
      return _buildShimmerHeader();
    }

    final profile = _userProfile;
    if (profile == null) {
      return _buildErrorHeader();
    }

    final nameInitials = _getNameInitials(profile.fullName);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: profile.profilePicture.isNotEmpty
                      ? Image.network(
                    profile.profilePicture,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildAvatarFallback(nameInitials);
                    },
                  )
                      : _buildAvatarFallback(nameInitials),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _getCropsDescription(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                _buildSubscriptionBadge(profile.subscription),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getNameInitials(String fullName) {
    if (fullName.isEmpty) return 'U';

    final words = fullName.trim().split(' ');
    if (words.isEmpty) return 'U';

    final initials = words
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word[0].toUpperCase())
        .join();

    return initials.isEmpty ? 'U' : initials;
  }

  Widget _buildAvatarFallback(String initials) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey.shade100,
          ],
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionBadge(String subscription) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_outlined,
            size: 14,
            color: Colors.white.withOpacity(0.9),
          ),
          const SizedBox(width: 6),
          Text(
            '$subscription Member',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey.shade300,
            Colors.grey.shade200,
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 80,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorHeader() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.error.withOpacity(0.8),
            theme.colorScheme.error.withOpacity(0.6),
          ],
        ),
      ),
      child: const Center(
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 40,
            ),
            SizedBox(height: 8),
            Text(
              'Profile Error',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      elevation: 0,
      child: Container(
        color: theme.colorScheme.background,
        child: Column(
          children: [
            // User Profile Header
            _buildUserProfileHeader(),

            // Navigation Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildNavigationSection(
                    title: 'MAIN',
                    items: [
                      _buildDrawerItem(
                        context,
                        icon: Icons.dashboard_rounded,
                        title: 'Dashboard',
                        description: 'Overview & analytics',
                        onTap: () => _navigateTo(const DashboardScreen(), true),
                      ),
                      _buildDrawerItem(
                        context,
                        icon: Icons.qr_code_scanner_rounded,
                        title: 'Disease Detection',
                        description: 'Scan & identify plant diseases',
                        onTap: () => _navigateTo(const DiseaseDetectionTab(), false),
                      ),
                      _buildDrawerItem(
                        context,
                        icon: Icons.medical_services_rounded,
                        title: 'Shop Treatments',
                        description: 'Purchase disease treatments',
                        onTap: () => _navigateTo(const TreatmentShopScreen(), false),
                      ),
                    ],
                  ),
                  _buildNavigationSection(
                    title: 'MANAGEMENT',
                    items: [
                      _buildDrawerItem(
                        context,
                        icon: Icons.task_alt_rounded,
                        title: 'My Tasks',
                        description: 'Manage farming tasks',
                        onTap: () => _navigateTo(const TasksScreen(), false),
                      ),
                      _buildDrawerItem(
                        context,
                        icon: Icons.shopping_cart_rounded,
                        title: 'My Orders',
                        description: 'View order history',
                        onTap: () => _navigateTo(const OrdersScreen(), false),
                      ),
                      _buildDrawerItem(
                        context,
                        icon: Icons.analytics_rounded,
                        title: 'Analytics',
                        description: 'Market insights & data',
                        onTap: () => _navigateTo(const MarketTab(), false),
                      ),
                    ],
                  ),
                  _buildNavigationSection(
                    title: 'SUPPORT',
                    items: [
                      _buildDrawerItem(
                        context,
                        icon: Icons.notifications_active_rounded,
                        title: 'Notifications',
                        description: 'Alerts & updates',
                        onTap: () => _navigateTo(const NotificationsScreen(), false),
                      ),
                      _buildDrawerItem(
                        context,
                        icon: Icons.help_center_rounded,
                        title: 'Help & Support',
                        description: 'Get assistance',
                        onTap: () {
                          Navigator.pop(context);
                          // Navigate to help screen
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildDrawerItem(
                    context,
                    icon: Icons.logout_rounded,
                    title: 'Logout',
                    description: 'Sign out of your account',
                    textColor: theme.colorScheme.error,
                    iconColor: theme.colorScheme.error,
                    backgroundColor: theme.colorScheme.error.withOpacity(0.1),
                    onTap: () => _showLogoutConfirmation(context),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),

            // App Version
            _buildAppVersion(),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationSection({
    required String title,
    required List<Widget> items,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Text(
            title,
            style: TextStyle(
              color: theme.colorScheme.onBackground.withOpacity(0.6),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...items,
      ],
    );
  }

  Widget _buildDrawerItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String description,
        required VoidCallback onTap,
        Color? textColor,
        Color? iconColor,
        Color? backgroundColor,
      }) {
    final theme = Theme.of(context);
    final isLogout = title == 'Logout';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: backgroundColor ?? Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: isLogout
              ? theme.colorScheme.error.withOpacity(0.1)
              : theme.colorScheme.primary.withOpacity(0.1),
          highlightColor: isLogout
              ? theme.colorScheme.error.withOpacity(0.05)
              : theme.colorScheme.primary.withOpacity(0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isLogout
                        ? theme.colorScheme.error.withOpacity(0.1)
                        : theme.colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: iconColor ?? (isLogout ? theme.colorScheme.error : theme.colorScheme.primary),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: textColor ?? theme.textTheme.bodyLarge!.color,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: TextStyle(
                          color: theme.textTheme.bodyMedium!.color!.withOpacity(0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.textTheme.bodyMedium!.color!.withOpacity(0.4),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppVersion() {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Divider(
            color: theme.dividerColor.withOpacity(0.3),
            height: 1,
          ),
          const SizedBox(height: 16),
          Text(
            'FarmAssist Pro v1.0.0',
            style: TextStyle(
              color: theme.textTheme.bodyMedium!.color!.withOpacity(0.5),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateTo(Widget screen, bool isReplacement) {
    Navigator.pop(context);
    if (isReplacement) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => screen),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => screen),
      );
    }
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Logout',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await AuthService().signOut(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
                    (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}