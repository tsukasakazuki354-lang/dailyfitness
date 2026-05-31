import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daily_fitness/models/address.dart';
import 'package:daily_fitness/models/cart_item.dart';
import 'package:daily_fitness/providers/session_provider.dart';
import 'package:daily_fitness/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CheckoutPage extends StatefulWidget {
  final List<CartItem> items;
  final double total;
  const CheckoutPage({super.key, required this.items, required this.total});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String _paymentMethod = 'cod';
  Address? _selectedAddress;
  bool _isLoading = false;
  bool _loadingAddresses = true;
  List<Address> _addresses = [];

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    final uid = Provider.of<SessionProvider>(context, listen: false).currentUser?.uid;
    if (uid == null) return;
    try {
      final snapshot = await FirestoreService.addresses().where('userId', isEqualTo: uid).get();
      final addresses = snapshot.docs.map((doc) => Address.fromMap(doc.data() as Map<String, dynamic>)).toList();
      if (mounted) {
        setState(() {
          _addresses = addresses;
          _selectedAddress = addresses.isNotEmpty ? addresses.firstWhere((a) => a.isDefault, orElse: () => addresses.first) : null;
          _loadingAddresses = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingAddresses = false);
    }
  }

  Future<void> _placeOrder() async {
    final uid = Provider.of<SessionProvider>(context, listen: false).currentUser?.uid;
    if (uid == null) return;
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add a delivery address first')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      const shippingFee = 5.0;

      // Group items by seller
      final Map<String, List<Map<String, dynamic>>> itemsBySeller = {};
      for (final item in widget.items) {
        final productDoc = await FirestoreService.products().doc(item.productId).get();
        final sellerId = productDoc.exists ? ((productDoc.data() as Map<String, dynamic>?)?['sellerId'] ?? '') : '';
        itemsBySeller.putIfAbsent(sellerId, () => []);
        itemsBySeller[sellerId]!.add({'productId': item.productId, 'name': item.name, 'quantity': item.quantity, 'price': item.price});
      }

      // Create one order per seller
      for (final entry in itemsBySeller.entries) {
        final sellerId = entry.key;
        final sellerItems = entry.value;
        final subtotal = sellerItems.fold<double>(0, (s, i) => s + ((i['price'] as num).toDouble() * (i['quantity'] as int)));
        final orderId = 'order_${DateTime.now().millisecondsSinceEpoch}_${sellerId.hashCode.abs() % 10000}';

        final orderData = {
          'orderId': orderId,
          'buyerId': uid,
          'sellerId': sellerId,
          'riderId': '',
          'items': sellerItems,
          'subtotal': subtotal,
          'shippingFee': shippingFee,
          'total': subtotal + shippingFee,
          'paymentMethod': _paymentMethod,
          'paymentStatus': 'pending',
          'orderStatus': 'pending',
          'deliveryStatus': 'pending',
          'address': {
            'streetAddress': _selectedAddress!.streetAddress,
            'barangay': _selectedAddress!.barangay,
            'municipality': _selectedAddress!.municipality,
            'provinceCity': _selectedAddress!.provinceCity,
            'region': _selectedAddress!.region,
            'zipCode': _selectedAddress!.zipCode,
          },
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        };
        await FirestoreService.createOrder(orderData);
      }

      // Deduct stock for each item
      for (final item in widget.items) {
        final productRef = FirestoreService.products().doc(item.productId);
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final snapshot = await transaction.get(productRef);
          if (snapshot.exists) {
            final currentStock = (snapshot.data() as Map<String, dynamic>?)?['stock'] ?? 0;
            final newStock = (currentStock as int) - item.quantity;
            final finalStock = newStock < 0 ? 0 : newStock;
            final updates = <String, dynamic>{'stock': finalStock};
            if (finalStock <= 0) updates['status'] = 'inactive';
            transaction.update(productRef, updates);
          }
        });
      }

      // Don't clear entire cart - the cart page handles removing checked-out items
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order placed successfully!')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error placing order: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: _loadingAddresses
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Delivery Address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (_addresses.isEmpty)
                    const Text('No saved addresses. Please add one in Saved Addresses.', style: TextStyle(color: Colors.black54))
                  else
                    ...(_addresses.map((addr) => RadioListTile<String>(
                          value: addr.addressId,
                          groupValue: _selectedAddress?.addressId,
                          title: Text('${addr.streetAddress}, ${addr.barangay}'),
                          subtitle: Text('${addr.municipality}, ${addr.provinceCity} ${addr.zipCode}'),
                          onChanged: (v) => setState(() => _selectedAddress = addr),
                        ))),
                  const SizedBox(height: 24),
                  const Text('Order Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...widget.items.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text('${item.name} x${item.quantity}', overflow: TextOverflow.ellipsis)),
                            Text('\$${(item.price * item.quantity).toStringAsFixed(2)}'),
                          ],
                        ),
                      )),
                  const Divider(height: 24),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Subtotal'), Text('\$${widget.total.toStringAsFixed(2)}')]),
                  const SizedBox(height: 4),
                  const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Shipping'), Text('\$5.00')]),
                  const Divider(height: 24),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text('\$${(widget.total + 5).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ]),
                  const SizedBox(height: 24),
                  const Text('Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  RadioListTile<String>(value: 'cod', groupValue: _paymentMethod, title: const Text('Cash on Delivery'), onChanged: (v) => setState(() => _paymentMethod = v!)),
                  RadioListTile<String>(value: 'card', groupValue: _paymentMethod, title: const Text('Card Payment'), onChanged: (v) => setState(() => _paymentMethod = v!)),
                  RadioListTile<String>(value: 'gcash', groupValue: _paymentMethod, title: const Text('GCash'), onChanged: (v) => setState(() => _paymentMethod = v!)),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _placeOrder,
                      child: _isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Place Order'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
