import 'package:daily_fitness/providers/session_provider.dart';
import 'package:daily_fitness/ui/admin/pages/admin_overview_page.dart';
import 'package:daily_fitness/ui/admin/pages/admin_users_page.dart';
import 'package:daily_fitness/ui/admin/pages/admin_products_page.dart';
import 'package:daily_fitness/ui/admin/pages/admin_analytics_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class _NavItem {
  final IconData icon, activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const List<_NavItem> _navItems = [
    _NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Dashboard'),
    _NavItem(icon: Icons.people_outline, activeIcon: Icons.people, label: 'Users'),
    _NavItem(icon: Icons.inventory_2_outlined, activeIcon: Icons.inventory_2, label: 'Products'),
    _NavItem(icon: Icons.analytics_outlined, activeIcon: Icons.analytics, label: 'Analytics'),
  ];

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) Navigator.pop(context);
  }

  Widget _buildPageContent() {
    switch (_currentIndex) {
      case 0: return const AdminOverviewPage();
      case 1: return const AdminUsersPage();
      case 2: return const AdminProductsPage();
      case 3: return const AdminAnalyticsPage();
      default: return const AdminOverviewPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 800;
    return Scaffold(
      key: _scaffoldKey,
      appBar: isWide ? null : AppBar(
        title: const Text('Admin Panel'),
        leading: IconButton(icon: const Icon(Icons.menu), onPressed: () => _scaffoldKey.currentState?.openDrawer()),
      ),
      drawer: isWide ? null : _buildMobileDrawer(),
      body: isWide ? Row(children: [_buildDesktopSidebar(), Expanded(child: _buildPageContent())]) : _buildPageContent(),
    );
  }

  Widget _buildDesktopSidebar() {
    final user = Provider.of<SessionProvider>(context).currentUser;
    return Container(
      width: 260,
      decoration: const BoxDecoration(color: Colors.white, border: Border(right: BorderSide(color: Color(0xFFEEF2F6)))),
      child: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 36, 20, 24),
          decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF0F2850), Color(0xFF1A3A6B)]), borderRadius: BorderRadius.only(bottomRight: Radius.circular(28))),
          child: Row(children: [
            const CircleAvatar(radius: 22, backgroundColor: Color(0xFF4AB3F4), child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(user?.firstName ?? 'Admin', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const Text('Administrator', style: TextStyle(color: Colors.white60, fontSize: 12)),
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
              return _AdminNavTile(icon: isActive ? item.activeIcon : item.icon, label: item.label, isActive: isActive, onTap: () => _onNavTap(index));
            },
          ),
        ),
        const Divider(indent: 20, endIndent: 20),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
          child: _AdminNavTile(icon: Icons.logout, label: 'Logout', isActive: false, isDestructive: true, onTap: () {
            Provider.of<SessionProvider>(context, listen: false).signOut().then((_) {
              if (mounted) Navigator.pushReplacementNamed(context, '/login');
            });
          }),
        ),
      ]),
    );
  }

  Widget _buildMobileDrawer() {
    final user = Provider.of<SessionProvider>(context).currentUser;
    return Drawer(
      child: SafeArea(
        child: Column(children: [
          Container(
            width: double.infinity, padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF0F2850), Color(0xFF1A3A6B)])),
            child: Row(children: [
              const CircleAvatar(radius: 22, backgroundColor: Color(0xFF4AB3F4), child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 22)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user?.firstName ?? 'Admin', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const Text('Administrator', style: TextStyle(color: Colors.white60, fontSize: 13)),
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
                return _AdminNavTile(icon: isActive ? item.activeIcon : item.icon, label: item.label, isActive: isActive, onTap: () => _onNavTap(index));
              },
            ),
          ),
          const Divider(indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
            child: _AdminNavTile(icon: Icons.logout, label: 'Logout', isActive: false, isDestructive: true, onTap: () {
              Provider.of<SessionProvider>(context, listen: false).signOut().then((_) {
                if (mounted) Navigator.pushReplacementNamed(context, '/login');
              });
            }),
          ),
        ]),
      ),
    );
  }
}

class _AdminNavTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive, isDestructive;
  final VoidCallback onTap;
  const _AdminNavTile({required this.icon, required this.label, required this.isActive, required this.onTap, this.isDestructive = false});
  @override
  State<_AdminNavTile> createState() => _AdminNavTileState();
}

class _AdminNavTileState extends State<_AdminNavTile> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF0F2850);
    const activeBg = Color(0xFFE8F1FF);
    const hoverBg = Color(0xFFF3F7FC);
    final destructiveColor = Colors.red.shade600;
    Color bg, fg; FontWeight fw;
    if (widget.isActive) { bg = activeBg; fg = activeColor; fw = FontWeight.w700; }
    else if (_hovered) { bg = hoverBg; fg = widget.isDestructive ? destructiveColor : activeColor; fw = FontWeight.w600; }
    else { bg = Colors.transparent; fg = widget.isDestructive ? destructiveColor : Colors.black87; fw = FontWeight.w500; }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Material(color: bg, borderRadius: BorderRadius.circular(12), child: InkWell(
          borderRadius: BorderRadius.circular(12), onTap: widget.onTap, splashColor: activeBg,
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Row(children: [
            Icon(widget.icon, size: 21, color: fg), const SizedBox(width: 14),
            Expanded(child: Text(widget.label, style: TextStyle(fontSize: 14, fontWeight: fw, color: fg))),
            if (widget.isActive) Container(width: 4, height: 18, decoration: BoxDecoration(color: const Color(0xFF4AB3F4), borderRadius: BorderRadius.circular(2))),
          ])),
        )),
      ),
    );
  }
}
