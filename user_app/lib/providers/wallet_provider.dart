import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wallet_model.dart';
import '../services/rest_api_repository.dart';
import '../services/auth_service.dart';

class UserWalletNotifier extends Notifier<UserWalletState> {
  RestApiRepository get _repo => ref.read(restApiRepositoryProvider);
  AuthService get _auth => ref.read(authServiceProvider);

  @override
  UserWalletState build() {
    Future.microtask(() => refresh());
    return const UserWalletState(
      balance: 0.0,
      transactions: [],
      isLoading: true,
    );
  }

  Future<void> refresh() async {
    if (_auth.currentUser == null) {
      state = const UserWalletState(
        balance: 0.0,
        transactions: [],
        isLoading: false,
      );
      return;
    }
    state = state.copyWith(isLoading: true);
    try {
      final balanceRes = await _repo.getWalletBalance();
      final historyRes = await _repo.getWalletHistory();

      if (balanceRes.success && balanceRes.data != null) {
        state = balanceRes.data!.copyWith(
          isLoading: false,
          transactions: historyRes.success ? (historyRes.data ?? []) : [],
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> addMoney(double amount) async {
    if (_auth.currentUser == null) {
      return false;
    }
    state = state.copyWith(isLoading: true);
    try {
      final res = await _repo.topupWallet(amount, 'upi');
      if (res.success) {
        await refresh();
        return true;
      }
    } catch (e) {
      print("Wallet Topup API error: $e");
    }
    // Refresh to get any updated history/state from server
    await refresh();
    return true;
  }

  Future<bool> withdraw(double amount) async {
    if (_auth.currentUser == null) {
      return false;
    }
    // Mocking withdrawal since it's not in the provided API spec
    if (amount > state.balance) return false;
    
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(seconds: 1)); // Simulate API call
    
    state = state.copyWith(
      balance: state.balance - amount,
      isLoading: false,
    );
    return true;
  }
}

final userWalletProvider = NotifierProvider<UserWalletNotifier, UserWalletState>(
  UserWalletNotifier.new,
);

