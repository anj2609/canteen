import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import '../models/order_model.dart';

class OrderDetailsScreen extends StatelessWidget {
  final OrderModel order;
  const OrderDetailsScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Order Details',
          style: GoogleFonts.urbanist(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Order ID
                    Text(
                      'Order #${order.orderId}',
                      style: GoogleFonts.urbanist(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(order.createdAt),
                      style: GoogleFonts.urbanist(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // QR Code
                    // Only show if QR code is available and order is in valid state
                    if (order.qrCode != null &&
                        order.qrCode!.isNotEmpty &&
                        order.status.toLowerCase() != 'completed' &&
                        order.status.toLowerCase() != 'pending' &&
                        order.status.toLowerCase() != 'cancelled') ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: SizedBox(
                          width: 180,
                          height: 180,
                          child: Image.memory(
                            base64Decode(
                              order.qrCode!.replaceFirst(
                                RegExp(r'data:image\/.*;base64,'),
                                '',
                              ),
                            ),
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(child: Icon(Icons.error));
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Show this QR code at the counter for pickup',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.urbanist(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],

                    // Status Indicator
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getStatusIcon(order.status),
                            color: _getStatusColor(order.status),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _getStatusText(order.status),
                            style: GoogleFonts.urbanist(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Refund Information (if refunded)
                    if (order.refundId != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD), // Light blue
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF1976D2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF1976D2),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Refund Processed',
                                  style: GoogleFonts.urbanist(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1976D2),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Refund ID: ${order.refundId}',
                              style: GoogleFonts.urbanist(
                                fontSize: 13,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'The refund will reflect in your original payment method within 2-3 business days.',
                              style: GoogleFonts.urbanist(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Pickup Location
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Pickup Location',
                        style: GoogleFonts.urbanist(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Main Canteen',
                        style: GoogleFonts.urbanist(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Order Items
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Order Items',
                        style: GoogleFonts.urbanist(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...order.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${item.name} ×${item.quantity}',
                                style: GoogleFonts.urbanist(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                '₹${item.price * item.quantity}',
                                style: GoogleFonts.urbanist(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Total Amount
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Amount',
                            style: GoogleFonts.urbanist(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            '₹${order.totalAmount}',
                            style: GoogleFonts.urbanist(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0B7D3B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Done Button
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A1A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Done',
                    style: GoogleFonts.urbanist(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      // Force UTC interpretation if missing offset
      if (!dateStr.endsWith('Z') && !dateStr.contains('+')) {
        dateStr += 'Z';
      }
      final date = DateTime.parse(dateStr).toLocal();
      // Match format from OrdersScreen: "MMM dd, h:mm a"
      // Note: Needs 'package:intl/intl.dart' which should be imported
      // If intl is not imported in this file, I'll need to add it or write custom formatter matching it.
      // Based on previous file, I'll use DateFormat if available, otherwise manual.
      // Let's use manual for safety if import is missing, but matching the style.

      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final hour = date.hour > 12
          ? date.hour - 12
          : (date.hour == 0 ? 12 : date.hour);
      final period = date.hour >= 12 ? 'PM' : 'AM';
      final minute = date.minute.toString().padLeft(2, '0');

      return '${months[date.month - 1]} ${date.day}, $hour:$minute $period';
    } catch (e) {
      return dateStr;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Payment Pending';
      case 'paid':
        return 'Paid';
      case 'preparing':
        return 'Cooking in Progress';
      case 'ready':
        return 'Ready for Pickup';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Processing';
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'paid':
      case 'preparing':
        return Icons.restaurant;
      case 'ready':
        return Icons.check_circle;
      case 'completed':
        return Icons.thumb_up;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'paid':
      case 'preparing':
        return const Color(0xFF0B7D3B);
      case 'ready':
        return const Color(0xFF0B7D3B);
      case 'completed':
        return const Color(0xFF0B7D3B);
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
