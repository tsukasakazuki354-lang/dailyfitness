import 'package:daily_fitness/data/ph_address_data.dart';
import 'package:flutter/material.dart';

/// Reusable cascading Philippine address dropdown fields.
/// Use this in any form that needs Region → Province → Municipality selection.
class AddressDropdownFields extends StatefulWidget {
  final String? initialRegion;
  final String? initialProvince;
  final String? initialMunicipality;
  final String? initialBarangay;
  final String? initialStreet;
  final String? initialZip;
  final ValueChanged<AddressData> onChanged;

  const AddressDropdownFields({
    super.key,
    this.initialRegion,
    this.initialProvince,
    this.initialMunicipality,
    this.initialBarangay,
    this.initialStreet,
    this.initialZip,
    required this.onChanged,
  });

  @override
  State<AddressDropdownFields> createState() => AddressDropdownFieldsState();
}

class AddressDropdownFieldsState extends State<AddressDropdownFields> {
  String? _selectedRegion;
  String? _selectedProvince;
  String? _selectedMunicipality;
  final _barangayController = TextEditingController();
  final _streetController = TextEditingController();
  final _zipController = TextEditingController();

  List<String> get _regions => phAddressData.keys.toList();
  List<String> get _provinces => _selectedRegion != null ? (phAddressData[_selectedRegion]?.keys.toList() ?? []) : [];
  List<String> get _municipalities => (_selectedRegion != null && _selectedProvince != null) ? (phAddressData[_selectedRegion]?[_selectedProvince] ?? []) : [];

  @override
  void initState() {
    super.initState();
    _selectedRegion = widget.initialRegion;
    _selectedProvince = widget.initialProvince;
    _selectedMunicipality = widget.initialMunicipality;
    _barangayController.text = widget.initialBarangay ?? '';
    _streetController.text = widget.initialStreet ?? '';
    _zipController.text = widget.initialZip ?? '';
  }

  @override
  void dispose() {
    _barangayController.dispose();
    _streetController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  void _notifyChange() {
    widget.onChanged(AddressData(
      region: _selectedRegion ?? '',
      provinceCity: _selectedProvince ?? '',
      municipality: _selectedMunicipality ?? '',
      barangay: _barangayController.text.trim(),
      streetAddress: _streetController.text.trim(),
      zipCode: _zipController.text.trim(),
    ));
  }

  /// Validate all fields and return true if valid
  bool validate() {
    if (_selectedRegion == null || _selectedProvince == null || _selectedMunicipality == null) return false;
    if (_barangayController.text.trim().isEmpty) return false;
    if (_streetController.text.trim().isEmpty) return false;
    if (_zipController.text.trim().isEmpty) return false;
    return true;
  }

  /// Get current address data
  AddressData get addressData => AddressData(
    region: _selectedRegion ?? '',
    provinceCity: _selectedProvince ?? '',
    municipality: _selectedMunicipality ?? '',
    barangay: _barangayController.text.trim(),
    streetAddress: _streetController.text.trim(),
    zipCode: _zipController.text.trim(),
  );

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final fieldWidth = width > 800 ? 320.0 : double.infinity;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Region & Province
        Wrap(spacing: 16, runSpacing: 16, children: [
          SizedBox(
            width: fieldWidth,
            child: DropdownButtonFormField<String>(
              value: (_selectedRegion != null && _regions.contains(_selectedRegion)) ? _selectedRegion : null,
              decoration: const InputDecoration(labelText: 'Region', prefixIcon: Icon(Icons.map_outlined, size: 20)),
              isExpanded: true,
              menuMaxHeight: 300,
              items: _regions.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (val) {
                setState(() { _selectedRegion = val; _selectedProvince = null; _selectedMunicipality = null; });
                _notifyChange();
              },
              validator: (v) => v == null ? 'Select a region' : null,
            ),
          ),
          SizedBox(
            width: fieldWidth,
            child: DropdownButtonFormField<String>(
              value: (_selectedProvince != null && _provinces.contains(_selectedProvince)) ? _selectedProvince : null,
              decoration: const InputDecoration(labelText: 'Province / City', prefixIcon: Icon(Icons.location_city_outlined, size: 20)),
              isExpanded: true,
              menuMaxHeight: 300,
              items: _provinces.map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: _selectedRegion != null ? (val) {
                setState(() { _selectedProvince = val; _selectedMunicipality = null; });
                _notifyChange();
              } : null,
              validator: (v) => v == null ? 'Select a province' : null,
              hint: Text(_selectedRegion == null ? 'Select region first' : 'Select province', style: const TextStyle(fontSize: 13, color: Colors.black38)),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        // Municipality & Barangay
        Wrap(spacing: 16, runSpacing: 16, children: [
          SizedBox(
            width: fieldWidth,
            child: DropdownButtonFormField<String>(
              value: (_selectedMunicipality != null && _municipalities.contains(_selectedMunicipality)) ? _selectedMunicipality : null,
              decoration: const InputDecoration(labelText: 'Municipality / City', prefixIcon: Icon(Icons.apartment_outlined, size: 20)),
              isExpanded: true,
              menuMaxHeight: 300,
              items: _municipalities.map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: _selectedProvince != null ? (val) {
                setState(() => _selectedMunicipality = val);
                _notifyChange();
              } : null,
              validator: (v) => v == null ? 'Select a municipality' : null,
              hint: Text(_selectedProvince == null ? 'Select province first' : 'Select municipality', style: const TextStyle(fontSize: 13, color: Colors.black38)),
            ),
          ),
          SizedBox(
            width: fieldWidth,
            child: TextFormField(
              controller: _barangayController,
              decoration: const InputDecoration(labelText: 'Barangay', prefixIcon: Icon(Icons.holiday_village_outlined, size: 20)),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              onChanged: (_) => _notifyChange(),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        // Street & Zip
        Wrap(spacing: 16, runSpacing: 16, children: [
          SizedBox(
            width: width > 800 ? 500 : double.infinity,
            child: TextFormField(
              controller: _streetController,
              decoration: const InputDecoration(labelText: 'Street Address / House No.', prefixIcon: Icon(Icons.home_outlined, size: 20)),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              onChanged: (_) => _notifyChange(),
            ),
          ),
          SizedBox(
            width: width > 800 ? 200 : double.infinity,
            child: TextFormField(
              controller: _zipController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Zip Code', prefixIcon: Icon(Icons.pin_outlined, size: 20)),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              onChanged: (_) => _notifyChange(),
            ),
          ),
        ]),
      ],
    );
  }
}

/// Data class holding address field values
class AddressData {
  final String region;
  final String provinceCity;
  final String municipality;
  final String barangay;
  final String streetAddress;
  final String zipCode;

  const AddressData({
    required this.region,
    required this.provinceCity,
    required this.municipality,
    required this.barangay,
    required this.streetAddress,
    required this.zipCode,
  });
}
