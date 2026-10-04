import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/models/currency_model.dart';
import '../../data/repositories/currency_repository.dart';

/// مزود مستودع العملات
final currencyRepositoryProvider = Provider<CurrencyRepository>((ref) {
  final client = ref.watch(dioClientProvider);
  return CurrencyRepository(client: client);
});

/// حالة قائمة العملات
class CurrenciesState {
  final bool isLoading;
  final String? error;
  final List<CurrencyModel> currencies;

  const CurrenciesState({
    this.isLoading = false,
    this.error,
    this.currencies = const [],
  });

  CurrenciesState copyWith({
    bool? isLoading,
    String? error,
    List<CurrencyModel>? currencies,
  }) {
    return CurrenciesState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currencies: currencies ?? this.currencies,
    );
  }
}

class CurrenciesNotifier extends StateNotifier<CurrenciesState> {
  final CurrencyRepository _repo;

  CurrenciesNotifier(this._repo) : super(const CurrenciesState()) {
    loadCurrencies();
  }

  Future<void> loadCurrencies() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final list = await _repo.fetchCurrencies();
      state = state.copyWith(isLoading: false, currencies: list);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<CurrencyResult> addCurrency(CurrencyModel currency) async {
    final res = await _repo.createCurrency(currency);
    if (res.success) {
      loadCurrencies();
    }
    return res;
  }

  Future<CurrencyResult> updateCurrency(
    int curNo,
    Map<String, dynamic> data,
  ) async {
    final res = await _repo.updateCurrency(curNo, data);
    if (res.success) {
      loadCurrencies();
    }
    return res;
  }

  Future<CurrencyResult> deleteCurrency(int curNo) async {
    final res = await _repo.deleteCurrency(curNo);
    if (res.success) {
      loadCurrencies();
    }
    return res;
  }
}

final currenciesProvider =
    StateNotifierProvider<CurrenciesNotifier, CurrenciesState>((ref) {
      final repo = ref.watch(currencyRepositoryProvider);
      return CurrenciesNotifier(repo);
    });

/// أسعار الصرف التاريخية لعملة محددة
final currencyPricesProvider = FutureProvider.family<Map<String, dynamic>, int>(
  (ref, curNo) async {
    final repo = ref.watch(currencyRepositoryProvider);
    return repo.fetchPrices(curNo);
  },
);
