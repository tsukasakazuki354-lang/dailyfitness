import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daily_fitness/services/firestore_service.dart';
import 'package:flutter/material.dart';

class AdminAnalyticsPage extends StatelessWidget {
  const AdminAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Platform Analytics'), automaticallyImplyLeading: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Platform Overview', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('Real-time analytics across all platform activity.', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 24),

          // User & Account Stats
          _buildSection('Account Status Distribution', _AccountStatusChart()),
          const SizedBox(height: 20),

          // Sales Trend
          _buildSection('Sales Trend (Monthly)', _SalesTrendChart()),
          const SizedBox(height: 20),

          // User Growth
          _buildSection('User Distribution by Role', _UserRoleChart()),
          const SizedBox(height: 20),

          // Key Metrics
          _buildSection('Key Platform Metrics', _KeyMetrics()),
        ]),
      ),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        child,
      ]),
    );
  }
}

// ─── Account Status Chart ────────────────────────────────────────────────────

class _AccountStatusChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreService.users().snapshots(),
      builder: (context, snapshot) {
        final users = snapshot.data?.docs ?? [];
        int pending = 0, active = 0, declined = 0, suspended = 0;
        for (final doc in users) {
          final status = (doc.data() as Map<String, dynamic>)['status'] ?? 'active';
          switch (status) { case 'pending': pending++; break; case 'declined': declined++; break; case 'suspended': suspended++; break; default: active++; }
        }
        final total = users.length;
        if (total == 0) return const Text('No users yet', style: TextStyle(color: Colors.black54));

        return Column(children: [
          _ProgressRow(label: 'Active / Approved', count: active, total: total, color: Colors.green),
          _ProgressRow(label: 'Pending Approval', count: pending, total: total, color: Colors.orange),
          _ProgressRow(label: 'Declined', count: declined, total: total, color: Colors.red),
          _ProgressRow(label: 'Suspended', count: suspended, total: total, color: Colors.grey),
        ]);
      },
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final int count, total;
  final Color color;
  const _ProgressRow({required this.label, required this.count, required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? count / total : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
        Text('$count', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 10),
        SizedBox(width: 80, child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: pct, backgroundColor: Colors.grey.shade100, valueColor: AlwaysStoppedAnimation(color), minHeight: 6))),
        const SizedBox(width: 8),
        SizedBox(width: 36, child: Text('${(pct * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 11, color: Colors.black54))),
      ]),
    );
  }
}

// ─── Sales Trend Chart ───────────────────────────────────────────────────────

class _SalesTrendChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreService.orders().snapshots(),
      builder: (context, snapshot) {
        final orders = snapshot.data?.docs ?? [];
        if (orders.isEmpty) return const SizedBox(height: 120, child: Center(child: Text('No orders yet', style: TextStyle(color: Colors.black54))));

        final Map<String, double> monthlyRevenue = {};
        for (final doc in orders) {
          final data = doc.data() as Map<String, dynamic>;
          final createdAt = data['createdAt'] as Timestamp?;
          final total = ((data['total'] ?? 0) as num).toDouble();
          if (createdAt != null) {
            final d = createdAt.toDate();
            final key = '${d.year}-${d.month.toString().padLeft(2, '0')}';
            monthlyRevenue[key] = (monthlyRevenue[key] ?? 0) + total;
          }
        }

        final sortedKeys = monthlyRevenue.keys.toList()..sort();
        final values = sortedKeys.map((k) => monthlyRevenue[k]!).toList();
        final maxVal = values.isNotEmpty ? values.reduce(math.max) : 1.0;
        final months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        final labels = sortedKeys.map((k) => months[int.tryParse(k.split('-').last) ?? 1]).toList();

        return SizedBox(
          height: 180,
          child: CustomPaint(size: Size.infinite, painter: _BarPainter(values: values, labels: labels, maxVal: maxVal, color: const Color(0xFF4AB3F4))),
        );
      },
    );
  }
}

