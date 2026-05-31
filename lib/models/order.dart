import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  final String productId;
  final String name;
  final int quantity;
  final double price;

  OrderItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.price,
  });

  factory OrderItem.fromMap(Map<String, dynamic> data) {
    return OrderItem(
      productId: data['productId'] ?? '',
      name: data['name'] ?? '',
      quantity: data['quantity'] ?? 1,
      price: (data['price'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'quantity': quantity,
      'price': price,
    };
  }
}

class Order {
  final String orderId;
  final String buyerId;
  final String sellerId;
  final String riderId;
  final List<OrderItem> items;
  final double subtotal;
  final double shippingFee;
  final double total;
  final String paymentMethod;
  final String paymentStatus;
  final String orderStatus;
  final String deliveryStatus;
  final Map<String, dynamic> address;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  Order({
    required this.orderId,
    required this.buyerId,
    required this.sellerId,
    required this.riderId,
    required this.items,
    required this.subtotal,
    required this.shippingFee,
    required this.total,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.orderStatus,
    required this.deliveryStatus,
    required this.address,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Order.fromMap(Map<String, dynamic> data) {
    return Order(
      orderId: data['orderId'] ?? '',
      buyerId: data['buyerId'] ?? '',
      sellerId: data['sellerId'] ?? '',
      riderId: data['riderId'] ?? '',
      items: data['items'] != null
          ? List<Map<String, dynamic>>.from(data['items']).map(OrderItem.fromMap).toList()
          : [],
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      shippingFee: (data['shippingFee'] ?? 0).toDouble(),
      total: (data['total'] ?? 0).toDouble(),
      paymentMethod: data['paymentMethod'] ?? 'card',
      paymentStatus: data['paymentStatus'] ?? 'pending',
      orderStatus: data['orderStatus'] ?? 'created',
      deliveryStatus: data['deliveryStatus'] ?? 'pending',
      address: Map<String, dynamic>.from(data['address'] ?? {}),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'buyerId': buyerId,
      'sellerId': sellerId,
      'riderId': riderId,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'shippingFee': shippingFee,
      'total': total,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'orderStatus': orderStatus,
      'deliveryStatus': deliveryStatus,
      'address': address,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
