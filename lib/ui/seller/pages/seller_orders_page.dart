import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daily_fitness/models/order.dart' as app_order;
import 'package:daily_fitness/providers/session_provider.dart';
import 'package:daily_fitness/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SellerOrdersPage extends StatefulWidget {
  const SellerOrdersPage({super.key});

  @override
  State<SellerOrdersPage> createState() => _SellerOrdersPageState();
}

class _SellerOrdersPageState extends State<SellerOrdersPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _tabs = const ['All', 'Pending', 'Confirmed', 'For Pickup', 'On Delivery', 'Completed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _statusFilter(int index) {
    switch (index) {
      case 1: return 'pending';
      case 2: return 'confirmed';
      case 3: return 'for_pickup';
      case 4: return 'on_delivery';
      case 5: return 'completed';
      case 6: return 'cancelled';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = Provider.of<SessionProvider>(context).currentUser?.uid;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(_tabs.length, (index) => _SellerOrderList(uid: uid ?? '', statusFilter: _statusFilter(index))),
      ),
    );
  }
}

class _SellerOrderList extends StatelessWidget {
  final String uid;
  final String statusFilter;
  const _SellerOrderList({required this.uid, required this.statusFilter});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreService.orders().where('sellerId', isEqualTo: uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        var orders = (snapshot.data?.docs ?? []).map((d) => app_order.Order.fromMap(d.data() as Map<String, dynamic>)).toList();
        orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        if (statusFilter.isNotEmpty) {
          orders = orders.where((o) => o.orderStatus == statusFilter).toList();
        }
        if (orders.isEmpty) {
          return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.receipt_long_outlined, size: 56, color: Colors.black26),
            const SizedBox(height: 12),
            Text(statusFilter.isEmpty ? 'No orders yet' : 'No ${statusFilter.replaceAll('_', ' ')} orders', style: const TextStyle(color: Colors.black54)),
          ]));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) => _SellerOrderCard(order: orders[index]),
        );
      },
    );
  }
}

class _SellerOrderCard extends StatelessWidget {
  final app_order.Order order;
  const _SellerOrderCard({required this.order});

  Color _statusColor(String status) {
    switch (status) {
      case 'completed': case 'delivered': return Colors.green;
      case 'cancelled': return Colors.red;
      case 'on_delivery': return Colors.blue;
      case 'confirmed': case 'for_pickup': return Colors.orange;
      default: return Colors.grey;
    }
  }

  String? _nextStatus(String current) {
    switch (current) {
      case 'pending': return 'confirmed';
      case 'confirmed': return 'for_pickup';
      case 'for_pickup': return 'on_delivery';
      case 'on_delivery': return 'delivered';
      case 'delivered': return 'completed';
      default: return null;
    }
  }

  String _nextLabel(String current) {
    switch (current) {
      case 'pending': return 'Confirm Order';
      case 'confirmed': return 'Mark For Pickup';
      case 'for_pickup': return 'Mark On Delivery';
      case 'on_delivery': return 'Mark Delivered';
      case 'delivered': return 'Mark Completed';
      default: return '';
    }
  }

  Future<void> _updateStatus(BuildContext context, String newStatus) async {
    try {
      // If moving to for_pickup, prompt to assign a rider
      if (newStatus == 'for_pickup' && order.riderId.isEmpty) {
        final riderId = await _showAssignRiderDialog(context);
        if (riderId == null) return; // User cancelled
        await FirestoreService.orders().doc(order.orderId).update({
          'orderStatus': newStatus,
          'deliveryStatus': newStatus,
          'riderId': riderId,
          'statusHistory': FieldValue.arrayUnion([{'status': newStatus, 'timestamp': Timestamp.now()}]),
          'updatedAt': Timestamp.now(),
        });
      } else {
        await FirestoreService.orders().doc(order.orderId).update({
          'orderStatus': newStatus,
          'deliveryStatus': newStatus,
          'statusHistory': FieldValue.arrayUnion([{'status': newStatus, 'timestamp': Timestamp.now()}]),
          'updatedAt': Timestamp.now(),
        });
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order updated to ${newStatus.replaceAll('_', ' ')}')));
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<String?> _showAssignRiderDialog(BuildContext context) async {
    return showDialog<String>(
      context: context,
      builder: (ctx) => _AssignRiderDialog(),
    );
  }

  Future<void> _cancelOrder(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await FirestoreService.orders().doc(order.orderId).update({
        'orderStatus': 'cancelled',
        'deliveryStatus': 'cancelled',
        'statusHistory': FieldValue.arrayUnion([{'status': 'cancelled', 'timestamp': Timestamp.now()}]),
        'updatedAt': Timestamp.now(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = order.orderStatus == 'created' ? 'pending' : order.orderStatus;
    final next = _nextStatus(status);

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _SellerOrderDetailPage(order: order))),
      child: Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Flexible(child: Text('Order #${order.orderId.length > 8 ? order.orderId.substring(order.orderId.length - 8) : order.orderId}', style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: _statusColor(status).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(status.replaceAll('_', ' ').toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _statusColor(status))),
            ),
          ]),
          const SizedBox(height: 10),
          ...order.items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(child: Text('${item.name} x${item.quantity}', style: const TextStyle(color: Colors.black54, fontSize: 13), overflow: TextOverflow.ellipsis)),
              Text('\$${(item.price * item.quantity).toStringAsFixed(2)}', style: const TextStyle(fontSize: 13)),
            ]),
          )),
          const Divider(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Payment: ${order.paymentMethod.toUpperCase()}', style: const TextStyle(fontSize: 12, color: Colors.black45)),
            Text('\$${order.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ]),
          if (next != null || status == 'pending') ...[
            const SizedBox(height: 14),
            Row(children: [
              if (next != null)
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateStatus(context, next),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                    child: Text(_nextLabel(status), style: const TextStyle(fontSize: 13)),
                  ),
                ),
              if (status == 'pending' || status == 'confirmed') ...[
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: () => _cancelOrder(context),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16)),
                  child: const Text('Cancel', style: TextStyle(fontSize: 13)),
                ),
              ],
            ]),
          ],
        ]),
      ),
      ),
    );
  }
}

