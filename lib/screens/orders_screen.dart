import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/orders_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/payment_provider.dart';
import '../providers/tab_provider.dart';
import 'login_sheet.dart';
import 'cart_sheet.dart';
import '../providers/cart_provider.dart';
import '../models/order_model.dart';
import '../models/menu_item_model.dart';
import 'order_details_screen.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  String _filter = 'All'; // All, Pending, Active, Completed, Cancelled

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ordersProvider.notifier).fetchOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Show login prompt if not authenticated
    if (!authState.isAuthenticated || authState.user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'My Orders',
            style: GoogleFonts.urbanist(fontWeight: FontWeight.bold),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long, size: 80, color: Colors.grey[300]),
              const SizedBox(height: 20),
              Text(
                'Login to view your orders',
                style: GoogleFonts.urbanist(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => const LoginSheet(),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF62F56),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Login / Register'),
              ),
            ],
          ),
        ),
      );
    }

    final ordersState = ref.watch(ordersProvider);

    // Updated filter logic to show pending and cancelled orders
    final displayedOrders = ordersState.orders.where((order) {
      if (_filter == 'All') return true;

      if (_filter == 'Pending') {
        return order.paymentStatus == 'pending' && order.status != 'cancelled';
      }

      if (_filter == 'Active') {
        bool isPaid =
            order.paymentStatus == 'completed' ||
            order.paymentStatus == 'success';
        return isPaid &&
            order.status != 'completed' &&
            order.status != 'cancelled';
      }

      if (_filter == 'Completed') return order.status == 'completed';
      if (_filter == 'Cancelled') return order.status == 'cancelled';

      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Orders',
          style: GoogleFonts.urbanist(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Global Cart Icon
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => CartSheet(
                  onBrowseMenu: () {
                    ref.read(selectedTabProvider.notifier).state = 0;
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: ['All', 'Pending', 'Active', 'Completed', 'Cancelled']
                  .map((filter) {
                    final isSelected = _filter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: FilterChip(
                        label: Text(filter),
                        selected: isSelected,
                        selectedColor: const Color(0xFFE5F5ED),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? const Color(0xFF0B7D3B)
                              : Colors.black,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        onSelected: (val) {
                          setState(() {
                            _filter = filter;
                          });
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    );
                  })
                  .toList(),
            ),
          ),
          const SizedBox(height: 10),

          Expanded(
            child: ordersState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () async {
                      await ref.read(ordersProvider.notifier).fetchOrders();
                    },
                    child: displayedOrders.isEmpty
                        ? Stack(
                            children: [
                              ListView(), // Scrollable for refresh
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Icon in circle
                                    Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.inventory_2_outlined,
                                        size: 50,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    // Heading
                                    Text(
                                      'No orders yet',
                                      style: GoogleFonts.urbanist(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    // Subtitle
                                    Text(
                                      'Your order history will appear here',
                                      style: GoogleFonts.urbanist(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 32),
                                    // Start Ordering Button
                                    ElevatedButton(
                                      onPressed: () {
                                        ref
                                                .read(
                                                  selectedTabProvider.notifier,
                                                )
                                                .state =
                                            0;
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF1A1A1A,
                                        ),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 32,
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        'Start Ordering',
                                        style: GoogleFonts.urbanist(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: displayedOrders.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final order = displayedOrders[index];
                              return _buildOrderCard(context, order);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order) {
    // Status badge styling
    Color statusBgColor;
    Color statusTextColor;
    String statusText;

    if (order.status == 'cancelled') {
      statusBgColor = const Color(0xFFFFE5EC);
      statusTextColor = const Color(0xFFFF4D6D);
      statusText = 'Cancelled';
    } else if (order.status == 'completed') {
      statusBgColor = const Color(0xFFE5F5ED);
      statusTextColor = const Color(0xFF0B7D3B);
      statusText = 'Completed';
    } else if (order.status == 'ready') {
      statusBgColor = const Color(0xFFE5F5ED);
      statusTextColor = const Color(0xFF0B7D3B);
      statusText = 'Ready';
    } else if (order.status == 'preparing') {
      statusBgColor = const Color(0xFFE5F5ED);
      statusTextColor = const Color(0xFF0B7D3B);
      statusText = 'Cooking';
    } else {
      statusBgColor = const Color(0xFFFFF4E5);
      statusTextColor = const Color(0xFFFF9800);
      statusText = 'Pending';
    }

    // Format Date: Jan 13, 7:11 PM
    String formattedDate = order.createdAt;
    try {
      final date = DateTime.parse(order.createdAt).toLocal();
      formattedDate = DateFormat('MMM dd, h:mm a').format(date);
    } catch (_) {}

    // Get first item name and count
    String itemSummary = '';
    if (order.items.isNotEmpty) {
      final firstItem = order.items.first;
      itemSummary = '${firstItem.name} ×${firstItem.quantity}';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order ID and Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ORD-${order.orderId}',
                style: GoogleFonts.urbanist(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusTextColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusText,
                      style: GoogleFonts.urbanist(
                        color: statusTextColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Date
          Text(
            formattedDate,
            style: GoogleFonts.urbanist(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),

          // Item count
          Text(
            '${order.items.length} Item${order.items.length > 1 ? 's' : ''}',
            style: GoogleFonts.urbanist(fontSize: 13, color: Colors.grey[700]),
          ),
          const SizedBox(height: 4),

          // Item summary
          Text(
            itemSummary,
            style: GoogleFonts.urbanist(fontSize: 13, color: Colors.grey[700]),
          ),
          const SizedBox(height: 12),

          // Total
          Row(
            children: [
              Text(
                'Total',
                style: GoogleFonts.urbanist(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
              const Spacer(),
              Text(
                '₹${order.totalAmount}',
                style: GoogleFonts.urbanist(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrderDetailsScreen(order: order),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'View Details',
                    style: GoogleFonts.urbanist(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed:
                      order.paymentStatus == 'pending' &&
                          order.status != 'cancelled'
                      ? () => _handlePayment(order)
                      : () {
                          // Reorder Logic
                          final canteenId = order.canteenId;
                          final cartNotifier = ref.read(cartProvider.notifier);
                          cartNotifier.clearCart();

                          for (var item in order.items) {
                            final menuItem = MenuItem(
                              id: item.menuItemId,
                              name: item.name,
                              price: item.price,
                              availableQuantity: 99,
                              canteenId: canteenId,
                              image: '',
                            );
                            cartNotifier.addItem(menuItem, canteenId);
                            for (int i = 0; i < item.quantity - 1; i++) {
                              cartNotifier.addItem(menuItem, canteenId);
                            }
                          }

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Items added to cart!'),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A1A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        order.paymentStatus == 'pending' &&
                                order.status != 'cancelled'
                            ? Icons.payment
                            : Icons.refresh,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        order.paymentStatus == 'pending' &&
                                order.status != 'cancelled'
                            ? 'Pay Now'
                            : 'Reorder',
                        style: GoogleFonts.urbanist(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handlePayment(OrderModel order) async {
    // Use the payment provider to initiate Razorpay payment flow
    // Pass orderId (e.g., "ORD123") not the MongoDB _id
    ref
        .read(paymentProvider.notifier)
        .initiatePaymentForExistingOrder(context, order.orderId);
  }
}
