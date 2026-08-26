import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../models/order_model.dart';
import '../../services/api_service.dart';

const Color _kGreen = Color(0xFF0C831F);

/// Lets the customer pick which items (and quantities) from a delivered
/// order to return, give a reason, and submit the return request.
class RequestReturnScreen extends StatefulWidget {
  final Order order;
  const RequestReturnScreen({super.key, required this.order});

  @override
  State<RequestReturnScreen> createState() => _RequestReturnScreenState();
}

class _RequestReturnScreenState extends State<RequestReturnScreen> {
  final _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // orderItemId -> selected quantity (0 = not selected)
  final Map<int, int> _selectedQty = {};
  bool _submitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  int get _selectedItemCount => _selectedQty.values.where((q) => q > 0).length;

  Future<void> _submit() async {
    if (_selectedItemCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Select at least one item to return', style: GoogleFonts.poppins())),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final items = _selectedQty.entries
          .where((e) => e.value > 0)
          .map((e) => {'order_item_id': e.key, 'quantity': e.value})
          .toList();

      await ApiService.requestReturn(
        orderId: int.parse(widget.order.id),
        reason: _reasonController.text.trim(),
        items: items,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Return request submitted', style: GoogleFonts.poppins())),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''), style: GoogleFonts.poppins())),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final order = widget.order;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: scheme.onSurface),
        title: Text('Request Return',
            style: GoogleFonts.poppins(color: scheme.onSurface, fontWeight: FontWeight.bold)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Order #${order.id}',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: scheme.onSurface.withValues(alpha: 0.6))),
            const SizedBox(height: 16),
            Text('Select items to return',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: scheme.onSurface)),
            const SizedBox(height: 8),
            ...order.items.map((item) => _buildItemTile(item, scheme)),
            const SizedBox(height: 20),
            Text('Reason for return',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: scheme.onSurface)),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _reasonController,
              label: 'Reason',
              hint: 'e.g. Item was damaged / not as described',
              maxLines: 3,
              maxLength: 300,
              autoValidate: true,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please tell us why you want to return this' : null,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Submit Return Request',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildItemTile(OrderItem item, ColorScheme scheme) {
    final selectedQty = _selectedQty[item.id] ?? 0;
    final isSelected = selectedQty > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? _kGreen : Colors.transparent, width: 1.5),
      ),
      child: Row(
        children: [
          Checkbox(
            value: isSelected,
            activeColor: _kGreen,
            onChanged: (checked) {
              setState(() {
                _selectedQty[item.id] = (checked ?? false) ? 1 : 0;
              });
            },
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: scheme.onSurface)),
                Text('Qty ordered: ${item.quantity} Â· â‚¹${item.price} each',
                    style: GoogleFonts.poppins(fontSize: 11, color: scheme.onSurface.withValues(alpha: 0.6))),
              ],
            ),
          ),
          if (isSelected)
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                  color: _kGreen,
                  onPressed: selectedQty > 1
                      ? () => setState(() => _selectedQty[item.id] = selectedQty - 1)
                      : null,
                ),
                Text('$selectedQty', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  color: _kGreen,
                  onPressed: selectedQty < item.quantity
                      ? () => setState(() => _selectedQty[item.id] = selectedQty + 1)
                      : null,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