// ─── Seller Order Detail Page ────────────────────────────────────────────────

class _SellerOrderDetailPage extends StatelessWidget {
  final app_order.Order order;
  const _SellerOrderDetailPage({required this.order});

  @override
  Widget build(BuildContext context) {
    final status = order.orderStatus == 'created' ? 'pending' : order.orderStatus;
    return Scaffold(
      appBar: AppBar(title: Text('Order #${order.orderId.length > 8 ? order.orderId.substring(order.orderId.length - 8) : order.orderId}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Status
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFF8FBFF), borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              const Icon(Icons.local_shipping_outlined, color: Color(0xFF0F2850)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Order Status', style: TextStyle(color: Colors.black54, fontSize: 12)),
                Text(status.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ])),
            ]),
          ),
          const SizedBox(height: 20),

          // Items
          const Text('Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...order.items.map((item) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)]),
            child: Row(children: [
              Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFF2F6FF), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.fitness_center, size: 20, color: Colors.black38)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('Qty: ${item.quantity}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
              ])),
              Text('\$${(item.price * item.quantity).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ]),
          )),
          const SizedBox(height: 20),

          // Summary
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)]),
            child: Column(children: [
              _row('Subtotal', '\$${order.subtotal.toStringAsFixed(2)}'),
              _row('Shipping', '\$${order.shippingFee.toStringAsFixed(2)}'),
              const Divider(height: 20),
              _row('Total', '\$${order.total.toStringAsFixed(2)}', bold: true),
              const SizedBox(height: 8),
              _row('Payment Method', order.paymentMethod.toUpperCase()),
              _row('Payment Status', order.paymentStatus),
              _row('Delivery Status', status.replaceAll('_', ' ')),
            ]),
          ),
          const SizedBox(height: 20),

          // Address
          if (order.address.isNotEmpty) ...[
            const Text('Delivery Address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (order.address['streetAddress'] != null) Text(order.address['streetAddress'], style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('${order.address['barangay'] ?? ''}, ${order.address['municipality'] ?? ''}', style: const TextStyle(color: Colors.black54)),
                Text('${order.address['provinceCity'] ?? ''}, ${order.address['region'] ?? ''} ${order.address['zipCode'] ?? ''}', style: const TextStyle(color: Colors.black54)),
              ]),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: Colors.black54, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
      Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: bold ? 18 : 14)),
    ]),
  );
}


// ─── Assign Rider Dialog ─────────────────────────────────────────────────────

class _AssignRiderDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Assign Rider'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirestoreService.users().where('role', isEqualTo: 'rider').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            final riders = (snapshot.data?.docs ?? []).where((d) {
              final data = d.data() as Map<String, dynamic>;
              final status = data['status'] ?? '';
              return status == 'active' || status == 'approved';
            }).toList();
            if (riders.isEmpty) {
              return const Center(child: Text('No approved riders available', style: TextStyle(color: Colors.black54)));
            }
            return ListView.separated(
              shrinkWrap: true,
              itemCount: riders.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final data = riders[index].data() as Map<String, dynamic>;
                final name = '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
                final uid = data['uid'] ?? '';
                final phone = data['phoneNumber'] ?? '';
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFE8F1FF),
                    child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'R', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F2850))),
                  ),
                  title: Text(name.isNotEmpty ? name : 'Rider', style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(phone.isNotEmpty ? phone : 'No phone', style: const TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black38),
                  onTap: () => Navigator.pop(context, uid),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      ],
    );
  }
}
