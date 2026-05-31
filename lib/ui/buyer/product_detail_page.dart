import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daily_fitness/models/product.dart';
import 'package:daily_fitness/providers/session_provider.dart';
import 'package:daily_fitness/services/firestore_service.dart';
import 'package:daily_fitness/ui/buyer/cart_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;
  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _quantity = 1;
  bool _addingToCart = false;
  bool _isInWishlist = false;
  bool _togglingWishlist = false;

  @override
  void initState() {
    super.initState();
    _checkWishlist();
  }

  Future<void> _checkWishlist() async {
    final uid = Provider.of<SessionProvider>(context, listen: false).currentUser?.uid;
    if (uid == null) return;
    final doc = await FirestoreService.wishlist().doc(uid).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>?;
      final items = List<String>.from(data?['productIds'] ?? []);
      if (mounted) {
        setState(() => _isInWishlist = items.contains(widget.product.productId));
      }
    }
  }

  Future<void> _toggleWishlist() async {
    final uid = Provider.of<SessionProvider>(context, listen: false).currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sign in to use wishlist')));
      return;
    }
    setState(() => _togglingWishlist = true);
    try {
      final ref = FirestoreService.wishlist().doc(uid);
      if (_isInWishlist) {
        await ref.update({'productIds': FieldValue.arrayRemove([widget.product.productId])});
      } else {
        await ref.set({
          'userId': uid,
          'productIds': FieldValue.arrayUnion([widget.product.productId]),
          'updatedAt': Timestamp.now(),
        }, SetOptions(merge: true));
      }
      setState(() => _isInWishlist = !_isInWishlist);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _togglingWishlist = false);
    }
  }

  Future<void> _addToCart() async {
    final uid = Provider.of<SessionProvider>(context, listen: false).currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sign in to add to cart')));
      return;
    }
    setState(() => _addingToCart = true);
    try {
      final cartRef = FirestoreService.carts().doc(uid);
      final cartDoc = await cartRef.get();
      List<Map<String, dynamic>> items = [];
      if (cartDoc.exists) {
        final data = cartDoc.data() as Map<String, dynamic>?;
        items = List<Map<String, dynamic>>.from(data?['items'] ?? []);
      }
      final existingIndex = items.indexWhere((i) => i['productId'] == widget.product.productId);
      if (existingIndex >= 0) {
        items[existingIndex]['quantity'] = (items[existingIndex]['quantity'] ?? 0) + _quantity;
      } else {
        items.add({
          'productId': widget.product.productId,
          'name': widget.product.productName,
          'image': widget.product.images.isNotEmpty ? widget.product.images.first : '',
          'quantity': _quantity,
          'price': widget.product.salePrice > 0 ? widget.product.salePrice : widget.product.price,
        });
      }
      final total = items.fold<double>(0, (sum, i) => sum + ((i['price'] ?? 0) as num).toDouble() * ((i['quantity'] ?? 1) as num).toInt());
      await FirestoreService.createCart(uid, items, total);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to cart!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _addingToCart = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final displayPrice = product.salePrice > 0 ? product.salePrice : product.price;
    return Scaffold(
      appBar: AppBar(
        title: Text(product.productName),
        actions: [
          IconButton(
            icon: Icon(_isInWishlist ? Icons.favorite : Icons.favorite_border, color: _isInWishlist ? Colors.red : null),
            onPressed: _togglingWishlist ? null : _toggleWishlist,
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartPage())),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 280,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F6FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: product.images.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(product.images.first, fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.fitness_center, size: 80, color: Colors.black26))),
                    )
                  : const Center(child: Icon(Icons.fitness_center, size: 80, color: Colors.black26)),
            ),
            const SizedBox(height: 20),
            Text(product.productName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFE5F2FF), borderRadius: BorderRadius.circular(8)),
                  child: Text(product.category, style: const TextStyle(fontSize: 12, color: Color(0xFF0F2850))),
                ),
                const SizedBox(width: 12),
                Text(product.stock > 0 ? 'In Stock (${product.stock})' : 'Sold Out',
                    style: TextStyle(color: product.stock > 0 ? Colors.green : Colors.red, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('\$${displayPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                if (product.salePrice > 0 && product.salePrice < product.price) ...[
                  const SizedBox(width: 12),
                  Text('\$${product.price.toStringAsFixed(2)}', style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.black38, fontSize: 18)),
                ],
              ],
            ),
            const SizedBox(height: 20),
            const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(product.description, style: const TextStyle(color: Colors.black54, height: 1.6)),
            if (product.tags.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: product.tags.map((tag) => Chip(label: Text(tag, style: const TextStyle(fontSize: 12)))).toList(),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                const Text('Quantity:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text('$_quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: _quantity < product.stock ? () => setState(() => _quantity++) : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: product.stock > 0 && !_addingToCart ? _addToCart : null,
                child: _addingToCart
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Add to Cart'),
              ),
            ),
            const SizedBox(height: 32),
            // Reviews Section
            _ProductReviewsSection(productId: product.productId),
          ],
        ),
      ),
    );
  }
}

