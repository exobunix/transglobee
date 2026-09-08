import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../providers/wallet_provider.dart';

class BankAccountsScreen extends ConsumerWidget {
  const BankAccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text('Bank Accounts', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.darkTextPrimary,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: wallet.bankAccounts.length + 1,
        itemBuilder: (context, index) {
          if (index == wallet.bankAccounts.length) {
            return _buildAddAccountButton(context);
          }
          final account = wallet.bankAccounts[index];
          return _buildAccountTile(context, ref, account);
        },
      ),
    );
  }

  Widget _buildAccountTile(BuildContext context, WidgetRef ref, BankAccount account) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: account.isPrimary ? AppTheme.earningsAmber.withValues(alpha: 0.3) : Colors.transparent,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.earningsAmber.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_balance, color: AppTheme.earningsAmber, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(account.bankName, style: const TextStyle(color: AppTheme.darkTextPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('•••• ${account.accountNumber.substring(account.accountNumber.length - 4)}', style: const TextStyle(color: AppTheme.darkTextSecondary, fontSize: 14)),
                  ],
                ),
              ),
              if (account.isPrimary)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.earningsAmber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Primary', style: TextStyle(color: AppTheme.earningsAmber, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!account.isPrimary)
                TextButton(
                  onPressed: () => ref.read(walletProvider.notifier).setPrimaryAccount(account.id),
                  child: const Text('Set as Primary', style: TextStyle(color: AppTheme.neonGreen)),
                ),
              TextButton(
                onPressed: () => _showDeleteConfirmation(context, ref, account),
                child: const Text('Remove', style: TextStyle(color: AppTheme.offlineRed)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddAccountButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: OutlinedButton.icon(
        onPressed: () => _showAddAccountSheet(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.earningsAmber,
          side: const BorderSide(color: AppTheme.earningsAmber),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('Add Bank Account', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, BankAccount account) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: const Text('Remove Bank Account?', style: TextStyle(color: AppTheme.darkTextPrimary)),
        content: Text('Are you sure you want to remove ${account.bankName} account ending in ${account.accountNumber.substring(account.accountNumber.length - 4)}?', style: const TextStyle(color: AppTheme.darkTextSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(walletProvider.notifier).removeBankAccount(account.id);
              Navigator.pop(context);
            },
            child: const Text('Remove', style: TextStyle(color: AppTheme.offlineRed)),
          ),
        ],
      ),
    );
  }

  void _showAddAccountSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _AddAccountSheet(),
    );
  }
}

class _AddAccountSheet extends ConsumerStatefulWidget {
  const _AddAccountSheet();
  @override
  ConsumerState<_AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends ConsumerState<_AddAccountSheet> {
  final _formKey = GlobalKey<FormState>();
  final _bankNameController = TextEditingController();
  final _holderController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _ifscController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Bank Account', style: TextStyle(color: AppTheme.darkTextPrimary, fontWeight: FontWeight.w700, fontSize: 20)),
            const SizedBox(height: 24),
            _buildTextField('Bank Name', _bankNameController, 'e.g. HDFC Bank'),
            const SizedBox(height: 16),
            _buildTextField('Account Holder Name', _holderController, 'e.g. John Doe'),
            const SizedBox(height: 16),
            _buildTextField('Account Number', _accountNumberController, 'Enter account number', keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            _buildTextField('IFSC Code', _ifscController, 'e.g. HDFC0001234', textCapitalization: TextCapitalization.characters),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.earningsAmber,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Save Account', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint, {TextInputType? keyboardType, TextCapitalization textCapitalization = TextCapitalization.none}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.darkTextSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          style: const TextStyle(color: AppTheme.darkTextPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppTheme.darkTextSecondary.withValues(alpha: 0.5)),
            filled: true,
            fillColor: AppTheme.darkCard,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
        ),
      ],
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final account = BankAccount(
        id: 'B${DateTime.now().millisecondsSinceEpoch}',
        bankName: _bankNameController.text,
        accountHolder: _holderController.text,
        accountNumber: _accountNumberController.text,
        ifsc: _ifscController.text,
      );
      ref.read(walletProvider.notifier).addBankAccount(account);
      Navigator.pop(context);
    }
  }
}
