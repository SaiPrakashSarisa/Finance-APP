import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/credit_model.dart';
import '../../data/repositories/credit_repository.dart';
import 'auth_provider.dart';

/// Purpose: Credit & Debt Tracker State Management Provider
/// Author: Antigravity AI

final creditRepositoryProvider = Provider<CreditRepository>((ref) {
  return CreditRepository(ref.watch(apiClientProvider));
});

class CreditState {
  final List<CreditModel> credits;
  final CreditTotalsModel? totals;
  final bool isLoading;
  final String? error;

  CreditState({
    required this.credits,
    this.totals,
    required this.isLoading,
    this.error,
  });
}

class CreditNotifier extends StateNotifier<CreditState> {
  final CreditRepository repository;

  CreditNotifier(this.repository)
      : super(CreditState(credits: [], isLoading: true)) {
    fetchCredits();
  }

  Future<void> fetchCredits({String? type, String? status}) async {
    state = CreditState(credits: state.credits, totals: state.totals, isLoading: true);
    try {
      final list = await repository.getCredits(type: type, status: status);
      final totals = await repository.getTotals();
      state = CreditState(credits: list, totals: totals, isLoading: false);
    } catch (e) {
      state = CreditState(credits: state.credits, totals: state.totals, isLoading: false, error: e.toString());
    }
  }

  Future<bool> addCredit(Map<String, dynamic> data) async {
    try {
      final item = await repository.createCredit(data);
      if (item != null) {
        await fetchCredits();
        return true;
      }
    } catch (_) {}
    return false;
  }
}

final creditProvider = StateNotifierProvider<CreditNotifier, CreditState>((ref) {
  return CreditNotifier(ref.watch(creditRepositoryProvider));
});
