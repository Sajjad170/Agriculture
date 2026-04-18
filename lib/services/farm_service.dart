import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/farm.dart';
import '../widgets/notification_banner.dart';

class FarmService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch farm by farm ID
  Future<Farm?> getFarm(String farmId, BuildContext context) async {
    try {
      final doc = await _firestore.collection('farms').doc(farmId).get();
      if (!doc.exists) return null;
      
      final data = doc.data()!;
      data['id'] = doc.id; // Ensure ID is included
      return Farm.fromJson(data);
    } catch (error) {
      print('Error fetching farm: $error');
      return null;
    }
  }

  // Create a new farm
  Future<String?> createFarm(Farm farm, BuildContext context) async {
    try {
      final docRef = await _firestore.collection('farms').add(farm.toJson());
      showNotificationBanner(context, 'Farm created successfully!', isSuccess: true);
      return docRef.id;
    } catch (error) {
      showNotificationBanner(context, 'Failed to create farm.');
      return null;
    }
  }

  // Update an existing farm
  Future<void> updateFarm(Farm farm, BuildContext context) async {
    try {
      await _firestore.collection('farms').doc(farm.id).update(farm.toJson());
      showNotificationBanner(context, 'Farm updated successfully!', isSuccess: true);
    } catch (error) {
      showNotificationBanner(context, 'Failed to update farm.');
    }
  }

  // Fetch farms by owner ID
  Future<List<Farm>> getFarmsByOwnerId(String ownerId, BuildContext context) async {
    try {
      final querySnapshot = await _firestore
          .collection('farms')
          .where('owner_id', isEqualTo: ownerId)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Farm.fromJson(data);
      }).toList();
    } catch (error) {
      print('Error fetching farms by owner: $error');
      showNotificationBanner(context, 'Failed to fetch farms.');
      return [];
    }
  }
}