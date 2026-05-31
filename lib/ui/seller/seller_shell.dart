import 'package:daily_fitness/providers/session_provider.dart';
import 'package:daily_fitness/ui/seller/pages/seller_overview_page.dart';
import 'package:daily_fitness/ui/seller/pages/seller_products_page.dart';
import 'package:daily_fitness/ui/seller/pages/seller_orders_page.dart';
import 'package:daily_fitness/ui/seller/pages/seller_analytics_page.dart';
import 'package:daily_fitness/ui/seller/pages/seller_reviews_page.dart';
import 'package:daily_fitness/ui/seller/pages/seller_warnings_page.dart';
import 'package:daily_fitness/ui/seller/pages/seller_settings_page.dart';
import 'package:daily_fitness/ui/seller/pages/seller_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}

class SellerDashboard extends StatefulWidget {
  const SellerDashboard({super.key});

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const List<_NavItem> _navItems = [
    _NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Overview'),
    _NavItem(icon: Icons.inventory_2_outlined, activeIcon: Icons.inventory_2, label: 'Products'),
    _NavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long, label: 'Orders'),
    _NavItem(icon: Icons.analytics_outlined, activeIcon: Icons.analytics, label: 'Analytics'),
    _NavItem(icon: Icons.reviews_outlined, activeIcon: Icons.reviews, label: 'Product Reviews'),
    _NavItem(icon: Icons.warning_amber_outlined, activeIcon: Icons.warning_amber, label: 'Warnings'),
    _NavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Settings'),
    _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile'),
  ];

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.pop(context);
    }
  }

  Widget _buildPageContent() {
    switch (_currentIndex) {
      case 0: return const SellerOverviewPage();
      case 1: return const SellerProductsPage();
      case 2: return const SellerOrdersPage();
      case 3: return const SellerAnalyticsPage();
      case 4: return const SellerReviewsPage();
      case 5: return const SellerWarningsPage();
      case 6: return const SellerSettingsPage();
      case 7: return const SellerProfilePage();
      default: return const SellerOverviewPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 800;

    return Scaffold(
      key: _scaffoldKey,
      appBar: isWide ? null : AppBar(
        title: const Text('Seller Dashboard'),
        leading: IconButton(icon: const Icon(Icons.menu), onPressed: () => _scaffoldKey.currentState?.openDrawer()),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}),
        ],
      ),
      drawer: isWide ? null : _buildMobileDrawer(),
      body: isWide
          ? Row(children: [_buildDesktopSidebar(), Expanded(child: _buildPageContent())])
          : _buildPageContent(),
    );
  }

  Widget _buildDesktopSidebar() {
    final user = Provider.of<SessionProvider>(context).currentUser;
    final name = user?.firstName ?? 'Seller';
    final store = user?.username ?? 'My Store';

    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFEEF2F6), width: 1)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 36, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF0F2850), Color(0xFF1A3A6B)]),
              borderRadius: BorderRadius.only(bottomRight: Radius.circular(28)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFF4AB3F4),
                    child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'S', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(store, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                    ],
                  )),
                ]),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                  child: const Text('Seller Account', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Nav items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isActive = _currentIndex == index;
                return _SellerNavTile(
                  icon: isActive ? item.activeIcon : item.icon,
                  label: item.label,
                  isActive: isActive,
                  onTap: () => _onNavTap(index),
                );
              },
            ),
          ),
          const Divider(indent: 20, endIndent: 20),
          // Logout
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
            child: _SellerNavTile(
              icon: Icons.logout,
              label: 'Logout',
              isActive: false,
              isDestructive: true,
              onTap: () {
                Provider.of<SessionProvider>(context, listen: false).signOut().then((_) {
                  if (mounted) Navigator.pushReplacementNamed(context, '/login');
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileDrawer() {
    final user = Provider.of<SessionProvider>(context).currentUser;
    final name = user?.firstName ?? 'Seller';

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF0F2850), Color(0xFF1A3A6B)]),
              ),
              child: Row(children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFF4AB3F4),
                  child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'S', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const Text('Seller Account', style: TextStyle(color: Colors.white60, fontSize: 13)),
                  ],
                )),
              ]),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                itemCount: _navItems.length,
                itemBuilder: (context, index) {
                  final item = _navItems[index];
                  final isActive = _currentIndex == index;
                  return _SellerNavTile(
                    icon: isActive ? item.activeIcon : item.icon,
                    label: item.label,
                    isActive: isActive,
                    onTap: () => _onNavTap(index),
                  );
                },
              ),
            ),
            const Divider(indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
              child: _SellerNavTile(
                icon: Icons.logout,
                label: 'Logout',
                isActive: false,
                isDestructive: true,
                onTap: () {
                  Provider.of<SessionProvider>(context, listen: false).signOut().then((_) {
                    if (mounted) Navigator.pushReplacementNamed(context, '/login');
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SellerNavTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isDestructive;
  final VoidCallback onTap;

  const _SellerNavTile({required this.icon, required this.label, required this.isActive, required this.onTap, this.isDestructive = false});

  @override
  State<_SellerNavTile> createState() => _SellerNavTileState();
}

class _SellerNavTileState extends State<_SellerNavTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF0F2850);
    const activeBg = Color(0xFFE8F1FF);
    const hoverBg = Color(0xFFF3F7FC);
    final destructiveColor = Colors.red.shade600;

    Color bg, fg;
    FontWeight fw;

    if (widget.isActive) { bg = activeBg; fg = activeColor; fw = FontWeight.w700; }
    else if (_hovered) { bg = hoverBg; fg = widget.isDestructive ? destructiveColor : activeColor; fw = FontWeight.w600; }
    else { bg = Colors.transparent; fg = widget.isDestructive ? destructiveColor : Colors.black87; fw = FontWeight.w500; }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: widget.onTap,
            splashColor: activeBg,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                Icon(widget.icon, size: 21, color: fg),
                const SizedBox(width: 14),
                Expanded(child: Text(widget.label, style: TextStyle(fontSize: 14, fontWeight: fw, color: fg))),
                if (widget.isActive)
                  Container(width: 4, height: 18, decoration: BoxDecoration(color: const Color(0xFF4AB3F4), borderRadius: BorderRadius.circular(2))),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
