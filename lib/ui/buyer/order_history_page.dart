import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daily_fitness/models/order.dart' as app_order;
import 'package:daily_fitness/providers/session_provider.dart';
import 'package:daily_fitness/services/firestore_service.dart';
import 'package:daily_fitness/ui/buyer/order_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _tabs = const ['All', 'Pending', 'Confirmed', 'For Pickup', 'Picked Up', 'On Delivery', 'Delivered', 'Completed', 'Cancelled'];

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
      case 4: return 'picked_up';
      case 5: return 'on_delivery';
      case 6: return 'delivered';
      case 7: return 'completed';
      case 8: return 'cancelled';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = Provider.of<SessionProvider>(context).currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order History')),
        body: const Center(child: Text('Please sign in to view orders')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(_tabs.length, (index) => _OrderList(uid: uid, statusFilter: _statusFilter(index))),
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  final String uid;
  final String statusFilter;
  const _OrderList({required this.uid, required this.statusFilter});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreService.orders().where('buyerId', isEqualTo: uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        var orders = (snapshot.data?.docs ?? []).map((d) => app_order.Order.fromMap(d.data() as Map<String, dynamic>)).toList();
        orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        if (statusFilter.isNotEmpty) {
          orders = orders.where((o) {
            final effectiveStatus = o.orderStatus == 'created' ? 'pending' : o.orderStatus;
            return effectiveStatus == statusFilter || o.deliveryStatus == statusFilter;
          }).toList();
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
          itemBuilder: (context, index) => _OrderCard(order: orders[index]),
        );
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final app_order.Order order;
  const _OrderCard({required this.order});

  Color _statusColor(String status) {
    switch (status) {
      case 'completed': case 'delivered': return Colors.green;
      case 'cancelled': return Colors.red;
      case 'on_delivery': case 'picked_up': return Colors.blue;
      case 'confirmed': case 'for_pickup': return Colors.orange;
      case 'pending': case 'created': return Colors.grey;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Treat 'created' as 'pending' for display
    final status = order.orderStatus == 'created' ? 'pending' : order.orderStatus;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailPage(order: order))),
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
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Payment: ${order.paymentMethod.toUpperCase()}', style: const TextStyle(fontSize: 12, color: Colors.black45)),
                Text('Delivery: ${order.deliveryStatus.replaceAll('_', ' ')}', style: const TextStyle(fontSize: 12, color: Colors.black45)),
              ]),
              Text('\$${order.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailPage(order: order))),
                icon: const Icon(Icons.visibility_outlined, size: 16),
                label: const Text('View Details', style: TextStyle(fontSize: 12)),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
