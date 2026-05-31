import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daily_fitness/providers/session_provider.dart';
import 'package:daily_fitness/services/auth_service.dart';
import 'package:daily_fitness/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SellerSettingsPage extends StatelessWidget {
  const SellerSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings & Preferences'), automaticallyImplyLeading: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Store Settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _SettingTile(title: 'Store Customization', subtitle: 'Design your storefront and branding.', icon: Icons.storefront, onTap: () => _openStoreCustomization(context)),
          _SettingTile(title: 'Payment & Payout', subtitle: 'Manage payout accounts and methods.', icon: Icons.account_balance_wallet, onTap: () => _openPaymentSettings(context)),
          _SettingTile(title: 'Shipping Settings', subtitle: 'Configure shipping rates and zones.', icon: Icons.local_shipping, onTap: () => _openShippingSettings(context)),
          _SettingTile(title: 'Security', subtitle: 'Update password and privacy settings.', icon: Icons.shield, onTap: () => _openSecuritySettings(context)),
          _SettingTile(title: 'Notifications', subtitle: 'Adjust alerts and email preferences.', icon: Icons.notifications_active, onTap: () => _openNotificationSettings(context)),
          _SettingTile(title: 'Tax & Compliance', subtitle: 'Manage tax registration documents.', icon: Icons.description, onTap: () => _openTaxSettings(context)),
        ]),
      ),
    );
  }

  void _openStoreCustomization(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const _StoreCustomizationPage()));
  }

  void _openPaymentSettings(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const _PaymentSettingsPage()));
  }

  void _openShippingSettings(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const _ShippingSettingsPage()));
  }

  void _openSecuritySettings(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const _SecuritySettingsPage()));
  }

  void _openNotificationSettings(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const _NotificationSettingsPage()));
  }

  void _openTaxSettings(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const _TaxSettingsPage()));
  }
}

class _SettingTile extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final VoidCallback onTap;
  const _SettingTile({required this.title, required this.subtitle, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)]),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFF0F5FF), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: const Color(0xFF0F2850), size: 22)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 13)),
        trailing: const Icon(Icons.chevron_right, color: Colors.black38),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onTap: onTap,
      ),
    );
  }
}

// ─── Store Customization ─────────────────────────────────────────────────────

class _StoreCustomizationPage extends StatefulWidget {
  const _StoreCustomizationPage();
  @override
  State<_StoreCustomizationPage> createState() => _StoreCustomizationPageState();
}

class _StoreCustomizationPageState extends State<_StoreCustomizationPage> {
  final _storeNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _saving = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final uid = Provider.of<SessionProvider>(context, listen: false).currentUser?.uid;
    if (uid == null) return;
    final doc = await FirestoreService.sellerProfiles().doc(uid).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>?;
      _storeNameController.text = data?['storeName'] ?? '';
      _descriptionController.text = data?['storeDescription'] ?? '';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final uid = Provider.of<SessionProvider>(context, listen: false).currentUser?.uid;
    if (uid == null) return;
    setState(() => _saving = true);
    try {
      await FirestoreService.sellerProfiles().doc(uid).update({
        'storeName': _storeNameController.text.trim(),
        'storeDescription': _descriptionController.text.trim(),
        'updatedAt': Timestamp.now(),
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Store updated!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() { _storeNameController.dispose(); _descriptionController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Store Customization')),
      body: _loading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Customize Your Store', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Update your store name and description visible to buyers.', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 24),
          TextFormField(controller: _storeNameController, decoration: const InputDecoration(labelText: 'Store Name', prefixIcon: Icon(Icons.storefront_outlined, size: 20))),
          const SizedBox(height: 16),
          TextFormField(controller: _descriptionController, maxLines: 4, decoration: const InputDecoration(labelText: 'Store Description', prefixIcon: Icon(Icons.description_outlined, size: 20), alignLabelWithHint: true)),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _saving ? null : _save, child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save Changes'))),
        ]),
      ),
    );
  }
}

