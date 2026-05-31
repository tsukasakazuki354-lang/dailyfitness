import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daily_fitness/providers/session_provider.dart';
import 'package:daily_fitness/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RiderEarningsPage extends StatelessWidget {
  const RiderEarningsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = Provider.of<SessionProvider>(context).currentUser?.uid ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Earnings & Reports'), automaticallyImplyLeading: false),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreService.orders().where('riderId', isEqualTo: uid).snapshots(),
        builder: (context, snapshot) {
          final orders = snapshot.data?.docs ?? [];
          double totalEarnings = 0;
          int completedCount = 0;
          for (final doc in orders) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['orderStatus'] == 'completed' || data['orderStatus'] == 'delivered') {
              completedCount++;
              totalEarnings += ((data['shippingFee'] ?? 0) as num).toDouble();
            }
          }
          final avgPerDelivery = completedCount > 0 ? totalEarnings / completedCount : 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Earnings Summary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _earningCard('Total Earnings', '\$${totalEarnings.toStringAsFixed(2)}', Icons.account_balance_wallet, Colors.green),
              _earningCard('Completed Deliveries', '$completedCount', Icons.check_circle, Colors.blue),
              _earningCard('Avg. per Delivery', '\$${avgPerDelivery.toStringAsFixed(2)}', Icons.trending_up, Colors.orange),
              _earningCard('Total Assigned', '${orders.length}', Icons.assignment, Colors.purple),
              const SizedBox(height: 24),
              const Text('Earnings Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (orders.isEmpty)
                const Text('No earnings data yet.', style: TextStyle(color: Colors.black54))
              else
                ...orders.where((d) => (d.data() as Map<String, dynamic>)['orderStatus'] == 'completed').take(10).map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final orderId = (data['orderId'] ?? '') as String;
                  final fee = ((data['shippingFee'] ?? 0) as num).toDouble();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)]),
                    child: Row(children: [
                      const Icon(Icons.receipt, size: 20, color: Color(0xFF0F2850)),
                      const SizedBox(width: 12),
                      Expanded(child: Text('Order #${orderId.length > 8 ? orderId.substring(orderId.length - 8) : orderId}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                      Text('+\$${fee.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    ]),
                  );
                }),
            ]),
          );
        },
      ),
    );
  }

  Widget _earningCard(String title, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)]),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 22)),
        const SizedBox(width: 16),
        Expanded(child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}
