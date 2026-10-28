import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/permission_codes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/tailoring_reference_model.dart';
import '../providers/tailoring_providers.dart';
import '../widgets/cutting_bill_form.dart';
import '../widgets/prototype_save_bar.dart';

/// شاشة إضافة فاتورة تفصيل — نموذج أولي بلا حفظ
/// The add cutting-bill screen — a prototype with no saving.
///
/// الشاشة تُبنى بالكامل (حقول، قواميس حقيقية، تسميات مقاسات فعلية) لكن زر الحفظ معطّل
/// صراحةً، ولا يُرسل أي طلب إلى الخادم: النماذج الأولية قراءة فقط بقرار المستخدم.
/// The whole screen is built (fields, real dictionaries, real measurement labels) but the save
/// button is plainly disabled and no request is sent: the prototypes are read-only by decision.
class CuttingBillAddScreen extends ConsumerWidget {
  const CuttingBillAddScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        title:  Row(
          children: [
            Icon(Icons.add_circle_outline_rounded, color: AppColors.success, size: 21),
            SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'إضافة فاتورة تفصيل',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'نموذج أولي — الحفظ غير مفعّل',
                    style: TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: reference.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        // المرجعيات تزيينية هنا: فشلها لا يمنع عرض النموذج، فتُمرَّر فارغة
        // The reference data is decorative here: its failure must not block the form, so it
        // is passed empty.
        error: (_, __) => const CuttingBillForm(
          reference: TailoringReference.empty,
          footerNote: 'نموذج أولي — الحفظ غير مفعّل',
        ),
        data: (data) => CuttingBillForm(
          reference: data,
          footerNote: 'نموذج أولي — الحفظ غير مفعّل',
        ),
      ),
      bottomNavigationBar: const PrototypeSaveBar(
        permissionCode: Perm.tailoringCreate,
        label: 'حفظ الفاتورة',
        note: 'نموذج أولي — الحفظ غير مفعّل',
      ),
    );
  }
}
