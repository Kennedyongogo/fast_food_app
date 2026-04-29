import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';
import '../screens/login_screen.dart';

class RiderTasks extends StatefulWidget {
  final AppUser user;
  const RiderTasks({super.key, required this.user});

  @override
  State<RiderTasks> createState() => _RiderTasksState();
}

class _RiderTasksState extends State<RiderTasks> {
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _deliveries = [
    {
      'id': 'ORD-001',
      'customer': 'John Doe',
      'address': '123 Main St',
      'status': 'ready',
      'restaurant': 'FastFood Express',
      'earnings': 5.00,
    },
    {
      'id': 'ORD-002',
      'customer': 'Jane Smith',
      'address': '456 Oak Ave',
      'status': 'picked_up',
      'restaurant': 'FastFood Express',
      'earnings': 5.00,
    },
    {
      'id': 'ORD-003',
      'customer': 'Mike Johnson',
      'address': '789 Pine Rd',
      'status': 'delivered',
      'restaurant': 'FastFood Express',
      'earnings': 5.00,
    },
  ];

  double get _todayEarnings {
    return _deliveries
        .where((d) => d['status'] == 'delivered')
        .fold(0.0, (sum, d) => sum + (d['earnings'] as double));
  }

  void _acceptDelivery(Map<String, dynamic> delivery) {
    setState(() => delivery['status'] = 'accepted');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Delivery for ${delivery['id']} accepted! Go to restaurant.',
        ),
      ),
    );
  }

  void _pickUp(Map<String, dynamic> delivery) {
    setState(() => delivery['status'] = 'picked_up');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Food picked up! Delivering to ${delivery['customer']}.'),
      ),
    );
  }

  void _deliver(Map<String, dynamic> delivery) {
    setState(() => delivery['status'] = 'delivered');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Delivery completed!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildAvailableScreen() {
    final availableDeliveries = _deliveries
        .where((d) => d['status'] == 'ready')
        .toList();

    if (availableDeliveries.isEmpty) {
      return Center(
        child: Text(
          'No deliveries available',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: availableDeliveries.length,
      itemBuilder: (context, index) {
        final delivery = availableDeliveries[index];
        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.green,
                      child: const Icon(Icons.restaurant, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Order: ${delivery['id']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(delivery['customer']),
                  subtitle: Text(delivery['address']),
                ),
                ListTile(
                  leading: const Icon(Icons.attach_money),
                  title: Text('Earnings: \$${delivery['earnings']}'),
                ),
                ElevatedButton(
                  onPressed: () => _acceptDelivery(delivery),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text('ACCEPT DELIVERY'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMyDeliveriesScreen() {
    final activeDeliveries = _deliveries
        .where((d) => d['status'] == 'accepted' || d['status'] == 'picked_up')
        .toList();

    if (activeDeliveries.isEmpty) {
      return Center(
        child: Text(
          'No active deliveries',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activeDeliveries.length,
      itemBuilder: (context, index) {
        final delivery = activeDeliveries[index];
        return Card(
          elevation: 4,
          color: delivery['status'] == 'picked_up'
              ? Colors.green.shade50
              : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      delivery['status'] == 'picked_up'
                          ? Icons.motorcycle
                          : Icons.restaurant,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Order: ${delivery['id']} - ${delivery['status'].toUpperCase()}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ListTile(
                  title: Text(delivery['customer']),
                  subtitle: Text(delivery['address']),
                ),
                if (delivery['status'] == 'accepted')
                  ElevatedButton(
                    onPressed: () => _pickUp(delivery),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    child: const Text('PICK UP FOOD'),
                  ),
                if (delivery['status'] == 'picked_up')
                  ElevatedButton(
                    onPressed: () => _deliver(delivery),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('MARK AS DELIVERED'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEarningsScreen() {
    final completedDeliveries = _deliveries
        .where((d) => d['status'] == 'delivered')
        .toList();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text(
                      'Today\'s Earnings',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${_todayEarnings.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('${completedDeliveries.length} deliveries completed'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Recent Deliveries',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Divider(),
                    ...completedDeliveries.map(
                      (delivery) => ListTile(
                        title: Text('Order ${delivery['id']}'),
                        subtitle: Text(delivery['customer']),
                        trailing: Text(
                          '\$${delivery['earnings']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileScreen() {
    final completedCount = _deliveries
        .where((d) => d['status'] == 'delivered')
        .length;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.orange,
              child: Text(
                widget.user.name[0],
                style: const TextStyle(fontSize: 48, color: Colors.white),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.user.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(widget.user.email, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 8),
            Chip(
              label: Text('DELIVERY RIDER'),
              backgroundColor: Colors.orange.shade100,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatChip(
                  '${completedCount} Deliveries',
                  Icons.delivery_dining,
                ),
                const SizedBox(width: 8),
                _buildStatChip('⭐ 4.8', Icons.star),
              ],
            ),
            const SizedBox(height: 32),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Delivery History'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Help'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                // Show confirmation dialog
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'Logout',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  // Show loading indicator
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Logging out...')),
                  );

                  // Actually sign out from Firebase
                  await FirebaseAuth.instance.signOut();

                  // Navigate to login screen and clear all routes
                  if (mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                      (route) => false,
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      backgroundColor: Colors.orange.shade50,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildAvailableScreen(),
      _buildMyDeliveriesScreen(),
      _buildEarningsScreen(),
      _buildProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('🛵 Rider Dashboard'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.delivery_dining),
            label: 'Available',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.motorcycle),
            label: 'My Deliveries',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: 'Earnings',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
