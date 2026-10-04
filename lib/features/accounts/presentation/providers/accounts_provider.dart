import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/models/account_model.dart';
import '../../data/models/chart_account_model.dart';
import '../../data/repositories/account_repository.dart';

/// مزود مستودع الحسابات
final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  final client = ref.watch(dioClientProvider);
  return AccountRepository(client: client);
});

/// حالة قائمة الشجرة المحاسبية
class AccountTreeState {
  final bool isLoading;
  final String? error;
  final List<AccountTreeNode> tree;

  const AccountTreeState({
    this.isLoading = false,
    this.error,
    this.tree = const [],
  });

  AccountTreeState copyWith({
    bool? isLoading,
    String? error,
    List<AccountTreeNode>? tree,
  }) {
    return AccountTreeState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      tree: tree ?? this.tree,
    );
  }
}

class AccountTreeNotifier extends StateNotifier<AccountTreeState> {
  final AccountRepository _repo;

  AccountTreeNotifier(this._repo) : super(const AccountTreeState()) {
    loadTree();
  }

  Future<void> loadTree() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final tree = await _repo.fetchAccountTree();
      state = state.copyWith(isLoading: false, tree: tree);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final accountTreeProvider =
    StateNotifierProvider<AccountTreeNotifier, AccountTreeState>((ref) {
      final repo = ref.watch(accountRepositoryProvider);
      return AccountTreeNotifier(repo);
    });

/// حالة قائمة الحسابات المالية (CHART_ACC)
class ChartAccountsState {
  final bool isLoading;
  final String search;
  final List<ChartAccountModel> accounts;
  final Map<String, dynamic> meta;
  final String? error;

  const ChartAccountsState({
    this.isLoading = false,
    this.search = '',
    this.accounts = const [],
    this.meta = const {},
    this.error,
  });

  ChartAccountsState copyWith({
    bool? isLoading,
    String? search,
    List<ChartAccountModel>? accounts,
    Map<String, dynamic>? meta,
    String? error,
  }) {
    return ChartAccountsState(
      isLoading: isLoading ?? this.isLoading,
      search: search ?? this.search,
      accounts: accounts ?? this.accounts,
      meta: meta ?? this.meta,
      error: error,
    );
  }
}

class ChartAccountsNotifier extends StateNotifier<ChartAccountsState> {
  final AccountRepository _repo;

  ChartAccountsNotifier(this._repo) : super(const ChartAccountsState()) {
    loadAccounts();
  }

  Future<void> loadAccounts({String? search, int page = 1}) async {
    final query = search ?? state.search;
    state = state.copyWith(isLoading: true, search: query, error: null);
    try {
      final res = await _repo.fetchChartAccounts(search: query, page: page);
      state = state.copyWith(
        isLoading: false,
        accounts: res['data'] as List<ChartAccountModel>? ?? [],
        meta: res['meta'] as Map<String, dynamic>? ?? {},
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final chartAccountsProvider =
    StateNotifierProvider<ChartAccountsNotifier, ChartAccountsState>((ref) {
      final repo = ref.watch(accountRepositoryProvider);
      return ChartAccountsNotifier(repo);
    });

/// مزودي الأقسام والحسابات للأب
final parentAccountsProvider = FutureProvider<List<AccountModel>>((ref) async {
  final repo = ref.watch(accountRepositoryProvider);
  return repo.fetchAccounts();
});

final parentAccMainProvider = FutureProvider.family<List<AccMainModel>, int?>((
  ref,
  accNo,
) async {
  final repo = ref.watch(accountRepositoryProvider);
  return repo.fetchAccMain(accNo: accNo);
});

final parentAccSubProvider = FutureProvider.family<List<AccSubModel>, int?>((
  ref,
  accSub,
) async {
  final repo = ref.watch(accountRepositoryProvider);
  return repo.fetchAccSub(accSub: accSub);
});

final parentAccSubGroupProvider =
    FutureProvider.family<List<AccSubGroupModel>, int?>((ref, accPart) async {
      final repo = ref.watch(accountRepositoryProvider);
      return repo.fetchAccSubGroup(accPart: accPart);
    });
