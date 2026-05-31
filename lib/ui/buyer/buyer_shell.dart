import 'package:daily_fitness/providers/session_provider.dart';
import 'package:daily_fitness/ui/buyer/buyer_home_content.dart';
import 'package:daily_fitness/ui/buyer/cart_page.dart';
import 'package:daily_fitness/ui/buyer/notifications_page.dart';
import 'package:daily_fitness/ui/buyer/order_history_page.dart';
import 'package:daily_fitness/ui/buyer/profile_page.dart';
import 'package:daily_fitness/ui/buyer/saved_addresses_page.dart';
import 'package:daily_fitness/ui/buyer/shop_page.dart';
import 'package:daily_fitness/ui/buyer/wishlist_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Navigation item definition
class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}

/// The persistent buyer shell with sidebar navigation.
/// All buyer pages render inside this shell so the sidebar never disappears.
class BuyerShell extends StatefulWidget {
  final bool isGuest;
  final int initialIndex;

  const BuyerShell({super.key, this.isGuest = false, this.initialIndex = 0});

  @override
  State<BuyerShell> createState() => _BuyerShellState();
}

class _BuyerShellState extends State<BuyerShell> {
  late int _currentIndex;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const List<_NavItem> _navItems = [
    _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_filled, label: 'Home'),
    _NavItem(icon: Icons.storefront_outlined, activeIcon: Icons.storefront, label: 'Shop'),
    _NavItem(icon: Icons.shopping_cart_outlined, activeIcon: Icons.shopping_cart, label: 'My Cart'),
    _NavItem(icon: Icons.favorite_border, activeIcon: Icons.favorite, label: 'Wishlist'),
    _NavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long, label: 'Orders'),
    _NavItem(icon: Icons.location_on_outlined, activeIcon: Icons.location_on, label: 'Addresses'),
    _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile'),
    _NavItem(icon: Icons.notifications_outlined, activeIcon: Icons.notifications, label: 'Notifications'),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
    // Close drawer on mobile after selection
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.pop(context);
    }
  }

  Widget _buildPageContent() {
    switch (_currentIndex) {
      case 0:
        return BuyerHomeContent(
          isGuest: widget.isGuest,
          onNavigate: _onNavTap,
        );
      case 1:
        return const ShopPage();
      case 2:
        return const CartPage();
      case 3:
        return const WishlistPage();
      case 4:
        return const OrderHistoryPage();
      case 5:
        return const SavedAddressesPage();
      case 6:
        return const ProfilePage();
      case 7:
        return const NotificationsPage();
      default:
        return BuyerHomeContent(isGuest: widget.isGuest, onNavigate: _onNavTap);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 800;

    return Scaffold(
      key: _scaffoldKey,
      appBar: isWide
          ? null
          : AppBar(
              title: const Text('Daily Fitness Store'),
              leading: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_none),
                  onPressed: () => _onNavTap(7),
                ),
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined),
                  onPressed: () => _onNavTap(2),
                ),
              ],
            ),
      drawer: isWide ? null : _buildMobileDrawer(),
      body: isWide
          ? Row(
              children: [
                _buildDesktopSidebar(),
                Expanded(child: _buildPageContent()),
              ],
            )
          : _buildPageContent(),
      // No bottom nav bar
      bottomNavigationBar: null,
    );
  }

  /// Desktop/tablet persistent sidebar
  Widget _buildDesktopSidebar() {
    final user = Provider.of<SessionProvider>(context).currentUser;
    final name = user?.firstName ?? 'Guest';

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(2, 0)),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
            decoration: const BoxDecoration(
              color: Color(0xFF0F2850),
              borderRadius: BorderRadius.only(bottomRight: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFF4AB3F4),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hello, $name', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          const Text('Buyer Account', style: TextStyle(color: Colors.white60, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Nav items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isActive = _currentIndex == index;
                return _SidebarNavTile(
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
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            child: _SidebarNavTile(
              icon: Icons.logout,
              label: 'Logout',
              isActive: false,
              isDestructive: true,
              onTap: () async {
                await Provider.of<SessionProvider>(context, listen: false).signOut();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Mobile drawer
  Widget _buildMobileDrawer() {
    final user = Provider.of<SessionProvider>(context).currentUser;
    final name = user?.firstName ?? 'Guest';

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: const Color(0xFF0F2850),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFF4AB3F4),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hello, $name', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const Text('Buyer Account', style: TextStyle(color: Colors.white60, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                itemCount: _navItems.length,
                itemBuilder: (context, index) {
                  final item = _navItems[index];
                  final isActive = _currentIndex == index;
                  return _SidebarNavTile(
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
              child: _SidebarNavTile(
                icon: Icons.logout,
                label: 'Logout',
                isActive: false,
                isDestructive: true,
                onTap: () async {
                  await Provider.of<SessionProvider>(context, listen: false).signOut();
                  if (mounted) {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bottom navigation bar for small phones
  Widget _buildBottomNav() {
    return NavigationBar(
      selectedIndex: _currentIndex < 5 ? _currentIndex : 0,
      onDestinationSelected: _onNavTap,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_filled), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'Shop'),
        NavigationDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite), label: 'Wishlist'),
        NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Orders'),
        NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}

/// Individual sidebar navigation tile with active state, hover, and focus
class _SidebarNavTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isDestructive;
  final VoidCallback onTap;

  const _SidebarNavTile({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  State<_SidebarNavTile> createState() => _SidebarNavTileState();
}

class _SidebarNavTileState extends State<_SidebarNavTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final Color activeColor = const Color(0xFF0F2850);
    final Color activeBg = const Color(0xFFE5F2FF);
    final Color hoverBg = const Color(0xFFF0F5FF);
    final Color destructiveColor = Colors.red.shade600;

    Color bgColor;
    Color fgColor;
    FontWeight fontWeight;

    if (widget.isActive) {
      bgColor = activeBg;
      fgColor = activeColor;
      fontWeight = FontWeight.w700;
    } else if (_isHovered) {
      bgColor = hoverBg;
      fgColor = widget.isDestructive ? destructiveColor : activeColor;
      fontWeight = FontWeight.w600;
    } else {
      bgColor = Colors.transparent;
      fgColor = widget.isDestructive ? destructiveColor : Colors.black87;
      fontWeight = FontWeight.w500;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Material(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: widget.onTap,
            splashColor: activeBg,
            highlightColor: activeBg.withOpacity(0.5),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(widget.icon, size: 22, color: fgColor),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      widget.label,
                      style: TextStyle(fontSize: 14, fontWeight: fontWeight, color: fgColor),
                    ),
                  ),
                  if (widget.isActive)
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4AB3F4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