// ─── Payment Settings ────────────────────────────────────────────────────────

class _PaymentSettingsPage extends StatefulWidget {
  const _PaymentSettingsPage();
  @override
  State<_PaymentSettingsPage> createState() => _PaymentSettingsPageState();
}

class _PaymentSettingsPageState extends State<_PaymentSettingsPage> {
  final _bankName = TextEditingController();
  final _accountName = TextEditingController();
  final _accountNumber = TextEditingController();
  bool _saving = false;

  Future<void> _save() async {
    final uid = Provider.of<SessionProvider>(context, listen: false).currentUser?.uid;
    if (uid == null) return;
    setState(() => _saving = true);
    try {
      await FirestoreService.sellerProfiles().doc(uid).update({
        'payoutInfo': {
          'bankName': _bankName.text.trim(),
          'accountName': _accountName.text.trim(),
          'accountNumber': _accountNumber.text.trim(),
        },
        'updatedAt': Timestamp.now(),
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment info saved!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() { _bankName.dispose(); _accountName.dispose(); _accountNumber.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment & Payout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Payout Information', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Add your bank details for receiving payouts.', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 24),
          TextFormField(controller: _bankName, decoration: const InputDecoration(labelText: 'Bank Name', prefixIcon: Icon(Icons.account_balance, size: 20))),
          const SizedBox(height: 16),
          TextFormField(controller: _accountName, decoration: const InputDecoration(labelText: 'Account Holder Name', prefixIcon: Icon(Icons.person_outline, size: 20))),
          const SizedBox(height: 16),
          TextFormField(controller: _accountNumber, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Account Number', prefixIcon: Icon(Icons.credit_card, size: 20))),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _saving ? null : _save, child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save Payout Info'))),
        ]),
      ),
    );
  }
}

// ─── Shipping Settings ───────────────────────────────────────────────────────

class _ShippingSettingsPage extends StatefulWidget {
  const _ShippingSettingsPage();
  @override
  State<_ShippingSettingsPage> createState() => _ShippingSettingsPageState();
}

class _ShippingSettingsPageState extends State<_ShippingSettingsPage> {
  final _shippingFee = TextEditingController(text: '5.00');
  final _freeShippingMin = TextEditingController(text: '50.00');
  bool _saving = false;

  Future<void> _save() async {
    final uid = Provider.of<SessionProvider>(context, listen: false).currentUser?.uid;
    if (uid == null) return;
    setState(() => _saving = true);
    try {
      await FirestoreService.sellerProfiles().doc(uid).update({
        'shippingSettings': {
          'defaultFee': double.tryParse(_shippingFee.text.trim()) ?? 5.0,
          'freeShippingMinimum': double.tryParse(_freeShippingMin.text.trim()) ?? 50.0,
        },
        'updatedAt': Timestamp.now(),
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shipping settings saved!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() { _shippingFee.dispose(); _freeShippingMin.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shipping Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Shipping Configuration', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Set your default shipping fee and free shipping threshold.', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 24),
          TextFormField(controller: _shippingFee, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Default Shipping Fee (\$)', prefixIcon: Icon(Icons.local_shipping_outlined, size: 20))),
          const SizedBox(height: 16),
          TextFormField(controller: _freeShippingMin, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Free Shipping Minimum (\$)', prefixIcon: Icon(Icons.money_off, size: 20))),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _saving ? null : _save, child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save Shipping Settings'))),
        ]),
      ),
    );
  }
}

// ─── Security Settings ───────────────────────────────────────────────────────

