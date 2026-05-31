import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daily_fitness/providers/session_provider.dart';
import 'package:daily_fitness/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SellerAnalyticsPage extends StatelessWidget {
  const SellerAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = Provider.of<SessionProvider>(context).currentUser?.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics'), automaticallyImplyLeading: false),
      body: uid == null
          ? const Center(child: Text('Please sign in'))
          : _AnalyticsBody(sellerId: uid),
    );
  }
}

class _AnalyticsBody extends StatelessWidget {
  final String sellerId;
  const _AnalyticsBody({required this.sellerId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreService.orders().where('sellerId', isEqualTo: sellerId).snapshots(),
      builder: (context, snapshot) {
        final orders = snapshot.data?.docs ?? [];
        // Calculate real metrics
        double totalRevenue = 0;
        int totalOrders = orders.length;
        int completedOrders = 0;
        final Map<String, double> monthlyRevenue = {};
        final Map<String, int> monthlyOrders = {};

        for (final doc in orders) {
          final data = doc.data() as Map<String, dynamic>;
          final total = ((data['total'] ?? 0) as num).toDouble();
          final status = data['orderStatus'] ?? '';
          totalRevenue += total;
          if (status == 'completed' || status == 'delivered') completedOrders++;

          // Group by month
          final createdAt = data['createdAt'] as Timestamp?;
          if (createdAt != null) {
            final date = createdAt.toDate();
            final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
            monthlyRevenue[monthKey] = (monthlyRevenue[monthKey] ?? 0) + total;
            monthlyOrders[monthKey] = (monthlyOrders[monthKey] ?? 0) + 1;
          }
        }

        final avgOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0.0;

        return StreamBuilder<QuerySnapshot>(
          stream: FirestoreService.products().where('sellerId', isEqualTo: sellerId).snapshots(),
          builder: (context, productSnapshot) {
            final activeListings = (productSnapshot.data?.docs ?? []).where((d) => (d.data() as Map<String, dynamic>)['status'] == 'active').length;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Store Analytics', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text('Real-time performance metrics from your orders.', style: TextStyle(color: Colors.black54, fontSize: 13)),
                const SizedBox(height: 20),

                // Metrics grid
                _buildMetricsGrid(totalRevenue, totalOrders, completedOrders, avgOrderValue, activeListings),
                const SizedBox(height: 24),

                // Revenue chart
                _buildChartCard(
                  title: 'Monthly Revenue',
                  subtitle: 'Revenue trend over time',
                  child: _BarChart(data: monthlyRevenue, color: const Color(0xFF4AB3F4)),
                ),
                const SizedBox(height: 20),

                // Orders chart
                _buildChartCard(
                  title: 'Monthly Orders',
                  subtitle: 'Order volume over time',
                  child: _LineChart(data: monthlyOrders.map((k, v) => MapEntry(k, v.toDouble())), color: const Color(0xFF37B24D)),
                ),
                const SizedBox(height: 20),

                // Order status breakdown
                _buildChartCard(
                  title: 'Order Status Breakdown',
                  subtitle: 'Distribution of order statuses',
                  child: _StatusBreakdown(orders: orders),
                ),
              ]),
            );
          },
        );
      },
    );
  }

  Widget _buildMetricsGrid(double revenue, int orders, int completed, double avg, int listings) {
    final width = WidgetsBinding.instance.platformDispatcher.views.first.physicalSize.width / WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
    final aspectRatio = width > 600 ? 1.5 : 1.2;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: aspectRatio,
      children: [
        _MetricCard(label: 'Total Revenue', value: '\$${revenue.toStringAsFixed(0)}', icon: Icons.attach_money, color: Colors.green),
        _MetricCard(label: 'Total Orders', value: '$orders', icon: Icons.shopping_cart, color: Colors.blue),
        _MetricCard(label: 'Completed', value: '$completed', icon: Icons.check_circle, color: Colors.teal),
        _MetricCard(label: 'Avg. Order', value: '\$${avg.toStringAsFixed(0)}', icon: Icons.receipt, color: Colors.orange),
        _MetricCard(label: 'Active Listings', value: '$listings', icon: Icons.inventory, color: Colors.purple),
        _MetricCard(label: 'Completion Rate', value: orders > 0 ? '${(completed / orders * 100).toStringAsFixed(1)}%' : '0%', icon: Icons.trending_up, color: const Color(0xFF4AB3F4)),
      ],
    );
  }

  Widget _buildChartCard({required String title, required String subtitle, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 12)),
        const SizedBox(height: 20),
        child,
      ]),
    );
  }
}

// ─── Metric Card ─────────────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _MetricCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 18)),
        const SizedBox(height: 10),
        FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 11), overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}

// ─── Bar Chart (Custom Painted) ──────────────────────────────────────────────

