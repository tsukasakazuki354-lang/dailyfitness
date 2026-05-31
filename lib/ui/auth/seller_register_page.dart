import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daily_fitness/models/app_user.dart';
import 'package:daily_fitness/services/auth_service.dart';
import 'package:daily_fitness/services/cloudinary_service.dart';
import 'package:daily_fitness/services/firestore_service.dart';
import 'package:daily_fitness/ui/shared/address_dropdown_fields.dart';
import 'package:daily_fitness/ui/shared/document_upload_field.dart';
import 'package:flutter/material.dart';

class SellerRegisterPage extends StatefulWidget {
  const SellerRegisterPage({super.key});

  @override
  State<SellerRegisterPage> createState() => _SellerRegisterPageState();
}

class _SellerRegisterPageState extends State<SellerRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _storeName = TextEditingController();
  String _businessType = 'Individual';
  final _addressKey = GlobalKey<AddressDropdownFieldsState>();
  AddressData _addressData = const AddressData(region: '', provinceCity: '', municipality: '', barangay: '', streetAddress: '', zipCode: '');
  final _region = TextEditingController();
  final _provinceCity = TextEditingController();
  final _municipality = TextEditingController();
  final _barangay = TextEditingController();
  final _streetAddress = TextEditingController();
  final _zipCode = TextEditingController();
  bool _agree = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  // Document uploads
  Uint8List? _validIdBytes;
  Uint8List? _businessPermitBytes;
  Uint8List? _taxRegistrationBytes;

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
    if (_validIdBytes == null || _businessPermitBytes == null || _taxRegistrationBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload all required documents')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final credential = await AuthService.signUpWithEmail(_email.text.trim(), _password.text.trim());
      final uid = credential.user?.uid ?? '';
      final now = Timestamp.now();

      // Upload documents to Cloudinary
      String validIdUrl = '';
      String permitUrl = '';
      String taxUrl = '';
      try {
        validIdUrl = await CloudinaryService.uploadImage(bytes: _validIdBytes!, folder: 'sellers/$uid', fileName: 'valid_id');
      } catch (_) {}
      try {
        permitUrl = await CloudinaryService.uploadImage(bytes: _businessPermitBytes!, folder: 'sellers/$uid', fileName: 'business_permit');
      } catch (_) {}
      try {
        taxUrl = await CloudinaryService.uploadImage(bytes: _taxRegistrationBytes!, folder: 'sellers/$uid', fileName: 'tax_registration');
      } catch (_) {}

      final user = AppUser(
        uid: uid,
        role: 'seller',
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        username: _username.text.trim(),
        email: _email.text.trim(),
        phoneNumber: _phone.text.trim(),
        profileImage: '',
        status: 'pending',
        createdAt: now,
        updatedAt: now,
      );
      await FirestoreService.createUserProfile(user);
      await FirestoreService.sellerProfiles().doc(uid).set({
        'sellerId': uid,
        'userId': uid,
        'storeName': _storeName.text.trim(),
        'businessType': _businessType,
        'businessPermitUrl': permitUrl,
        'taxRegistrationUrl': taxUrl,
        'validIdUrl': validIdUrl,
        'verificationStatus': 'pending',
        'commissionRate': 0.12,
        'createdAt': now,
        'updatedAt': now,
      });
      await FirestoreService.addresses().doc().set({
        'addressId': '${uid}_${DateTime.now().millisecondsSinceEpoch}',
        'userId': uid,
        'region': _addressData.region,
        'provinceCity': _addressData.provinceCity,
        'municipality': _addressData.municipality,
        'barangay': _addressData.barangay,
        'streetAddress': _addressData.streetAddress,
        'zipCode': _addressData.zipCode,
        'isDefault': true,
        'createdAt': now,
      });
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

  Widget _buildField(TextEditingController controller, String label, {TextInputType keyboardType = TextInputType.text, bool obscure = false}) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label),
      validator: (value) => value == null || value.isEmpty ? 'Required field' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(title: const Text('Seller Registration')),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Seller Registration', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Submit your seller profile for verification and start listing products.', style: TextStyle(fontSize: 16, color: Colors.black54)),
                    const SizedBox(height: 24),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                            SizedBox(
                              width: width > 800 ? 320 : double.infinity,
                              child: TextFormField(
                                controller: _password,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                                validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null,
                              ),
                            ),
                          ]),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: width > 800 ? 320 : double.infinity,
                            child: TextFormField(
                              controller: _confirmPassword,
                              obscureText: _obscureConfirm,
                              decoration: InputDecoration(
                                labelText: 'Confirm Password',
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                ),
                              ),
                              validator: (v) => v == null || v.isEmpty ? 'Required field' : null,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text('Business Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 16),
                          _buildField(_storeName, 'Store Name'),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _businessType,
                            decoration: const InputDecoration(labelText: 'Business Type'),
                            items: const [
                              DropdownMenuItem(value: 'Individual', child: Text('Individual')),
                              DropdownMenuItem(value: 'Corporation', child: Text('Corporation')),
                              DropdownMenuItem(value: 'Partnership', child: Text('Partnership')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _businessType = value);
                              }
                            },
                          ),
                          const SizedBox(height: 24),
                          const Text('Address Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 16),
                          AddressDropdownFields(
                            key: _addressKey,
                            onChanged: (data) => _addressData = data,
                          ),
                          const SizedBox(height: 24),
                          const Text('Required Documents', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          const Text('Upload clear images of the following documents for verification.', style: TextStyle(color: Colors.black54, fontSize: 13)),
                          const SizedBox(height: 16),
                          DocumentUploadField(
                            label: 'Valid ID',
                            hint: 'Upload a government-issued ID',
                            icon: Icons.badge_outlined,
                            onPicked: (bytes) => _validIdBytes = bytes,
                          ),
                          const SizedBox(height: 16),
                          DocumentUploadField(
                            label: 'Business Permit',
                            hint: 'Upload your business permit',
                            icon: Icons.business_outlined,
                            onPicked: (bytes) => _businessPermitBytes = bytes,
                          ),
                          const SizedBox(height: 16),
                          DocumentUploadField(
                            label: 'Tax Registration / DTI',
                            hint: 'Upload DTI or BIR registration',
                            icon: Icons.description_outlined,
                            onPicked: (bytes) => _taxRegistrationBytes = bytes,
                          ),
                          const SizedBox(height: 24),
                          Row(children: [
                            Checkbox(value: _agree, onChanged: (value) => setState(() => _agree = value ?? false)),
                            const Expanded(child: Text('I agree to the Terms and Conditions and Privacy Policy.')),
                          ]),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _register,
                              child: Text(_isLoading ? 'Registering seller...' : 'Register as Seller'),
                            ),
                          ),
                          const SizedBox(height: 18),
                          TextButton(onPressed: () => Navigator.pushReplacementNamed(context, '/login'), child: const Text('Sign in here')),
                        ],
                      ),
                    )
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
