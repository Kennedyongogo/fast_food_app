class AppUser {
  final String id;
  final String name;
  final String email;
  final String role; // 'customer', 'owner', 'rider'
  final String? phone;
  final DateTime? createdAt;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.createdAt,
  });

  // Create from Firebase Firestore
  factory AppUser.fromFirestore(Map<String, dynamic> data, String documentId) {
    return AppUser(
      id: documentId,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'customer',
      phone: data['phone'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'phone': phone ?? '',
      'createdAt': createdAt ?? DateTime.now(),
    };
  }

  // Mock users for testing (keep for demo)
  static final List<AppUser> mockUsers = [
    AppUser(
      id: '1',
      name: 'John Customer',
      email: 'customer@test.com',
      role: 'customer',
      phone: '0712345678',
      createdAt: DateTime.now(),
    ),
    AppUser(
      id: '2',
      name: 'Restaurant Owner',
      email: 'owner@test.com',
      role: 'owner',
      phone: '0723456789',
      createdAt: DateTime.now(),
    ),
    AppUser(
      id: '3',
      name: 'Rider Michael',
      email: 'rider@test.com',
      role: 'rider',
      phone: '0734567890',
      createdAt: DateTime.now(),
    ),
  ];

  static AppUser? getUserByEmail(String email) {
    try {
      return mockUsers.firstWhere((user) => user.email == email);
    } catch (e) {
      return null;
    }
  }
}
