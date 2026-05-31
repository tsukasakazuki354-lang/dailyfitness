import 'package:flutter/material.dart';

/// Modern "Get Started" landing page with Login, Register, and Continue as Guest options.
class GuestPage extends StatelessWidget {
  const GuestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F2850), Color(0xFF163566)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Logo
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF4AB3F4),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4AB3F4).withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.fitness_center, size: 48, color: Colors.white),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Daily Fitness',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Premium Gym Equipment & Supplements',
                  style: TextStyle(fontSize: 14, color: Colors.white60),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                // Get Started card
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Get Started',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F2850)),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Sign in to your account, create a new one, or browse as a guest.',
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      // Login button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/login'),
                          icon: const Icon(Icons.login, size: 20),
                          label: const Text('Login'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F2850),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Register button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/register'),
                          icon: const Icon(Icons.person_add_outlined, size: 20),
                          label: const Text('Create Account'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0F2850),
                            side: const BorderSide(color: Color(0xFF0F2850), width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text('or', style: TextStyle(color: Colors.black38, fontSize: 13)),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Continue as Guest
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          onPressed: () => Navigator.pushReplacementNamed(context, '/guest/browse'),
                          icon: const Icon(Icons.storefront_outlined, size: 20),
                          label: const Text('Continue as Guest'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF4AB3F4),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            backgroundColor: const Color(0xFFF0F8FF),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Features list
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Guest access includes:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                      SizedBox(height: 12),
                      _FeatureRow(icon: Icons.storefront, text: 'Browse all products & categories'),
                      _FeatureRow(icon: Icons.star_outline, text: 'View featured collections'),
                      _FeatureRow(icon: Icons.info_outline, text: 'Read about Daily Fitness'),
                      _FeatureRow(icon: Icons.devices, text: 'Full mobile & web experience'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF4AB3F4)),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: Colors.white70))),
        ],
      ),
    );
  }
}
