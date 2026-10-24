import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/validators/validators.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../providers/gift_card_provider.dart';
import '../../../../providers/wallet_provider.dart';

class RedeemGiftCardScreen extends StatefulWidget {
  const RedeemGiftCardScreen({super.key});

  @override
  State<RedeemGiftCardScreen> createState() => _RedeemGiftCardScreenState();
}

class _RedeemGiftCardScreenState extends State<RedeemGiftCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final gp = context.read<GiftCardProvider>();
    final wp = context.read<WalletProvider>();
    await gp.redeemCard(_codeController.text);
    if (gp.redeemStatus == RedeemStatus.success) wp.loadSummary(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GiftCardProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Redeem Gift Card')),
      body: switch (provider.redeemStatus) {
        RedeemStatus.success => _SuccessState(
            card: provider.lastRedeemedCard!,
            onDone: () {
              provider.resetRedeemState();
              Navigator.pop(context);
            },
          ),
        _ => _RedeemForm(
            formKey: _formKey,
            controller: _codeController,
            isSubmitting: provider.redeemStatus == RedeemStatus.submitting,
            errorMessage: provider.redeemStatus == RedeemStatus.error
                ? provider.redeemErrorMessage
                : null,
            onSubmit: _submit,
          ),
      },
    );
  }
}

class _RedeemForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  final bool isSubmitting;
  final String? errorMessage;
  final VoidCallback onSubmit;

  const _RedeemForm({
    required this.formKey,
    required this.controller,
    required this.isSubmitting,
    required this.errorMessage,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.card_giftcard_rounded,
                size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text('Have a gift card code?', style: theme.textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              'Enter the code printed on your gift card to add the balance to your account.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            CustomTextField(
              controller: controller,
              label: 'Gift Card Code',
              hint: 'e.g. VALID-1234-5678',
              autoValidate: true,
              validator: Validators.giftCardCode,
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.error_outline,
                      size: 18, color: theme.colorScheme.error),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      errorMessage!,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.error),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isSubmitting ? null : onSubmit,
              child: isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Redeem'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessState extends StatelessWidget {
  final dynamic card;
  final VoidCallback onDone;

  const _SuccessState({required this.card, required this.onDone});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded,
                size: 72, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text('Gift card redeemed!', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              '\u20B9${card.balance.toStringAsFixed(0)} has been added to your account from card ${card.cardNumber}.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onDone,
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}

