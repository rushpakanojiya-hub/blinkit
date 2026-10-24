import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class DeliveryRatingCard extends StatefulWidget {
  final String orderId;
  final bool autoPrompt;
  const DeliveryRatingCard({super.key, required this.orderId, this.autoPrompt = false});

  @override
  State<DeliveryRatingCard> createState() => _DeliveryRatingCardState();
}

class _DeliveryRatingCardState extends State<DeliveryRatingCard> {
  static final Set<String> _prompted = {};
  static const Color _green = Color(0xFF0C831F);

  bool _loaded = false;
  bool _rated = false;
  bool _canRate = false;
  int _rating = 0;
  String _review = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = int.tryParse(widget.orderId);
    if (id == null) return;
    try {
      final d = await ApiService.getDeliveryRating(id);
      if (!mounted) return;
      setState(() {
        _rated = d['rated'] == true;
        _canRate = d['can_rate'] == true;
        _rating = (d['rating'] as num?)?.toInt() ?? 0;
        _review = (d['review'] ?? '').toString();
        _loaded = true;
      });
      if (widget.autoPrompt && _canRate && !_rated && _prompted.add(widget.orderId)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _openSheet();
        });
      }
    } catch (_) {}
  }

  Future<void> _openSheet() async {
    final done = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _RatingSheet(orderId: int.tryParse(widget.orderId) ?? 0),
    );
    if (done == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || (!_rated && !_canRate)) return const SizedBox.shrink();

    if (_rated) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8E8E8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You rated your delivery partner',
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Row(
              children: List.generate(
                5,
                (i) => Icon(i < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber, size: 22),
              ),
            ),
            if (_review.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(_review, style: GoogleFonts.poppins(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
            ],
          ],
        ),
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: _openSheet,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8E8E8)),
        ),
        child: Row(
          children: [
            const Icon(Icons.star_outline, color: _green),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Rate delivery partner',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
            const Icon(Icons.chevron_right, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}

class _RatingSheet extends StatefulWidget {
  final int orderId;
  const _RatingSheet({required this.orderId});

  @override
  State<_RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends State<_RatingSheet> {
  int _stars = 0;
  bool _submitting = false;
  String? _error;
  final TextEditingController _review = TextEditingController();

  @override
  void dispose() {
    _review.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_stars == 0 || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ApiService.submitDeliveryRating(widget.orderId, _stars, _review.text.trim());
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rate your delivery partner',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (i) => IconButton(
                icon: Icon(i < _stars ? Icons.star : Icons.star_border,
                    color: Colors.amber, size: 38),
                onPressed: () => setState(() => _stars = i + 1),
              ),
            ),
          ),
          TextField(
            controller: _review,
            maxLength: 300,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Write a short review (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
            ),
          Row(
            children: [
              TextButton(
                onPressed: _submitting ? null : () => Navigator.pop(context, false),
                child: const Text('Skip'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: (_stars == 0 || _submitting) ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0C831F),
                    foregroundColor: Colors.white,
                  ),
                  child: _submitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Submit'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}