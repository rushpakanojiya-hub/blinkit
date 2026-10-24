import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/validators/validators.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../domain/entities/gst_entity.dart';
import '../providers/gst_provider.dart';

class AddEditGstScreen extends StatefulWidget {
  final GstEntity? existing;

  const AddEditGstScreen({super.key, this.existing});

  @override
  State<AddEditGstScreen> createState() => _AddEditGstScreenState();
}

class _AddEditGstScreenState extends State<AddEditGstScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _gstNumber;
  late final TextEditingController _businessName;
  late final TextEditingController _businessAddress;

  bool _isSubmitting = false;

  bool get isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _gstNumber = TextEditingController(text: e?.gstNumber ?? '');
    _businessName = TextEditingController(text: e?.businessName ?? '');
    _businessAddress = TextEditingController(text: e?.businessAddress ?? '');
  }

  @override
  void dispose() {
    _gstNumber.dispose();
    _businessName.dispose();
    _businessAddress.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Guard against a fast double-tap firing this twice before the
    // isSaving-driven rebuild has a chance to disable the button.
    if (_isSubmitting) return;
    _isSubmitting = true;

    if (!_formKey.currentState!.validate()) {
      _isSubmitting = false;
      return;
    }

    final provider = context.read<GstProvider>();
    final entity = GstEntity(
      id: widget.existing?.id ?? const Uuid().v4(),
      gstNumber: _gstNumber.text.trim().toUpperCase(),
      businessName: _businessName.text.trim(),
      businessAddress: _businessAddress.text.trim(),
    );

    final ok = isEditing
        ? await provider.updateGst(entity)
        : await provider.addGst(entity);

    _isSubmitting = false;
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Could not save GST details. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = context.watch<GstProvider>().isSaving;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit GST Details' : 'Add GST Details')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CustomTextField(
              controller: _gstNumber,
              label: 'GST Number',
              maxLength: 15,
              autoValidate: true,
              inputFormatters: [
                UpperCaseTextFormatter(),
                LengthLimitingTextInputFormatter(15),
              ],
              validator: Validators.gstNumber,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: _businessName,
              label: 'Business Name',
              autoValidate: true,
              validator: (v) => Validators.required(v, field: 'Business name'),
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: _businessAddress,
              label: 'Business Address',
              maxLines: 3,
              autoValidate: true,
              validator: (v) => Validators.required(v, field: 'Business address'),
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
                  : Text(isEditing ? 'Save Changes' : 'Save GST Details'),
            ),
          ],
        ),
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
