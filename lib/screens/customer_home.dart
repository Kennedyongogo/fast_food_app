import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/app_user.dart';
import '../screens/login_screen.dart';

class CustomerHome extends StatefulWidget {
  final AppUser user;
  const CustomerHome({super.key, required this.user});

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  int _selectedIndex = 0;

  // Menu data from API
  List<Map<String, dynamic>> _menuItems = [];
  final Map<String, int> _cart = {}; // itemId -> quantity
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

  String _resolveImageUrl(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final normalized = raw.replaceAll('\\', '/');
    if (normalized.startsWith('http')) return normalized;
    final host = ApiService.baseUrl.replaceAll('/api', '');
    return '$host/$normalized';
  }

  int get _totalItems => _cart.values.fold(0, (sum, qty) => sum + qty);

  double get _totalAmount {
    double total = 0;
    _cart.forEach((itemId, quantity) {
      final item = _menuItems.firstWhere(
        (item) => item['id'].toString() == itemId,
      );
      total += (item['price'] as double) * quantity;
    });
    return total;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Load only available menu items for customers
    final menuData = await ApiService.getMenuItems(availableOnly: true);
    if (menuData.isNotEmpty) {
      setState(() {
        _menuItems = menuData
            .where((item) => item['available'] == true)
            .map(
              (item) => {
                'id': item['id'],
                'name': item['name'],
                'price': double.tryParse(item['price'].toString()) ?? 0.0,
                'description': item['description'] ?? '',
                'image_url': _resolveImageUrl(
                  (item['image_url'] ??
                          item['imageUrl'] ??
                          item['image'])
                      ?.toString(),
                ),
              },
            )
            .toList();
      });
    }

    // Load orders
    final ordersData = await ApiService.getOrders();
    if (ordersData.isNotEmpty) {
      setState(() {
        _orders = ordersData
            .map(
              (order) => {
                'id': order['id'],
                'status': order['status'],
                'total': order['total'],
                'date': order['created_at'] != null
                    ? DateTime.parse(
                        order['created_at'],
                      ).toString().substring(0, 10)
                    : DateTime.now().toString().substring(0, 10),
              },
            )
            .toList();
      });
    }

    setState(() => _isLoading = false);
  }

  Future<void> _placeOrder() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Your cart is empty')));
      return;
    }

    setState(() => _isLoading = true);

    // Prepare order items
    final orderItems = _cart.entries.map((entry) {
      final item = _menuItems.firstWhere(
        (i) => i['id'].toString() == entry.key,
      );
      return {
        'item_id': entry.key,
        'name': item['name'],
        'price': item['price'],
        'quantity': entry.value,
      };
    }).toList();

    try {
      final response = await ApiService.placeOrder(
        items: orderItems,
        total: _totalAmount,
        deliveryAddress:
            'Customer Address', // You can add address selection later
        latitude: 0.0, // Add geolocation later
        longitude: 0.0,
      );

      if (response['success'] == true) {
        setState(() {
          _cart.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order placed successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh orders
        await _loadData();

        // Switch to My Orders tab
        setState(() => _selectedIndex = 2);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to place order'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => _isLoading = false);
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
            const SizedBox(height: 16),
            ..._cart.entries.map((entry) {
              final item = _menuItems.firstWhere(
                (i) => i['id'].toString() == entry.key,
              );
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

  Widget _buildMenuScreen() {
    if (_menuItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No menu items available',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _menuItems.length,
      itemBuilder: (context, index) {
        final item = _menuItems[index];
        final itemId = item['id'].toString();
        final quantity = _cart[itemId] ?? 0;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: item['image_url'] != null &&
                          item['image_url'].toString().isNotEmpty
                      ? Image.network(
                          item['image_url'].toString(),
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey.shade200,
                              child: Icon(
                                Icons.fastfood,
                                color: Colors.grey.shade400,
                              ),
                            );
                          },
                        )
                      : Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey.shade200,
                          child: Icon(
                            Icons.fastfood,
                            color: Colors.grey.shade400,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
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
                      const SizedBox(height: 4),
                      Text(
                        item['description'],
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
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
                                if (quantity == 1) {
                                  _cart.remove(itemId);
                                } else {
                                  _cart[itemId] = quantity - 1;
                                }
                              })
                            : null,
                      ),
                      SizedBox(
                        width: 30,
                        child: Text('$quantity', textAlign: TextAlign.center),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 20),
                        onPressed: () => setState(() {
                          _cart[itemId] = quantity + 1;
                        }),
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
              final item = _menuItems.firstWhere(
                (i) => i['id'].toString() == itemId,
              );
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
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '\$${(item['price'] * quantity).toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      GestureDetector(
                        onTap: () => setState(() {
                          if (quantity == 1) {
                            _cart.remove(itemId);
                          } else {
                            _cart[itemId] = quantity - 1;
                          }
                        }),
                        child: const Padding(
                          padding: EdgeInsets.all(2),
                          child: Icon(
                            Icons.remove_circle,
                            color: Colors.red,
                            size: 20,
                          ),
                        ),
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

  Widget _buildOrdersScreen() {
    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No orders yet',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => setState(() => _selectedIndex = 0),
              child: const Text('Start Ordering'),
            ),
          ],
        ),
      );
    }

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
          case 'ready_for_pickup':
            statusColor = Colors.green;
            statusIcon = Icons.check_circle;
            break;
          case 'delivered':
            statusColor = Colors.green;
            statusIcon = Icons.delivery_dining;
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
              label: Text(order['status'].toString().toUpperCase()),
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
                        title: Text(
                          'Status: ${order['status'].toString().toUpperCase()}',
                        ),
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
          if (_selectedIndex == 0)
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : screens[_selectedIndex],
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
