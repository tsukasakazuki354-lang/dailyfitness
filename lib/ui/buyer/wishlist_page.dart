import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daily_fitness/models/product.dart';
import 'package:daily_fitness/providers/session_provider.dart';
import 'package:daily_fitness/services/firestore_service.dart';
import 'package:daily_fitness/ui/buyer/product_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = Provider.of<SessionProvider>(context).currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Wishlist')),
        body: const Center(child: Text('Please sign in to view your wishlist')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('My Wishlist')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirestoreService.wishlist().doc(uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return _emptyState();
          }
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          final productIds = List<String>.from(data?['productIds'] ?? []);
          if (productIds.isEmpty) {
            return _emptyState();
          }
          return _WishlistGrid(productIds: productIds, userId: uid);
        },
      ),
    );
  }

  Widget _emptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_border, size: 64, color: Colors.black26),
          SizedBox(height: 16),
          Text('Your wishlist is empty', style: TextStyle(fontSize: 16, color: Colors.black54)),
          SizedBox(height: 8),
          Text('Browse products and tap the heart icon to save items', style: TextStyle(color: Colors.black38)),
        ],
      ),
    );
  }
}

class _WishlistGrid extends StatelessWidget {
  final List<String> productIds;
  final String userId;
  const _WishlistGrid({required this.productIds, required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirestoreService.products().where('productId', whereIn: productIds.take(10).toList()).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading wishlist: ${snapshot.error}'));
        }
        final products = (snapshot.data?.docs ?? []).map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>)).toList();
        if (products.isEmpty) {
          return const Center(child: Text('Products in your wishlist are no longer available'));
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return _WishlistCard(product: product, userId: userId);
              },
            );
          },
        );
      },
    );
  }
}

class _WishlistCard extends StatelessWidget {
  final Product product;
  final String userId;
  const _WishlistCard({required this.product, required this.userId});

  Future<void> _removeFromWishlist(BuildContext context) async {
    try {
      await FirestoreService.wishlist().doc(userId).update({
        'productIds': FieldValue.arrayRemove([product.productId]),
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${product.productName} removed from wishlist')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayPrice = product.salePrice > 0 ? product.salePrice : product.price;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailPage(product: product))),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(color: const Color(0xFFF2F6FF), borderRadius: BorderRadius.circular(12)),
                      child: product.images.isNotEmpty
                          ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(product.images.first, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.fitness_center, size: 40, color: Colors.black26))))
                          : const Center(child: Icon(Icons.fitness_center, size: 40, color: Colors.black26)),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _removeFromWishlist(context),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.favorite, color: Colors.red, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(product.productName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text('\$${displayPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}
