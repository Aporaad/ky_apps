import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../accounts/data/models/chart_account_model.dart';
import '../../accounts/presentation/providers/accounts_provider.dart';
import '../../accounts/presentation/screens/edit_account_screen.dart';
import '../../admin/data/models/app_user_model.dart';
import '../../admin/presentation/screens/assign_permissions_screen.dart';
import '../../admin/presentation/screens/edit_user_screen.dart';
import '../../admin/presentation/screens/user_activity_screen.dart';
import '../../admin/presentation/widgets/user_picker_screen.dart';
import '../../customers/data/models/customer_model.dart';
import '../../customers/presentation/screens/customer_statement_screen.dart';
import '../../customers/presentation/screens/edit_customer_screen.dart';
import '../../customers/presentation/widgets/customer_picker_screen.dart';
import '../../workers/data/models/worker_model.dart';
import '../../workers/presentation/screens/add_edit_worker_screen.dart';

/// التدفّقات التي تحتاج معطى قبل الشاشة: منتقي ثم وجهة
/// Flows that need a datum before the screen: a picker, then the destination.
///
/// دوال عليا لا كلاشرات، لأن الكتالوج `const`: الكلاشر ليس تعبيرًا ثابتًا، ومرجع الدالة العليا هو.
/// Top-level functions rather than closures, because the catalog is `const`: a closure is not a
/// constant expression, while a reference to a top-level function is.
///
/// نسخة مطابقة لما تفعله بطاقات لوحة العملاء (`customers_dashboard_screen.dart`) ولوحة الإدارة
/// (`management_dashboard_screen.dart`) — لا منطق جديد، ولا مسار موازٍ.
/// A faithful copy of what the customers and admin dashboards already do — no new logic and no
/// parallel route.

/// كشف حساب عميل: اختيار عميل ثم كشفه
/// Customer statement: pick a customer, then open the statement.
Future<void> openCustomerStatement(BuildContext context) async {
  final picked = await Navigator.of(context).push<CustomerModel>(
    MaterialPageRoute(
      builder:
          (_) => const CustomerPickerScreen(
            title: 'اختر العميل لكشف الحساب',
            subtitle: 'ابحث بالاسم أو الرقم لعرض كشف حسابه',
            icon: Icons.receipt_long_rounded,
          ),
    ),
  );
  if (picked == null || !context.mounted) return;

  await Navigator.of(context).push(
    MaterialPageRoute(
      builder:
          (_) => CustomerStatementScreen(
            custNo: picked.custNo,
            custName: picked.custName,
            accNo: picked.accNo,
          ),
    ),
  );
}

/// تعديل عميل: اختيار عميل ثم نموذج التعديل
/// Customer edit: pick a customer, then the edit form.
Future<void> openCustomerEdit(BuildContext context) async {
  final picked = await Navigator.of(context).push<CustomerModel>(
    MaterialPageRoute(
      builder:
          (_) => const CustomerPickerScreen(
            title: 'اختر العميل للتعديل',
            subtitle: 'ابحث عن العميل الذي تريد تعديل بياناته',
            icon: Icons.edit_note_rounded,
          ),
    ),
  );
  if (picked == null || !context.mounted) return;

  await Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => EditCustomerScreen(customer: picked)),
  );
}

/// سجل نشاط مستخدم: الاختيار أولًا لأن الخادم لا يقدّم سجلًا عامًا
/// User activity: the pick comes first because the server exposes no general trail.
Future<void> openUserActivity(BuildContext context) async {
  final picked = await Navigator.of(context).push<AppUserModel>(
    MaterialPageRoute(
      builder:
          (_) => const UserPickerScreen(
            title: 'سجل النشاط',
            subtitle: 'اختر مستخدمًا لعرض سجل عملياته',
          ),
    ),
  );
  if (picked == null || !context.mounted) return;

  await Navigator.of(context).push(
    MaterialPageRoute(
      builder:
          (_) => UserActivityScreen(
            userId: picked.userId,
            userName: picked.displayName,
          ),
    ),
  );
}

/// نماذج إضافة العاملين الثلاثة — مراجع دوال عليا ليبقى الكتالوج `const`
/// The three "add worker" forms — top-level references so the catalog stays `const`.
Widget buildAddEmployeeScreen() =>
    const AddEditWorkerScreen(workerType: WorkerType.employee);

