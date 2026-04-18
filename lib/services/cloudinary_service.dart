import 'dart:io';
import 'package:cloudinary_sdk/cloudinary_sdk.dart';

class CloudinaryService {
  final Cloudinary _cloudinary;

  CloudinaryService()
      : _cloudinary = Cloudinary.full(
          apiKey: '234283582753374',
          apiSecret: 'g2nI2R_Ai4CVg25drkHoaCXFlWQ',
          cloudName: 'dfbyxmk6f',
        );

  /// Uploads an image to Cloudinary and returns the secure URL.
  Future<String?> uploadImage(File imageFile, {String folder = 'profiles'}) async {
    try {
      final response = await _cloudinary.uploadResource(
        CloudinaryUploadResource(
          filePath: imageFile.path,
          folder: folder,
          resourceType: CloudinaryResourceType.image,
        ),
      );

      if (response.isSuccessful) {
        return response.secureUrl;
      } else {
        print('Cloudinary upload failed: ${response.error}');
        return null;
      }
    } catch (e) {
      print('Cloudinary upload error: $e');
      return null;
    }
  }

  /// Uploads an image from bytes (if needed).
  Future<String?> uploadImageFromBytes(List<int> bytes, {String folder = 'profiles', String fileName = 'upload.jpg'}) async {
    try {
      // cloudinary_sdk might have different way for bytes, but usually it supports it
      // If not supported directly, we can write to a temp file
      final response = await _cloudinary.uploadResource(
        CloudinaryUploadResource(
          fileBytes: bytes,
          fileName: fileName,
          folder: folder,
          resourceType: CloudinaryResourceType.image,
        ),
      );

      if (response.isSuccessful) {
        return response.secureUrl;
      } else {
        print('Cloudinary upload failed: ${response.error}');
        return null;
      }
    } catch (e) {
      print('Cloudinary upload error: $e');
      return null;
    }
  }
}
