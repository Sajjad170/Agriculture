import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/farm.dart';
import '../models/crop.dart';
import '../widgets/notification_banner.dart';

class ProfileSetupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<bool> completeProfile({
    required UserProfile userProfile,
    required Farm farm,
    required List<Crop> crops,
    required BuildContext context,
  }) async {
    try {
      print('PROFILE SETUP: Starting profile setup process');

      // Verify authentication status
      final user = _auth.currentUser;
      if (user == null) {
        print('ERROR: User not authenticated');
        showNotificationBanner(context, 'User not authenticated. Please log in again.');
        return false;
      }

      print('PROFILE SETUP: User authenticated as ${user.uid}');

      // Use a batch for atomic writes
      final batch = _firestore.batch();

      // STEP 1: Prepare Farm
      print('PROFILE SETUP: Preparing farm details');
      final farmRef = _firestore.collection('farms').doc(); // Auto-generated ID
      final farmId = farmRef.id;
      
      final farmData = Farm(
        id: farmId,
        name: farm.name,
        location: farm.location,
        totalArea: farm.totalArea,
        ownerId: user.uid,
      ).toJson();
      
      batch.set(farmRef, farmData);

      // STEP 2: Prepare User Profile
      print('PROFILE SETUP: Preparing user profile');
      final userProfileRef = _firestore.collection('user_profiles').doc(user.uid);
      
      final updatedUserProfile = UserProfile(
        id: user.uid,
        fullName: userProfile.fullName,
        email: userProfile.email,
        phone: userProfile.phone,
        profilePicture: userProfile.profilePicture,
        memberSince: userProfile.memberSince,
        subscription: userProfile.subscription,
        farmId: farmId,
      );

      batch.set(userProfileRef, updatedUserProfile.toJson());

      // STEP 3: Prepare Crops
      print('PROFILE SETUP: Preparing ${crops.length} crops');
      for (var crop in crops) {
        final cropRef = _firestore.collection('crops').doc();
        final cropData = Crop(
          id: cropRef.id,
          name: crop.name,
          farmId: farmId,
          type: crop.type,
        ).toJson();
        batch.set(cropRef, cropData);
      }

      // Commit the batch
      print('PROFILE SETUP: Committing batch write');
      await batch.commit();
      
      print('PROFILE SETUP: All details saved successfully');
      return true;
    } catch (error) {
      print('ERROR IN PROFILE SETUP: $error');
      showNotificationBanner(context, 'Profile setup failed. Please try again.');
      return false;
    }
  }
}