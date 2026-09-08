import 'package:flutter_riverpod/flutter_riverpod.dart';

class Transaction {
  final String id;
  final String description;
  final double amount;
  final bool isCredit;
  final String type; // ride, payout, bonus, commission
  final DateTime time;
  final String? bankAccountId;

  const Transaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.isCredit,
    required this.type,
    required this.time,
    this.bankAccountId,
  });
}

class BankAccount {
  final String id;
  final String bankName;
  final String accountHolder;
  final String accountNumber;
  final String ifsc;
  final bool isPrimary;

  const BankAccount({
    required this.id,
    required this.bankName,
    required this.accountHolder,
    required this.accountNumber,
    required this.ifsc,
    this.isPrimary = false,
  });

  BankAccount copyWith({bool? isPrimary}) {
    return BankAccount(
      id: id,
      bankName: bankName,
      accountHolder: accountHolder,
      accountNumber: accountNumber,
      ifsc: ifsc,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }
}

class WalletState {
  final double balance;
  final double totalEarned;
  final double totalPaidOut;
  final double todayEarnings;
  final double weekEarnings;
  final double monthEarnings;
  final List<Transaction> transactions;
  final List<BankAccount> bankAccounts;

  const WalletState({
    required this.balance,
    required this.totalEarned,
    required this.totalPaidOut,
    required this.todayEarnings,
    required this.weekEarnings,
    required this.monthEarnings,
    required this.transactions,
    required this.bankAccounts,
  });
}

class WalletNotifier extends Notifier<WalletState> {
  @override
  WalletState build() {
    final transactions = [
      Transaction(id: 'T1', description: 'Ride - Priya Sharma', amount: 180, isCredit: true, type: 'ride', time: DateTime.now().subtract(const Duration(hours: 1))),
      Transaction(id: 'T2', description: 'Ride - Rahul Verma', amount: 450, isCredit: true, type: 'ride', time: DateTime.now().subtract(const Duration(hours: 3))),
      Transaction(id: 'T3', description: 'Incentive Bonus', amount: 500, isCredit: true, type: 'bonus', time: DateTime.now().subtract(const Duration(hours: 4))),
      Transaction(id: 'T4', description: 'Platform Commission (10%)', amount: 63, isCredit: false, type: 'commission', time: DateTime.now().subtract(const Duration(hours: 4))),
      Transaction(id: 'T5', description: 'Payout to HDFC Bank', amount: 5000, isCredit: false, type: 'payout', time: DateTime.now().subtract(const Duration(days: 1))),
      Transaction(id: 'T6', description: 'Freight - Amit Kumar', amount: 2400, isCredit: true, type: 'ride', time: DateTime.now().subtract(const Duration(days: 1))),
      Transaction(id: 'T7', description: 'Incentive Bonus', amount: 300, isCredit: true, type: 'bonus', time: DateTime.now().subtract(const Duration(days: 2))),
      Transaction(id: 'T8', description: 'Payout to HDFC Bank', amount: 8080, isCredit: false, type: 'payout', time: DateTime.now().subtract(const Duration(days: 3))),
    ];

    final bankAccounts = [
      const BankAccount(id: 'B1', bankName: 'HDFC Bank', accountHolder: 'John Doe', accountNumber: '50100234567890', ifsc: 'HDFC0001234', isPrimary: true),
      const BankAccount(id: 'B2', bankName: 'ICICI Bank', accountHolder: 'John Doe', accountNumber: '000405123456', ifsc: 'ICIC0000004'),
    ];

    return _calculateState(
      balance: 3240.50,
      totalEarned: 48650,
      totalPaidOut: 45409.50,
      transactions: transactions,
      bankAccounts: bankAccounts,
    );
  }
  WalletState _calculateState({
    required double balance,
    required double totalEarned,
    required double totalPaidOut,
    required List<Transaction> transactions,
    required List<BankAccount> bankAccounts,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekAgo = now.subtract(const Duration(days: 7));
    final monthAgo = DateTime(now.year, now.month - 1, now.day);

    double todayVal = 0;
    double weekVal = 0;
    double monthVal = 0;

    for (var txn in transactions) {
      if (!txn.isCredit) continue;
      if (txn.time.isAfter(today)) todayVal += txn.amount;
      if (txn.time.isAfter(weekAgo)) weekVal += txn.amount;
      if (txn.time.isAfter(monthAgo)) monthVal += txn.amount;
    }

    return WalletState(
      balance: balance,
      totalEarned: totalEarned,
      totalPaidOut: totalPaidOut,
      todayEarnings: todayVal,
      weekEarnings: weekVal,
      monthEarnings: monthVal,
      transactions: transactions,
      bankAccounts: bankAccounts,
    );
  }

  void requestPayout(double amount, [String? bankAccountId]) {
    final bank = (bankAccountId != null 
        ? state.bankAccounts.where((b) => b.id == bankAccountId).firstOrNull
        : null) ?? 
        state.bankAccounts.where((b) => b.isPrimary).firstOrNull ?? 
        (state.bankAccounts.isNotEmpty ? state.bankAccounts.first : const BankAccount(id: 'temp', bankName: 'Unknown', accountHolder: '', accountNumber: '', ifsc: ''));

    if (bank.id == 'temp') return; // Cannot payout without account

    final newTxn = Transaction(
      id: 'T${state.transactions.length + 1}',
      description: 'Payout to ${bank.bankName}',
      amount: amount,
      isCredit: false,
      type: 'payout',
      time: DateTime.now(),
      bankAccountId: bank.id,
    );
    
    final newTransactions = [newTxn, ...state.transactions];
    state = _calculateState(
      balance: state.balance - amount,
      totalEarned: state.totalEarned,
      totalPaidOut: state.totalPaidOut + amount,
      transactions: newTransactions,
      bankAccounts: state.bankAccounts,
    );
  }

  void addBankAccount(BankAccount account) {
    final newAccounts = [...state.bankAccounts, account];
    state = _calculateState(
      balance: state.balance,
      totalEarned: state.totalEarned,
      totalPaidOut: state.totalPaidOut,
      transactions: state.transactions,
      bankAccounts: newAccounts,
    );
  }

  void removeBankAccount(String id) {
    if (state.bankAccounts.length <= 1) return; // Keep at least one
    final accountToRemove = state.bankAccounts.where((b) => b.id == id).firstOrNull;
    if (accountToRemove == null) return;
    
    final newAccounts = state.bankAccounts.where((b) => b.id != id).toList();
    if (accountToRemove.isPrimary && newAccounts.isNotEmpty) {
      // Set the first remaining as primary
      final first = newAccounts[0].copyWith(isPrimary: true);
      newAccounts[0] = first;
    }
    state = _calculateState(
      balance: state.balance,
      totalEarned: state.totalEarned,
      totalPaidOut: state.totalPaidOut,
      transactions: state.transactions,
      bankAccounts: newAccounts,
    );
  }

  void setPrimaryAccount(String id) {
    final newAccounts = state.bankAccounts.map((b) => b.copyWith(isPrimary: b.id == id)).toList();
    state = _calculateState(
      balance: state.balance,
      totalEarned: state.totalEarned,
      totalPaidOut: state.totalPaidOut,
      transactions: state.transactions,
      bankAccounts: newAccounts,
    );
  }
}

final walletProvider = NotifierProvider<WalletNotifier, WalletState>(
  WalletNotifier.new,
);
