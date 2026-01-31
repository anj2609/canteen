import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../models/order_model.dart';
import '../screens/login_sheet.dart';
import '../providers/canteen_provider.dart';
import '../providers/payment_provider.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final canteenState = ref.watch(canteenProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
        ),
        title: Text(
          'My Cart',
          style: GoogleFonts.urbanist(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20, top: 16),
            child: Text(
              '${cartState.totalItems} items',
              style: GoogleFonts.urbanist(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: cartState.items.isEmpty
          ? _buildEmptyState(context)
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: cartState.items.length + 1,
              separatorBuilder: (_, index) {
                if (index == cartState.items.length - 1) {
                  return const SizedBox(height: 24);
                }
                return const SizedBox(height: 16);
              },
              itemBuilder: (context, index) {
                // If last item, build Summary Section
                if (index == cartState.items.length) {
                  return _buildSummarySection(context, ref, cartState);
                }
                final item = cartState.items.values.elementAt(index);
                final menuItem = canteenState.menu.firstWhere(
                  (m) => m.id == item.menuItemId,
                  orElse: () => canteenState.menu.first,
                );
                return _buildCartItem(context, ref, item, menuItem.image ?? '');
              },
            ),
    );
  }

  Widget _buildCartItem(
    BuildContext context,
    WidgetRef ref,
    OrderLineItem item,
    String? image,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECF4)), // Light border
        // No shadow
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Container(
            width: 80, // Slightly larger image
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[100],
              image: const DecorationImage(
                image: AssetImage('assets/images/all-menu-item.avif'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and Price Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: GoogleFonts.urbanist(
                              fontSize: 16,
                              fontWeight: FontWeight.w600, // Regular-ish bold
                              color: const Color(0xFF1E232C),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${item.price}',
                            style: GoogleFonts.urbanist(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0B7D3B), // Green
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Trash Icon
                    InkWell(
                      onTap: () {
                        // Using a dummy item to remove helps if provider relies on ID check
                        // But best is to rely on ID.
                        // Assuming provider logic works for now.
                        ref
                            .read(cartProvider.notifier)
                            .removeItem(
                              ref
                                  .read(canteenProvider)
                                  .menu
                                  .firstWhere((m) => m.id == item.menuItemId),
                            );
                      },
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.red, // Red trash icon
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Quantity Row
                Row(
                  children: [
                    _buildCounterButton(
                      icon: Icons.remove,
                      onTap: () => ref
                          .read(cartProvider.notifier)
                          .decrementItem(item.menuItemId),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '${item.quantity}',
                        style: GoogleFonts.urbanist(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildCounterButton(
                      icon: Icons.add,
                      onTap: () => ref
                          .read(cartProvider.notifier)
                          .incrementItem(item.menuItemId),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8F9), // Very light grey bg
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Icon(icon, size: 16, color: const Color(0xFF1E232C)),
      ),
    );
  }

  Widget _buildSummarySection(
    BuildContext context,
    WidgetRef ref,
    CartState cartState,
  ) {
    final paymentState = ref.watch(paymentProvider);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8ECF4)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subtotal',
                  style: GoogleFonts.urbanist(
                    color: const Color(0xFF8391A1), // Grey
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '₹${cartState.totalAmount.toStringAsFixed(0)}',
                  style: GoogleFonts.urbanist(
                    color: const Color(0xFF1E232C),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Divider(color: Color(0xFFE8ECF4)), // Light divider
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: GoogleFonts.urbanist(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E232C),
                  ),
                ),
                Text(
                  '₹${cartState.totalAmount.toStringAsFixed(0)}',
                  style: GoogleFonts.urbanist(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0B7D3B), // Green
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Pickup Notice
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4E5), // Light orange background
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFF9800)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFFFF9800),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Order must be picked up within 12 hours or will be refunded',
                      style: GoogleFonts.urbanist(
                        fontSize: 12,
                        color: const Color(0xFFFF9800),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed:
                    paymentState.isLoading ||
                        (ref
                                .read(canteenProvider)
                                .selectedCanteen
                                ?.isCurrentlyOpen ==
                            false)
                    ? null
                    : () {
                        _handleCheckout(context, ref, cartState);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E232C), // Dark color
                  disabledBackgroundColor: Colors.grey[400],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: paymentState.isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Proceed to Checkout',
                        style: GoogleFonts.urbanist(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            if (ref.watch(canteenProvider).selectedCanteen?.isCurrentlyOpen ==
                false) ...[
              const SizedBox(height: 12),
              Text(
                'Canteen is currently closed',
                style: GoogleFonts.urbanist(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleCheckout(
    BuildContext context,
    WidgetRef ref,
    CartState cartState,
  ) {
    final authState = ref.watch(authProvider);

    if (cartState.canteenId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Error: Canteen information missing. Please try clearing cart.',
          ),
        ),
      );
      return;
    }

    if (!authState.isAuthenticated) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const LoginSheet(),
      );
      return;
    }

    // Call Payment Provider
    ref
        .read(paymentProvider.notifier)
        .initiateCheckout(
          context,
          cartState.canteenId!,
          cartState.items.values.toList(),
        );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              color: Color(0xFFF5F5F5), // Light grey circle color
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.shopping_bag_outlined, // Using Bag icon as per design
                size: 50,
                color: Color(0xFF9E9E9E), // Grey icon color
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Your cart is empty',
            style: GoogleFonts.urbanist(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E232C), // Dark text color
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add items to get started',
            style: GoogleFonts.urbanist(
              fontSize: 16,
              color: const Color(0xFF8391A1), // Light grey text color
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 200, // Fixed width for button
            height: 56,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E232C), // Dark button color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'Browse Menu',
                style: GoogleFonts.urbanist(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