class _BarPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final double maxVal;
  final Color color;
  _BarPainter({required this.values, required this.labels, required this.maxVal, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final barWidth = (size.width - 40) / values.length * 0.6;
    final spacing = (size.width - 40) / values.length;
    final chartHeight = size.height - 30;
    final gridPaint = Paint()..color = Colors.grey.shade200..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) { final y = chartHeight * (1 - i / 4); canvas.drawLine(Offset(30, y), Offset(size.width, y), gridPaint); }
    for (int i = 0; i < values.length; i++) {
      final barHeight = maxVal > 0 ? (values[i] / maxVal) * (chartHeight - 10) : 0.0;
      final x = 30 + spacing * i + (spacing - barWidth) / 2;
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, chartHeight - barHeight, barWidth, barHeight), const Radius.circular(4)), Paint()..color = color.withOpacity(0.8));
      final tp = TextPainter(text: TextSpan(text: labels[i], style: TextStyle(color: Colors.grey.shade600, fontSize: 10)), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(x + barWidth / 2 - tp.width / 2, chartHeight + 8));
    }
    for (int i = 0; i <= 4; i++) {
      final y = chartHeight * (1 - i / 4);
      final tp = TextPainter(text: TextSpan(text: (maxVal * i / 4).toStringAsFixed(0), style: TextStyle(color: Colors.grey.shade500, fontSize: 9)), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ─── User Role Distribution ──────────────────────────────────────────────────

class _UserRoleChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreService.users().snapshots(),
      builder: (context, snapshot) {
        final users = snapshot.data?.docs ?? [];
        int buyers = 0, sellers = 0, riders = 0, admins = 0;
        for (final doc in users) {
          final role = (doc.data() as Map<String, dynamic>)['role'] ?? 'buyer';
          switch (role) { case 'seller': sellers++; break; case 'rider': riders++; break; case 'admin': admins++; break; default: buyers++; }
        }
        final total = users.length;
        if (total == 0) return const Text('No users', style: TextStyle(color: Colors.black54));

        return Column(children: [
          _ProgressRow(label: 'Buyers', count: buyers, total: total, color: Colors.green),
          _ProgressRow(label: 'Sellers', count: sellers, total: total, color: Colors.orange),
          _ProgressRow(label: 'Riders', count: riders, total: total, color: Colors.blue),
          _ProgressRow(label: 'Admins', count: admins, total: total, color: Colors.purple),
        ]);
      },
    );
  }
}

// ─── Key Metrics ─────────────────────────────────────────────────────────────

class _KeyMetrics extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreService.orders().snapshots(),
      builder: (context, orderSnap) {
        final orders = orderSnap.data?.docs ?? [];
        double revenue = 0;
        int completed = 0, cancelled = 0;
        for (final doc in orders) {
          final data = doc.data() as Map<String, dynamic>;
          revenue += ((data['total'] ?? 0) as num).toDouble();
          final s = data['orderStatus'] ?? '';
          if (s == 'completed' || s == 'delivered') completed++;
          if (s == 'cancelled') cancelled++;
        }
        final successRate = orders.isNotEmpty ? ((orders.length - cancelled) / orders.length * 100) : 0.0;

        return StreamBuilder<QuerySnapshot>(
          stream: FirestoreService.products().snapshots(),
          builder: (context, prodSnap) {
            final products = prodSnap.data?.docs.length ?? 0;
            return Wrap(spacing: 12, runSpacing: 12, children: [
              _MiniMetric(label: 'Revenue', value: '\$${revenue.toStringAsFixed(0)}', color: Colors.green),
              _MiniMetric(label: 'Orders', value: '${orders.length}', color: Colors.blue),
              _MiniMetric(label: 'Completed', value: '$completed', color: Colors.teal),
              _MiniMetric(label: 'Cancelled', value: '$cancelled', color: Colors.red),
              _MiniMetric(label: 'Success Rate', value: '${successRate.toStringAsFixed(1)}%', color: Colors.purple),
              _MiniMetric(label: 'Products', value: '$products', color: Colors.orange),
            ]);
          },
        );
      },
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MiniMetric({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}
