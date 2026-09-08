import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../providers/wallet_provider.dart';
import '../../features/driver/controllers/driver_providers.dart';
import '../../core/network/api_state.dart';
import 'bank_accounts_screen.dart';

class PayoutScreen extends ConsumerStatefulWidget {
  const PayoutScreen({super.key});

  @override
  ConsumerState<PayoutScreen> createState() => _PayoutScreenState();
}

class _PayoutScreenState extends ConsumerState<PayoutScreen> {
  final _amountController = TextEditingController();
  BankAccount? _selectedAccount;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Bridging: Using legacy provider for bank accounts for now
      final accounts = ref.read(walletProvider).bankAccounts;
      if (accounts.isNotEmpty) {
        setState(() {
          _selectedAccount = accounts.where((b) => b.isPrimary).firstOrNull ?? 
                             (accounts.isNotEmpty ? accounts.first : null);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(walletControllerProvider);
    final wallet = walletState.data;
    final legacyWallet = ref.watch(walletProvider); // Bridging for bank accounts

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text('Request Payout', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.darkTextPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.earningsAmber.withValues(alpha: 0.15), AppTheme.darkCard],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.earningsAmber.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  const Text('Available for Payout', style: TextStyle(color: AppTheme.darkTextSecondary, fontSize: 13)),
                  const SizedBox(height: 8),
                  Text('₹${wallet?.balance.toStringAsFixed(2) ?? '0.00'}', style: const TextStyle(color: AppTheme.darkTextPrimary, fontSize: 32, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Amount Input
            const Text('Payout Amount', style: TextStyle(color: AppTheme.darkTextPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppTheme.earningsAmber, fontSize: 28, fontWeight: FontWeight.w900),
              decoration: InputDecoration(
                prefixText: '₹ ',
                prefixStyle: const TextStyle(color: AppTheme.earningsAmber, fontSize: 28, fontWeight: FontWeight.w900),
                hintText: '0.00',
                hintStyle: TextStyle(color: AppTheme.earningsAmber.withValues(alpha: 0.2)),
                enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.darkDivider)),
                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.earningsAmber, width: 2)),
              ),
              onChanged: (val) {
                final amt = double.tryParse(val) ?? 0;
                final balance = wallet?.balance ?? 0;
                setState(() {
                  _error = amt > balance ? 'Amount exceeds available balance' : null;
                });
              },
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: const TextStyle(color: AppTheme.offlineRed, fontSize: 12)),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              children: [500.0, 1000.0, 2000.0, wallet?.balance ?? 0.0].map((a) =>
                ActionChip(
                  label: Text('₹${a.toStringAsFixed(0)}'),
                  onPressed: () {
                    _amountController.text = a.toStringAsFixed(0);
                    setState(() { _error = null; });
                  },
                  backgroundColor: AppTheme.darkCard,
                  labelStyle: const TextStyle(color: AppTheme.earningsAmber, fontWeight: FontWeight.w700),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: AppTheme.earningsAmber.withValues(alpha: 0.2))),
                )
              ).toList(),
            ),
            
            const SizedBox(height: 40),
            
            // Bank Selection
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Deposit to', style: TextStyle(color: AppTheme.darkTextPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BankAccountsScreen())),
                  child: const Text('Manage Banks', style: TextStyle(color: AppTheme.neonGreen, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...legacyWallet.bankAccounts.map((account) => 
              GestureDetector(
                onTap: () => setState(() => _selectedAccount = account),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.darkCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedAccount?.id == account.id ? AppTheme.earningsAmber : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.account_balance, color: _selectedAccount?.id == account.id ? AppTheme.earningsAmber : AppTheme.darkTextSecondary, size: 24),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(account.bankName, style: const TextStyle(color: AppTheme.darkTextPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                            Text('•••• ${account.accountNumber.substring(account.accountNumber.length - 4)}', style: const TextStyle(color: AppTheme.darkTextSecondary, fontSize: 12)),
                          ],
                        ),
                      ),
                      if (_selectedAccount?.id == account.id)
                        const Icon(Icons.check_circle, color: AppTheme.earningsAmber, size: 20),
                    ],
                  ),
                ),
              )
            ),
            
            const SizedBox(height: 40),
            
            // Confirm Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canSubmit() ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.earningsAmber,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                  disabledBackgroundColor: AppTheme.darkCard,
                ),
                child: const Text('Request Withdrawal', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5)),
              ),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'Funds usually arrive within 24-48 hours',
                style: TextStyle(color: AppTheme.darkTextSecondary, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canSubmit() {
    final amt = double.tryParse(_amountController.text) ?? 0;
    final balance = ref.read(walletControllerProvider).data?.balance ?? 0;
    return amt > 0 && amt <= balance && _selectedAccount != null && _error == null;
  }

  void _submit() async {
    final amt = double.parse(_amountController.text);
    final payoutNotifier = ref.read(payoutControllerProvider.notifier);
    
    await payoutNotifier.requestPayout(amt, 'bank_transfer'); // Using primary account logic
    
    if (mounted) {
      final state = ref.read(payoutControllerProvider);
      if (state.status == ApiStatus.success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Withdrawal request of ₹${amt.toStringAsFixed(0)} submitted!'),
            backgroundColor: AppTheme.neonGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else if (state.status == ApiStatus.error) {
        setState(() => _error = state.message);
      }
    }
  }
}
