import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daily_fitness/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email') ?? '';
    final remember = prefs.getBool('remember_me') ?? false;
    if (remember && savedEmail.isNotEmpty) {
      setState(() {
        _emailController.text = savedEmail;
        _rememberMe = true;
      });
    }
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('saved_email', _emailController.text.trim());
      await prefs.setBool('remember_me', true);
    } else {
      await prefs.remove('saved_email');
      await prefs.setBool('remember_me', false);
    }
  }

  Future<String> _resolveEmail(String usernameOrEmail) async {
    final input = usernameOrEmail.trim();
    if (input.contains('@')) return input;

    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: input)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw Exception('No account found for "$input".');
    }
    return query.docs.first.data()['email'] as String;
  }

  Future<void> _navigateToDashboardForUser(User? user) async {
    if (user == null) return;
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final role = snapshot.exists ? (snapshot.data()?['role'] as String?) : null;

      if (role == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account role not configured. Contact support.')),
          );
        }
        return;
      }

      // Check approval status for seller and rider accounts
      final status = snapshot.exists ? (snapshot.data()?['status'] as String?) ?? 'active' : 'active';
      if ((role == 'seller' || role == 'rider') && status != 'active' && status != 'approved') {
        if (mounted) {
          String message;
          switch (status) {
            case 'pending':
              message = 'Your account is pending admin approval. Please wait for verification.';
              break;
            case 'declined':
              message = 'Your account has been declined. Contact support for more information.';
              break;
            case 'suspended':
              message = 'Your account has been suspended. Contact support.';
              break;
            default:
              message = 'Your account status is: $status. Contact support.';
          }
          await AuthService.signOut();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 4)));
        }
        return;
      }

      final route = switch (role) {
        'seller' => '/dashboard/seller',
        'rider' => '/dashboard/rider',
        'admin' => '/dashboard/admin',
        _ => '/dashboard/buyer',
      };

      if (mounted) Navigator.pushReplacementNamed(context, route);
    } on FirebaseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
      }
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final email = await _resolveEmail(_emailController.text.trim());
      final credential = await AuthService.signInWithEmail(email, _passwordController.text.trim());
      await _saveCredentials();
      await _navigateToDashboardForUser(credential.user);
    } on FirebaseAuthException catch (e) {
      final message = switch (e.code) {
        'invalid-credential' => 'Incorrect email/username or password.',
        'user-not-found' => 'No account found. Please sign up first.',
        'wrong-password' => 'Incorrect password.',
        'user-disabled' => 'Account disabled. Contact support.',
        'too-many-requests' => 'Too many attempts. Try again later.',
        'invalid-email' => 'Invalid email address.',
        _ => e.message ?? 'Login failed.',
      };
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final credential = await AuthService.signInWithGoogle();
      if (credential != null) {
        await _navigateToDashboardForUser(credential.user);
      }
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Google sign-in failed: $error')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showForgotPasswordDialog() {
    final resetController = TextEditingController(text: _emailController.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset Password', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your email address and we\'ll send you a link to reset your password.', style: TextStyle(color: Colors.black54, fontSize: 14)),
            const SizedBox(height: 16),
            TextField(
              controller: resetController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final email = resetController.text.trim();
              if (email.isEmpty || !email.contains('@')) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid email')));
                return;
              }
              try {
                await AuthService.sendPasswordReset(email);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reset link sent to $email')));
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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
                constraints: BoxConstraints(maxWidth: width > 900 ? 480 : 440),
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
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Welcome back', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F2850))),
                            const SizedBox(height: 6),
                            const Text('Sign in to continue shopping', style: TextStyle(fontSize: 14, color: Colors.black54)),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email or Username',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _rememberMe = !_rememberMe),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: Checkbox(
                                            value: _rememberMe,
                                            onChanged: (v) => setState(() => _rememberMe = v ?? true),
                                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Text('Remember Me', style: TextStyle(fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: _showForgotPasswordDialog,
                                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                  child: const Text('Forgot Password?', style: TextStyle(fontSize: 13)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                child: _isLoading
                                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Text('Sign In'),
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                icon: const Text('G', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                                label: const Text('Sign in with Google'),
                                onPressed: _isLoading ? null : _signInWithGoogle,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("Don't have an account? ", style: TextStyle(fontSize: 13, color: Colors.black54)),
                                GestureDetector(
                                  onTap: () => Navigator.pushNamed(context, '/register'),
                                  child: const Text('Sign up', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F2850))),
                                ),
                              ],
                            ),
                          ],
                        ),
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