class _SecuritySettingsPage extends StatefulWidget {
  const _SecuritySettingsPage();
  @override
  State<_SecuritySettingsPage> createState() => _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends State<_SecuritySettingsPage> {
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _saving = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;

  Future<void> _changePassword() async {
    if (_newPassword.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New password must be at least 6 characters')));
      return;
    }
    if (_newPassword.text != _confirmPassword.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }
    setState(() => _saving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) throw Exception('Not authenticated');
      final cred = EmailAuthProvider.credential(email: user.email!, password: _currentPassword.text);
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(_newPassword.text);
      if (mounted) {
        _currentPassword.clear(); _newPassword.clear(); _confirmPassword.clear();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed successfully!')));
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.code == 'wrong-password' ? 'Current password is incorrect' : 'Error: ${e.message}')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() { _currentPassword.dispose(); _newPassword.dispose(); _confirmPassword.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Security')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Change Password', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Update your account password for security.', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 24),
          TextFormField(controller: _currentPassword, obscureText: _obscureCurrent, decoration: InputDecoration(labelText: 'Current Password', prefixIcon: const Icon(Icons.lock_outline, size: 20), suffixIcon: IconButton(icon: Icon(_obscureCurrent ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20), onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent)))),
          const SizedBox(height: 16),
          TextFormField(controller: _newPassword, obscureText: _obscureNew, decoration: InputDecoration(labelText: 'New Password', prefixIcon: const Icon(Icons.lock_reset, size: 20), suffixIcon: IconButton(icon: Icon(_obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20), onPressed: () => setState(() => _obscureNew = !_obscureNew)))),
          const SizedBox(height: 16),
          TextFormField(controller: _confirmPassword, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm New Password', prefixIcon: Icon(Icons.lock_outline, size: 20))),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _saving ? null : _changePassword, child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Change Password'))),
        ]),
      ),
    );
  }
}

// ─── Notification Settings ───────────────────────────────────────────────────

class _NotificationSettingsPage extends StatefulWidget {
  const _NotificationSettingsPage();
  @override
  State<_NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<_NotificationSettingsPage> {
  bool _orderAlerts = true;
  bool _stockAlerts = true;
  bool _reviewAlerts = true;
  bool _promoAlerts = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Notification Preferences', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Choose which notifications you want to receive.', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 24),
          SwitchListTile(title: const Text('Order Alerts'), subtitle: const Text('Get notified for new orders'), value: _orderAlerts, onChanged: (v) => setState(() => _orderAlerts = v)),
          SwitchListTile(title: const Text('Low Stock Alerts'), subtitle: const Text('Alert when products are running low'), value: _stockAlerts, onChanged: (v) => setState(() => _stockAlerts = v)),
          SwitchListTile(title: const Text('Review Notifications'), subtitle: const Text('New customer reviews'), value: _reviewAlerts, onChanged: (v) => setState(() => _reviewAlerts = v)),
          SwitchListTile(title: const Text('Promotional Updates'), subtitle: const Text('Platform promotions and offers'), value: _promoAlerts, onChanged: (v) => setState(() => _promoAlerts = v)),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preferences saved!'))),
            child: const Text('Save Preferences'),
          )),
        ]),
      ),
    );
  }
}

// ─── Tax Settings ────────────────────────────────────────────────────────────

class _TaxSettingsPage extends StatelessWidget {
  const _TaxSettingsPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tax & Compliance')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Tax Documents', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Upload and manage your tax registration documents.', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 24),
          _docTile('Business Permit', 'Not uploaded', Icons.business),
          _docTile('Tax Registration (BIR)', 'Not uploaded', Icons.receipt_long),
          _docTile('Valid ID', 'Not uploaded', Icons.badge),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(12)),
            child: const Row(children: [
              Icon(Icons.info_outline, color: Colors.amber, size: 20),
              SizedBox(width: 12),
              Expanded(child: Text('Document upload will be available in a future update. Contact support for manual verification.', style: TextStyle(fontSize: 13, color: Colors.black54))),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _docTile(String title, String status, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFEEF2F6))),
      child: Row(children: [
        Icon(icon, color: const Color(0xFF0F2850), size: 24),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(status, style: const TextStyle(color: Colors.black45, fontSize: 12)),
        ])),
        const Icon(Icons.upload_file, color: Colors.black38, size: 20),
      ]),
    );
  }
}