class _BarChart extends StatelessWidget {
  final Map<String, double> data;
  final Color color;
  const _BarChart({required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox(height: 160, child: Center(child: Text('No data yet', style: TextStyle(color: Colors.black38))));
    }
    final sortedKeys = data.keys.toList()..sort();
    final values = sortedKeys.map((k) => data[k]!).toList();
    final maxVal = values.reduce(math.max);
    final labels = sortedKeys.map((k) {
      final parts = k.split('-');
      final months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return months[int.tryParse(parts.last) ?? 1];
    }).toList();

    return SizedBox(
      height: 180,
      child: CustomPaint(
        size: Size.infinite,
        painter: _BarChartPainter(values: values, labels: labels, maxVal: maxVal, color: color),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final double maxVal;
  final Color color;

  _BarChartPainter({required this.values, required this.labels, required this.maxVal, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final barWidth = (size.width - 40) / values.length * 0.6;
    final spacing = (size.width - 40) / values.length;
    final chartHeight = size.height - 30;

    // Grid lines
    final gridPaint = Paint()..color = Colors.grey.shade200..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = chartHeight * (1 - i / 4);
      canvas.drawLine(Offset(30, y), Offset(size.width, y), gridPaint);
    }

    // Bars
    for (int i = 0; i < values.length; i++) {
      final barHeight = maxVal > 0 ? (values[i] / maxVal) * (chartHeight - 10) : 0.0;
      final x = 30 + spacing * i + (spacing - barWidth) / 2;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, chartHeight - barHeight, barWidth, barHeight),
        const Radius.circular(4),
      );
      final paint = Paint()..color = color.withOpacity(0.8);
      canvas.drawRRect(rect, paint);

      // Label
      final textPainter = TextPainter(
        text: TextSpan(text: labels[i], style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(x + barWidth / 2 - textPainter.width / 2, chartHeight + 8));
    }

    // Y-axis labels
    for (int i = 0; i <= 4; i++) {
      final y = chartHeight * (1 - i / 4);
      final val = (maxVal * i / 4).toStringAsFixed(0);
      final tp = TextPainter(text: TextSpan(text: val, style: TextStyle(color: Colors.grey.shade500, fontSize: 9)), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ─── Line Chart (Custom Painted) ─────────────────────────────────────────────

class _LineChart extends StatelessWidget {
  final Map<String, double> data;
  final Color color;
  const _LineChart({required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox(height: 160, child: Center(child: Text('No data yet', style: TextStyle(color: Colors.black38))));
    }
    final sortedKeys = data.keys.toList()..sort();
    final values = sortedKeys.map((k) => data[k]!).toList();
    final maxVal = values.reduce(math.max);
    final labels = sortedKeys.map((k) {
      final parts = k.split('-');
      final months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return months[int.tryParse(parts.last) ?? 1];
    }).toList();

    return SizedBox(
      height: 180,
      child: CustomPaint(
        size: Size.infinite,
        painter: _LineChartPainter(values: values, labels: labels, maxVal: maxVal, color: color),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final double maxVal;
  final Color color;

  _LineChartPainter({required this.values, required this.labels, required this.maxVal, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final chartHeight = size.height - 30;
    final spacing = (size.width - 40) / (values.length > 1 ? values.length - 1 : 1);

    // Grid
    final gridPaint = Paint()..color = Colors.grey.shade200..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = chartHeight * (1 - i / 4);
      canvas.drawLine(Offset(30, y), Offset(size.width, y), gridPaint);
    }

    // Fill area
    final fillPath = Path();
    final linePath = Path();
    for (int i = 0; i < values.length; i++) {
      final x = 30 + spacing * i;
      final y = maxVal > 0 ? chartHeight - (values[i] / maxVal) * (chartHeight - 10) : chartHeight;
      if (i == 0) {
        fillPath.moveTo(x, chartHeight);
        fillPath.lineTo(x, y);
        linePath.moveTo(x, y);
      } else {
        fillPath.lineTo(x, y);
        linePath.lineTo(x, y);
      }
    }
    fillPath.lineTo(30 + spacing * (values.length - 1), chartHeight);
    fillPath.close();

    // Draw fill
    canvas.drawPath(fillPath, Paint()..color = color.withOpacity(0.1)..style = PaintingStyle.fill);
    // Draw line
    canvas.drawPath(linePath, Paint()..color = color..strokeWidth = 2.5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);

    // Dots and labels
    for (int i = 0; i < values.length; i++) {
      final x = 30 + spacing * i;
      final y = maxVal > 0 ? chartHeight - (values[i] / maxVal) * (chartHeight - 10) : chartHeight;
      canvas.drawCircle(Offset(x, y), 4, Paint()..color = color);
      canvas.drawCircle(Offset(x, y), 2, Paint()..color = Colors.white);

      final tp = TextPainter(text: TextSpan(text: labels[i], style: TextStyle(color: Colors.grey.shade600, fontSize: 10)), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, chartHeight + 8));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ─── Status Breakdown ────────────────────────────────────────────────────────

class _StatusBreakdown extends StatelessWidget {
  final List<QueryDocumentSnapshot> orders;
  const _StatusBreakdown({required this.orders});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const SizedBox(height: 100, child: Center(child: Text('No orders yet', style: TextStyle(color: Colors.black38))));
    }

    final Map<String, int> statusCounts = {};
    for (final doc in orders) {
      final data = doc.data() as Map<String, dynamic>;
      var status = (data['orderStatus'] ?? 'pending') as String;
      if (status == 'created') status = 'pending';
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
    }

    final statusColors = {
      'pending': Colors.grey,
      'confirmed': Colors.orange,
      'for_pickup': Colors.amber,
      'on_delivery': Colors.blue,
      'delivered': Colors.teal,
      'completed': Colors.green,
      'cancelled': Colors.red,
    };

    final total = orders.length;

    return Column(children: statusCounts.entries.map((entry) {
      final percentage = entry.value / total;
      final color = statusColors[entry.key] ?? Colors.grey;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 10),
          Expanded(child: Text(entry.key.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
          Text('${entry.value}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: percentage, backgroundColor: Colors.grey.shade100, valueColor: AlwaysStoppedAnimation(color), minHeight: 6),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 36, child: Text('${(percentage * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 11, color: Colors.black54))),
        ]),
      );
    }).toList());
  }
}
