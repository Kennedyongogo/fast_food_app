import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';
import '../screens/login_screen.dart';

class CustomerHome extends StatefulWidget {
  final AppUser user;
  const CustomerHome({super.key, required this.user});

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  int _selectedIndex = 0;

  // Menu data
  final List<Map<String, dynamic>> _menuItems = [
    {
      'id': 1,
      'name': '🍔 Beef Burger',
      'price': 8.99,
      'description': 'Juicy beef patty with lettuce, tomato, and cheese',
    },
    {
      'id': 2,
      'name': '🍕 Pepperoni Pizza',
      'price': 12.99,
      'description': 'Classic pepperoni with mozzarella cheese',
    },
    {
      'id': 3,
      'name': '🍟 French Fries',
      'price': 3.99,
      'description': 'Crispy golden fries with salt',
    },
    {
      'id': 4,
      'name': '🥤 Soft Drink',
      'price': 2.49,
      'description': 'Coke, Sprite, or Fanta',
    },
    {
      'id': 5,
      'name': '🍗 Fried Chicken',
      'price': 7.99,
      'description': 'Crispy fried chicken (2 pieces)',
    },
    {
      'id': 6,
      'name': '🥗 Caesar Salad',
      'price': 6.49,
      'description': 'Fresh salad with Caesar dressing',
    },
  ];

  final Map<int, int> _cart = {};

  int get _totalItems => _cart.values.fold(0, (sum, qty) => sum + qty);

  double get _totalAmount {
    double total = 0;
    _cart.forEach((itemId, quantity) {
      final item = _menuItems.firstWhere((item) => item['id'] == itemId);
      total += (item['price'] as double) * quantity;
    });
    return total;
  }

  // Mock orders for tracking
  final List<Map<String, dynamic>> _orders = [
    {
      'id': 'ORD-001',
      'status': 'delivered',
      'total': 12.98,
      'date': '2026-04-28',
    },
    {
      'id': 'ORD-002',
      'status': 'preparing',
      'total': 24.97,
      'date': '2026-04-28',
    },
  ];

  void _placeOrder() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Order Placed! 🎉'),
        content: Text(
          'Order for $_totalItems item(s) totaling \$${_totalAmount.toStringAsFixed(2)}\n\nStatus: PENDING\n\nThe owner will be notified.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _cart.clear());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Order placed! Track it in "My Orders"'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showCart() {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cart is empty')));
      return;
    }
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Your Cart',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            ..._cart.entries.map((entry) {
              final item = _menuItems.firstWhere((i) => i['id'] == entry.key);
              return ListTile(
                leading: Text('${entry.value}x'),
                title: Text(item['name']),
                trailing: Text(
                  '\$${(item['price'] * entry.value).toStringAsFixed(2)}',
                ),
              );
            }),
            const Divider(),
            ListTile(
              title: const Text('Total'),
              trailing: Text('\$${_totalAmount.toStringAsFixed(2)}'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _placeOrder();
              },
              child: const Text('Place Order'),
            ),
          ],
        ),
      ),
    );
  }

  // Menu Screen
  Widget _buildMenuScreen() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _menuItems.length,
      itemBuilder: (context, index) {
        final item = _menuItems[index];
        final quantity = _cart[item['id']] ?? 0;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        item['description'],
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        '\$${item['price']}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 20),
                        onPressed: quantity > 0
                            ? () => setState(() {
                                if (quantity == 1)
                                  _cart.remove(item['id']);
                                else
                                  _cart[item['id']] = quantity - 1;
                              })
                            : null,
                      ),
                      SizedBox(
                        width: 30,
                        child: Text('$quantity', textAlign: TextAlign.center),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 20),
                        onPressed: () =>
                            setState(() => _cart[item['id']] = quantity + 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Cart Screen
  Widget _buildCartScreen() {
    if (_cart.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Your cart is empty',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => setState(() => _selectedIndex = 0),
              child: const Text('Browse Menu'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _cart.length,
            itemBuilder: (context, index) {
              final itemId = _cart.keys.elementAt(index);
              final item = _menuItems.firstWhere((i) => i['id'] == itemId);
              final quantity = _cart[itemId]!;
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange,
                    child: Text(
                      '${quantity}x',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(item['name']),
                  subtitle: Text('\$${item['price']} each'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '\$${(item['price'] * quantity).toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.remove_circle,
                          color: Colors.red,
                        ),
                        onPressed: () => setState(() {
                          if (quantity == 1)
                            _cart.remove(itemId);
                          else
                            _cart[itemId] = quantity - 1;
                        }),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 8)],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total: \$${_totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_totalItems} items',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text('PLACE ORDER'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // My Orders Screen
  Widget _buildOrdersScreen() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final order = _orders[index];
        Color statusColor;
        IconData statusIcon;

        switch (order['status']) {
          case 'pending':
            statusColor = Colors.orange;
            statusIcon = Icons.pending;
            break;
          case 'preparing':
            statusColor = Colors.blue;
            statusIcon = Icons.kitchen;
            break;
          case 'delivered':
            statusColor = Colors.green;
            statusIcon = Icons.check_circle;
            break;
          default:
            statusColor = Colors.grey;
            statusIcon = Icons.receipt;
        }

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: statusColor,
              child: Icon(statusIcon, color: Colors.white),
            ),
            title: Text('Order ${order['id']}'),
            subtitle: Text('${order['date']} • \$${order['total']}'),
            trailing: Chip(
              label: Text(order['status'].toUpperCase()),
              backgroundColor: statusColor.withOpacity(0.2),
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Order ${order['id']}'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: Text('Status: ${order['status'].toUpperCase()}'),
                      ),
                      ListTile(title: Text('Total: \$${order['total']}')),
                      ListTile(title: Text('Date: ${order['date']}')),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Profile Screen
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
              label: Text(widget.user.role.toUpperCase()),
              backgroundColor: Colors.orange.shade100,
            ),
            const SizedBox(height: 32),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Order History'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => setState(() => _selectedIndex = 2),
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Help & Support'),
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
      _buildMenuScreen(),
      _buildCartScreen(),
      _buildOrdersScreen(),
      _buildProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('🍔 FastFood Express'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          if (_selectedIndex == 0) // Show cart badge only on menu
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () => setState(() => _selectedIndex = 1),
                ),
                if (_totalItems > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$_totalItems',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Menu'),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt),
            label: 'My Orders',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
