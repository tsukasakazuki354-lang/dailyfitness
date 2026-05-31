import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daily_fitness/data/ph_address_data.dart';
import 'package:daily_fitness/models/address.dart';
import 'package:daily_fitness/providers/session_provider.dart';
import 'package:daily_fitness/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SavedAddressesPage extends StatelessWidget {
  const SavedAddressesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = Provider.of<SessionProvider>(context).currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Saved Addresses')),
        body: const Center(child: Text('Please sign in to manage addresses')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Addresses')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddressDialog(context, uid, null),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreService.addresses().where('userId', isEqualTo: uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final addresses = (snapshot.data?.docs ?? []).map((doc) => Address.fromMap(doc.data() as Map<String, dynamic>)).toList();
          if (addresses.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_off_outlined, size: 64, color: Colors.black26),
                  SizedBox(height: 16),
                  Text('No saved addresses', style: TextStyle(fontSize: 16, color: Colors.black54)),
                  SizedBox(height: 8),
                  Text('Tap + to add your first address', style: TextStyle(color: Colors.black38)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: addresses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final address = addresses[index];
              return _AddressCard(
                address: address,
                userId: uid,
                onEdit: () => _showAddressDialog(context, uid, address),
                onDelete: () => _deleteAddress(context, address),
                onSetDefault: () => _setDefault(uid, address, addresses),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _deleteAddress(BuildContext context, Address address) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Address'),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      final query = await FirestoreService.addresses().where('addressId', isEqualTo: address.addressId).get();
      for (final doc in query.docs) {
        await doc.reference.delete();
      }
    }
  }

  Future<void> _setDefault(String uid, Address address, List<Address> allAddresses) async {
    final batch = FirebaseFirestore.instance.batch();
    for (final addr in allAddresses) {
      final query = await FirestoreService.addresses().where('addressId', isEqualTo: addr.addressId).get();
      for (final doc in query.docs) {
        batch.update(doc.reference, {'isDefault': addr.addressId == address.addressId});
      }
    }
    await batch.commit();
  }

  void _showAddressDialog(BuildContext context, String uid, Address? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => _AddressForm(
            userId: uid,
            existing: existing,
            scrollController: scrollController,
          ),
        ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final Address address;
  final String userId;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;

  const _AddressCard({required this.address, required this.userId, required this.onEdit, required this.onDelete, required this.onSetDefault});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, size: 20, color: Color(0xFF4AB3F4)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(address.streetAddress, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                if (address.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(6)),
                    child: const Text('Default', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${address.barangay}, ${address.municipality}', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                  Text('${address.provinceCity}, ${address.region} ${address.zipCode}', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (!address.isDefault)
                  TextButton.icon(
                    onPressed: onSetDefault,
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('Set Default', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                  ),
                const Spacer(),
                IconButton(icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF0F2850)), onPressed: onEdit),
                IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red), onPressed: onDelete),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Address Form with Cascading Dropdowns ───────────────────────────────────

class _AddressForm extends StatefulWidget {
  final String userId;
  final Address? existing;
  final ScrollController scrollController;
  const _AddressForm({required this.userId, this.existing, required this.scrollController});

  @override
  State<_AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<_AddressForm> {
  final _formKey = GlobalKey<FormState>();
  final _streetController = TextEditingController();
  final _barangayController = TextEditingController();
  final _zipController = TextEditingController();

  String? _selectedRegion;
  String? _selectedProvince;
  String? _selectedMunicipality;
  bool _isDefault = false;
  bool _saving = false;

  List<String> get _regions => phAddressData.keys.toList();

  List<String> get _provinces {
    if (_selectedRegion == null) return [];
    return phAddressData[_selectedRegion]?.keys.toList() ?? [];
  }

  List<String> get _municipalities {
    if (_selectedRegion == null || _selectedProvince == null) return [];
    return phAddressData[_selectedRegion]?[_selectedProvince] ?? [];
  }

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _selectedRegion = widget.existing!.region.isNotEmpty ? widget.existing!.region : null;
      _selectedProvince = widget.existing!.provinceCity.isNotEmpty ? widget.existing!.provinceCity : null;
      _selectedMunicipality = widget.existing!.municipality.isNotEmpty ? widget.existing!.municipality : null;
      _barangayController.text = widget.existing!.barangay;
      _streetController.text = widget.existing!.streetAddress;
      _zipController.text = widget.existing!.zipCode;
      _isDefault = widget.existing!.isDefault;
    }
  }

  @override
  void dispose() {
    _streetController.dispose();
    _barangayController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final data = {
        'region': _selectedRegion ?? '',
        'provinceCity': _selectedProvince ?? '',
        'municipality': _selectedMunicipality ?? '',
        'barangay': _barangayController.text.trim(),
        'streetAddress': _streetController.text.trim(),
        'zipCode': _zipController.text.trim(),
        'isDefault': _isDefault,
      };

      if (widget.existing != null) {
        final query = await FirestoreService.addresses().where('addressId', isEqualTo: widget.existing!.addressId).get();
        for (final doc in query.docs) {
          await doc.reference.update(data);
        }
      } else {
        final addressId = '${widget.userId}_${DateTime.now().millisecondsSinceEpoch}';
        await FirestoreService.addresses().doc().set({
          ...data,
          'addressId': addressId,
          'userId': widget.userId,
          'createdAt': Timestamp.now(),
        });
      }
      if (mounted) Navigator.pop(context);
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Form(
        key: _formKey,
        child: ListView(
          controller: widget.scrollController,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text(
              widget.existing != null ? 'Edit Address' : 'Add New Address',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F2850)),
            ),
            const SizedBox(height: 6),
            const Text('Fill in your delivery address details', style: TextStyle(color: Colors.black54, fontSize: 13)),
            const SizedBox(height: 24),

            // Region dropdown
            _buildDropdown(
              label: 'Region',
              icon: Icons.map_outlined,
              value: _selectedRegion,
              items: _regions,
              onChanged: (val) {
                setState(() {
                  _selectedRegion = val;
                  _selectedProvince = null;
                  _selectedMunicipality = null;
                });
              },
              validator: (v) => v == null ? 'Select a region' : null,
            ),
            const SizedBox(height: 14),

            // Province/City dropdown
            _buildDropdown(
              label: 'Province / City',
              icon: Icons.location_city_outlined,
              value: _selectedProvince,
              items: _provinces,
              onChanged: (val) {
                setState(() {
                  _selectedProvince = val;
                  _selectedMunicipality = null;
                });
              },
              validator: (v) => v == null ? 'Select a province/city' : null,
              enabled: _selectedRegion != null,
            ),
            const SizedBox(height: 14),

            // Municipality dropdown
            _buildDropdown(
              label: 'Municipality / City',
              icon: Icons.apartment_outlined,
              value: _selectedMunicipality,
              items: _municipalities,
              onChanged: (val) => setState(() => _selectedMunicipality = val),
              validator: (v) => v == null ? 'Select a municipality' : null,
              enabled: _selectedProvince != null,
            ),
            const SizedBox(height: 14),

            // Barangay text field
            TextFormField(
              controller: _barangayController,
              decoration: const InputDecoration(
                labelText: 'Barangay',
                prefixIcon: Icon(Icons.holiday_village_outlined, size: 20),
                hintText: 'e.g. Brgy. San Antonio',
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 14),

            // Street address
            TextFormField(
              controller: _streetController,
              decoration: const InputDecoration(
                labelText: 'Street Address / House No.',
                prefixIcon: Icon(Icons.home_outlined, size: 20),
                hintText: 'e.g. 123 Rizal St.',
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 14),

            // Zip code
            TextFormField(
              controller: _zipController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Zip Code',
                prefixIcon: Icon(Icons.pin_outlined, size: 20),
                hintText: 'e.g. 1200',
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 14),

            // Default checkbox
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FBFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8F0FE)),
              ),
              child: CheckboxListTile(
                value: _isDefault,
                onChanged: (v) => setState(() => _isDefault = v ?? false),
                title: const Text('Set as default address', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                subtitle: const Text('Used automatically at checkout', style: TextStyle(fontSize: 12, color: Colors.black45)),
                controlAffinity: ListTileControlAffinity.leading,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_outlined, size: 20),
                label: Text(widget.existing != null ? 'Update Address' : 'Save Address'),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    // If the current value isn't in the items list, reset it
    final effectiveValue = (value != null && items.contains(value)) ? value : null;

    return DropdownButtonFormField<String>(
      value: effectiveValue,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        enabled: enabled,
      ),
      isExpanded: true,
      menuMaxHeight: 300,
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item, style: const TextStyle(fontSize: 14)))).toList(),
      onChanged: enabled ? onChanged : null,
      validator: validator,
      hint: Text(enabled ? 'Select $label' : 'Select previous field first', style: const TextStyle(fontSize: 13, color: Colors.black38)),
    );
  }
}
