import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/account_model.dart';
import '../../data/repositories/account_repository.dart';
import 'auth_provider.dart';

/// Purpose: Accounts State Management Provider
/// Author: Antigravity AI

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

  Future<bool> updateAccount(String id, Map<String, dynamic> data) async {
    try {
      final acc = await repository.updateAccount(id, data);
      if (acc != null) {
        await fetchAccounts();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> deleteAccount(String id) async {
    try {
      final ok = await repository.deleteAccount(id);
      if (ok) {
        await fetchAccounts();
        return true;
      }
    } catch (_) {}
    return false;
  }
}

final accountProvider = StateNotifierProvider<AccountNotifier, AccountState>((ref) {
  final authState = ref.watch(authProvider);
  final notifier = AccountNotifier(ref.watch(accountRepositoryProvider));
  if (authState.isAuthenticated) {
    notifier.fetchAccounts();
  }
  return notifier;
});
