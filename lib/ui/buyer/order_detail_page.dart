import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daily_fitness/models/order.dart' as app_order;
import 'package:daily_fitness/services/firestore_service.dart';
import 'package:flutter/material.dart';

class OrderDetailPage extends StatelessWidget {
  final app_order.Order order;
  const OrderDetailPage({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Order #${order.orderId.length > 8 ? order.orderId.substring(order.orderId.length - 8) : order.orderId}')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirestoreService.orders().doc(order.orderId).snapshots(),
        builder: (context, snapshot) {
          final liveData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final liveStatus = (liveData['orderStatus'] ?? order.orderStatus) as String;
          final statusHistory = (liveData['statusHistory'] as List<dynamic>?) ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Order Tracking', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildTracker(liveStatus, statusHistory),
              const SizedBox(height: 28),
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
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)]),
                child: Column(children: [
                  _summaryRow('Subtotal', '\$${order.subtotal.toStringAsFixed(2)}'),
                  _summaryRow('Shipping', '\$${order.shippingFee.toStringAsFixed(2)}'),
                  const Divider(height: 20),
                  _summaryRow('Total', '\$${order.total.toStringAsFixed(2)}', bold: true),
                  const SizedBox(height: 12),
                  _summaryRow('Payment', order.paymentMethod.toUpperCase()),
                  _summaryRow('Payment Status', order.paymentStatus),
                ]),
              ),
              const SizedBox(height: 20),
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
          );
        },
      ),
    );
  }

  Widget _buildTracker(String currentStatus, List<dynamic> statusHistory) {
    final steps = ['Pending', 'Confirmed', 'For Pickup', 'Picked Up', 'On Delivery', 'Delivered', 'Completed'];
    final statusKeys = ['pending', 'confirmed', 'for_pickup', 'picked_up', 'on_delivery', 'delivered', 'completed'];
    final statusMap = {'created': 0, 'pending': 0, 'confirmed': 1, 'for_pickup': 2, 'picked_up': 3, 'on_delivery': 4, 'delivered': 5, 'completed': 6};
    final currentStep = statusMap[currentStatus] ?? 0;
    final isCancelled = currentStatus == 'cancelled';

    // Build timestamp map from statusHistory
    final Map<String, DateTime> timestamps = {};
    for (final entry in statusHistory) {
      if (entry is Map) {
        final s = entry['status'] as String? ?? '';
        final t = entry['timestamp'] as Timestamp?;
        if (t != null) timestamps[s] = t.toDate();
      }
    }

    if (isCancelled) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
        child: const Row(children: [
          Icon(Icons.cancel, color: Colors.red),
          SizedBox(width: 12),
          Text('This order has been cancelled', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
        ]),
      );
    }

    return Column(
      children: List.generate(steps.length, (index) {
        final isCompleted = index <= currentStep;
        final isCurrent = index == currentStep;
        final stepKey = statusKeys[index];
        final timestamp = timestamps[stepKey];

        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Column(children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? const Color(0xFF0F2850) : Colors.grey.shade200,
                border: isCurrent ? Border.all(color: const Color(0xFF4AB3F4), width: 3) : null,
              ),
              child: isCompleted ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
            ),
            if (index < steps.length - 1) Container(width: 2, height: 36, color: isCompleted ? const Color(0xFF0F2850) : Colors.grey.shade200),
          ]),
          const SizedBox(width: 14),
          Expanded(child: Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(steps[index], style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500, color: isCompleted ? Colors.black87 : Colors.black38, fontSize: 14)),
              if (timestamp != null)
                Text(_formatDateTime(timestamp), style: const TextStyle(color: Colors.black45, fontSize: 11)),
            ]),
          )),
        ]);
      }),
    );
  }

  String _formatDateTime(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    return '${months[date.month - 1]} ${date.day}, ${date.year} at $hour:${date.minute.toString().padLeft(2, '0')} $amPm';
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: Colors.black54, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: bold ? 18 : 14)),
      ]),
    );
  }
}
