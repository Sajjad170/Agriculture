import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:country_picker/country_picker.dart';
import '../models/user_profile.dart';
import '../models/farm.dart';
import '../models/crop.dart';
import '../services/user_onboarding_service.dart';
import '../services/cloudinary_service.dart';
import '../widgets/notification_banner.dart';
import '../screens/dashboard/dashboard_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  // User Information
  final TextEditingController _phoneController = TextEditingController();
  String _profilePicture = '';
  File? _selectedImage;
  String _selectedCountryCode = '+1';
  String _selectedFlag = '🇺🇸';

  // User details from Auth
  String _userEmail = '';
  String _userName = '';

  // Farm Details
  final TextEditingController _farmNameController = TextEditingController();
  final TextEditingController _farmLocationController = TextEditingController();
  final TextEditingController _farmAreaController = TextEditingController();

  // Crop Details
  List<Map<String, String>> _crops = [];

  // Services
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CloudinaryService _cloudinaryService = CloudinaryService();

  // Animations
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _getUserDetails();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: Curves.easeInOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController!.forward();
  }

  // Fetch user details from Firebase Auth
  Future<void> _getUserDetails() async {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _userEmail = user.email ?? '';
        _userName = user.displayName ?? _userEmail.split('@').first;
      });
    }
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _phoneController.dispose();
    _farmNameController.dispose();
    _farmLocationController.dispose();
    _farmAreaController.dispose();
    super.dispose();
  }

  void _addCrop() {
    setState(() {
      _crops.add({'name': '', 'type': ''});
    });
  }

  void _removeCrop(int index) {
    setState(() {
      _crops.removeAt(index);
    });
  }

  // Select and Upload Image to Cloudinary
  Future<void> _pickAndUploadProfilePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile == null) return;

    final File file = File(pickedFile.path);

    try {
      if (_auth.currentUser == null) {
        showNotificationBanner(context, 'User not authenticated.');
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final String? imageUrl = await _cloudinaryService.uploadImage(file, folder: 'profile_pictures');

      if (mounted) Navigator.pop(context);

      if (imageUrl != null) {
        setState(() {
          _selectedImage = file;
          _profilePicture = imageUrl;
        });
        showNotificationBanner(context, 'Profile picture uploaded!', isSuccess: true);
      } else {
        showNotificationBanner(context, 'Failed to upload profile picture.');
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      showNotificationBanner(context, 'Error: ${e.toString()}');
    }
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = _auth.currentUser;
    if (user == null) {
      showNotificationBanner(context, 'User not authenticated. Please log in again.');
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final String fullPhoneNumber = '$_selectedCountryCode${_phoneController.text.trim()}';

      if (_farmNameController.text.trim().isEmpty || _farmLocationController.text.trim().isEmpty) {
        if (context.mounted) Navigator.pop(context);
        showNotificationBanner(context, 'Please fill in all farm details.');
        return;
      }

      if (_crops.isEmpty) {
        if (context.mounted) Navigator.pop(context);
        showNotificationBanner(context, 'Please add at least one crop.');
        return;
      }

      for (var crop in _crops) {
        final name = crop['name'];
        final type = crop['type'];

        if (name == null || name.isEmpty || type == null || type.isEmpty) {
          if (context.mounted) Navigator.pop(context);
          showNotificationBanner(context, 'Please fill in all crop details (name and type).');
          return;
        }
      }

      final farm = Farm(
        id: '',
        name: _farmNameController.text.trim(),
        location: _farmLocationController.text.trim(),
        totalArea: _farmAreaController.text.trim(),
        ownerId: user.uid,
      );

      final userProfile = UserProfile(
        id: user.uid,
        fullName: _userName,
        email: _userEmail,
        phone: fullPhoneNumber,
        profilePicture: _profilePicture,
        memberSince: DateTime.now().toIso8601String(),
        subscription: 'Free',
        farmId: '',
      );

      List<Crop> crops = _crops.map((crop) {
        return Crop(
          id: '',
          name: crop['name']!,
          farmId: '',
          type: crop['type']!,
        );
      }).toList();

      final success = await ProfileSetupService().completeProfile(
        userProfile: userProfile,
        farm: farm,
        crops: crops,
        context: context,
      );

      if (context.mounted) Navigator.pop(context);

      if (success) {
        showNotificationBanner(context, 'Profile setup completed!', isSuccess: true);
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const DashboardScreen(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          ),
        );
      } else {
        showNotificationBanner(context, 'Failed to save profile. Please try again.');
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      showNotificationBanner(context, 'Error: ${e.toString()}');
    }
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
        _animationController!.reset();
        _animationController!.forward();
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _animationController!.reset();
        _animationController!.forward();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_animationController == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Header with progress
              _buildHeader(colorScheme, textTheme),
              const SizedBox(height: 32),

              // Animated content
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: _buildStepContent(colorScheme, textTheme),
                ),
              ),

              // Navigation buttons
              _buildNavigationButtons(colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back button
        IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: Icon(Icons.arrow_back_ios_rounded, color: colorScheme.onSurface),
          style: IconButton.styleFrom(
            backgroundColor: Colors.grey.shade50,
            padding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 24),

        // Title and progress
        Text(
          'Complete Your Profile',
          style: textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tell us about yourself and your farm',
          style: textTheme.bodyLarge?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 32),

        // Progress indicator
        _buildProgressIndicator(colorScheme),
      ],
    );
  }

  Widget _buildProgressIndicator(ColorScheme colorScheme) {
    return Column(
      children: [
        // Progress bar
        Container(
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(2),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            width: MediaQuery.of(context).size.width * ((_currentStep + 1) / 3),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Step labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStepLabel(0, 'Personal', colorScheme),
            _buildStepLabel(1, 'Farm', colorScheme),
            _buildStepLabel(2, 'Crops', colorScheme),
          ],
        ),
      ],
    );
  }

  Widget _buildStepLabel(int step, String label, ColorScheme colorScheme) {
    bool isActive = _currentStep >= step;
    bool isCurrent = _currentStep == step;

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? colorScheme.primary : Colors.grey.shade300,
            shape: BoxShape.circle,
            border: isCurrent ? Border.all(color: colorScheme.primary, width: 3) : null,
          ),
          child: Center(
            child: Text(
              '${step + 1}',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? colorScheme.primary : Colors.grey.shade500,
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStepContent(ColorScheme colorScheme, TextTheme textTheme) {
    return AnimatedBuilder(
      animation: _animationController!,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation!,
          child: SlideTransition(
            position: _slideAnimation!,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  key: ValueKey(_currentStep),
                  children: [
                    if (_currentStep == 0) _buildPersonalStep(colorScheme),
                    if (_currentStep == 1) _buildFarmStep(colorScheme),
                    if (_currentStep == 2) _buildCropStep(colorScheme),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPersonalStep(ColorScheme colorScheme) {
    return Column(
      children: [
        // Profile picture section
        _buildProfilePictureSection(colorScheme),
        const SizedBox(height: 32),

        // User info section
        Column(
          children: [
            _buildReadOnlyField(
              label: 'Full Name',
              value: _userName,
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            _buildReadOnlyField(
              label: 'Email',
              value: _userEmail,
              icon: Icons.email_outlined,
            ),
            const SizedBox(height: 16),
            _buildPhoneField(colorScheme),
          ],
        ),
      ],
    );
  }

  Widget _buildProfilePictureSection(ColorScheme colorScheme) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.primary.withOpacity(0.2), width: 3),
              ),
              child: ClipOval(
                child: _selectedImage != null
                    ? Image.file(_selectedImage!, fit: BoxFit.cover)
                    : Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _pickAndUploadProfilePicture,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Add Profile Picture',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField({required String label, required String value, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade500, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneField(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phone Number',
          style: TextStyle(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Country code selector
            GestureDetector(
              onTap: () {
                showCountryPicker(
                  context: context,
                  showPhoneCode: true,
                  countryListTheme: CountryListThemeData(
                    borderRadius: BorderRadius.circular(16),
                    inputDecoration: InputDecoration(
                      hintText: 'Search...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  onSelect: (Country country) {
                    setState(() {
                      _selectedCountryCode = '+${country.phoneCode}';
                      _selectedFlag = country.flagEmoji;
                    });
                  },
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_selectedFlag, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(_selectedCountryCode),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_drop_down, color: Colors.grey.shade500),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Enter phone number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colorScheme.primary, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFarmStep(ColorScheme colorScheme) {
    return Column(
      children: [
        _buildFarmField(
          controller: _farmNameController,
          label: 'Farm Name',
          hint: 'Enter your farm name',
          icon: Icons.agriculture_outlined,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your farm name';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        _buildFarmField(
          controller: _farmLocationController,
          label: 'Location',
          hint: 'Enter farm location',
          icon: Icons.location_on_outlined,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your farm location';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        _buildFarmField(
          controller: _farmAreaController,
          label: 'Total Area (acres)',
          hint: 'Enter farm area',
          icon: Icons.square_foot,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your farm area';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildFarmField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.grey.shade500),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildCropStep(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Crops',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Add the crops you are currently growing',
          style: TextStyle(
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 24),
        ..._crops.asMap().entries.map((entry) {
          int index = entry.key;
          Map<String, String> crop = entry.value;

          return _buildCropField(index, crop, colorScheme);
        }).toList(),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _addCrop,
          icon: const Icon(Icons.add),
          label: const Text('Add Another Crop'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCropField(int index, Map<String, String> crop, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Crop #${index + 1}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (_crops.length > 1)
                IconButton(
                  onPressed: () => _removeCrop(index),
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: crop['name'],
            onChanged: (value) => _crops[index]['name'] = value,
            decoration: InputDecoration(
              labelText: 'Crop Name',
              hintText: 'e.g. Tomato, Corn',
              prefixIcon: const Icon(Icons.eco_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter crop name';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: crop['type'],
            onChanged: (value) => _crops[index]['type'] = value,
            decoration: InputDecoration(
              labelText: 'Crop Type',
              hintText: 'e.g. Vegetable, Cereal',
              prefixIcon: const Icon(Icons.category_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter crop type';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Previous'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _currentStep < 2 ? _nextStep : _submitProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                _currentStep < 2 ? 'Continue' : 'Finish Setup',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}