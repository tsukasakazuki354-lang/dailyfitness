import 'package:daily_fitness/models/product.dart';
import 'package:daily_fitness/providers/session_provider.dart';
import 'package:daily_fitness/services/firestore_service.dart';
import 'package:daily_fitness/ui/buyer/cart_page.dart';
import 'package:daily_fitness/ui/buyer/product_detail_page.dart';
import 'package:daily_fitness/ui/buyer/shop_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The home page content for the buyer dashboard.
/// Rendered inside BuyerShell — no Scaffold or AppBar here.
class BuyerHomeContent extends StatefulWidget {
  final bool isGuest;
  final ValueChanged<int> onNavigate;

  const BuyerHomeContent({super.key, this.isGuest = false, required this.onNavigate});

  @override
  State<BuyerHomeContent> createState() => _BuyerHomeContentState();
}

class _BuyerHomeContentState extends State<BuyerHomeContent> {
  final TextEditingController _searchController = TextEditingController();
  String _filter = 'Relevance';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateTo(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<SessionProvider>(context).currentUser;
    final width = MediaQuery.of(context).size.width;
    final name = user?.firstName ?? 'Guest';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroSection(name, width),
          const SizedBox(height: 24),
          _buildFilterBar(),
          const SizedBox(height: 24),
          _buildQuickActionRow(width),
          const SizedBox(height: 28),
          _buildSectionHeader('Shop by Category', onViewAll: () => widget.onNavigate(1)),
          const SizedBox(height: 16),
          _buildCategories(width),
          const SizedBox(height: 28),
          _buildSectionHeader('Best Sellers', onViewAll: () => widget.onNavigate(1)),
          const SizedBox(height: 16),
          _buildBestSellers(),
          const SizedBox(height: 28),
          _buildSectionHeader('New Arrivals', onViewAll: () => widget.onNavigate(1)),
          const SizedBox(height: 16),
          _buildNewArrivals(),
          const SizedBox(height: 28),
          _buildSectionHeader('All Products', onViewAll: () => widget.onNavigate(1)),
          const SizedBox(height: 16),
          _buildProductsGrid(width),
          const SizedBox(height: 28),
          _buildAboutUs(),
        ],
      ),
    );
  }

  Widget _buildHeroSection(String name, double width) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 24)],
      ),
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Daily Fitness', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  'Hi $name, discover premium gym equipment, supplements, and accessories all in one premium store.',
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: () => widget.onNavigate(1),
                  child: const Text('Browse Products'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(color: const Color(0xFF4AB3F4), borderRadius: BorderRadius.circular(24)),
                child: Center(child: Icon(Icons.fitness_center, size: width < 400 ? 48 : 64, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search products...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); setState(() {}); })
                  : null,
            ),
          ),
        ),
        const SizedBox(width: 12),
        DropdownButton<String>(
          value: _filter,
          underline: const SizedBox(),
          items: const [
            DropdownMenuItem(value: 'Relevance', child: Text('Relevance')),
            DropdownMenuItem(value: 'Latest', child: Text('Latest')),
            DropdownMenuItem(value: 'Top Sales', child: Text('Top Sales')),
            DropdownMenuItem(value: 'Price: Low to High', child: Text('Low→High')),
            DropdownMenuItem(value: 'Price: High to Low', child: Text('High→Low')),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _filter = value);
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionRow(double width) {
    final actions = [
      {'label': 'Browse Products', 'index': 1},
      {'label': 'View Cart', 'index': -1},
      {'label': 'My Wishlist', 'index': 2},
      {'label': 'My Orders', 'index': 3},
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: actions.map((item) {
        return SizedBox(
          width: width > 720 ? 160 : (width - 64) / 2,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE5F2FF),
              foregroundColor: const Color(0xFF0F2850),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () {
              final idx = item['index'] as int;
              if (idx == -1) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CartPage()));
              } else {
                widget.onNavigate(idx);
              }
            },
            child: Text(item['label'] as String, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onViewAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        TextButton(onPressed: onViewAll, child: const Text('View all')),
      ],
    );
  }

  Widget _buildCategories(double width) {
    final categories = ['Gym Equipment', 'Supplements', 'Accessories'];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: categories.map((category) {
        return GestureDetector(
          onTap: () => _navigateTo(ShopPage(initialCategory: category)),
          child: Container(
            width: width > 760 ? 160 : (width - 64) / 2,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.category, size: 28, color: Color(0xFF0F2850)),
                const SizedBox(height: 10),
                Text(category, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBestSellers() {
    return SizedBox(
      height: 230,
      child: StreamBuilder<List<Product>>(
        stream: FirestoreService.liveProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final products = snapshot.data ?? [];
          if (products.isEmpty) {
            return const Center(child: Text('No products available', style: TextStyle(color: Colors.black54)));
          }
          final bestSellers = products.take(5).toList();
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: bestSellers.length,
            itemBuilder: (context, index) => _productHighlight(bestSellers[index]),
          );
        },
      ),
    );
  }

  Widget _productHighlight(Product product) {
    final displayPrice = product.salePrice > 0 ? product.salePrice : product.price;
    return GestureDetector(
      onTap: () => _navigateTo(ProductDetailPage(product: product)),
      child: Container(
        width: 260,
        margin: const EdgeInsets.only(right: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.star, color: Color(0xFF4AB3F4), size: 24),
            const SizedBox(height: 10),
            Text(product.productName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Text(product.description, style: const TextStyle(color: Colors.black54, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('\$${displayPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ElevatedButton(
                  onPressed: () => _navigateTo(ProductDetailPage(product: product)),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
                  child: const Text('View', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewArrivals() {
    return SizedBox(
      height: 210,
      child: StreamBuilder<List<Product>>(
        stream: FirestoreService.liveProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final products = snapshot.data ?? [];
          if (products.isEmpty) {
            return const Center(child: Text('No new arrivals', style: TextStyle(color: Colors.black54)));
          }
          final sorted = List<Product>.from(products)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          final arrivals = sorted.take(5).toList();
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: arrivals.length,
            itemBuilder: (context, index) => _arrivalCard(arrivals[index]),
          );
        },
      ),
    );
  }

  Widget _arrivalCard(Product product) {
    final displayPrice = product.salePrice > 0 ? product.salePrice : product.price;
    return GestureDetector(
      onTap: () => _navigateTo(ProductDetailPage(product: product)),
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.new_releases, size: 26, color: Color(0xFF0F2850)),
            const SizedBox(height: 10),
            Text(product.productName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Text(product.description, style: const TextStyle(color: Colors.black54, fontSize: 12, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
            const Spacer(),
            Text('\$${displayPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsGrid(double width) {
    return StreamBuilder<List<Product>>(
      stream: FirestoreService.liveProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final products = snapshot.data ?? [];
        if (products.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.storefront_outlined, size: 48, color: Colors.black26),
                  SizedBox(height: 12),
                  Text('No products are available yet.', style: TextStyle(color: Colors.black54)),
                ],
              ),
            ),
          );
        }
        final filtered = products.where((p) => p.productName.toLowerCase().contains(_searchController.text.toLowerCase())).toList();
        if (filtered.isEmpty) {
          return const Center(child: Text('No products match your search', style: TextStyle(color: Colors.black54)));
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: width > 1000 ? 4 : width > 600 ? 3 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.72,
          ),
          itemCount: filtered.length,
          itemBuilder: (context, index) => _buildProductCard(filtered[index]),
        );
      },
    );
  }

  Widget _buildProductCard(Product product) {
    final displayPrice = product.salePrice > 0 ? product.salePrice : product.price;
    return GestureDetector(
      onTap: () => _navigateTo(ProductDetailPage(product: product)),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(color: const Color(0xFFF2F6FF), borderRadius: BorderRadius.circular(12)),
                  child: product.images.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(product.images.first, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(child: Icon(Icons.fitness_center, size: 36, color: Colors.blue.shade200))),
                        )
                      : Center(child: Icon(Icons.fitness_center, size: 36, color: Colors.blue.shade200)),
                ),
              ),
              const SizedBox(height: 8),
              Text(product.productName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text('\$${displayPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                  SizedBox(
                    height: 28,
                    child: ElevatedButton(
                      onPressed: () => _addToCartQuick(product),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10)),
                      child: const Text('Add', style: TextStyle(fontSize: 11)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addToCartQuick(Product product) async {
    final uid = Provider.of<SessionProvider>(context, listen: false).currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sign in to add to cart')));
      return;
    }
    try {
      final cartRef = FirestoreService.carts().doc(uid);
      final cartDoc = await cartRef.get();
      List<Map<String, dynamic>> items = [];
      if (cartDoc.exists) {
        final data = cartDoc.data() as Map<String, dynamic>?;
        items = List<Map<String, dynamic>>.from(data?['items'] ?? []);
      }
      final existingIndex = items.indexWhere((i) => i['productId'] == product.productId);
      if (existingIndex >= 0) {
        items[existingIndex]['quantity'] = ((items[existingIndex]['quantity'] ?? 0) as num).toInt() + 1;
      } else {
        items.add({
          'productId': product.productId,
          'name': product.productName,
          'image': product.images.isNotEmpty ? product.images.first : '',
          'quantity': 1,
          'price': product.salePrice > 0 ? product.salePrice : product.price,
        });
      }
      final total = items.fold<double>(0, (s, i) => s + ((i['price'] ?? 0) as num).toDouble() * ((i['quantity'] ?? 1) as num).toInt());
      await FirestoreService.createCart(uid, items, total);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${product.productName} added to cart')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Widget _buildAboutUs() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16)],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('About Us', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          const Text('The Story Behind Daily Fitness', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text(
            'Daily Fitness brings premium equipment, clean supplements, and essential accessories together in a modern shopping experience designed for athletes and everyday gym-goers.',
            style: TextStyle(color: Colors.black54, height: 1.6),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _featureTile('What Makes Us Different', 'Curated products, fast support, and a premium experience.'),
              _featureTile('What We Stand For', 'Health, performance, and seamless shopping across devices.'),
              _featureTile('Meet the Experts', 'Trainers and nutrition coaches who help source every item.'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _featureTile(String title, String subtitle) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFF8FBFF), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 13)),
        ],
      ),
    );
  }
}
