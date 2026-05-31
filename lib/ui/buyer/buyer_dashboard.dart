import 'package:daily_fitness/models/product.dart';
import 'package:daily_fitness/providers/session_provider.dart';
import 'package:daily_fitness/services/firestore_service.dart';
import 'package:daily_fitness/ui/buyer/cart_page.dart';
import 'package:daily_fitness/ui/buyer/notifications_page.dart';
import 'package:daily_fitness/ui/buyer/order_history_page.dart';
import 'package:daily_fitness/ui/buyer/product_detail_page.dart';
import 'package:daily_fitness/ui/buyer/profile_page.dart';
import 'package:daily_fitness/ui/buyer/saved_addresses_page.dart';
import 'package:daily_fitness/ui/buyer/shop_page.dart';
import 'package:daily_fitness/ui/buyer/wishlist_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BuyerDashboard extends StatefulWidget {
  final bool isGuest;
  const BuyerDashboard({super.key, this.isGuest = false});

  @override
  State<BuyerDashboard> createState() => _BuyerDashboardState();
}

class _BuyerDashboardState extends State<BuyerDashboard> {
  final TextEditingController _searchController = TextEditingController();
  String _filter = 'Relevance';

  void _navigateTo(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<SessionProvider>(context).currentUser;
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Fitness Store'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () => _navigateTo(const NotificationsPage()),
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => _navigateTo(const CartPage()),
          ),
        ],
      ),
      drawer: width < 900 ? _buildDrawer(context, user?.firstName ?? 'Guest') : null,
      body: Row(
        children: [
          if (width >= 900) SizedBox(width: 280, child: _buildDrawer(context, user?.firstName ?? 'Guest')),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroSection(user?.firstName ?? 'Guest'),
                  const SizedBox(height: 24),
                  _buildFilterBar(),
                  const SizedBox(height: 24),
                  _buildQuickActionRow(width),
                  const SizedBox(height: 28),
                  _buildSectionHeader('Shop by Category', onViewAll: () => _navigateTo(const ShopPage())),
                  const SizedBox(height: 16),
                  _buildCategories(width),
                  const SizedBox(height: 28),
                  _buildSectionHeader('Best Sellers', onViewAll: () => _navigateTo(const ShopPage())),
                  const SizedBox(height: 16),
                  _buildBestSellers(width),
                  const SizedBox(height: 28),
                  _buildSectionHeader('New Arrivals', onViewAll: () => _navigateTo(const ShopPage())),
                  const SizedBox(height: 16),
                  _buildNewArrivals(width),
                  const SizedBox(height: 28),
                  _buildSectionHeader('All Products', onViewAll: () => _navigateTo(const ShopPage())),
                  const SizedBox(height: 16),
                  _buildProductsGrid(width),
                  const SizedBox(height: 28),
                  _buildAboutUs(width),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, String name) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              color: const Color(0xFF0F2850),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hello, $name', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('Shop gym equipment, supplements, and essentials.', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _drawerItem(Icons.home_filled, 'Home', () {
                    Navigator.pop(context);
                  }),
                  _drawerItem(Icons.category, 'Shop', () {
                    Navigator.pop(context);
                    _navigateTo(const ShopPage());
                  }),
                  _drawerItem(Icons.favorite_border, 'Wishlist', () {
                    Navigator.pop(context);
                    _navigateTo(const WishlistPage());
                  }),
                  _drawerItem(Icons.history, 'Order History', () {
                    Navigator.pop(context);
                    _navigateTo(const OrderHistoryPage());
                  }),
                  _drawerItem(Icons.location_on_outlined, 'Saved Addresses', () {
                    Navigator.pop(context);
                    _navigateTo(const SavedAddressesPage());
                  }),
                  _drawerItem(Icons.person_outline, 'My Profile', () {
                    Navigator.pop(context);
                    _navigateTo(const ProfilePage());
                  }),
                  _drawerItem(Icons.notifications_outlined, 'Notifications', () {
                    Navigator.pop(context);
                    _navigateTo(const NotificationsPage());
                  }),
                  _drawerItem(Icons.logout, 'Logout', () async {
                    await Provider.of<SessionProvider>(context, listen: false).signOut();
                    if (mounted) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF0F2850)),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }

  Widget _buildHeroSection(String name) {
    final width = MediaQuery.of(context).size.width;
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 24)]),
      padding: const EdgeInsets.all(28),
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
                Text('Hi $name, discover premium gym equipment, supplements, and accessories all in one premium store.', style: const TextStyle(fontSize: 14, color: Colors.black54)),
                const SizedBox(height: 18),
                SizedBox(
                  width: 180,
                  child: ElevatedButton(
                    onPressed: () => _navigateTo(const ShopPage()),
                    child: const Text('Browse Products'),
                  ),
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
                child: Center(child: Icon(Icons.fitness_center, size: width < 400 ? 48 : 72, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search gym equipment, supplements, accessories',
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
        const SizedBox(width: 18),
        DropdownButton<String>(
          value: _filter,
          items: const [
            DropdownMenuItem(value: 'Relevance', child: Text('Relevance')),
            DropdownMenuItem(value: 'Latest', child: Text('Latest')),
            DropdownMenuItem(value: 'Top Sales', child: Text('Top Sales')),
            DropdownMenuItem(value: 'Price: Low to High', child: Text('Price: Low to High')),
            DropdownMenuItem(value: 'Price: High to Low', child: Text('Price: High to Low')),
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
      {'label': 'Browse Products', 'action': () => _navigateTo(const ShopPage())},
      {'label': 'View Cart', 'action': () => _navigateTo(const CartPage())},
      {'label': 'My Wishlist', 'action': () => _navigateTo(const WishlistPage())},
      {'label': 'My Orders', 'action': () => _navigateTo(const OrderHistoryPage())},
    ];
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: actions.map((item) {
        return SizedBox(
          width: width > 720 ? 180 : double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE5F2FF), foregroundColor: const Color(0xFF0F2850)),
            onPressed: item['action'] as VoidCallback,
            child: Text(item['label'] as String, textAlign: TextAlign.center),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onViewAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        TextButton(onPressed: onViewAll ?? () => _navigateTo(const ShopPage()), child: const Text('View all')),
      ],
    );
  }

  Widget _buildCategories(double width) {
    final categories = ['Gym Equipment', 'Supplements', 'Accessories', 'Performance', 'Recovery'];
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: categories.map((category) {
        return GestureDetector(
          onTap: () => _navigateTo(ShopPage(initialCategory: category)),
          child: Container(
            width: width > 760 ? 180 : double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16)]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.category, size: 32, color: Color(0xFF0F2850)),
                const SizedBox(height: 14),
                Text(category, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBestSellers(double width) {
    return SizedBox(
      height: 240,
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
        width: 280,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16)]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.star, color: Color(0xFF4AB3F4), size: 28),
            const SizedBox(height: 12),
            Text(product.productName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Text(product.description, style: const TextStyle(color: Colors.black54), maxLines: 2, overflow: TextOverflow.ellipsis),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('\$${displayPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ElevatedButton(
                  onPressed: () => _navigateTo(ProductDetailPage(product: product)),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                  child: const Text('Shop Now'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewArrivals(double width) {
    return SizedBox(
      height: 220,
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
          // Sort by createdAt descending for new arrivals
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
        width: 220,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.new_releases, size: 30, color: Color(0xFF0F2850)),
          const SizedBox(height: 12),
          Text(product.productName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Text(product.description, style: const TextStyle(color: Colors.black54, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
          const Spacer(),
          Text('\$${displayPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
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
        final filtered = products.where((product) => product.productName.toLowerCase().contains(_searchController.text.toLowerCase())).toList();
        if (filtered.isEmpty) {
          return const Center(child: Text('No products match your search', style: TextStyle(color: Colors.black54)));
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: width > 1200 ? 4 : width > 800 ? 3 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.72,
          ),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final product = filtered[index];
            return _buildProductCard(product);
          },
        );
      },
    );
  }

  Widget _buildProductCard(Product product) {
    final displayPrice = product.salePrice > 0 ? product.salePrice : product.price;
    return GestureDetector(
      onTap: () => _navigateTo(ProductDetailPage(product: product)),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F6FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: product.images.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(product.images.first, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(child: Icon(Icons.fitness_center, size: 40, color: Colors.blue.shade200))),
                        )
                      : Center(child: Icon(Icons.fitness_center, size: 40, color: Colors.blue.shade200)),
                ),
              ),
              const SizedBox(height: 10),
              Text(product.productName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(product.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black54, fontSize: 12)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text('\$${displayPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                  SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      onPressed: () => _addToCartQuick(product),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
                      child: const Text('Add', style: TextStyle(fontSize: 12)),
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
      final total = items.fold<double>(0, (sum, i) => sum + ((i['price'] ?? 0) as num).toDouble() * ((i['quantity'] ?? 1) as num).toInt());
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

  Widget _buildAboutUs(double width) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 24)]),
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('About Us', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 18),
        const Text('The Story Behind Daily Fitness', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        const Text('Daily Fitness brings premium equipment, clean supplements, and essential accessories together in a modern shopping experience designed for athletes and everyday gym-goers.', style: TextStyle(color: Colors.black54, height: 1.6)),
        const SizedBox(height: 16),
        Wrap(spacing: 16, runSpacing: 16, children: [
          _featureTile('What Makes Us Different', 'Curated products, fast support, and a premium experience.'),
          _featureTile('What We Stand For', 'Health, performance, and seamless shopping across devices.'),
          _featureTile('Meet the Experts', 'Trainers and nutrition coaches who help source every item.'),
        ]),
      ]),
    );
  }

  Widget _featureTile(String title, String subtitle) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFFF8FBFF), borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(subtitle, style: const TextStyle(color: Colors.black54)),
      ]),
    );
  }
}
