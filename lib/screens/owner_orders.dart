import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';
import '../screens/login_screen.dart';
import '../screens/menu_management_screen.dart';

class OwnerOrders extends StatefulWidget {
  final AppUser user;
  const OwnerOrders({super.key, required this.user});

  @override
  State<OwnerOrders> createState() => _OwnerOrdersState();
}

class _OwnerOrdersState extends State<OwnerOrders> {
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _orders = [
    {
      'id': 'ORD-001',
      'customer': 'John Doe',
      'items': 'Burger, Fries',
      'total': 12.98,
      'status': 'pending',
    },
    {
      'id': 'ORD-002',
      'customer': 'Jane Smith',
      'items': 'Pizza',
      'total': 12.99,
      'status': 'preparing',
    },
    {
      'id': 'ORD-003',
      'customer': 'Mike Johnson',
      'items': 'Chicken, Soda',
      'total': 10.48,
      'status': 'ready',
    },
  ];

  void _acceptOrder(Map<String, dynamic> order) {
    setState(() => order['status'] = 'preparing');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Order ${order['id']} accepted - Preparing food')),
    );
  }

  void _markReady(Map<String, dynamic> order) {
    setState(() => order['status'] = 'ready');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Order ${order['id']} is ready for pickup!')),
    );
  }

  Widget _buildOrdersScreen() {
    final pendingOrders = _orders
        .where((o) => o['status'] == 'pending')
        .toList();
    final preparingOrders = _orders
        .where((o) => o['status'] == 'preparing')
        .toList();
    final readyOrders = _orders.where((o) => o['status'] == 'ready').toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.orange.shade50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard('Pending', pendingOrders.length, Colors.orange),
              _buildStatCard('Preparing', preparingOrders.length, Colors.blue),
              _buildStatCard('Ready', readyOrders.length, Colors.green),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _orders.length,
            itemBuilder: (context, index) {
              final order = _orders[index];
              return Card(
                child: ExpansionTile(
                  title: Text('Order ${order['id']} - \$${order['total']}'),
                  subtitle: Text(
                    'Status: ${order['status'].toString().toUpperCase()}',
                  ),
                  leading: CircleAvatar(
                    backgroundColor: order['status'] == 'pending'
                        ? Colors.orange
                        : order['status'] == 'preparing'
                        ? Colors.blue
                        : Colors.green,
                    child: const Icon(Icons.receipt, color: Colors.white),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          ListTile(
                            title: Text('Customer: ${order['customer']}'),
                          ),
                          ListTile(title: Text('Items: ${order['items']}')),
                          ListTile(title: Text('Total: \$${order['total']}')),
                          if (order['status'] == 'pending')
                            ElevatedButton(
                              onPressed: () => _acceptOrder(order),
                              child: const Text('ACCEPT ORDER'),
                            ),
                          if (order['status'] == 'preparing')
                            ElevatedButton(
                              onPressed: () => _markReady(order),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              child: const Text('MARK AS READY'),
                            ),
                          if (order['status'] == 'ready')
                            const Padding(
                              padding: EdgeInsets.all(8),
                              child: Text(
                                '✅ READY FOR PICKUP',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardScreen() {
    final totalOrders = _orders.length;
    final totalRevenue = _orders.fold(
      0.0,
      (sum, order) => sum + (order['total'] as double),
    );
    final pendingCount = _orders.where((o) => o['status'] == 'pending').length;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildDashboardCard(
              'Total Orders',
              '$totalOrders',
              Icons.receipt,
              Colors.orange,
            ),
            _buildDashboardCard(
              'Total Revenue',
              '\$${totalRevenue.toStringAsFixed(2)}',
              Icons.attach_money,
              Colors.green,
            ),
            _buildDashboardCard(
              'Pending Orders',
              '$pendingCount',
              Icons.pending,
              Colors.red,
            ),
            const SizedBox(height: 20),
            Card(
              child: ListTile(
                leading: const Icon(Icons.trending_up),
                title: const Text('Today\'s Performance'),
                subtitle: Text(
                  'Completed: ${totalOrders - pendingCount} orders',
                ),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              radius: 30,
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.grey[600])),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // UPDATED: Professional Menu Management Screen
  Widget _buildMenuManagementScreen() {
    return const MenuManagementScreen();
  }

  Widget _buildProfileScreen() {
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
              label: Text('RESTAURANT OWNER'),
              backgroundColor: Colors.orange.shade100,
            ),
            const SizedBox(height: 32),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.restaurant),
              title: const Text('Restaurant Settings'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('Reports'),
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

  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildOrdersScreen(),
      _buildDashboardScreen(),
      _buildMenuManagementScreen(),
      _buildProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('👨‍🍳 Owner Dashboard'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Orders'),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Menu'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
