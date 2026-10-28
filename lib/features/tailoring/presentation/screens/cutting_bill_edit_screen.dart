import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/permission_codes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/permission_gate.dart';
import '../../data/models/cutting_bill_summary_model.dart';
import '../../data/models/tailoring_reference_model.dart';
import '../../data/repositories/tailoring_repository.dart';
import '../providers/tailoring_providers.dart';
import '../widgets/cutting_bill_form.dart';
import '../widgets/prototype_save_bar.dart';

/// شاشة تعديل فاتورة تفصيل — نموذج أولي معبّأ من فاتورة حقيقية
/// The edit cutting-bill screen — a prototype pre-filled from a real bill.
///
/// الشاشة تقرأ الفاتورة فعلياً من الخادم وتعرض حقولها كما هي في النظام، لكن أي تعديل يبقى
/// في حالة الواجهة ولا يُحفظ: الحفظ معطّل صراحةً ولا يوجد أي مسار كتابة في الخادم.
/// The screen really loads the bill from the server and shows its fields as stored, but every
/// change stays in the widget state and is never saved: saving is plainly disabled and no write
/// route exists on the server.
class CuttingBillEditScreen extends ConsumerWidget {
  /// هوية الفاتورة المركّبة (رقم، سنة)
  /// The composite bill identity (number, year).
  final CuttingBillKey billKey;

  const CuttingBillEditScreen({super.key, required this.billKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(cuttingBillDetailProvider(billKey));
    final reference = ref.watch(tailoringReferenceProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        scrolledUnderElevation: 2,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Icon(Icons.edit_note_rounded, color: AppColors.info, size: 22),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تعديل فاتورة تفصيل ${billKey.id}',
                    style:  TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    'نموذج أولي — التعديل غير مفعّل',
                    style: TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(cuttingBillDetailProvider(billKey)),
            icon: const Icon(Icons.refresh_rounded, size: 21),
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: PermissionGate(
        code: Perm.tailoringUpdate,
        hide: false,
        onDenied: const _NoEditGrant(),
        child: detail.when(
          loading: () => const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 14),
                Text(
                  'جارٍ تحميل الفاتورة...',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
          error: (error, _) => _buildError(context, ref, error),
          data: (data) => CuttingBillForm(
            // الفاتورة نفسها هي مصدر التعبئة المسبقة — لا نسخة موازية من البيانات
            // The bill itself is the pre-fill source — no parallel copy of the data.
            initial: data,
            reference: reference.value ?? TailoringReference.empty,
            footerNote: 'نموذج أولي — التعديل غير مفعّل',
          ),
        ),
      ),
      bottomNavigationBar: const PrototypeSaveBar(
        permissionCode: Perm.tailoringUpdate,
        label: 'حفظ التعديلات',
        note: 'نموذج أولي — التعديل غير مفعّل',
      ),
    );
  }

  /// الخطأ هنا قد يكون «خارج نطاق العرض» أيضاً، فيُشرح بلا لبس
  /// The error can also be "outside the view's scope", so it is stated plainly.
  Widget _buildError(BuildContext context, WidgetRef ref, Object error) {
    final isNotFound = error is TailoringException && error.notFoundInView;
    final message = error is TailoringException
        ? error.displayMessage
        : 'تعذّر تحميل الفاتورة';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isNotFound ? Icons.playlist_remove_rounded : Icons.wifi_off_rounded,
              size: 54,
              color: isNotFound ? AppColors.textMuted : AppColors.error,
            ),
            const SizedBox(height: 14),
            Text(
              isNotFound ? 'الفاتورة غير متاحة للتعديل' : 'تعذّر تحميل الفاتورة',
              style:  TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isNotFound
                  ? 'هذه الفاتورة ليست ضمن الفواتير المُسندة إلى قصّاص وخيّاط، وهي التي '
                        'يعرضها مصدر البيانات. الرقم قد يكون صحيحاً لكن الفاتورة خارج نطاق العرض.'
                  : message,
              textAlign: TextAlign.center,
              style:  TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(cuttingBillDetailProvider(billKey)),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// منع صريح: الشاشة كلها ضمن صلاحية `tailoring.update`
/// An explicit denial: the whole screen sits inside `tailoring.update`.
///
/// الرسالة تشرح السبب بدل صفحة فارغة، لأن المستخدم وصل من بطاقة في لوحة القسم.
/// The message explains why instead of showing a blank page, since the user arrived from a
/// dashboard card.
class _NoEditGrant extends StatelessWidget {
  const _NoEditGrant();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children:  [
            Icon(Icons.lock_outline_rounded, size: 48, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text(
              'لا تملك صلاحية تعديل فواتير التفصيل',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'راجع مدير النظام لمنحك صلاحية «تعديل فاتورة التفصيل»',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
