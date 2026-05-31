import 'package:daily_fitness/ui/buyer/buyer_home_content.dart';
import 'package:daily_fitness/ui/buyer/shop_page.dart';
import 'package:flutter/material.dart';

/// The guest browsing shell — mirrors the Buyer layout but restricts
/// protected features behind a login/register prompt.
class GuestShell extends StatefulWidget {
  const GuestShell({super.key});

  @override
  State<GuestShell> createState() => _GuestShellState();
}

class _GuestShellState extends State<GuestShell> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const List<_GuestNavItem> _navItems = [
    _GuestNavItem(icon: Icons.home_outlined, activeIcon: Icons.home_filled, label: 'Home', protected: false),
    _GuestNavItem(icon: Icons.storefront_outlined, activeIcon: Icons.storefront, label: 'Shop', protected: false),
    _GuestNavItem(icon: Icons.favorite_border, activeIcon: Icons.favorite, label: 'Wishlist', protected: true),
    _GuestNavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long, label: 'Orders', protected: true),
    _GuestNavItem(icon: Icons.location_on_outlined, activeIcon: Icons.location_on, label: 'Addresses', protected: true),
    _GuestNavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile', protected: true),
    _GuestNavItem(icon: Icons.notifications_outlined, activeIcon: Icons.notifications, label: 'Notifications', protected: true),
  ];

  void _onNavTap(int index) {
    if (_navItems[index].protected) {
      _showAuthPrompt();
      return;
    }
    setState(() => _currentIndex = index);
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.pop(context);
    }
  }

  void _showAuthPrompt() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE5F2FF),
                ),
                child: const Icon(Icons.lock_outline, size: 32, color: Color(0xFF0F2850)),
              ),
              const SizedBox(height: 20),
              const Text(
                'Account Required',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F2850)),
              ),
              const SizedBox(height: 10),
              const Text(
                'Please log in or register to access this feature.',
                style: TextStyle(fontSize: 14, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushNamed(context, '/login');
                  },
                  icon: const Icon(Icons.login, size: 18),
                  label: const Text('Login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F2850),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushNamed(context, '/register');
                  },
                  icon: const Icon(Icons.person_add_outlined, size: 18),
                  label: const Text('Register'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F2850),
                    side: const BorderSide(color: Color(0xFF0F2850), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: Colors.black45)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageContent() {
    switch (_currentIndex) {
      case 0:
        return BuyerHomeContent(isGuest: true, onNavigate: _onNavTap);
      case 1:
        return const ShopPage();
      default:
        return BuyerHomeContent(isGuest: true, onNavigate: _onNavTap);
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
                // Login button in app bar for guests
                TextButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  icon: const Icon(Icons.login, size: 18, color: Color(0xFF4AB3F4)),
                  label: const Text('Login', style: TextStyle(color: Color(0xFF4AB3F4))),
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
      bottomNavigationBar: null,
    );
  }

  Widget _buildDesktopSidebar() {
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
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Color(0xFF4AB3F4),
                      child: Icon(Icons.person_outline, color: Colors.white, size: 22),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hello, Guest', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('Browse Mode', style: TextStyle(color: Colors.white60, fontSize: 12)),
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
                return _GuestSidebarTile(
                  icon: isActive ? item.activeIcon : item.icon,
                  label: item.label,
                  isActive: isActive,
                  isProtected: item.protected,
                  onTap: () => _onNavTap(index),
                );
              },
            ),
          ),
          // Cart (protected)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: _GuestSidebarTile(
              icon: Icons.shopping_cart_outlined,
              label: 'My Cart',
              isActive: false,
              isProtected: true,
              onTap: _showAuthPrompt,
            ),
          ),
          const Divider(indent: 20, endIndent: 20),
          // Login & Register instead of Logout
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: _GuestSidebarTile(
              icon: Icons.login,
              label: 'Login',
              isActive: false,
              isProtected: false,
              onTap: () => Navigator.pushNamed(context, '/login'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: _GuestSidebarTile(
              icon: Icons.person_add_outlined,
              label: 'Register',
              isActive: false,
              isProtected: false,
              onTap: () => Navigator.pushNamed(context, '/register'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: const Color(0xFF0F2850),
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Color(0xFF4AB3F4),
                    child: Icon(Icons.person_outline, color: Colors.white, size: 24),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hello, Guest', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('Browse Mode', style: TextStyle(color: Colors.white60, fontSize: 13)),
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
                  return _GuestSidebarTile(
                    icon: isActive ? item.activeIcon : item.icon,
                    label: item.label,
                    isActive: isActive,
                    isProtected: item.protected,
                    onTap: () {
                      if (item.protected) {
                        Navigator.pop(context);
                        _showAuthPrompt();
                      } else {
                        _onNavTap(index);
                      }
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: _GuestSidebarTile(
                icon: Icons.shopping_cart_outlined,
                label: 'My Cart',
                isActive: false,
                isProtected: true,
                onTap: () {
                  Navigator.pop(context);
                  _showAuthPrompt();
                },
              ),
            ),
            const Divider(indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: _GuestSidebarTile(
                icon: Icons.login,
                label: 'Login',
                isActive: false,
                isProtected: false,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/login');
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              child: _GuestSidebarTile(
                icon: Icons.person_add_outlined,
                label: 'Register',
                isActive: false,
                isProtected: false,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/register');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return NavigationBar(
      selectedIndex: _currentIndex < 2 ? _currentIndex : 0,
      onDestinationSelected: (index) {
        if (index < 2) {
          _onNavTap(index);
        } else {
          _showAuthPrompt();
        }
      },
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_filled), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'Shop'),
        NavigationDestination(icon: Icon(Icons.favorite_border), label: 'Wishlist'),
        NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Orders'),
        NavigationDestination(icon: Icon(Icons.login), label: 'Login'),
      ],
    );
  }
}

/// Nav item model with protected flag
class _GuestNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool protected;

  const _GuestNavItem({required this.icon, required this.activeIcon, required this.label, required this.protected});
}

/// Sidebar tile for guest — shows a lock icon on protected items
class _GuestSidebarTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isProtected;
  final VoidCallback onTap;

  const _GuestSidebarTile({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.isProtected = false,
  });

  @override
  State<_GuestSidebarTile> createState() => _GuestSidebarTileState();
}

class _GuestSidebarTileState extends State<_GuestSidebarTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    const Color activeColor = Color(0xFF0F2850);
    const Color activeBg = Color(0xFFE5F2FF);
    const Color hoverBg = Color(0xFFF0F5FF);

    Color bgColor;
    Color fgColor;
    FontWeight fontWeight;

    if (widget.isActive) {
      bgColor = activeBg;
      fgColor = activeColor;
      fontWeight = FontWeight.w700;
    } else if (_isHovered) {
      bgColor = hoverBg;
      fgColor = widget.isProtected ? Colors.black54 : activeColor;
      fontWeight = FontWeight.w600;
    } else {
      bgColor = Colors.transparent;
      fgColor = widget.isProtected ? Colors.black45 : Colors.black87;
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
                  if (widget.isProtected)
                    const Icon(Icons.lock_outline, size: 14, color: Colors.black26)
                  else if (widget.isActive)
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
