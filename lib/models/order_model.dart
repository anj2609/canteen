class OrderLineItem {
  final String menuItemId;
  final String name;
  final double price;
  final int quantity;

  OrderLineItem({
    required this.menuItemId,
    required this.name,
    required this.price,
    required this.quantity,
  });

  factory OrderLineItem.fromJson(Map<String, dynamic> json) {
    return OrderLineItem(
      menuItemId: json['menuItemId'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'menuItemId': menuItemId,
      'name': name,
      'price': price,
      'quantity': quantity,
    };
  }
}

class OrderModel {
  // Renamed to avoid overlap with Order keyword if any
  final String id;
  final String orderId;
  final String userId;
  final String canteenId;
  final List<OrderLineItem> items;
  final double totalAmount;
  final String status;
  final String paymentStatus;
  final String? paymentId; // Added paymentId
  final String? qrCode;
  final String? refundId; // Refund ID if order was refunded
  final String createdAt;

  OrderModel({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.canteenId,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.paymentStatus,
    this.paymentId,
    this.qrCode,
    this.refundId,
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    var itemsList = json['items'] as List?;
    List<OrderLineItem> lineItems = itemsList != null
        ? itemsList.map((i) => OrderLineItem.fromJson(i)).toList()
        : [];

    return OrderModel(
      id: json['_id'] ?? '',
      orderId: json['orderId'] ?? '',
      userId: json['userId'] is String
          ? json['userId']
          : (json['userId']?['_id'] ?? ''),
      canteenId: json['canteenId'] is String
          ? json['canteenId']
          : (json['canteenId']?['_id'] ?? ''),
      items: lineItems,
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      paymentStatus: json['paymentStatus'] ?? 'pending',
      paymentId: json['paymentId'], // Parse paymentId
      qrCode: json['qrCode'],
      refundId: json['refundId'], // Parse refundId
      createdAt: json['createdAt'] ?? '',
    );
  }
}
