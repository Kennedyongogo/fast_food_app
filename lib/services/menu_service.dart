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

  // Add new menu item with image
  static Future<String> uploadImage(File imageFile, String fileName) async {
    try {
      final ref = _storage.ref().child('menu_images/$fileName');
      final uploadTask = await ref.putFile(imageFile);
      final imageUrl = await uploadTask.ref.getDownloadURL();
      return imageUrl;
    } catch (e) {
      print('Image upload error: $e');
      return '';
    }
  }

  // Add menu item to Firestore
  static Future<void> addMenuItem(MenuItem item) async {
    await _firestore
        .collection(_collection)
        .doc(item.id)
        .set(item.toFirestore());
  }

  // Update menu item
  static Future<void> updateMenuItem(MenuItem item) async {
    await _firestore
        .collection(_collection)
        .doc(item.id)
        .update(item.toFirestore());
  }

  // Delete menu item
  static Future<void> deleteMenuItem(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  // Toggle availability
  static Future<void> toggleAvailability(String id, bool available) async {
    await _firestore.collection(_collection).doc(id).update({
      'available': available,
    });
  }
}
