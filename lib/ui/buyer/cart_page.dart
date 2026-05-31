import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daily_fitness/models/cart_item.dart';
import 'package:daily_fitness/models/product.dart';
import 'package:daily_fitness/providers/session_provider.dart';
import 'package:daily_fitness/services/firestore_service.dart';
import 'package:daily_fitness/ui/buyer/checkout_page.dart';
import 'package:daily_fitness/ui/buyer/product_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final Set<String> _selectedIds = {};
  bool _selectAll = false;

  @override
  Widget build(BuildContext context) {
    final uid = Provider.of<SessionProvider>(context).currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Cart')),
        body: const Center(child: Text('Please sign in to view your cart')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('My Cart')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirestoreService.carts().doc(uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return _emptyCart();
          }
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final items = (data['items'] as List<dynamic>?)?.map((e) => CartItem.fromMap(Map<String, dynamic>.from(e))).toList() ?? [];

          if (items.isEmpty) return _emptyCart();

          // Calculate selected total
          final selectedItems = items.where((i) => _selectedIds.contains(i.productId)).toList();
          final selectedTotal = selectedItems.fold<double>(0, (s, i) => s + i.price * i.quantity);

          return Column(
            children: [
              // Select all row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: const Color(0xFFF8FBFF),
                child: Row(children: [
                  SizedBox(
                    width: 24, height: 24,
                    child: Checkbox(
                      value: _selectAll && _selectedIds.length == items.length,
                      onChanged: (v) {
                        setState(() {
                          _selectAll = v ?? false;
                          if (_selectAll) {
                            _selectedIds.addAll(items.map((i) => i.productId));
                          } else {
                            _selectedIds.clear();
                          }
                        });
                      },
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text('Select All', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const Spacer(),
                  Text('${_selectedIds.length} selected', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                ]),
              ),
              // Items list
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isSelected = _selectedIds.contains(item.productId);
                    return _CartItemTile(
                      item: item,
                      isSelected: isSelected,
                      onSelect: (v) {
                        setState(() {
                          if (v) {
                            _selectedIds.add(item.productId);
                          } else {
                            _selectedIds.remove(item.productId);
                          }
                          _selectAll = _selectedIds.length == items.length;
                        });
                      },
                      onUpdateQuantity: (newQty) => _updateQuantity(uid, items, index, newQty),
                      onRemove: () => _removeItem(uid, items, index),
                      onTap: () => _viewProduct(item),
                    );
                  },
                ),
              ),
              // Bottom bar
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
                ),
                child: SafeArea(
                  child: Row(children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${selectedItems.length} item(s) selected', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                          const SizedBox(height: 2),
                          Text('\$${selectedTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: selectedItems.isEmpty ? null : () => _checkout(uid, items, selectedItems, selectedTotal),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14)),
                      child: const Text('Checkout'),
                    ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _emptyCart() {
    return const Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.black26),
        SizedBox(height: 16),
        Text('Your cart is empty', style: TextStyle(fontSize: 16, color: Colors.black54)),
      ]),
    );
  }

  Future<void> _viewProduct(CartItem item) async {
    try {
      final doc = await FirestoreService.products().doc(item.productId).get();
      if (doc.exists && mounted) {
        final product = Product.fromMap(doc.data() as Map<String, dynamic>);
        Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailPage(product: product)));
      }
    } catch (_) {}
  }

  void _checkout(String uid, List<CartItem> allItems, List<CartItem> selectedItems, double total) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CheckoutPage(items: selectedItems, total: total)),
    );
    // If checkout was successful, remove only the checked-out items from cart
    if (result == true && mounted) {
      final remainingItems = allItems.where((i) => !_selectedIds.contains(i.productId)).map((e) => e.toMap()).toList();
      final remainingTotal = remainingItems.fold<double>(0, (s, i) => s + ((i['price'] ?? 0) as num).toDouble() * ((i['quantity'] ?? 1) as num).toInt());
      await FirestoreService.createCart(uid, remainingItems, remainingTotal);
      setState(() => _selectedIds.clear());
    }
  }

  Future<void> _updateQuantity(String uid, List<CartItem> items, int index, int newQty) async {
    final updatedItems = items.map((e) => e.toMap()).toList();
    updatedItems[index]['quantity'] = newQty;
    final total = updatedItems.fold<double>(0, (s, i) => s + ((i['price'] ?? 0) as num).toDouble() * ((i['quantity'] ?? 1) as num).toInt());
    await FirestoreService.createCart(uid, updatedItems, total);
  }

  Future<void> _removeItem(String uid, List<CartItem> items, int index) async {
    final removedId = items[index].productId;
    final updatedItems = items.map((e) => e.toMap()).toList();
    updatedItems.removeAt(index);
    final total = updatedItems.fold<double>(0, (s, i) => s + ((i['price'] ?? 0) as num).toDouble() * ((i['quantity'] ?? 1) as num).toInt());
    await FirestoreService.createCart(uid, updatedItems, total);
    setState(() => _selectedIds.remove(removedId));
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  final bool isSelected;
  final ValueChanged<bool> onSelect;
  final ValueChanged<int> onUpdateQuantity;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  const _CartItemTile({required this.item, required this.isSelected, required this.onSelect, required this.onUpdateQuantity, required this.onRemove, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF0F7FF) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isSelected ? const Color(0xFF4AB3F4) : const Color(0xFFEEF2F6), width: 1.5),
      ),
      child: Row(children: [
        SizedBox(
          width: 22, height: 22,
          child: Checkbox(
            value: isSelected,
            onChanged: (v) => onSelect(v ?? false),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 56, height: 56,
            decoration: BoxDecoration(color: const Color(0xFFF2F6FF), borderRadius: BorderRadius.circular(12)),
            child: item.image.isNotEmpty
                ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(item.image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.fitness_center, color: Colors.black26)))
                : const Icon(Icons.fitness_center, color: Colors.black26),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text('\$${item.price.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF0F2850), fontWeight: FontWeight.bold)),
            ]),
          ),
        ),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            GestureDetector(
              onTap: item.quantity > 1 ? () => onUpdateQuantity(item.quantity - 1) : null,
              child: Icon(Icons.remove_circle_outline, size: 22, color: item.quantity > 1 ? const Color(0xFF0F2850) : Colors.black26),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
            GestureDetector(
              onTap: () => onUpdateQuantity(item.quantity + 1),
              child: const Icon(Icons.add_circle_outline, size: 22, color: Color(0xFF0F2850)),
            ),
          ]),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
          ),
        ]),
      ]),
    );
  }
}