// ─── Product Reviews Section ─────────────────────────────────────────────────

class _ProductReviewsSection extends StatelessWidget {
  final String productId;
  const _ProductReviewsSection({required this.productId});

  @override
  Widget build(BuildContext context) {
    final uid = Provider.of<SessionProvider>(context).currentUser?.uid;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Reviews', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        if (uid != null)
          TextButton.icon(
            onPressed: () => _showWriteReviewDialog(context, uid),
            icon: const Icon(Icons.rate_review_outlined, size: 18),
            label: const Text('Write Review'),
          ),
      ]),
      const SizedBox(height: 12),
      StreamBuilder<QuerySnapshot>(
        stream: FirestoreService.reviews().where('productId', isEqualTo: productId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return const Text('Unable to load reviews', style: TextStyle(color: Colors.black54));
          final reviews = snapshot.data?.docs ?? [];
          if (reviews.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFFF8FBFF), borderRadius: BorderRadius.circular(14)),
              child: const Center(child: Text('No reviews yet. Be the first to review!', style: TextStyle(color: Colors.black54))),
            );
          }
          return Column(children: reviews.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _ReviewTile(data: data);
          }).toList());
        },
      ),
    ]);
  }

  void _showWriteReviewDialog(BuildContext context, String uid) {
    final commentController = TextEditingController();
    int rating = 5;
    // Get user data from the page context (not dialog context)
    final user = Provider.of<SessionProvider>(context, listen: false).currentUser;
    final userName = '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Write a Review'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) => GestureDetector(
              onTap: () => setDialogState(() => rating = i + 1),
              child: Icon(i < rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 32),
            ))),
            const SizedBox(height: 16),
            TextField(controller: commentController, maxLines: 3, decoration: const InputDecoration(hintText: 'Share your experience...', border: OutlineInputBorder())),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (commentController.text.trim().isEmpty) return;
                final reviewId = 'rev_${DateTime.now().millisecondsSinceEpoch}';
                try {
                  await FirestoreService.reviews().doc(reviewId).set({
                    'reviewId': reviewId,
                    'productId': productId,
                    'userId': uid,
                    'userName': userName.isNotEmpty ? userName : 'Anonymous',
                    'rating': rating,
                    'comment': commentController.text.trim(),
                    'sellerReply': '',
                    'createdAt': Timestamp.now(),
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error submitting review: $e')));
                  }
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ReviewTile({required this.data});

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    final date = (timestamp as Timestamp).toDate();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    return '${months[date.month - 1]} ${date.day}, ${date.year} at $hour:${date.minute.toString().padLeft(2, '0')} $amPm';
  }

  @override
  Widget build(BuildContext context) {
    final rating = data['rating'] ?? 5;
    final comment = data['comment'] ?? '';
    final userName = data['userName'] ?? 'Anonymous';
    final sellerReply = data['sellerReply'] ?? '';
    final dateStr = _formatDate(data['createdAt']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(radius: 16, backgroundColor: const Color(0xFFE8F1FF), child: Text(userName.isNotEmpty ? userName[0].toUpperCase() : '?', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F2850)))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(userName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            if (dateStr.isNotEmpty) Text(dateStr, style: const TextStyle(color: Colors.black45, fontSize: 11)),
          ])),
          Row(mainAxisSize: MainAxisSize.min, children: List.generate(5, (i) => Icon(i < (rating as int) ? Icons.star : Icons.star_border, size: 16, color: Colors.amber))),
        ]),
        const SizedBox(height: 10),
        Text(comment, style: const TextStyle(color: Colors.black87, height: 1.4)),
        if (sellerReply.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF0F5FF), borderRadius: BorderRadius.circular(10)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.store, size: 16, color: Color(0xFF0F2850)),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Seller Reply', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF0F2850))),
                const SizedBox(height: 4),
                Text(sellerReply, style: const TextStyle(fontSize: 13, color: Colors.black54)),
              ])),
            ]),
          ),
        ],
      ]),
    );
  }
}
