import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/account_model.dart';
import '../../data/repositories/account_repository.dart';
import 'auth_provider.dart';

/// Purpose: Accounts State Provider
/// Author: Antigravity AI
/// Last Modified: 2026-08-03

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository(ref.watch(apiClientProvider));
});

class AccountState {
  final List<AccountModel> accounts;
  final bool isLoading;
  final String? error;

  AccountState({
    required this.accounts,
    required this.isLoading,
    this.error,
  });

  double get netWorth => accounts.fold(0.0, (sum, acc) => sum + acc.balance);
}

class AccountNotifier extends StateNotifier<AccountState> {
  final AccountRepository repository;

  AccountNotifier(this.repository)
      : super(AccountState(accounts: [], isLoading: true)) {
    fetchAccounts();
  }

  Future<void> fetchAccounts() async {
    state = AccountState(accounts: state.accounts, isLoading: true);
    try {
      final list = await repository.getAccounts();
      state = AccountState(accounts: list, isLoading: false);
    } catch (e) {
      state = AccountState(accounts: state.accounts, isLoading: false, error: e.toString());
    }
  }

  Future<bool> addAccount(Map<String, dynamic> data) async {
    try {
      final acc = await repository.createAccount(data);
      if (acc != null) {
        await fetchAccounts();
        return true;
      }
    } catch (_) {}
    return false;
  }
}

final accountProvider = StateNotifierProvider<AccountNotifier, AccountState>((ref) {
  return AccountNotifier(ref.watch(accountRepositoryProvider));
});
