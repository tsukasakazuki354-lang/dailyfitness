import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daily_fitness/models/product.dart';
import 'package:daily_fitness/providers/session_provider.dart';
import 'package:daily_fitness/services/cloudinary_service.dart';
import 'package:daily_fitness/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class SellerProductsPage extends StatelessWidget {
  const SellerProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = Provider.of<SessionProvider>(context).currentUser?.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('My Products'), automaticallyImplyLeading: false),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddProductSheet(context, uid ?? ''),
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreService.products().where('sellerId', isEqualTo: uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final products = (snapshot.data?.docs ?? []).map((d) => Product.fromMap(d.data() as Map<String, dynamic>)).toList();

          // Auto-fix: set products with 0 stock to inactive
          for (final p in products) {
            if (p.stock <= 0 && p.status == 'active') {
              FirestoreService.products().doc(p.productId).update({'status': 'inactive'});
            }
          }

          if (products.isEmpty) {
            return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.inventory_2_outlined, size: 64, color: Colors.black26),
              SizedBox(height: 16),
              Text('No products yet', style: TextStyle(fontSize: 16, color: Colors.black54)),
              SizedBox(height: 8),
              Text('Tap + to add your first product', style: TextStyle(color: Colors.black38)),
            ]));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final p = products[index];
              return _ProductCard(product: p, sellerId: uid ?? '');
            },
          );
        },
      ),
    );
  }

  void _showAddProductSheet(BuildContext context, String sellerId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: DraggableScrollableSheet(
          initialChildSize: 0.9, minChildSize: 0.5, maxChildSize: 0.95, expand: false,
          builder: (context, sc) => _AddProductForm(sellerId: sellerId, scrollController: sc),
        ),
      ),
    );
  }
}

// ─── Product Card (tappable to view) ─────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final Product product;
  final String sellerId;
  const _ProductCard({required this.product, required this.sellerId});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _SellerProductDetailPage(product: product))),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(color: const Color(0xFFF2F6FF), borderRadius: BorderRadius.circular(12)),
              child: product.images.isNotEmpty
                  ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(product.images.first, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.fitness_center, color: Colors.black26)))
                  : const Icon(Icons.fitness_center, color: Colors.black26),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(product.productName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text('Stock: ${product.stock} • \$${product.price.toStringAsFixed(2)}', style: const TextStyle(color: Colors.black54, fontSize: 13)),
              Text(product.category, style: const TextStyle(color: Colors.black38, fontSize: 12)),
            ])),
            Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: product.stock <= 0 ? Colors.red.shade50 : product.status == 'active' ? Colors.green.shade50 : Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                child: Text(product.stock <= 0 ? 'sold out' : product.status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: product.stock <= 0 ? Colors.red.shade700 : product.status == 'active' ? Colors.green.shade700 : Colors.grey)),
              ),
              const SizedBox(height: 8),
              Row(mainAxisSize: MainAxisSize.min, children: [
                InkWell(onTap: () => _editProduct(context), child: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF0F2850))),
                const SizedBox(width: 12),
                InkWell(onTap: () => _deleteProduct(context), child: const Icon(Icons.delete_outline, size: 18, color: Colors.red)),
              ]),
            ]),
          ]),
        ),
      ),
    );
  }

  void _editProduct(BuildContext context) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: DraggableScrollableSheet(
          initialChildSize: 0.9, minChildSize: 0.5, maxChildSize: 0.95, expand: false,
          builder: (context, sc) => _AddProductForm(sellerId: sellerId, scrollController: sc, existing: product),
        ),
      ),
    );
  }

  void _deleteProduct(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Product'),
        content: Text('Delete "${product.productName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) await FirestoreService.products().doc(product.productId).delete();
  }
}

// ─── Product Detail View (Seller) ────────────────────────────────────────────

class _SellerProductDetailPage extends StatelessWidget {
  final Product product;
  const _SellerProductDetailPage({required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(product.productName)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            height: 220, width: double.infinity,
            decoration: BoxDecoration(color: const Color(0xFFF2F6FF), borderRadius: BorderRadius.circular(20)),
            child: product.images.isNotEmpty
                ? ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.network(product.images.first, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.fitness_center, size: 64, color: Colors.black26))))
                : const Center(child: Icon(Icons.fitness_center, size: 64, color: Colors.black26)),
          ),
          const SizedBox(height: 20),
          Text(product.productName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFE5F2FF), borderRadius: BorderRadius.circular(8)), child: Text(product.category, style: const TextStyle(fontSize: 12, color: Color(0xFF0F2850)))),
            const SizedBox(width: 12),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: product.status == 'active' ? Colors.green.shade50 : Colors.grey.shade100, borderRadius: BorderRadius.circular(8)), child: Text(product.status.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: product.status == 'active' ? Colors.green.shade700 : Colors.grey))),
          ]),
          const SizedBox(height: 16),
          Text('\$${product.price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _infoRow('Stock', '${product.stock} units'),
          _infoRow('Product ID', product.productId),
          const SizedBox(height: 16),
          const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(product.description, style: const TextStyle(color: Colors.black54, height: 1.6)),
        ]),
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600))),
      Expanded(child: Text(value)),
    ]),
  );
}

// ─── Add/Edit Product Form with Image Picker ─────────────────────────────────

class _AddProductForm extends StatefulWidget {
  final String sellerId;
  final ScrollController scrollController;
  final Product? existing;
  const _AddProductForm({required this.sellerId, required this.scrollController, this.existing});

