import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/crop.dart';
import '../widgets/notification_banner.dart';

class CropService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch all crops for a specific farm
  Future<List<Crop>> getCropsByFarm(String farmId, BuildContext context) async {
    try {
      final querySnapshot = await _firestore
          .collection('crops')
          .where('farm_id', isEqualTo: farmId)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Crop.fromJson(data);
      }).toList();
    } catch (error) {
      showNotificationBanner(context, 'Failed to fetch crops.');
      return [];
    }
  }

  // Add a new crop
  Future<void> addCrop(Crop crop, BuildContext context) async {
    try {
      await _firestore.collection('crops').add(crop.toJson());
      showNotificationBanner(context, 'Crop added successfully!', isSuccess: true);
    } catch (error) {
      showNotificationBanner(context, 'Failed to add crop.');
    }
  }

  // Update an existing crop
  Future<void> updateCrop(Crop crop, BuildContext context) async {
    try {
      await _firestore.collection('crops').doc(crop.id).update(crop.toJson());
      showNotificationBanner(context, 'Crop updated successfully!', isSuccess: true);
    } catch (error) {
      showNotificationBanner(context, 'Failed to update crop.');
    }
  }
}