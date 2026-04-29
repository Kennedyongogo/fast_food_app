import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // UPDATE: Using your computer's IP address from ipconfig (192.168.1.116)
  static const String baseUrl = 'http://192.168.1.116:4000/api';

  // Make sure your phone and computer are on the same Wi-Fi network!
  // Your backend must be running on port 4000

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Register user (Customer, Rider, or Owner)
  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    String? role,
  }) async {
    try {
      print('📡 Registering user to: $baseUrl/users/register');
      final response = await http.post(
        Uri.parse('$baseUrl/users/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'full_name': fullName,
          'email': email,
          'password': password,
          'phone': phone,
          'role': role ?? 'customer',
        }),
      );
      print('📡 Response status: ${response.statusCode}');
      return json.decode(response.body);
    } catch (e) {
      print('❌ Register error: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Setup owner account (one-time only)
  static Future<Map<String, dynamic>> setupOwner({
    required String fullName,
    required String email,
    required String password,
    required String phone,
  }) async {
    try {
      print('📡 Setting up owner account to: $baseUrl/users/setup-owner');
      final response = await http.post(
        Uri.parse('$baseUrl/users/setup-owner'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'full_name': fullName,
          'email': email,
          'password': password,
          'phone': phone,
        }),
      );
      print('📡 Response status: ${response.statusCode}');
      return json.decode(response.body);
    } catch (e) {
      print('❌ Setup owner error: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Login user
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      print('📡 Logging in to: $baseUrl/users/login');
      final response = await http.post(
        Uri.parse('$baseUrl/users/login'),
        headers: {'Content-Type': 'application/json'}, // ✅ FIXED: added quotes
        body: json.encode({'email': email, 'password': password}),
      );
      print('📡 Response status: ${response.statusCode}');

      final data = json.decode(response.body);
      final payload = data['data'] is Map<String, dynamic>
          ? data['data'] as Map<String, dynamic>
          : <String, dynamic>{};
      final token = data['token'] ?? payload['token'];
      final user = data['user'] ?? payload['user'];

      if (response.statusCode == 200 && token != null && user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        await prefs.setString('user_id', user['id']);
        await prefs.setString('user_role', user['role']);
        // Also store owner_exists flag if owner
        if (user['role'] == 'owner') {
          await prefs.setBool('owner_exists', true);
        }
      }

      return data;
    } catch (e) {
      print('❌ Login error: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    await prefs.remove('user_role');
  }

  // Get current user (using /users/:id endpoint)
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    final token = prefs.getString('auth_token');

    if (token == null || userId == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('❌ Get current user error: $e');
      return null;
    }
  }

  static Future<bool> ownerExists() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/owner-exists'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final payload = data['data'] is Map<String, dynamic>
            ? data['data'] as Map<String, dynamic>
            : <String, dynamic>{};
        return payload['exists'] == true;
      }
      return false;
    } catch (e) {
      print('❌ Owner exists check error: $e');
      return false;
    }
  }

  // Get dashboard stats (for owner/staff)
  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/dashboard/stats'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'success': false, 'message': 'Failed to load stats'};
    } catch (e) {
      print('❌ Dashboard stats error: $e');
      return {'success': false, 'message': 'Network error'};
    }
  }

  // Get all users (for owner/staff)
  static Future<List<dynamic>> getAllUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? data['users'] ?? [];
      }
      return [];
    } catch (e) {
      print('❌ Get all users error: $e');
      return [];
    }
  }

  // Get menu items
  static Future<List<dynamic>> getMenuItems({
    String? category,
    bool availableOnly = true,
    bool featuredOnly = false,
  }) async {
    try {
      final query = <String, String>{
        'availableOnly': availableOnly.toString(),
        'featuredOnly': featuredOnly.toString(),
      };
      if (category != null && category.isNotEmpty && category != 'All') {
        query['category'] = category;
      }
      final response = await http.get(
        Uri.parse('$baseUrl/menu').replace(queryParameters: query),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) return data;
        return data['data'] ?? [];
      }
    } catch (e) {
      print('Get menu items error: $e');
    }
    return [];
  }

  // Add menu item (Owner/Staff)
  static Future<Map<String, dynamic>> addMenuItem({
    required String name,
    required double price,
    required String description,
    required String category,
    bool available = true,
    bool isFeatured = false,
    int preparationTime = 15,
    int? calories,
    String? imagePath,
  }) async {
    try {
      final token = await _getToken();
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/menu'));
      request.fields.addAll({
        'name': name,
        'price': price.toString(),
        'description': description,
        'category': category,
        'available': available.toString(),
        'is_featured': isFeatured.toString(),
        'preparation_time': preparationTime.toString(),
      });
      if (calories != null) request.fields['calories'] = calories.toString();
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      if (imagePath != null && imagePath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath('image', imagePath));
      }
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      return json.decode(response.body);
    } catch (e) {
      print('❌ Add menu item error: $e');
      return {'success': false, 'message': 'Network error'};
    }
  }

  static Future<Map<String, dynamic>> updateMenuItem({
    required String id,
    String? name,
    double? price,
    String? description,
    String? category,
    bool? available,
    bool? isFeatured,
    int? preparationTime,
    int? calories,
    String? imagePath,
  }) async {
    try {
      final token = await _getToken();
      final request = http.MultipartRequest('PUT', Uri.parse('$baseUrl/menu/$id'));
      if (name != null) request.fields['name'] = name;
      if (price != null) request.fields['price'] = price.toString();
      if (description != null) request.fields['description'] = description;
      if (category != null) request.fields['category'] = category;
      if (available != null) request.fields['available'] = available.toString();
      if (isFeatured != null) {
        request.fields['is_featured'] = isFeatured.toString();
      }
      if (preparationTime != null) {
        request.fields['preparation_time'] = preparationTime.toString();
      }
      if (calories != null) request.fields['calories'] = calories.toString();
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      if (imagePath != null && imagePath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath('image', imagePath));
      }
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      return json.decode(response.body);
    } catch (e) {
      print('❌ Update menu item error: $e');
      return {'success': false, 'message': 'Network error'};
    }
  }

  static Future<Map<String, dynamic>> deleteMenuItem(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/menu/$id'),
        headers: await _getHeaders(),
      );
      return json.decode(response.body);
    } catch (e) {
      print('❌ Delete menu item error: $e');
      return {'success': false, 'message': 'Network error'};
    }
  }

  static Future<Map<String, dynamic>> toggleMenuAvailability(String id) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/menu/$id/toggle-availability'),
        headers: await _getHeaders(),
      );
      return json.decode(response.body);
    } catch (e) {
      print('❌ Toggle menu item availability error: $e');
      return {'success': false, 'message': 'Network error'};
    }
  }

  // Place order (you'll need to add this endpoint to your backend)
  static Future<Map<String, dynamic>> placeOrder({
    required List<Map<String, dynamic>> items,
    required double total,
    required String deliveryAddress,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: await _getHeaders(),
        body: json.encode({
          'items': items,
          'total': total,
          'delivery_address': deliveryAddress,
          'latitude': latitude,
          'longitude': longitude,
        }),
      );
      return json.decode(response.body);
    } catch (e) {
      print('❌ Place order error: $e');
      return {'success': false, 'message': 'Network error'};
    }
  }

  // Get orders (you'll need to add this endpoint to your backend)
  static Future<List<dynamic>> getOrders() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      print('❌ Get orders error: $e');
      return [];
    }
  }

  // Update order status (you'll need to add this endpoint to your backend)
  static Future<Map<String, dynamic>> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/orders/$orderId/status'),
        headers: await _getHeaders(),
        body: json.encode({'status': status}),
      );
      return json.decode(response.body);
    } catch (e) {
      print('❌ Update order status error: $e');
      return {'success': false, 'message': 'Network error'};
    }
  }

  // Get staff list (Owner only)
  static Future<List<dynamic>> getStaff() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final users = data['data'] ?? data['users'] ?? [];
        return users.where((user) => user['role'] == 'staff').toList();
      }
      return [];
    } catch (e) {
      print('❌ Get staff error: $e');
      return [];
    }
  }

  // Create staff (Owner only)
  static Future<Map<String, dynamic>> createStaff({
    required String fullName,
    required String email,
    required String password,
    required String phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/staff'),
        headers: await _getHeaders(),
        body: json.encode({
          'full_name': fullName,
          'email': email,
          'password': password,
          'phone': phone,
        }),
      );
      return json.decode(response.body);
    } catch (e) {
      print('❌ Create staff error: $e');
      return {'success': false, 'message': 'Network error'};
    }
  }

  // Delete user (staff)
  static Future<Map<String, dynamic>> deleteStaff(String staffId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/users/$staffId'),
        headers: await _getHeaders(),
      );
      return json.decode(response.body);
    } catch (e) {
      print('❌ Delete staff error: $e');
      return {'success': false, 'message': 'Network error'};
    }
  }

  // Update user profile
  static Future<Map<String, dynamic>> updateProfile({
    required String userId,
    String? name,
    String? phone,
    String? profileImage,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId'),
        headers: await _getHeaders(),
        body: json.encode({
          if (name != null) 'full_name': name,
          if (phone != null) 'phone': phone,
          if (profileImage != null) 'profile_image': profileImage,
        }),
      );
      return json.decode(response.body);
    } catch (e) {
      print('❌ Update profile error: $e');
      return {'success': false, 'message': 'Network error'};
    }
  }

  // Change password
  static Future<Map<String, dynamic>> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId/password'),
        headers: await _getHeaders(),
        body: json.encode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );
      return json.decode(response.body);
    } catch (e) {
      print('❌ Change password error: $e');
      return {'success': false, 'message': 'Network error'};
    }
  }
}
