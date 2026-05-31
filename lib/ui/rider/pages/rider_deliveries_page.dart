import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daily_fitness/models/order.dart' as app_order;
import 'package:daily_fitness/providers/session_provider.dart';
import 'package:daily_fitness/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RiderDeliveriesPage extends StatelessWidget {
  const RiderDeliveriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = Provider.of<SessionProvider>(context).currentUser?.uid ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('My Deliveries'), automaticallyImplyLeading: false),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreService.orders().where('riderId', isEqualTo: uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final orders = (snapshot.data?.docs ?? []).map((d) => app_order.Order.fromMap(d.data() as Map<String, dynamic>)).toList();
          orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          if (orders.isEmpty) {
            return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.delivery_dining_outlined, size: 64, color: Colors.black26),
              SizedBox(height: 16),
              Text('No deliveries assigned', style: TextStyle(fontSize: 16, color: Colors.black54)),
            ]));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final o = orders[index];
              final status = o.orderStatus == 'created' ? 'pending' : o.orderStatus;
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Flexible(child: Text('Order #${o.orderId.length > 8 ? o.orderId.substring(o.orderId.length - 8) : o.orderId}', style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: _statusColor(status).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(status.replaceAll('_', ' ').toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _statusColor(status))),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Text('${o.items.length} item(s) • \$${o.total.toStringAsFixed(2)}', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                    if (o.address.isNotEmpty) Text('${o.address['barangay'] ?? ''}, ${o.address['municipality'] ?? ''}', style: const TextStyle(color: Colors.black45, fontSize: 12)),
                    if (status == 'for_pickup' || status == 'on_delivery') ...[
                      const SizedBox(height: 12),
                      SizedBox(width: double.infinity, child: ElevatedButton(
                        onPressed: () => _updateStatus(context, o.orderId, status == 'for_pickup' ? 'on_delivery' : 'delivered'),
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                        child: Text(status == 'for_pickup' ? 'Start Delivery' : 'Mark Delivered', style: const TextStyle(fontSize: 13)),
                      )),
                    ],
                  ]),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s) { case 'completed': case 'delivered': return Colors.green; case 'on_delivery': return Colors.blue; case 'for_pickup': return Colors.orange; case 'cancelled': return Colors.red; default: return Colors.grey; }
  }

  Future<void> _updateStatus(BuildContext context, String orderId, String newStatus) async {
    await FirestoreService.orders().doc(orderId).update({'orderStatus': newStatus, 'deliveryStatus': newStatus, 'updatedAt': Timestamp.now()});
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Updated to ${newStatus.replaceAll('_', ' ')}')));
  }
}
