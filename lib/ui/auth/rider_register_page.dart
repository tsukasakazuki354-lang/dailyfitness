import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daily_fitness/models/app_user.dart';
import 'package:daily_fitness/services/auth_service.dart';
import 'package:daily_fitness/services/cloudinary_service.dart';
import 'package:daily_fitness/services/firestore_service.dart';
import 'package:daily_fitness/ui/shared/address_dropdown_fields.dart';
import 'package:daily_fitness/ui/shared/document_upload_field.dart';
import 'package:flutter/material.dart';

class RiderRegisterPage extends StatefulWidget {
  const RiderRegisterPage({super.key});

  @override
  State<RiderRegisterPage> createState() => _RiderRegisterPageState();
}

class _RiderRegisterPageState extends State<RiderRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _addressKey = GlobalKey<AddressDropdownFieldsState>();
  AddressData _addressData = const AddressData(region: '', provinceCity: '', municipality: '', barangay: '', streetAddress: '', zipCode: '');
  bool _agree = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  Uint8List? _validIdBytes;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agree) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You must agree to the terms and privacy policy.')));
      return;
    }
    if (_password.text != _confirmPassword.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }
    if (_validIdBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload your Valid ID or Driver\'s License')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final credential = await AuthService.signUpWithEmail(_email.text.trim(), _password.text.trim());
      final uid = credential.user?.uid ?? '';
      final now = Timestamp.now();
      String validIdUrl = '';
      try { validIdUrl = await CloudinaryService.uploadImage(bytes: _validIdBytes!, folder: 'riders/$uid', fileName: 'valid_id'); } catch (_) {}
      final user = AppUser(uid: uid, role: 'rider', firstName: _firstName.text.trim(), lastName: _lastName.text.trim(), username: _username.text.trim(), email: _email.text.trim(), phoneNumber: _phone.text.trim(), profileImage: '', status: 'pending', createdAt: now, updatedAt: now);
      await FirestoreService.createUserProfile(user);
      await FirestoreService.riderProfiles().doc(uid).set({'riderId': uid, 'userId': uid, 'validIdUrl': validIdUrl, 'driverLicenseUrl': validIdUrl, 'performanceStats': {'totalDeliveries': 0, 'onTimeRate': 0}, 'riderLevel': 'Bronze', 'verificationStatus': 'pending', 'createdAt': now, 'updatedAt': now});
      await FirestoreService.addresses().doc().set({'addressId': '${uid}_${DateTime.now().millisecondsSinceEpoch}', 'userId': uid, 'region': _addressData.region, 'provinceCity': _addressData.provinceCity, 'municipality': _addressData.municipality, 'barangay': _addressData.barangay, 'streetAddress': _addressData.streetAddress, 'zipCode': _addressData.zipCode, 'isDefault': true, 'createdAt': now});
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Registration successful! Your account is pending admin approval.'),
          duration: Duration(seconds: 4),
        ));
      }
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registration failed: $error')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildField(TextEditingController controller, String label, {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(controller: controller, keyboardType: keyboardType, decoration: InputDecoration(labelText: label), validator: (v) => v == null || v.isEmpty ? 'Required' : null);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(title: const Text('Rider Registration')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: width > 1000 ? 980 : 700),
            child: Card(
              margin: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Rider Registration', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Sign up as a rider to manage deliveries and earnings.', style: TextStyle(fontSize: 16, color: Colors.black54)),
                  const SizedBox(height: 24),
                  Form(
                    key: _formKey,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Personal Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 16),
                      Wrap(spacing: 16, runSpacing: 16, children: [
                        SizedBox(width: width > 800 ? 320 : double.infinity, child: _buildField(_firstName, 'First Name')),
                        SizedBox(width: width > 800 ? 320 : double.infinity, child: _buildField(_lastName, 'Last Name')),
                      ]),
                      const SizedBox(height: 16),
                      Wrap(spacing: 16, runSpacing: 16, children: [
                        SizedBox(width: width > 800 ? 320 : double.infinity, child: _buildField(_username, 'Username')),
                        SizedBox(width: width > 800 ? 320 : double.infinity, child: _buildField(_email, 'Email Address', keyboardType: TextInputType.emailAddress)),
                      ]),
                      const SizedBox(height: 16),
                      Wrap(spacing: 16, runSpacing: 16, children: [
                        SizedBox(width: width > 800 ? 320 : double.infinity, child: _buildField(_phone, 'Phone Number', keyboardType: TextInputType.phone)),
                        SizedBox(width: width > 800 ? 320 : double.infinity, child: TextFormField(controller: _password, obscureText: _obscurePassword, decoration: InputDecoration(labelText: 'Password', suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20), onPressed: () => setState(() => _obscurePassword = !_obscurePassword))), validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null)),
                      ]),
                      const SizedBox(height: 16),
                      SizedBox(width: width > 800 ? 320 : double.infinity, child: TextFormField(controller: _confirmPassword, obscureText: _obscureConfirm, decoration: InputDecoration(labelText: 'Confirm Password', suffixIcon: IconButton(icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20), onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm))), validator: (v) => v == null || v.isEmpty ? 'Required' : null)),
                      const SizedBox(height: 24),
                      const Text('Address Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 16),
                      AddressDropdownFields(key: _addressKey, onChanged: (data) => _addressData = data),
                      const SizedBox(height: 24),
                      const Text('Required Document', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      const Text('Upload a clear image of your valid ID or driver\'s license for verification.', style: TextStyle(color: Colors.black54, fontSize: 13)),
                      const SizedBox(height: 16),
                      DocumentUploadField(label: 'Valid ID or Driver\'s License', hint: 'Upload your government-issued ID', icon: Icons.badge_outlined, onPicked: (bytes) => _validIdBytes = bytes),
                      const SizedBox(height: 24),
                      Row(children: [
                        Checkbox(value: _agree, onChanged: (v) => setState(() => _agree = v ?? false)),
                        const Expanded(child: Text('I agree to the Terms and Conditions and Privacy Policy.')),
                      ]),
                      const SizedBox(height: 18),
                      SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _isLoading ? null : _register, child: Text(_isLoading ? 'Registering rider...' : 'Register as Rider'))),
                      const SizedBox(height: 18),
                      TextButton(onPressed: () => Navigator.pushReplacementNamed(context, '/login'), child: const Text('Sign in here')),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
