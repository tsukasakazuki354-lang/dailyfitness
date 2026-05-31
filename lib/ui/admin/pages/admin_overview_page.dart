import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daily_fitness/providers/session_provider.dart';
import 'package:daily_fitness/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdminOverviewPage extends StatelessWidget {
  const AdminOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<SessionProvider>(context).currentUser;
    final width = MediaQuery.of(context).size.width;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Welcome, ${user?.firstName ?? 'Admin'}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('Platform overview and real-time metrics.', style: TextStyle(color: Colors.black54)),
        const SizedBox(height: 24),
        _buildMetrics(width),
        const SizedBox(height: 24),
        _buildRecentActivity(width),
      ]),
    );
  }

  Widget _buildMetrics(double width) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreService.users().snapshots(),
      builder: (context, userSnap) {
        final totalUsers = userSnap.data?.docs.length ?? 0;
        final buyers = (userSnap.data?.docs ?? []).where((d) => (d.data() as Map<String, dynamic>)['role'] == 'buyer').length;
        final sellers = (userSnap.data?.docs ?? []).where((d) => (d.data() as Map<String, dynamic>)['role'] == 'seller').length;
        final riders = (userSnap.data?.docs ?? []).where((d) => (d.data() as Map<String, dynamic>)['role'] == 'rider').length;

        return StreamBuilder<QuerySnapshot>(
          stream: FirestoreService.orders().snapshots(),
          builder: (context, orderSnap) {
            final totalOrders = orderSnap.data?.docs.length ?? 0;
            double revenue = 0;
            for (final doc in (orderSnap.data?.docs ?? [])) {
              revenue += ((doc.data() as Map<String, dynamic>)['total'] ?? 0 as num).toDouble();
            }
            return StreamBuilder<QuerySnapshot>(
              stream: FirestoreService.products().snapshots(),
              builder: (context, prodSnap) {
                final totalProducts = prodSnap.data?.docs.length ?? 0;
                final cols = width > 900 ? 4 : 2;
                return GridView.count(
                  crossAxisCount: cols, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: width > 900 ? 1.6 : 1.3,
                  children: [
                    _MetricCard(title: 'Total Users', value: '$totalUsers', icon: Icons.people, color: Colors.blue, subtitle: 'B:$buyers S:$sellers R:$riders'),
                    _MetricCard(title: 'Total Orders', value: '$totalOrders', icon: Icons.receipt_long, color: Colors.green, subtitle: 'All time'),
                    _MetricCard(title: 'Revenue', value: '\$${revenue.toStringAsFixed(0)}', icon: Icons.attach_money, color: Colors.orange, subtitle: 'Platform total'),
                    _MetricCard(title: 'Products', value: '$totalProducts', icon: Icons.inventory_2, color: Colors.purple, subtitle: 'Active listings'),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildRecentActivity(double width) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Recent Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
        StreamBuilder<QuerySnapshot>(
          stream: FirestoreService.orders().snapshots(),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) return const Text('No orders yet.', style: TextStyle(color: Colors.black54));
            final recent = docs.take(5).toList();
            return Column(children: recent.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final orderId = (data['orderId'] ?? '') as String;
              final status = (data['orderStatus'] ?? 'pending') as String;
              final total = ((data['total'] ?? 0) as num).toDouble();
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('#${orderId.length > 8 ? orderId.substring(orderId.length - 8) : orderId}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Text('\$${total.toStringAsFixed(2)}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: status == 'completed' ? Colors.green.shade50 : Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Text(status.replaceAll('_', ' '), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: status == 'completed' ? Colors.green.shade700 : Colors.blue.shade700)),
                  ),
                ]),
              );
            }).toList());
          },
        ),
      ]),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title, value, subtitle;
  final IconData icon;
  final Color color;
  const _MetricCard({required this.title, required this.value, required this.icon, required this.color, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 20)),
        const SizedBox(height: 10),
        FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w600)),
        Text(subtitle, style: const TextStyle(color: Colors.black45, fontSize: 11)),
      ]),
    );
  }
}
