import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/app_user.dart';
import '../screens/login_screen.dart';
import '../screens/menu_management_screen.dart';
import '../screens/staff_management_screen.dart';

class OwnerOrders extends StatefulWidget {
  final AppUser user;
  const OwnerOrders({super.key, required this.user});

  @override
  State<OwnerOrders> createState() => _OwnerOrdersState();
}

class _OwnerOrdersState extends State<OwnerOrders> {
  int _selectedIndex = 0;
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final ordersData = await ApiService.getOrders();
    if (ordersData.isNotEmpty) {
      setState(() {
        _orders = ordersData
            .map(
              (order) => {
                'id': order['id'],
                'customer': order['customer_name'] ?? 'Customer',
                'items':
                    order['items']?.map((item) => item['name']).join(', ') ??
                    '',
                'total': order['total'],
                'status': order['status'],
              },
            )
            .toList();
      });
    }
    setState(() => _isLoading = false);
  }

  Future<void> _acceptOrder(Map<String, dynamic> order) async {
    setState(() => order['status'] = 'preparing');

    final response = await ApiService.updateOrderStatus(
      orderId: order['id'],
      status: 'preparing',
    );

    if (response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order ${order['id']} accepted - Preparing food'),
        ),
      );
      await _loadOrders(); // Refresh orders
    } else {
      setState(() => order['status'] = 'pending');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to accept order'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _markReady(Map<String, dynamic> order) async {
    setState(() => order['status'] = 'ready_for_pickup');

    final response = await ApiService.updateOrderStatus(
      orderId: order['id'],
      status: 'ready_for_pickup',
    );

    if (response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order ${order['id']} is ready for pickup!')),
      );
      await _loadOrders(); // Refresh orders
    } else {
      setState(() => order['status'] = 'preparing');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to mark order ready'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildOrdersScreen() {
    final pendingOrders = _orders
        .where((o) => o['status'] == 'pending')
        .toList();
    final preparingOrders = _orders
        .where((o) => o['status'] == 'preparing')
        .toList();
    final readyOrders = _orders
        .where((o) => o['status'] == 'ready_for_pickup')
        .toList();

    if (_orders.isEmpty && !_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('No orders yet'),
          ],
        ),
      );
    }

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
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.orange),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    return Card(
                      child: ExpansionTile(
                        title: Text(
                          'Order ${order['id']} - \$${order['total']}',
                        ),
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
                                ListTile(
                                  title: Text('Items: ${order['items']}'),
                                ),
                                ListTile(
                                  title: Text('Total: \$${order['total']}'),
                                ),
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
                                if (order['status'] == 'ready_for_pickup')
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

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.orange),
      );
    }

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

  Widget _buildMenuManagementScreen() {
    return const MenuManagementScreen();
  }

  Widget _buildStaffManagementScreen() {
    return const StaffManagementScreen();
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Logging out...')),
                  );

                  await ApiService.logout();

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
      _buildStaffManagementScreen(),
      _buildProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('👨‍🍳 Owner Dashboard'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading && _selectedIndex == 0
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : screens[_selectedIndex],
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
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Staff'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
