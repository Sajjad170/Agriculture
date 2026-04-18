import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../widgets/notification_banner.dart';
import '../screens/profile_onboarding_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  // Restore session when app starts
  Future<bool> restoreSession() async {
    return currentUser != null;
  }

  // Sign up with email and password
  Future<UserCredential?> signUp({
    required String email,
    required String password,
    required String name,
    required BuildContext context,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await credential.user?.updateDisplayName(name);

      showNotificationBanner(context, 'Account created! Please verify your email.', isSuccess: true);
      return credential;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(context, e);
      return null;
    } catch (e) {
      showNotificationBanner(context, 'An unexpected error occurred. Try again.');
      return null;
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signIn({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        showNotificationBanner(context, 'Invalid credentials. Try again.');
        return null;
      }

      showNotificationBanner(context, 'Login successful!', isSuccess: true);

      // Check if user profile exists in Firestore
      final hasProfile = await _checkUserProfile(credential.user!.uid);
      if (hasProfile) {
        // Navigate to Dashboard
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      } else {
        // Navigate to Profile Onboarding
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(context, e);
      return null;
    } catch (e) {
      showNotificationBanner(context, 'An unexpected error occurred. Try again.');
      return null;
    }
  }

  // Check if user has a profile in Firestore
  Future<bool> _checkUserProfile(String userId) async {
    final doc = await _firestore.collection('user_profiles').doc(userId).get();
    return doc.exists;
  }

  // Sign out
  Future<void> signOut(BuildContext context) async {
    await _auth.signOut();
    showNotificationBanner(context, 'Logged out successfully.', isSuccess: true);
  }

  // Handle specific authentication errors
  void _handleAuthError(BuildContext context, FirebaseAuthException e) {
    String message;

    switch (e.code) {
      case 'user-not-found':
        message = 'No user found for that email.';
        break;
      case 'wrong-password':
        message = 'Wrong password provided.';
        break;
      case 'email-already-in-use':
        message = 'The account already exists for that email.';
        break;
      case 'invalid-email':
        message = 'The email address is not valid.';
        break;
      case 'weak-password':
        message = 'The password is too weak.';
        break;
      default:
        message = e.message ?? 'Authentication failed. Try again.';
    }

    showNotificationBanner(context, message);
  }
}