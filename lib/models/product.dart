import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String productId;
  final String sellerId;
  final String category;
  final String productName;
  final String description;
  final double price;
  final double salePrice;
  final int stock;
  final String status;
  final List<String> images;
  final List<String> tags;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  Product({
    required this.productId,
    required this.sellerId,
    required this.category,
    required this.productName,
    required this.description,
    required this.price,
    required this.salePrice,
    required this.stock,
    required this.status,
    required this.images,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromMap(Map<String, dynamic> data) {
    return Product(
      productId: data['productId'] ?? '',
      sellerId: data['sellerId'] ?? '',
      category: data['category'] ?? 'Accessories',
      productName: data['productName'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      salePrice: (data['salePrice'] ?? 0).toDouble(),
      stock: data['stock'] ?? 0,
      status: data['status'] ?? 'active',
      images: List<String>.from(data['images'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'sellerId': sellerId,
      'category': category,
      'productName': productName,
      'description': description,
      'price': price,
      'salePrice': salePrice,
      'stock': stock,
      'status': status,
      'images': images,
      'tags': tags,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
