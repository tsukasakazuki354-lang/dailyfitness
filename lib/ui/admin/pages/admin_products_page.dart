import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daily_fitness/models/product.dart';
import 'package:daily_fitness/services/firestore_service.dart';
import 'package:flutter/material.dart';

class AdminProductsPage extends StatefulWidget {
  const AdminProductsPage({super.key});

  @override
  State<AdminProductsPage> createState() => _AdminProductsPageState();
}

class _AdminProductsPageState extends State<AdminProductsPage> {
  String _search = '';
  String _categoryFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product Monitoring'), automaticallyImplyLeading: false),
      body: Column(children: [
        // Search and filter
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(children: [
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => _search = v.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true, fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 12),
            DropdownButton<String>(
              value: _categoryFilter,
              underline: const SizedBox(),
              items: ['All', 'Gym Equipment', 'Supplements', 'Accessories'].map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (v) { if (v != null) setState(() => _categoryFilter = v); },
            ),
          ]),
        ),
        // Product list
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirestoreService.products().snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              var products = (snapshot.data?.docs ?? []).map((d) => Product.fromMap(d.data() as Map<String, dynamic>)).toList();

              if (_categoryFilter != 'All') products = products.where((p) => p.category == _categoryFilter).toList();
              if (_search.isNotEmpty) products = products.where((p) => p.productName.toLowerCase().contains(_search) || p.description.toLowerCase().contains(_search)).toList();

              if (products.isEmpty) return const Center(child: Text('No products found', style: TextStyle(color: Colors.black54)));

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: products.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final p = products[index];
                  return _ProductMonitorCard(product: p);
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _ProductMonitorCard extends StatelessWidget {
  final Product product;
  const _ProductMonitorCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(color: const Color(0xFFF2F6FF), borderRadius: BorderRadius.circular(12)),
            child: product.images.isNotEmpty
                ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(product.images.first, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.fitness_center, color: Colors.black26)))
                : const Icon(Icons.fitness_center, color: Colors.black26),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(product.productName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text('${product.category} • \$${product.price.toStringAsFixed(2)}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
            Row(children: [
              Icon(Icons.inventory, size: 14, color: product.stock > 0 ? Colors.green : Colors.red),
              const SizedBox(width: 4),
              Text('Stock: ${product.stock}', style: TextStyle(fontSize: 11, color: product.stock > 0 ? Colors.green : Colors.red, fontWeight: FontWeight.w600)),
              const SizedBox(width: 12),
              Text('Seller: ${product.sellerId.length > 8 ? product.sellerId.substring(0, 8) : product.sellerId}...', style: const TextStyle(fontSize: 11, color: Colors.black38)),
            ]),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: product.status == 'active' ? Colors.green.shade50 : Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
            child: Text(product.status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: product.status == 'active' ? Colors.green.shade700 : Colors.grey)),
          ),
        ]),
      ),
    );
  }
}
