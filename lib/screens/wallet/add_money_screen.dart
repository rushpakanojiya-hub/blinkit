import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/wallet_provider.dart';

const Color kGreen = Color(0xFF0C831F);

class AddMoneyScreen extends StatefulWidget {
  const AddMoneyScreen({super.key});

  @override
  State<AddMoneyScreen> createState() => _AddMoneyScreenState();
}

class _AddMoneyScreenState extends State<AddMoneyScreen> {
  bool _autoAdd = false;
  int _amount = 2000;
  final _quickAmounts = const [2000, 5000, 10000];
  late final TextEditingController _amountController =
      TextEditingController(text: _amount.toString());
  bool _processing = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _selectQuickAmount(int amount) {
    setState(() {
      _amount = amount;
      _amountController.text = amount.toString();
    });
  }

  Future<void> _addMoney() async {
    if (_amount <= 0 || _processing) return;
    setState(() => _processing = true);
    try {
      await context.read<WalletProvider>().addMoney(_amount);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('₹$_amount added to your GoFresh Money wallet'),
          backgroundColor: kGreen,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _processing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add money: ${e.toString().replaceAll("Exception: ", "")}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        title: Text('Add money',
            style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _autoAdd = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _autoAdd ? kGreen : Colors.transparent,
                              borderRadius: BorderRadius.circular(26),
                            ),
                            child: Center(
                              child: Text('Auto add',
                                  style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _autoAdd ? Colors.white : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _autoAdd = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !_autoAdd ? kGreen : Colors.transparent,
                              borderRadius: BorderRadius.circular(26),
                            ),
                            child: Center(
                              child: Text('Add once',
                                  style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: !_autoAdd ? Colors.white : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Center(
                  child: Text('Enter amount to add',
                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600])),
                ),
                const SizedBox(height: 8),
                Center(
                  child: IntrinsicWidth(
                    child: TextField(
                      controller: _amountController,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.poppins(
                          fontSize: 36, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                      decoration: const InputDecoration(
                        prefixText: '\u20b9 ',
                        border: InputBorder.none,
                      ),
                      onChanged: (v) {
                        setState(() => _amount = int.tryParse(v) ?? 0);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: _quickAmounts.map((amount) {
                    final selected = amount == _amount;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          onTap: () => _selectQuickAmount(amount),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selected ? kGreen.withValues(alpha: 0.1) : Colors.white,
                              border: Border.all(color: selected ? kGreen : Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text('\u20b9${amount.toString().replaceAllMapped(
                                  RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}',
                                  style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: selected ? kGreen : Theme.of(context).colorScheme.onSurface)),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('NOTE',
                          style: GoogleFonts.poppins(
                              fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1, color: Colors.grey[600])),
                      const SizedBox(height: 10),
                      Text(
                          '\u2022 GoFresh Money balance is valid for 1 year from the date of money added',
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700], height: 1.5)),
                      const SizedBox(height: 6),
                      Text('\u2022 GoFresh Money is useable on GoFresh',
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700], height: 1.5)),
                      const SizedBox(height: 6),
                      Text(
                          '\u2022 GoFresh Money cannot be transferred to a bank account as per RBI guidelines.',
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700], height: 1.5)),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Icon(Icons.account_balance_wallet_outlined, size: 48, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Center(
                  child: Text('Enjoy seamless\nsingle tap payments',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[350])),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, -2))],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PAY USING',
                            style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text('Google Pay UPI',
                            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _processing ? null : _addMoney,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kGreen,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _processing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Row(
                            children: [
                              Text('\u20b9$_amount.00',
                                  style: GoogleFonts.poppins(
                                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(width: 8),
                              Text('Add money',
                                  style: GoogleFonts.poppins(
                                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_right, color: Colors.white, size: 18),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
