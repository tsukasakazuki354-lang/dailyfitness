import 'package:cloud_firestore/cloud_firestore.dart';

class CartItem {
  final String productId;
  final String name;
  final String image;
  final int quantity;
  final double price;

  CartItem({
    required this.productId,
    required this.name,
    required this.image,
    required this.quantity,
    required this.price,
  });

  factory CartItem.fromMap(Map<String, dynamic> data) {
    return CartItem(
      productId: data['productId'] ?? '',
      name: data['name'] ?? '',
      image: data['image'] ?? '',
      quantity: data['quantity'] ?? 1,
      price: (data['price'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'image': image,
      'quantity': quantity,
      'price': price,
    };
  }
}
