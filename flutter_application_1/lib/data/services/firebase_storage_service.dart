import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  static const String profileImagesPath = 'profile_images';

  /// Upload profile image
  Future<String> uploadProfileImage({
    required File imageFile,
    required String userEmail,
  }) async {
    try {
      // Create file name with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${userEmail}_$timestamp';
      
      final ref = _storage.ref('$profileImagesPath/$fileName');
      
      // Upload file
      await ref.putFile(imageFile);
      
      // Get download URL
      final downloadUrl = await ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw 'Erreur lors de l\'upload de l\'image: $e';
    }
  }

  /// Delete profile image
  Future<void> deleteProfileImage(String imageUrl) async {
    try {
      // Extract file name from URL and delete
      final ref = FirebaseStorage.instance.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      throw 'Erreur lors de la suppression de l\'image: $e';
    }
  }

  /// Upload multiple images
  Future<List<String>> uploadMultipleImages({
    required List<File> imageFiles,
    required String userEmail,
  }) async {
    try {
      final urls = <String>[];
      
      for (final file in imageFiles) {
        final url = await uploadProfileImage(
          imageFile: file,
          userEmail: userEmail,
        );
        urls.add(url);
      }
      
      return urls;
    } catch (e) {
      throw 'Erreur lors de l\'upload des images: $e';
    }
  }
}
