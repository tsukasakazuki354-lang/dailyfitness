import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daily_fitness/providers/session_provider.dart';
import 'package:daily_fitness/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstName;
  late TextEditingController _lastName;
  late TextEditingController _username;
  late TextEditingController _phone;
  bool _saving = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<SessionProvider>(context, listen: false).currentUser;
    _firstName = TextEditingController(text: user?.firstName ?? '');
    _lastName = TextEditingController(text: user?.lastName ?? '');
    _username = TextEditingController(text: user?.username ?? '');
    _phone = TextEditingController(text: user?.phoneNumber ?? '');
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _username.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = Provider.of<SessionProvider>(context, listen: false).currentUser?.uid;
    if (uid == null) return;
    setState(() => _saving = true);
    try {
      await FirestoreService.users().doc(uid).update({
        'firstName': _firstName.text.trim(),
        'lastName': _lastName.text.trim(),
        'username': _username.text.trim(),
        'phoneNumber': _phone.text.trim(),
        'updatedAt': Timestamp.now(),
      });
      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<SessionProvider>(context).currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Profile')),
        body: const Center(child: Text('Please sign in to view your profile')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          if (!_isEditing)
            IconButton(icon: const Icon(Icons.edit), onPressed: () => setState(() => _isEditing = true))
          else
            IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _isEditing = false)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: const Color(0xFFE5F2FF),
                backgroundImage: user.profileImage.isNotEmpty ? NetworkImage(user.profileImage) : null,
                child: user.profileImage.isEmpty ? Text(user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : '?', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)) : null,
              ),
              const SizedBox(height: 12),
              Text('${user.firstName} ${user.lastName}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text(user.email, style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFE5F2FF), borderRadius: BorderRadius.circular(8)),
                child: Text(user.role.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F2850))),
              ),
              const SizedBox(height: 32),
              if (_isEditing) ...[
                TextFormField(controller: _firstName, decoration: const InputDecoration(labelText: 'First Name'), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
                const SizedBox(height: 16),
                TextFormField(controller: _lastName, decoration: const InputDecoration(labelText: 'Last Name')),
                const SizedBox(height: 16),
                TextFormField(controller: _username, decoration: const InputDecoration(labelText: 'Username'), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
                const SizedBox(height: 16),
                TextFormField(controller: _phone, decoration: const InputDecoration(labelText: 'Phone Number'), keyboardType: TextInputType.phone),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _saveProfile,
                    child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save Changes'),
                  ),
                ),
              ] else ...[
                _profileField('First Name', user.firstName),
                _profileField('Last Name', user.lastName),
                _profileField('Username', user.username),
                _profileField('Email', user.email),
                _profileField('Phone', user.phoneNumber.isNotEmpty ? user.phoneNumber : 'Not set'),
                _profileField('Status', user.status),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}
