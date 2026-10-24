import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/validators/validators.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../domain/entities/address_entity.dart';
import '../providers/address_provider.dart';
import '../../../../services/location_service.dart';
import '../../../../services/nominatim_service.dart';

class AddEditAddressScreen extends StatefulWidget {
  final AddressEntity? existing;

  const AddEditAddressScreen({super.key, this.existing});

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _fullName;
  late final TextEditingController _mobile;
  late final TextEditingController _houseNumber;
  late final TextEditingController _areaStreet;
  late final TextEditingController _landmark;
  late final TextEditingController _city;
  late final TextEditingController _state;
  late final TextEditingController _pincode;

  bool get isEditing => widget.existing != null;
  double? _latitude;
  double? _longitude;
  bool _isFetchingLocation = false;

  Future<void> _useCurrentLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      final result = await LocationService.getCurrentLocation();
      if (!mounted) return;
      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location captured.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _fullName = TextEditingController(text: e?.fullName ?? '');
    _mobile = TextEditingController(text: e?.mobileNumber ?? '');
    _houseNumber = TextEditingController(text: e?.houseNumber ?? '');
    _areaStreet = TextEditingController(text: e?.areaStreet ?? '');
    _landmark = TextEditingController(text: e?.landmark ?? '');
    _city = TextEditingController(text: e?.city ?? '');
    _state = TextEditingController(text: e?.state ?? '');
    _pincode = TextEditingController(text: e?.pincode ?? '');
    _latitude = e?.latitude;
    _longitude = e?.longitude;
  }

  @override
  void dispose() {
    _fullName.dispose();
    _mobile.dispose();
    _houseNumber.dispose();
    _areaStreet.dispose();
    _landmark.dispose();
    _city.dispose();
    _state.dispose();
    _pincode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_latitude == null || _longitude == null) {
      final query = "${_houseNumber.text.trim()}, ${_areaStreet.text.trim()}, ${_city.text.trim()}, ${_state.text.trim()}, ${_pincode.text.trim()}";
      final results = await NominatimService.search(query);
      debugPrint('Geocode query: $query -> ${results.length} results');
      if (results.isNotEmpty) {
        _latitude = results.first.lat;
        _longitude = results.first.lng;
      }
    }

    if (!mounted) return;
    final provider = context.read<AddressProvider>();
    final entity = AddressEntity(
      id: widget.existing?.id ?? const Uuid().v4(),
      fullName: _fullName.text.trim(),
      mobileNumber: _mobile.text.trim(),
      houseNumber: _houseNumber.text.trim(),
      areaStreet: _areaStreet.text.trim(),
      landmark: _landmark.text.trim(),
      city: _city.text.trim(),
      state: _state.text.trim(),
      pincode: _pincode.text.trim(),
      isDefault: widget.existing?.isDefault ?? false,
      latitude: _latitude,
      longitude: _longitude,
    );

    final ok = isEditing
        ? await provider.updateAddress(entity)
        : await provider.addAddress(entity);

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save address. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = context.watch<AddressProvider>().isSaving;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Address' : 'Add Address')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            OutlinedButton.icon(
              onPressed: _isFetchingLocation ? null : _useCurrentLocation,
              icon: _isFetchingLocation
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
              label: Text(
                _latitude != null
                    ? 'Location captured'
                    : 'Use Current Location',
              ),
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: _fullName,
              label: 'Full Name',
              autoValidate: true,
              validator: (v) => Validators.required(v, field: 'Full name'),
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: _mobile,
              label: 'Mobile Number',
              keyboardType: TextInputType.phone,
              maxLength: 10,
              autoValidate: true,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              validator: Validators.mobileNumber,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: _houseNumber,
              label: 'House / Flat Number',
              autoValidate: true,
              validator: (v) => Validators.required(v, field: 'House/Flat number'),
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: _areaStreet,
              label: 'Area / Street',
              autoValidate: true,
              validator: (v) => Validators.required(v, field: 'Area/Street'),
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: _landmark,
              label: 'Landmark (optional)',
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: _city,
              label: 'City',
              autoValidate: true,
              validator: (v) => Validators.required(v, field: 'City'),
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: _state,
              label: 'State',
              autoValidate: true,
              validator: (v) => Validators.required(v, field: 'State'),
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: _pincode,
              label: 'Pincode',
              keyboardType: TextInputType.number,
              maxLength: 6,
              autoValidate: true,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              validator: Validators.pincode,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isSaving ? null : _submit,
              child: isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(isEditing ? 'Save Changes' : 'Save Address'),
            ),
          ],
        ),
      ),
    );
  }
}

