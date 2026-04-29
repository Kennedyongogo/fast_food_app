import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/menu_item.dart';

class MenuService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static const String _collection = 'menu_items';

  // Get all menu items in real-time
  static Stream<List<MenuItem>> getMenuItems() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return MenuItem.fromFirestore(doc.data(), doc.id);
          }).toList();
        });
  }

  // Upload image to Firebase Storage
  static Future<String> uploadImage(File imageFile, String fileName) async {
    try {
      print('📸 Starting image upload...');
      print('📸 File path: ${imageFile.path}');
      print('📸 File size: ${await imageFile.length()} bytes');

      final ref = _storage.ref().child('menu_images/$fileName');

      // Add metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedAt': DateTime.now().toString(),
          'fileName': fileName,
        },
      );

      print('📸 Uploading to Firebase Storage...');
      final uploadTask = await ref.putFile(imageFile, metadata);
      print('📸 Upload complete!');

      final imageUrl = await uploadTask.ref.getDownloadURL();
      print('📸 Download URL: $imageUrl');

      return imageUrl;
    } on FirebaseException catch (e) {
      print('❌ Firebase Storage error: ${e.code} - ${e.message}');
      return '';
    } catch (e) {
      print('❌ Image upload error: $e');
      return '';
    }
  }

  // Add menu item to Firestore
  static Future<void> addMenuItem(MenuItem item) async {
    try {
      print('📝 Adding menu item to Firestore...');
      await _firestore
          .collection(_collection)
          .doc(item.id)
          .set(item.toFirestore());
      print('✅ Menu item added successfully!');
    } catch (e) {
      print('❌ Error adding menu item: $e');
      rethrow;
    }
  }

  // Update menu item
  static Future<void> updateMenuItem(MenuItem item) async {
    try {
      print('📝 Updating menu item in Firestore...');
      await _firestore
          .collection(_collection)
          .doc(item.id)
          .update(item.toFirestore());
      print('✅ Menu item updated successfully!');
    } catch (e) {
      print('❌ Error updating menu item: $e');
      rethrow;
    }
  }

  // Delete menu item
  static Future<void> deleteMenuItem(String id) async {
    try {
      print('🗑️ Deleting menu item...');
      await _firestore.collection(_collection).doc(id).delete();
      print('✅ Menu item deleted successfully!');
    } catch (e) {
      print('❌ Error deleting menu item: $e');
      rethrow;
    }
  }

  // Toggle availability
  static Future<void> toggleAvailability(String id, bool available) async {
    try {
      print('🔄 Toggling availability to: $available');
      await _firestore.collection(_collection).doc(id).update({
        'available': available,
      });
      print('✅ Availability toggled successfully!');
    } catch (e) {
      print('❌ Error toggling availability: $e');
      rethrow;
    }
  }
}