  @override
  State<_AddProductForm> createState() => _AddProductFormState();
}

class _AddProductFormState extends State<_AddProductForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name;
  late TextEditingController _description;
  late TextEditingController _price;
  late TextEditingController _stock;
  String _imageUrl = '';
  Uint8List? _pickedImageBytes;
  String? _pickedImageName;
  String _category = 'Gym Equipment';
  String _status = 'active';
  bool _saving = false;

  final _categories = ['Gym Equipment', 'Supplements', 'Accessories'];
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _name = TextEditingController(text: p?.productName ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _price = TextEditingController(text: p != null ? p.price.toString() : '');
    _stock = TextEditingController(text: p != null ? p.stock.toString() : '');
    _imageUrl = (p != null && p.images.isNotEmpty) ? p.images.first : '';
    _category = p?.category ?? 'Gym Equipment';
    _status = p?.status ?? 'active';
  }

  @override
  void dispose() {
    _name.dispose(); _description.dispose(); _price.dispose(); _stock.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, imageQuality: 80);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _pickedImageBytes = bytes;
          _pickedImageName = image.name;
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final now = Timestamp.now();
      final productId = widget.existing?.productId ?? 'prod_${DateTime.now().millisecondsSinceEpoch}';

      // Upload image if picked (won't block product creation if upload fails)
      String imageUrl = _imageUrl;
      if (_pickedImageBytes != null) {
        try {
          imageUrl = await CloudinaryService.uploadImage(bytes: _pickedImageBytes!, folder: 'products/$productId', fileName: 'product_image');
        } catch (_) {
          // Image upload failed - continue without image
        }
      }

      final images = imageUrl.isNotEmpty ? [imageUrl] : <String>[];
      final stockQty = int.tryParse(_stock.text.trim()) ?? 0;
      // Auto-set status to inactive if stock is 0
      final effectiveStatus = stockQty <= 0 ? 'inactive' : _status;
      final data = {
        'productId': productId,
        'sellerId': widget.sellerId,
        'category': _category,
        'productName': _name.text.trim(),
        'description': _description.text.trim(),
        'price': double.tryParse(_price.text.trim()) ?? 0,
        'salePrice': 0.0,
        'stock': stockQty,
        'status': effectiveStatus,
        'images': images,
        'tags': <String>[],
        'updatedAt': now,
      };
      if (widget.existing == null) data['createdAt'] = now;

      await FirestoreService.products().doc(productId).set(data, SetOptions(merge: true));
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.existing != null ? 'Product updated!' : 'Product added!')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Form(
        key: _formKey,
        child: ListView(
          controller: widget.scrollController,
          children: [
            Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            Text(widget.existing != null ? 'Edit Product' : 'Add New Product', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F2850))),
            const SizedBox(height: 6),
            const Text('Fill in the product details below', style: TextStyle(color: Colors.black54, fontSize: 13)),
            const SizedBox(height: 24),

            // Image picker area
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 180, width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F6FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFDDE5F0), width: 1.5),
                ),
                child: _pickedImageBytes != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Stack(children: [
                        Image.memory(_pickedImageBytes!, width: double.infinity, height: 180, fit: BoxFit.cover),
                        Positioned(top: 8, right: 8, child: Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.edit, size: 16, color: Color(0xFF0F2850)))),
                      ]))
                    : _imageUrl.isNotEmpty
                        ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Stack(children: [
                            Image.network(_imageUrl, width: double.infinity, height: 180, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, size: 48, color: Colors.black26))),
                            Positioned(top: 8, right: 8, child: Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.edit, size: 16, color: Color(0xFF0F2850)))),
                          ]))
                        : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.add_photo_alternate_outlined, size: 44, color: Color(0xFF0F2850)),
                            SizedBox(height: 10),
                            Text('Tap to pick image from gallery', style: TextStyle(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.w500)),
                            SizedBox(height: 4),
                            Text('Supports JPG, PNG', style: TextStyle(color: Colors.black38, fontSize: 12)),
                          ]),
              ),
            ),
            const SizedBox(height: 18),

            TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Product Name', prefixIcon: Icon(Icons.label_outline, size: 20)), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
            const SizedBox(height: 14),
            TextFormField(controller: _description, decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.description_outlined, size: 20)), maxLines: 3, validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category_outlined, size: 20)),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) { if (v != null) setState(() => _category = v); },
            ),
            const SizedBox(height: 14),
            TextFormField(controller: _price, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Price (\$)', prefixIcon: Icon(Icons.attach_money, size: 20)), validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              final num = double.tryParse(v.trim());
              if (num == null || num <= 0) return 'Must be greater than 0';
              return null;
            }),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: TextFormField(controller: _stock, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stock Quantity', prefixIcon: Icon(Icons.inventory_outlined, size: 20)), validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                final num = int.tryParse(v.trim());
                if (num == null || num < 0) return 'Cannot be negative';
                return null;
              })),
              const SizedBox(width: 12),
              Expanded(child: DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Status', prefixIcon: Icon(Icons.toggle_on_outlined, size: 20)),
                items: const [DropdownMenuItem(value: 'active', child: Text('Active')), DropdownMenuItem(value: 'inactive', child: Text('Inactive')), DropdownMenuItem(value: 'draft', child: Text('Draft'))],
                onChanged: (v) { if (v != null) setState(() => _status = v); },
              )),
            ]),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save_outlined, size: 20),
              label: Text(widget.existing != null ? 'Update Product' : 'Add Product'),
            )),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