Widget buildAddCutterScreen() =>
    const AddEditWorkerScreen(workerType: WorkerType.cutter);

Widget buildAddTailorScreen() =>
    const AddEditWorkerScreen(workerType: WorkerType.tailor);

/// تعديل بيانات حساب: اختيار حساب من الشجرة المالية ثم نموذج التعديل
/// Account edit: pick an account from the chart, then the edit form.
Future<void> openAccountEdit(BuildContext context) async {
  final picked = await _pickAccount(context);
  if (picked == null || !context.mounted) return;

  await Navigator.of(context).push(
    MaterialPageRoute(
      builder:
          (_) =>
              EditAccountScreen(accNo: picked.accNo, accName: picked.accName),
    ),
  );
}

/// تعديل مستخدم: اختيار مستخدم ثم نموذجه
/// User edit: pick a user, then their form.
Future<void> openUserEdit(BuildContext context) async {
  final picked = await Navigator.of(context).push<AppUserModel>(
    MaterialPageRoute(
      builder:
          (_) => const UserPickerScreen(
            title: 'تعديل مستخدم',
            subtitle: 'اختر المستخدم الذي تريد تعديل بياناته',
          ),
    ),
  );
  if (picked == null || !context.mounted) return;

  await Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => EditUserScreen(user: picked)));
}

/// منح الصلاحيات: اختيار مستخدم ثم شاشة منحه
/// Granting permissions: pick a user, then the grant screen.
Future<void> openUserGrants(BuildContext context) async {
  final picked = await Navigator.of(context).push<AppUserModel>(
    MaterialPageRoute(
      builder:
          (_) => const UserPickerScreen(
            title: 'منح الصلاحيات',
            subtitle: 'اختر المستخدم لتعديل صلاحياته',
          ),
    ),
  );
  if (picked == null || !context.mounted) return;

  await Navigator.of(context).push(
    MaterialPageRoute(
      builder:
          (_) => AssignPermissionsScreen(
            userId: picked.userId,
            userName: picked.displayName,
          ),
    ),
  );
}

/// لوحة اختيار حساب — تُرجع الحساب المختار أو null
/// The account picker sheet — returns the chosen account or null.
Future<ChartAccountModel?> _pickAccount(BuildContext context) {
  return showModalBottomSheet<ChartAccountModel>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _AccountPickerSheet(),
  );
}

/// بحث واختيار حساب من `CHART_ACC`
/// Search and pick an account from `CHART_ACC`.
class _AccountPickerSheet extends ConsumerStatefulWidget {
  const _AccountPickerSheet();

  @override
  ConsumerState<_AccountPickerSheet> createState() =>
      _AccountPickerSheetState();
}

class _AccountPickerSheetState extends ConsumerState<_AccountPickerSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // القائمة قد تكون محمّلة من لوحة الحسابات؛ وإلا فهذا يبدأ التحميل
    // The list may already be loaded by the accounts dashboard; otherwise this starts the load.
    Future<void>.microtask(
      () => ref.read(chartAccountsProvider.notifier).loadAccounts(),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chartAccountsProvider);

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.75,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'اختر الحساب المراد تعديله',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'إغلاق',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _searchCtrl,
              onChanged: (value) {
                // نفس مهلة البحث المعتمدة في المشروع
                // The project's established search debounce.
                _debounce?.cancel();
                _debounce = Timer(
                  const Duration(milliseconds: 300),
                  () => ref
                      .read(chartAccountsProvider.notifier)
                      .loadAccounts(search: value.trim()),
                );
              },
              decoration: const InputDecoration(
                hintText: 'بحث باسم أو رقم الحساب…',
                prefixIcon: Icon(Icons.search_rounded, size: 20),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child:
                  state.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : state.accounts.isEmpty
                      ? Center(
                        child: Text(
                          'لا توجد حسابات مطابقة',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      )
                      : ListView.separated(
                        itemCount: state.accounts.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final account = state.accounts[index];

                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.edit_note_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              account.accName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text('رقم الحساب: ${account.accNo}'),
                            onTap: () => Navigator.pop(context, account),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
