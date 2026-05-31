import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daily_fitness/providers/session_provider.dart';
import 'package:daily_fitness/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RiderOverviewPage extends StatelessWidget {
  const RiderOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<SessionProvider>(context).currentUser;
    final uid = user?.uid ?? '';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Welcome, ${user?.firstName ?? 'Rider'}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('Track deliveries, earnings, and performance.', style: TextStyle(color: Colors.black54)),
        const SizedBox(height: 24),
        StreamBuilder<QuerySnapshot>(
          stream: FirestoreService.orders().where('riderId', isEqualTo: uid).snapshots(),
          builder: (context, snapshot) {
            final orders = snapshot.data?.docs ?? [];
            int ongoing = 0, completed = 0;
            double earnings = 0;
            for (final doc in orders) {
              final data = doc.data() as Map<String, dynamic>;
              final status = data['orderStatus'] ?? '';
              if (status == 'on_delivery' || status == 'picked_up' || status == 'for_pickup') ongoing++;
              if (status == 'completed' || status == 'delivered') { completed++; earnings += ((data['shippingFee'] ?? 0) as num).toDouble(); }
            }
            return Column(children: [
              Row(children: [
                Expanded(child: _StatCard(title: 'Ongoing', value: '$ongoing', icon: Icons.delivery_dining, color: Colors.blue)),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(title: 'Completed', value: '$completed', icon: Icons.check_circle, color: Colors.green)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _StatCard(title: 'Earnings', value: '\$${earnings.toStringAsFixed(0)}', icon: Icons.attach_money, color: Colors.orange)),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(title: 'Total Orders', value: '${orders.length}', icon: Icons.receipt_long, color: Colors.purple)),
              ]),
            ]);
          },
        ),
        const SizedBox(height: 24),
        // Recent deliveries
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            StreamBuilder<QuerySnapshot>(
              stream: FirestoreService.orders().where('riderId', isEqualTo: uid).snapshots(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) return const Text('No deliveries assigned yet.', style: TextStyle(color: Colors.black54));
                final recent = docs.take(5).toList();
                return Column(children: recent.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = (data['orderStatus'] ?? 'pending') as String;
                  final orderId = (data['orderId'] ?? '') as String;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(children: [
                      Expanded(child: Text('Order #${orderId.length > 8 ? orderId.substring(orderId.length - 8) : orderId}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
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
        ),
      ]),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 20)),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(color: Colors.black54, fontSize: 12)),
        const SizedBox(height: 4),
        FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
      ]),
    );
  }
}
