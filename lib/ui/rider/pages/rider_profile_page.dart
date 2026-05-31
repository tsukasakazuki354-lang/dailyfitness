import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daily_fitness/providers/session_provider.dart';
import 'package:daily_fitness/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RiderProfilePage extends StatefulWidget {
  const RiderProfilePage({super.key});

  @override
  State<RiderProfilePage> createState() => _RiderProfilePageState();
}

class _RiderProfilePageState extends State<RiderProfilePage> {
  bool _isEditing = false;
  bool _saving = false;
  late TextEditingController _firstName, _lastName, _phone, _username;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<SessionProvider>(context, listen: false).currentUser;
    _firstName = TextEditingController(text: user?.firstName ?? '');
    _lastName = TextEditingController(text: user?.lastName ?? '');
    _phone = TextEditingController(text: user?.phoneNumber ?? '');
    _username = TextEditingController(text: user?.username ?? '');
  }

  @override
  void dispose() { _firstName.dispose(); _lastName.dispose(); _phone.dispose(); _username.dispose(); super.dispose(); }

  Future<void> _save() async {
    final uid = Provider.of<SessionProvider>(context, listen: false).currentUser?.uid;
    if (uid == null) return;
    setState(() => _saving = true);
    try {
      await FirestoreService.users().doc(uid).update({'firstName': _firstName.text.trim(), 'lastName': _lastName.text.trim(), 'phoneNumber': _phone.text.trim(), 'username': _username.text.trim(), 'updatedAt': Timestamp.now()});
      if (mounted) { setState(() => _isEditing = false); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated'))); }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
    finally { if (mounted) setState(() => _saving = false); }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<SessionProvider>(context).currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile'), automaticallyImplyLeading: false, actions: [
        IconButton(icon: Icon(_isEditing ? Icons.close : Icons.edit), onPressed: () => setState(() => _isEditing = !_isEditing)),
      ]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          CircleAvatar(radius: 44, backgroundColor: const Color(0xFFE8F1FF), child: Text(user?.firstName.isNotEmpty == true ? user!.firstName[0].toUpperCase() : 'R', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF0F2850)))),
          const SizedBox(height: 12),
          Text('${user?.firstName ?? ''} ${user?.lastName ?? ''}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(user?.email ?? '', style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 8),
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFE8F1FF), borderRadius: BorderRadius.circular(8)), child: const Text('RIDER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F2850)))),
          const SizedBox(height: 28),
          if (_isEditing) ...[
            TextFormField(controller: _firstName, decoration: const InputDecoration(labelText: 'First Name')),
            const SizedBox(height: 14),
            TextFormField(controller: _lastName, decoration: const InputDecoration(labelText: 'Last Name')),
            const SizedBox(height: 14),
            TextFormField(controller: _username, decoration: const InputDecoration(labelText: 'Username')),
            const SizedBox(height: 14),
            TextFormField(controller: _phone, decoration: const InputDecoration(labelText: 'Phone'), keyboardType: TextInputType.phone),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _saving ? null : _save, child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save Changes'))),
          ] else ...[
            _infoRow('First Name', user?.firstName ?? ''),
            _infoRow('Last Name', user?.lastName ?? ''),
            _infoRow('Username', user?.username ?? ''),
            _infoRow('Email', user?.email ?? ''),
            _infoRow('Phone', user?.phoneNumber ?? 'Not set'),
            _infoRow('Status', user?.status ?? ''),
          ],
        ]),
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(children: [SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600))), Expanded(child: Text(value, style: const TextStyle(fontSize: 15)))]),
  );
}
