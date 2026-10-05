import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/location_service.dart';
import '../services/nominatim_service.dart';
import '../services/api_service.dart';
import 'location_picker_screen.dart';

class SelectLocationScreen extends StatefulWidget {
  const SelectLocationScreen({super.key});

  @override
  State<SelectLocationScreen> createState() => _SelectLocationScreenState();
}

class _SelectLocationScreenState extends State<SelectLocationScreen> {
  static const _primaryGreen = Color(0xFF0C831F);

  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  bool _isSearching = false;
  List<PlaceSuggestion> _suggestions = [];

  bool _isLocating = false;
  String? _locateError;

  bool _loadingAddresses = true;
  List<Map<String, dynamic>> _savedAddresses = [];

  @override
  void initState() {
    super.initState();
    _loadSavedAddresses();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedAddresses() async {
    setState(() => _loadingAddresses = true);
    try {
      final backendAddresses = await ApiService.getAddresses();
      setState(() {
        _savedAddresses = backendAddresses
            .map<Map<String, dynamic>>((a) => Map<String, dynamic>.from(a))
            .toList();
      });
    } catch (_) {
      setState(() => _savedAddresses = []);
    } finally {
      if (mounted) setState(() => _loadingAddresses = false);
    }
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _isSearching = true);
      final results = await NominatimService.search(query);
      if (!mounted) return;
      setState(() {
        _suggestions = results;
        _isSearching = false;
      });
    });
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _isLocating = true;
      _locateError = null;
    });
    try {
      // Triggers the native location permission prompt if not yet granted.
      final result = await LocationService.getCurrentLocation();
      if (mounted) {
        Navigator.pop(context, {'address': result.displayAddress, 'lat': result.latitude, 'lng': result.longitude});
      }
    } catch (e) {
      setState(() {
        _locateError = e.toString().replaceFirst('Exception: ', '');
        _isLocating = false;
      });
    }
  }

  String _formatSavedAddress(Map<String, dynamic> a) {
    final parts = [
      a['line1'],
      a['city'],
      a['state'],
      a['pincode'],
    ].where((v) => v != null && v.toString().trim().isNotEmpty).map((v) => v.toString()).toList();
    return parts.isNotEmpty ? parts.join(', ') : 'Saved address';
  }

  IconData _iconForLabel(String? label) {
    switch (label) {
      case 'Home':
        return Icons.home_outlined;
      case 'Office':
      case 'Work':
        return Icons.work_outline;
      default:
        return Icons.location_on_outlined;
    }
  }

  void _openAddAddressSheet() {
    final buildingController = TextEditingController();
    final addressController = TextEditingController();
    final cityController = TextEditingController();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    String selectedType = 'Home';
    double? capturedLat;
    double? capturedLng;
    String? locationErrorModal;
    bool isSaving = false;
    String? formError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
                left: 20, right: 20, top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Add New Address',
                      style: GoogleFonts.poppins(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: ['Home', 'Office', 'Other'].map((type) {
                      final isSelected = selectedType == type;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedType = type),
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? _primaryGreen : Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(type,
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: isSelected ? Colors.white : Colors.grey,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(buildingController, 'Building & Block No. (Optional)',
                      Icons.home_outlined),
                  const SizedBox(height: 12),
                  _buildTextField(addressController, 'House No. & Floor',
                      Icons.apartment_outlined),
                  const SizedBox(height: 12),
                  _buildTextField(cityController, 'City, State, Pincode',
                      Icons.location_city_outlined),
                  const SizedBox(height: 12),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          final picked = await Navigator.push<PickedLocation>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LocationPickerScreen(
                                initialLat: capturedLat,
                                initialLng: capturedLng,
                              ),
                            ),
                          );
                          if (picked != null) {
                            setModalState(() {
                              capturedLat = picked.lat;
                              capturedLng = picked.lng;
                              if (picked.streetLine.isNotEmpty) {
                                addressController.text = picked.streetLine;
                              }
                              if (picked.cityLine.isNotEmpty) {
                                cityController.text = picked.cityLine;
                              }
                              locationErrorModal = null;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.map_outlined, size: 14, color: _primaryGreen),
                              const SizedBox(width: 6),
                              Text(
                                'Select on map',
                                style: GoogleFonts.poppins(fontSize: 12, color: _primaryGreen),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (capturedLat != null && capturedLng != null)
                        Text('Location captured',
                            style: GoogleFonts.poppins(fontSize: 11, color: Colors.green)),
                    ],
                  ),
                  if (locationErrorModal != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(locationErrorModal!,
                          style: GoogleFonts.poppins(fontSize: 11, color: Colors.red)),
                    ),
                  const SizedBox(height: 20),
                  Text('Receiver details',
                      style: GoogleFonts.poppins(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildTextField(nameController, "Receiver's Name", Icons.person_outline),
                  const SizedBox(height: 12),
                  _buildTextField(phoneController, "Receiver's Phone Number",
                      Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      maxLength: 10),
                  if (formError != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      margin: const EdgeInsets.only(top: 12),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(formError!,
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 13)),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              if (nameController.text.isEmpty ||
                                  addressController.text.isEmpty) {
                                setModalState(() => formError = 'Please fill all fields');
                                return;
                              }

                              if (!RegExp(r'^[6-9]\d{9}$').hasMatch(phoneController.text)) {
                                setModalState(() => formError = 'Enter a valid 10-digit phone number');
                                return;
                              }

                              setModalState(() { isSaving = true; formError = null; });

                              final phone10 = phoneController.text;

                              final line1 = [
                                buildingController.text,
                                addressController.text,
                              ].where((v) => v.trim().isNotEmpty).join(', ');

                              final cityRaw = cityController.text;
                              final parts = cityRaw.split(',');
                              final city = parts.isNotEmpty ? parts[0].trim() : cityRaw;
                              final state = parts.length > 1
                                  ? parts[1].replaceAll(RegExp(r'[0-9]'), '').trim()
                                  : '';
                              final pinMatch = RegExp(r'(\d{6})').firstMatch(cityRaw);
                              final pincode = pinMatch != null ? pinMatch.group(1)! : '000000';

                              try {
                                await ApiService.createAddress({
                                  'label': selectedType,
                                  'full_name': nameController.text,
                                  'phone': phone10,
                                  'line1': line1,
                                  'line2': '',
                                  'city': city.isEmpty ? 'NA' : city,
                                  'state': state.isEmpty ? 'NA' : state,
                                  'pincode': pincode,
                                  'lat': capturedLat,
                                  'lng': capturedLng,
                                  'is_default': _savedAddresses.isEmpty,
                                });

                                if (!mounted) return;
                                Navigator.pop(context); // close sheet
                                final formatted = [
                                  line1,
                                  city,
                                  state,
                                  pincode,
                                ].where((v) => v.trim().isNotEmpty).join(', ');
                                Navigator.pop(context, {'address': formatted, 'lat': capturedLat, 'lng': capturedLng}); // close screen with result
                              } catch (e) {
                                debugPrint('ADD_ADDRESS_ERROR: $e');
                                setModalState(() => isSaving = false);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text('Could not save address',
                                        style: GoogleFonts.poppins()),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                  ));
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: isSaving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : Text('Save Address',
                              style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  List<TextInputFormatter>? inputFormatters,
  int? maxLength,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      buildCounter: maxLength != null
          ? (context, {required currentLength, required isFocused, maxLength}) => null
          : null,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.grey, fontSize: 13),
        prefixIcon: Icon(icon, color: _primaryGreen, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primaryGreen, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: _primaryGreen, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.w600, color: _primaryGreen)),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        titleSpacing: 0,
        title: Text('Select Location',
            style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: GoogleFonts.poppins(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search Address',
                hintStyle: GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _primaryGreen, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          if (_suggestions.isNotEmpty)
            Container(
              color: Colors.white,
              child: Column(
                children: _suggestions.map((s) {
                  return ListTile(
                    leading: const Icon(Icons.location_on_outlined, color: _primaryGreen),
                    title: Text(s.displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(fontSize: 13)),
                    onTap: () => Navigator.pop(context, {'address': s.displayName, 'lat': s.lat, 'lng': s.lng}),
                  );
                }).toList(),
              ),
            ),

          const SizedBox(height: 8),

          Container(
            color: Colors.white,
            child: Column(
              children: [
                _buildActionTile(
                  icon: Icons.my_location,
                  label: _isLocating ? 'Locating...' : 'Use my Current Location',
                  onTap: _isLocating ? null : _useCurrentLocation,
                  trailing: _isLocating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: _primaryGreen),
                        )
                      : null,
                ),
                if (_locateError != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 54, right: 16, bottom: 12),
                    child: Text(_locateError!,
                        style: GoogleFonts.poppins(fontSize: 11, color: Colors.red)),
                  ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildActionTile(
                  icon: Icons.add,
                  label: 'Add New Address',
                  onTap: _openAddAddressSheet,
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text('Saved Addresses',
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
          ),

          Container(
            color: Colors.white,
            child: _loadingAddresses
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _savedAddresses.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text('No saved addresses yet',
                            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey)),
                      )
                    : Column(
                        children: _savedAddresses.asMap().entries.map((entry) {
                          final a = entry.value;
                          final isLast = entry.key == _savedAddresses.length - 1;
                          return Column(
                            children: [
                              ListTile(
                                leading: Icon(_iconForLabel(a['label']), color: Colors.black87),
                                title: Text(a['label'] ?? 'Address',
                                    style: GoogleFonts.poppins(
                                        fontSize: 14, fontWeight: FontWeight.bold)),
                                subtitle: Text(_formatSavedAddress(a),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700])),
                                onTap: () => Navigator.pop(context, {'address': _formatSavedAddress(a), 'lat': (a['lat'] as num?)?.toDouble(), 'lng': (a['lng'] as num?)?.toDouble()}),
                              ),
                              if (!isLast) const Divider(height: 1, indent: 16, endIndent: 16),
                            ],
                          );
                        }).toList(),
                      ),
          ),
        ],
      ),
    );
  }
}
