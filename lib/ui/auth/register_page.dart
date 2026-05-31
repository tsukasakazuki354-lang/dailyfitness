import 'package:flutter/material.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A1E3D), Color(0xFF0F2850), Color(0xFF163566)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: width > 900 ? 520 : 460),
                child: Column(
                  children: [
                    // Logo
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF4AB3F4),
                        boxShadow: [BoxShadow(color: const Color(0xFF4AB3F4).withOpacity(0.3), blurRadius: 16)],
                      ),
                      child: const Icon(Icons.fitness_center, size: 36, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    const Text('Daily Fitness', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
                    const SizedBox(height: 28),
                    // Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 8))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Create Account', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F2850))),
                          const SizedBox(height: 6),
                          const Text('Select your role to get started', style: TextStyle(fontSize: 14, color: Colors.black54)),
                          const SizedBox(height: 24),
                          _RoleCard(
                            icon: Icons.shopping_bag_outlined,
                            title: 'Buyer',
                            subtitle: 'Browse products, save favorites, and manage orders.',
                            onTap: () => Navigator.pushNamed(context, '/register/buyer'),
                          ),
                          const SizedBox(height: 14),
                          _RoleCard(
                            icon: Icons.store_outlined,
                            title: 'Seller',
                            subtitle: 'Upload products, view sales, and manage your store.',
                            onTap: () => Navigator.pushNamed(context, '/register/seller'),
                          ),
                          const SizedBox(height: 14),
                          _RoleCard(
                            icon: Icons.delivery_dining_outlined,
                            title: 'Rider',
                            subtitle: 'Manage deliveries and stay on schedule.',
                            onTap: () => Navigator.pushNamed(context, '/register/rider'),
                          ),
                          const SizedBox(height: 22),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Already have an account? ', style: TextStyle(fontSize: 13, color: Colors.black54)),
                              GestureDetector(
                                onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                                child: const Text('Sign in', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F2850))),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Get Started (Guest) button
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () => Navigator.pushReplacementNamed(context, '/guest/browse'),
                        icon: const Icon(Icons.storefront_outlined, size: 18, color: Colors.white70),
                        label: const Text('Get Started as Guest', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.white.withOpacity(0.2))),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RoleCard({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _isHovered ? const Color(0xFFF0F7FF) : const Color(0xFFF8FBFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _isHovered ? const Color(0xFF4AB3F4) : const Color(0xFFE8F0FE), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5F2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, color: const Color(0xFF0F2850), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F2850))),
                    const SizedBox(height: 3),
                    Text(widget.subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF4AB3F4)),
            ],
          ),
        ),
      ),
    );
  }
}
