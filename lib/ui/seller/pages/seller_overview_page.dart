import 'package:daily_fitness/providers/session_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SellerOverviewPage extends StatelessWidget {
  const SellerOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<SessionProvider>(context).currentUser;
    final width = MediaQuery.of(context).size.width;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Welcome back, ${user?.firstName ?? 'Seller'}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('Manage your store, track orders, and view analytics.', style: TextStyle(color: Colors.black54)),
        const SizedBox(height: 24),
        _buildOverviewGrid(width),
        const SizedBox(height: 24),
        _buildSalesPerformance(width),
        const SizedBox(height: 24),
        _buildLowStockAndOrders(width),
      ]),
    );
  }

  Widget _buildOverviewGrid(double width) {
    final cards = [
      _StatCard(title: 'Earnings', value: '\$16,480', subtitle: 'This month', icon: Icons.trending_up, color: Colors.green),
      _StatCard(title: 'Orders', value: '284', subtitle: 'Pending + Confirmed', icon: Icons.shopping_bag, color: Colors.blue),
      _StatCard(title: 'Low Stock', value: '7', subtitle: 'Restock alerts', icon: Icons.warning_amber, color: Colors.orange),
      _StatCard(title: 'Reviews', value: '4.9', subtitle: 'Average rating', icon: Icons.star, color: Colors.amber),
    ];
    return GridView.count(
      crossAxisCount: width > 1000 ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: width > 1000 ? 1.6 : width > 500 ? 1.4 : 1.2,
      children: cards,
    );
  }

  Widget _buildSalesPerformance(double width) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Sales Performance', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        width > 500
            ? Row(children: [
                Expanded(child: _perfCard('Total Sales', '\$46,300', 'Strong growth in gym products.')),
                const SizedBox(width: 12),
                Expanded(child: _perfCard('Commission', '12%', 'Optimized payout rate.')),
              ])
            : Column(children: [
                _perfCard('Total Sales', '\$46,300', 'Strong growth in gym products.'),
                const SizedBox(height: 12),
                _perfCard('Commission', '12%', 'Optimized payout rate.'),
              ]),
      ]),
    );
  }

  Widget _perfCard(String title, String value, String desc) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: const Color(0xFFF7FBFF), borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54)),
        const SizedBox(height: 8),
        FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold))),
        const SizedBox(height: 6),
        Text(desc, style: const TextStyle(color: Colors.black45, fontSize: 12)),
      ]),
    );
  }

  Widget _buildLowStockAndOrders(double width) {
    final topProducts = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Top Products', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
        _productRow('Power Rack', '104 sold', Colors.green),
        _productRow('Supplements Pack', '87 sold', Colors.blue),
        _productRow('Training Gloves', '64 sold', Colors.orange),
      ]),
    );
    final recentOrders = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Recent Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
        _orderItem('#8124', 'Fitness Essentials', 'Confirmed'),
        const Divider(height: 16),
        _orderItem('#8121', 'Fuel Bundle', 'For Pickup'),
        const Divider(height: 16),
        _orderItem('#8118', 'Recovery Set', 'On Delivery'),
      ]),
    );
    if (width > 700) {
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: topProducts), const SizedBox(width: 14), Expanded(child: recentOrders)]);
    }
    return Column(children: [topProducts, const SizedBox(height: 14), recentOrders]);
  }

  Widget _productRow(String name, String sub, Color c) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(children: [
      CircleAvatar(radius: 18, backgroundColor: c.withOpacity(0.12), child: Icon(Icons.inventory_2, color: c, size: 18)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)), Text(sub, style: const TextStyle(color: Colors.black54, fontSize: 12))])),
    ]),
  );

  Widget _orderItem(String id, String name, String status) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(id, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)), Text(name, style: const TextStyle(color: Colors.black54, fontSize: 12))])),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: status == 'Confirmed' ? Colors.green.shade50 : Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
        child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: status == 'Confirmed' ? Colors.green.shade700 : Colors.orange.shade700)),
      ),
    ]),
  );
}

class _StatCard extends StatelessWidget {
  final String title, value, subtitle;
  final IconData icon;
  final Color color;
  const _StatCard({required this.title, required this.value, required this.subtitle, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 18)),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
        ]),
        const Spacer(),
        FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 11), overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}
