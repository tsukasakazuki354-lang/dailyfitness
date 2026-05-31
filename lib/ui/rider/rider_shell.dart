import 'package:daily_fitness/providers/session_provider.dart';
import 'package:daily_fitness/ui/rider/pages/rider_overview_page.dart';
import 'package:daily_fitness/ui/rider/pages/rider_earnings_page.dart';
import 'package:daily_fitness/ui/rider/pages/rider_deliveries_page.dart';
import 'package:daily_fitness/ui/rider/pages/rider_complaints_page.dart';
import 'package:daily_fitness/ui/rider/pages/rider_map_page.dart';
import 'package:daily_fitness/ui/rider/pages/rider_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}

class RiderDashboard extends StatefulWidget {
  const RiderDashboard({super.key});

  @override
  State<RiderDashboard> createState() => _RiderDashboardState();
}

class _RiderDashboardState extends State<RiderDashboard> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const List<_NavItem> _navItems = [
    _NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Dashboard'),
    _NavItem(icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet, label: 'Earnings & Reports'),
    _NavItem(icon: Icons.delivery_dining_outlined, activeIcon: Icons.delivery_dining, label: 'My Deliveries'),
    _NavItem(icon: Icons.feedback_outlined, activeIcon: Icons.feedback, label: 'Complaints'),
    _NavItem(icon: Icons.map_outlined, activeIcon: Icons.map, label: 'Delivery Map'),
    _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile'),
  ];

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) Navigator.pop(context);
  }

  Widget _buildPageContent() {
    switch (_currentIndex) {
      case 0: return const RiderOverviewPage();
      case 1: return const RiderEarningsPage();
      case 2: return const RiderDeliveriesPage();
      case 3: return const RiderComplaintsPage();
      case 4: return const RiderMapPage();
      case 5: return const RiderProfilePage();
      default: return const RiderOverviewPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 800;

    return Scaffold(
      key: _scaffoldKey,
      appBar: isWide ? null : AppBar(
        title: const Text('Rider Dashboard'),
        leading: IconButton(icon: const Icon(Icons.menu), onPressed: () => _scaffoldKey.currentState?.openDrawer()),
        actions: [IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {})],
      ),
      drawer: isWide ? null : _buildMobileDrawer(),
      body: isWide
          ? Row(children: [_buildDesktopSidebar(), Expanded(child: _buildPageContent())])
          : _buildPageContent(),
    );
  }

  Widget _buildDesktopSidebar() {
    final user = Provider.of<SessionProvider>(context).currentUser;
    final name = user?.firstName ?? 'Rider';

    return Container(
      width: 260,
      decoration: const BoxDecoration(color: Colors.white, border: Border(right: BorderSide(color: Color(0xFFEEF2F6)))),
      child: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 36, 20, 24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF0F2850), Color(0xFF1A3A6B)]),
            borderRadius: BorderRadius.only(bottomRight: Radius.circular(28)),
          ),
          child: Row(children: [
            CircleAvatar(radius: 22, backgroundColor: const Color(0xFF4AB3F4), child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'R', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const Text('Rider Account', style: TextStyle(color: Colors.white60, fontSize: 12)),
            ])),
          ]),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _navItems.length,
            itemBuilder: (context, index) {
              final item = _navItems[index];
              final isActive = _currentIndex == index;
              return _RiderNavTile(icon: isActive ? item.activeIcon : item.icon, label: item.label, isActive: isActive, onTap: () => _onNavTap(index));
            },
          ),
        ),
        const Divider(indent: 20, endIndent: 20),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
          child: _RiderNavTile(icon: Icons.logout, label: 'Logout', isActive: false, isDestructive: true, onTap: () {
            Provider.of<SessionProvider>(context, listen: false).signOut();
            Navigator.pushReplacementNamed(context, '/login');
          }),
        ),
      ]),
    );
  }

  Widget _buildMobileDrawer() {
    final user = Provider.of<SessionProvider>(context).currentUser;
    final name = user?.firstName ?? 'Rider';

    return Drawer(
      child: SafeArea(
        child: Column(children: [
          Container(
            width: double.infinity, padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF0F2850), Color(0xFF1A3A6B)])),
            child: Row(children: [
              CircleAvatar(radius: 22, backgroundColor: const Color(0xFF4AB3F4), child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'R', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const Text('Rider Account', style: TextStyle(color: Colors.white60, fontSize: 13)),
              ])),
            ]),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isActive = _currentIndex == index;
                return _RiderNavTile(icon: isActive ? item.activeIcon : item.icon, label: item.label, isActive: isActive, onTap: () => _onNavTap(index));
              },
            ),
          ),
          const Divider(indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
            child: _RiderNavTile(icon: Icons.logout, label: 'Logout', isActive: false, isDestructive: true, onTap: () {
              Provider.of<SessionProvider>(context, listen: false).signOut();
              Navigator.pushReplacementNamed(context, '/login');
            }),
          ),
        ]),
      ),
    );
  }
}

class _RiderNavTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isDestructive;
  final VoidCallback onTap;
  const _RiderNavTile({required this.icon, required this.label, required this.isActive, required this.onTap, this.isDestructive = false});

  @override
  State<_RiderNavTile> createState() => _RiderNavTileState();
}

class _RiderNavTileState extends State<_RiderNavTile> {
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
          color: bg, borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12), onTap: widget.onTap, splashColor: activeBg,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                Icon(widget.icon, size: 21, color: fg),
                const SizedBox(width: 14),
                Expanded(child: Text(widget.label, style: TextStyle(fontSize: 14, fontWeight: fw, color: fg))),
                if (widget.isActive) Container(width: 4, height: 18, decoration: BoxDecoration(color: const Color(0xFF4AB3F4), borderRadius: BorderRadius.circular(2))),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
