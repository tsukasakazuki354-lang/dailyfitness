import 'package:daily_fitness/models/product.dart';
import 'package:daily_fitness/services/firestore_service.dart';
import 'package:daily_fitness/ui/buyer/product_detail_page.dart';
import 'package:flutter/material.dart';

class ShopPage extends StatefulWidget {
  final String? initialCategory;
  const ShopPage({super.key, this.initialCategory});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _sortBy = 'Relevance';

  final List<String> _categories = [
    'All',
    'Gym Equipment',
    'Supplements',
    'Accessories',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null && widget.initialCategory!.isNotEmpty) {
      _selectedCategory = widget.initialCategory!;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Product> _applyFilters(List<Product> products) {
    var filtered = products.where((p) {
      final matchesCategory = _selectedCategory == 'All' || p.category == _selectedCategory;
      final matchesSearch = _searchController.text.isEmpty ||
          p.productName.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          p.description.toLowerCase().contains(_searchController.text.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    switch (_sortBy) {
      case 'Price: Low to High':
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Price: High to Low':
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Latest':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shop')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = cat == _selectedCategory;
                return ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedCategory = cat),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('Sort: '),
                DropdownButton<String>(
                  value: _sortBy,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'Relevance', child: Text('Relevance')),
                    DropdownMenuItem(value: 'Latest', child: Text('Latest')),
                    DropdownMenuItem(value: 'Price: Low to High', child: Text('Low to High')),
                    DropdownMenuItem(value: 'Price: High to Low', child: Text('High to Low')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _sortBy = v);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: FirestoreService.liveProducts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final products = _applyFilters(snapshot.data ?? []);
                if (products.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.storefront_outlined, size: 64, color: Colors.black26),
                        SizedBox(height: 16),
                        Text('No products found', style: TextStyle(fontSize: 16, color: Colors.black54)),
                      ],
                    ),
                  );
                }
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 900 ? 4 : constraints.maxWidth > 600 ? 3 : 2;
                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.7,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) => _ProductCard(product: products[index]),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final displayPrice = product.salePrice > 0 ? product.salePrice : product.price;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductDetailPage(product: product)),
      ),
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: product.images.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(product.images.first, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.fitness_center, size: 40, color: Colors.black26))),
                        )
                      : const Center(child: Icon(Icons.fitness_center, size: 40, color: Colors.black26)),
                ),
              ),
              const SizedBox(height: 8),
              Text(product.productName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(product.category, style: const TextStyle(color: Colors.black45, fontSize: 12)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text('\$${displayPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  if (product.salePrice > 0 && product.salePrice < product.price) ...[
                    const SizedBox(width: 6),
                    Text('\$${product.price.toStringAsFixed(2)}', style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.black38, fontSize: 12)),
                  ],
                ],
              ),
              if (product.stock <= 0)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(6)),
                  child: const Text('Sold Out', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
