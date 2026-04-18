import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../widgets/notification_banner.dart';

class UserProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch user profile by user ID
  Future<UserProfile?> getUserProfile(String userId, BuildContext context) async {
    try {
      print('🔍 Fetching user profile for: $userId');

      final doc = await _firestore.collection('user_profiles').doc(userId).get();

      if (!doc.exists) {
        print('ℹ️  No profile found for user: $userId');
        return null;
      }

      print('✅ Profile fetched successfully');
      return UserProfile.fromJson(doc.data()!);
    } catch (error) {
      print('❌ Error fetching user profile: $error');
      showNotificationBanner(context, 'Failed to fetch profile.');
      return null;
    }
  }

  // Create a new user profile
  Future<void> createUserProfile(UserProfile profile, BuildContext context) async {
    try {
      print('👤 Creating new user profile for: ${profile.id}');

      await _firestore.collection('user_profiles').doc(profile.id).set(profile.toJson());

      print('✅ Profile created successfully');
      showNotificationBanner(context, 'Profile created successfully!', isSuccess: true);
    } catch (error) {
      print('❌ Error creating user profile: $error');
      showNotificationBanner(context, 'Failed to create profile.');
    }
  }

  // Update existing user profile
  Future<void> updateUserProfile(UserProfile profile, BuildContext context) async {
    try {
      print('✏️ Updating user profile for: ${profile.id}');

      await _firestore.collection('user_profiles').doc(profile.id).update(profile.toJson());

      print('✅ Profile updated successfully');
      showNotificationBanner(context, 'Profile updated successfully!', isSuccess: true);
    } catch (error) {
      print('❌ Error updating user profile: $error');
      showNotificationBanner(context, 'Failed to update profile.');
    }
  }
}