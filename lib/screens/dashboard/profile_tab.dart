import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/user_profile.dart';
import '../../models/farm.dart';
import '../../models/crop.dart';
import '../../services/profile_service.dart';
import '../../services/farm_service.dart';
import '../../services/crop_service.dart';
import '../../services/cloudinary_service.dart';
import '../../widgets/notification_banner.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserProfileService _profileService = UserProfileService();
  final FarmService _farmService = FarmService();
  final CropService _cropService = CropService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final ImagePicker _imagePicker = ImagePicker();

  UserProfile? _profile;
  Farm? _farm;
  List<Crop> _crops = [];
  bool _loading = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      showNotificationBanner(context, 'Not authenticated');
      return;
    }

    final profile = await _profileService.getUserProfile(userId, context);
    Farm? farm;
    List<Crop> crops = [];

    if (profile != null) {
      farm = await _farmService.getFarm(profile.farmId, context);
      crops = await _cropService.getCropsByFarm(profile.farmId, context);
    }

    if (mounted) {
      setState(() {
        _profile = profile;
        _farm = farm;
        _crops = crops;
        _loading = false;
      });
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
      );

      if (image == null) return;

      setState(() => _isUploading = true);

      final imageFile = File(image.path);
      final imageUrl = await _cloudinaryService.uploadImage(imageFile, folder: 'profiles');

      if (imageUrl != null && _profile != null) {
        final updatedProfile = UserProfile(
          id: _profile!.id,
          fullName: _profile!.fullName,
          email: _profile!.email,
          phone: _profile!.phone,
          profilePicture: imageUrl,
          memberSince: _profile!.memberSince,
          subscription: _profile!.subscription,
          farmId: _profile!.farmId,
        );

        await _profileService.updateUserProfile(updatedProfile, context);

        if (mounted) {
          setState(() {
            _profile = updatedProfile;
            _isUploading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isUploading = false);
          showNotificationBanner(context, 'Failed to upload image');
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isUploading = false);
        showNotificationBanner(context, 'Failed to update profile picture');
      }
    }
  }

  void _showProfileEditSheet() {
    if (_profile == null) return;

    final fullNameController = TextEditingController(text: _profile!.fullName);
    final emailController = TextEditingController(text: _profile!.email);
    final phoneController = TextEditingController(text: _profile!.phone);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSheetHeader(context, 'Edit Profile'),
              const SizedBox(height: 24),
              _buildTextField(
                controller: fullNameController,
                label: 'Full Name',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: emailController,
                label: 'Email',
                icon: Icons.email_outlined,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: phoneController,
                label: 'Phone',
                icon: Icons.phone_outlined,
              ),
              const SizedBox(height: 20),
              _buildImageUploadOption(context),
              const SizedBox(height: 24),
              _buildActionButton(
                context: context,
                text: 'Save Changes',
                onPressed: () async {
                  final updatedProfile = UserProfile(
                    id: _profile!.id,
                    fullName: fullNameController.text,
                    email: emailController.text,
                    phone: phoneController.text,
                    profilePicture: _profile!.profilePicture,
                    memberSince: _profile!.memberSince,
                    subscription: _profile!.subscription,
                    farmId: _profile!.farmId,
                  );

                  await _profileService.updateUserProfile(updatedProfile, context);
                  if (mounted) {
                    Navigator.pop(context);
                    _loadData();
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showFarmEditSheet() {
    if (_farm == null) return;

    final nameController = TextEditingController(text: _farm!.name);
    final locationController = TextEditingController(text: _farm!.location);
    final areaController = TextEditingController(text: _farm!.totalArea);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSheetHeader(context, 'Edit Farm Details'),
              const SizedBox(height: 24),
              _buildTextField(
                controller: nameController,
                label: 'Farm Name',
                icon: Icons.agriculture_outlined,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: locationController,
                label: 'Location',
                icon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: areaController,
                label: 'Total Area',
                icon: Icons.square_foot_outlined,
              ),
              const SizedBox(height: 24),
              _buildActionButton(
                context: context,
                text: 'Save Changes',
                onPressed: () async {
                  final updatedFarm = Farm(
                    id: _farm!.id,
                    name: nameController.text,
                    location: locationController.text,
                    totalArea: areaController.text,
                    ownerId: _farm!.ownerId,
                  );

                  await _farmService.updateFarm(updatedFarm, context);
                  if (mounted) {
                    Navigator.pop(context);
                    _loadData();
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showCropManagementSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSheetHeader(context, 'Manage Crops'),
              const SizedBox(height: 24),
              Text(
                'Your Crops',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _crops.isEmpty
                    ? _buildEmptyState(
                  icon: Icons.agriculture_outlined,
                  title: 'No Crops Added',
                  subtitle: 'Add your first crop to get started',
                )
                    : ListView.separated(
                  itemCount: _crops.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final crop = _crops[index];
                    return _buildCropItem(crop);
                  },
                ),
              ),
              const SizedBox(height: 16),
              _buildActionButton(
                context: context,
                text: 'Add New Crop',
                onPressed: _showAddCropSheet,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCropItem(Crop crop) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.eco_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          crop.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text('Type: ${crop.type}'),
        trailing: IconButton(
          icon: Icon(Icons.edit_outlined, size: 20, color: Colors.grey.shade600),
          onPressed: () => _showEditCropSheet(crop),
        ),
      ),
    );
  }

  void _showEditCropSheet(Crop crop) {
    final nameController = TextEditingController(text: crop.name);
    final typeController = TextEditingController(text: crop.type);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSheetHeader(context, 'Edit Crop'),
              const SizedBox(height: 24),
              _buildTextField(
                controller: nameController,
                label: 'Crop Name',
                icon: Icons.eco_outlined,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: typeController,
                label: 'Crop Type',
                icon: Icons.category_outlined,
              ),
              const SizedBox(height: 24),
              _buildActionButton(
                context: context,
                text: 'Save Changes',
                onPressed: () async {
                  final updatedCrop = Crop(
                    id: crop.id,
                    name: nameController.text,
                    type: typeController.text,
                    farmId: crop.farmId,
                  );

                  await _cropService.updateCrop(updatedCrop, context);
                  if (mounted) {
                    Navigator.pop(context);
                    Navigator.pop(context);
                    _loadData();
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddCropSheet() {
    if (_profile == null || _profile!.farmId.isEmpty) return;

    final nameController = TextEditingController();
    final typeController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSheetHeader(context, 'Add New Crop'),
              const SizedBox(height: 24),
              _buildTextField(
                controller: nameController,
                label: 'Crop Name',
                icon: Icons.eco_outlined,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: typeController,
                label: 'Crop Type',
                icon: Icons.category_outlined,
              ),
              const SizedBox(height: 24),
              _buildActionButton(
                context: context,
                text: 'Add Crop',
                onPressed: () async {
                  final newCrop = Crop(
                    name: nameController.text,
                    type: typeController.text,
                    farmId: _profile!.farmId,
                  );

                  await _cropService.addCrop(newCrop, context);
                  if (mounted) {
                    Navigator.pop(context);
                    Navigator.pop(context);
                    _loadData();
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // Reusable UI Components
  Widget _buildSheetHeader(BuildContext context, String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
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
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
      ),
    );
  }

  Widget _buildImageUploadOption(BuildContext context) {
    return InkWell(
      onTap: _pickAndUploadImage,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(
              Icons.photo_camera_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Text(
              'Change Profile Picture',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String text,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_profile == null) {
      return _buildEmptyState(
        icon: Icons.error_outline,
        title: 'Profile Not Found',
        subtitle: 'Unable to load your profile information',
      );
    }

    return Scaffold(
      backgroundColor: colors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Profile'),
            centerTitle: true,
            backgroundColor: colors.background,
            elevation: 0,
            foregroundColor: colors.onBackground,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () {
                  // Navigate to settings
                },
              ),
            ],
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildProfileHeader(context),
                    const SizedBox(height: 32),
                    _buildFarmSection(context),
                    const SizedBox(height: 24),
                    _buildCropsSection(context),
                    const SizedBox(height: 24),
                    _buildAccountSection(context),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final initials = _profile!.fullName.isNotEmpty
        ? _profile!.fullName
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
        .join()
        .substring(0, min(2, _profile!.fullName.split(' ').where((e) => e.isNotEmpty).length))
        : 'U';

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.7),
                  ],
                ),
              ),
              child: _profile!.profilePicture.isNotEmpty
                  ? ClipOval(
                child: Image.network(
                  _profile!.profilePicture,
                  fit: BoxFit.cover,
                  width: 120,
                  height: 120,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                ),
              )
                  : Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            if (_isUploading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              ),
            Positioned(
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: _pickAndUploadImage,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          _profile!.fullName,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _crops.isNotEmpty
              ? '${_crops.map((e) => e.type).toSet().join(', ')} Farmer'
              : 'Farm Manager',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: 160,
          child: ElevatedButton(
            onPressed: _showProfileEditSheet,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.surface,
              foregroundColor: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.edit, size: 18),
                SizedBox(width: 8),
                Text('Edit Profile'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFarmSection(BuildContext context) {
    return _buildSection(
      context: context,
      title: 'Farm Information',
      icon: Icons.agriculture_outlined,
      children: [
        _buildInfoRow('Farm Name', _farm?.name ?? 'Not set'),
        _buildInfoRow('Location', _farm?.location ?? 'Not set'),
        _buildInfoRow('Total Area', _farm?.totalArea ?? 'Not set'),
        _buildInfoRow('Crops Count', _crops.length.toString()),
      ],
      onEdit: _farm != null ? _showFarmEditSheet : null,
    );
  }

  Widget _buildCropsSection(BuildContext context) {
    return _buildSection(
      context: context,
      title: 'Crops',
      icon: Icons.eco_outlined,
      children: _crops.isEmpty
          ? [
        _buildEmptyState(
          icon: Icons.agriculture_outlined,
          title: 'No Crops',
          subtitle: 'Add crops to manage your farm production',
        ),
      ]
          : _crops.take(3).map((crop) => _buildCropPreview(crop)).toList(),
      onEdit: _showCropManagementSheet,
      showViewAll: _crops.length > 3,
    );
  }

  Widget _buildAccountSection(BuildContext context) {
    return _buildSection(
      context: context,
      title: 'Account Information',
      icon: Icons.person_outline,
      children: [
        _buildInfoRow('Email', _profile!.email),
        _buildInfoRow('Phone', _profile!.phone),
        _buildInfoRow('Member Since', _profile!.memberSince.split('T').first),
        _buildInfoRow('Subscription', _profile!.subscription),
      ],
      onEdit: _showProfileEditSheet,
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Widget> children,
    VoidCallback? onEdit,
    bool showViewAll = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (onEdit != null)
                  InkWell(
                    onTap: onEdit,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        'Edit',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
            if (showViewAll)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: InkWell(
                  onTap: _showCropManagementSheet,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'View All Crops',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCropPreview(Crop crop) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.eco_outlined,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              crop.name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            crop.type,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  int min(int a, int b) => a < b ? a : b;
}