import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../models/menu_item_model.dart';
import '../providers/cart_provider.dart';
import '../screens/login_sheet.dart';

class MenuItemCard extends ConsumerWidget {
  final MenuItem item;
  final String canteenId;
  final VoidCallback? onAdd;
  final VoidCallback? onRemove;

  const MenuItemCard({
    super.key,
    required this.item,
    required this.canteenId,
    this.onAdd,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final quantity = cart.items[item.id]?.quantity ?? 0;
    final isOutOfStock = item.availableQuantity == 0;
    final isMaxQuantity = quantity >= item.availableQuantity;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isOutOfStock ? null : () {},
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section
              Stack(
                children: [
                  Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isOutOfStock
                          ? const Color(
                              0xFF1A1A1A,
                            ) // Solid dark for unavailable
                          : Colors.grey[100],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      image: !isOutOfStock
                          ? const DecorationImage(
                              image: AssetImage(
                                'assets/images/all-menu-item.avif',
                              ),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    // Show "Unavailable" text for out of stock items
                    child: isOutOfStock
                        ? Center(
                            child: Text(
                              'Unavailable',
                              style: GoogleFonts.urbanist(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          )
                        : null,
                  ),
                ],
              ),

              // Content Section
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item Name
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.urbanist(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        height: 1.2,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Price and Quantity Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Price
                        Text(
                          '₹${item.price.toInt()}',
                          style: GoogleFonts.urbanist(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: const Color(0xFF0B7D3B), // Green color
                          ),
                        ),
                        // Available Quantity
                        if (!isOutOfStock)
                          Text(
                            '${item.availableQuantity}',
                            style: GoogleFonts.urbanist(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Action Button
                    _buildActionButton(
                      context,
                      ref,
                      quantity,
                      isOutOfStock,
                      isMaxQuantity,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    WidgetRef ref,
    int quantity,
    bool isOutOfStock,
    bool isMaxQuantity,
  ) {
    if (isOutOfStock) {
      // N/A Button for out of stock
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'N/A',
          textAlign: TextAlign.center,
          style: GoogleFonts.urbanist(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      );
    }

    if (quantity == 0) {
      // Add Button
      return Material(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            // Auth Check
            final auth = ref.read(authProvider);
            if (!auth.isAuthenticated) {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const LoginSheet(),
              );
              return;
            }
            ref.read(cartProvider.notifier).addItem(item, canteenId);
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: const Icon(Icons.add, color: Colors.white, size: 20),
          ),
        ),
      );
    } else {
      // Quantity Controls
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Minus Button
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
                onTap: () {
                  ref.read(cartProvider.notifier).removeItem(item);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: const Icon(
                    Icons.remove,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // Quantity
            Text(
              '$quantity',
              style: GoogleFonts.urbanist(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),

            // Plus Button
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                onTap: isMaxQuantity
                    ? null
                    : () {
                        ref
                            .read(cartProvider.notifier)
                            .addItem(item, canteenId);
                      },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Icon(
                    Icons.add,
                    size: 18,
                    color: isMaxQuantity ? Colors.grey : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}
