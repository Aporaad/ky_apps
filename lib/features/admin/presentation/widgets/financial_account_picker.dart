import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../accounts/data/models/chart_account_model.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';

/// فاتحة اختيار الحساب المالي (CHART_ACC) لربطه بالمستخدم.
/// The financial-account (CHART_ACC) picker used to link an account to a user.
///
/// تُستخدم في نموذج إنشاء/تعديل المستخدم لاختيار `ACC_NO`. القراءة تتم عبر
/// `chartAccountsProvider` نفسه الذي يغذّي منتقي كشف الحساب، فتبقى لائحة الحسابات
/// مصدرًا واحدًا لا نسخة ثانية.
/// It reuses the same `chartAccountsProvider` that powers the statement picker, so the
/// account list stays a single source rather than a second copy.
class FinancialAccountPickerSheet extends ConsumerStatefulWidget {
  /// ينادى عند اختيار حساب — يغلق النافذة بعد الاختيار في المستدعي.
  /// Called on selection; the caller pops the sheet afterwards.
  final ValueChanged<ChartAccountModel> onSelected;

  /// عنوان الفاتحة — يختلف بين ربط الحساب المالي وربط أي حساب آخر.
  final String title;

  const FinancialAccountPickerSheet({
    required this.onSelected,
    this.title = 'اختر الحساب المالي',
    super.key,
  });

  @override
  ConsumerState<FinancialAccountPickerSheet> createState() =>
      _FinancialAccountPickerSheetState();
}

class _FinancialAccountPickerSheetState
    extends ConsumerState<FinancialAccountPickerSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chartState = ref.watch(chartAccountsProvider);

    return Padding(
      // مساحة لوحة المفاتيح حتى لا يحجب الإدخالَ آخرُ السطور.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(32, 32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _searchCtrl,
              onChanged: (val) {
                // إلغاء بحث سابق لم يكتمل: النتيجة الأحدث يجب ألا تطمسها الأقدم.
                // Debounced server search so a stale response never overwrites the newest one.
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 300), () {
                  ref
                      .read(chartAccountsProvider.notifier)
                      .loadAccounts(search: val.trim());
                });
              },
              decoration: InputDecoration(
                hintText: 'بحث باسم الحساب أو رقمه...',
                hintStyle: const TextStyle(fontSize: 13),
                prefixIcon: const Icon(Icons.search, size: 18),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: chartState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : chartState.error != null && chartState.accounts.isEmpty
                  ? Center(
                      child: Text(
                        'تعذّر تحميل الحسابات',
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    )
                  : chartState.accounts.isEmpty
                  ? const Center(
                      child: Text(
                        'لا توجد حسابات مطابقة',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    )
                  : ListView.separated(
                      itemCount: chartState.accounts.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, idx) {
                        final acc = chartState.accounts[idx];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.account_balance_outlined,
                              size: 18,
                            ),
                          ),
                          title: Text(
                            acc.accName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5,
                            ),
                          ),
                          subtitle: Text(
                            'رقم: ${acc.accNo}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                          trailing: acc.balance != null
                              ? Text(
                                  '${acc.balance!.toStringAsFixed(2)} ر.ي',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: (acc.balance ?? 0) >= 0
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
                                )
                              : null,
                          onTap: () => widget.onSelected(acc),
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

/// فتح فاتحة اختيار الحساب المالي فوق الشاشة الحالية.
/// Opens the financial-account picker over the current screen.
Future<void> showFinancialAccountPicker(
  BuildContext context, {
  required ValueChanged<ChartAccountModel> onSelected,
  String title = 'اختر الحساب المالي',
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => FinancialAccountPickerSheet(
      title: title,
      onSelected: (acc) {
        Navigator.pop(ctx);
        onSelected(acc);
      },
    ),
  );
}
