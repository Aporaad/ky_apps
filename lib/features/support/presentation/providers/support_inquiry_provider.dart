import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/repositories/support_repository.dart';

/// مزود مستودع الدعم — يستخدم عميل Dio المركزي (فُتح للاستخدام قبل الدخول أيضاً)
/// Support repository provider — rides the shared Dio client, which is usable before login too.
final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  return SupportRepository(client: ref.watch(dioClientProvider));
});

/// حالة نموذج إرسال الاستفسار
/// Inquiry submission form state.
class SupportInquiryState {
  const SupportInquiryState({
    this.submitting = false,
    this.submitted = false,
    this.errorMessage,
    this.ticketId,
  });

  /// جارٍ الإرسال
  final bool submitting;

  /// تمّ الإرسال بنجاح — الشاشة تعرض لوحة الشكر مكان النموذج
  /// Submitted successfully — the screen shows the thank-you panel instead of the form.
  final bool submitted;

  /// رفض الخادم أو فشل الشبكة (يُعرض داخل النموذج لا كحوار)
  /// A server refusal or network failure, shown inline inside the form rather than as a dialog.
  final String? errorMessage;

  /// معرّف التذكرة الذي أعاده الخادم — يُعرض للمستخدم كمرجع
  /// The ticket id returned by the server, shown to the user as a reference.
  final int? ticketId;

  SupportInquiryState copyWith({
    bool? submitting,
    bool? submitted,
    String? Function()? errorMessage,
    int? Function()? ticketId,
  }) {
    return SupportInquiryState(
      submitting: submitting ?? this.submitting,
      submitted: submitted ?? this.submitted,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      ticketId: ticketId != null ? ticketId() : this.ticketId,
    );
  }
}

/// مُبلِغ إرسال الاستفسار — يحمل الحالة الوحيدة التي يهمّها النموذج
/// The submission notifier — holds the only state the form cares about.
///
/// لا يحتفظ بقائمة التذاكر: قسم الدعم في شاشة المعلومات نموذج إرسال فقط (قرار صريح)، وسجل
/// الاستفسارات شاشة إدارة مستقلة تُقرأ بصلاحية `support.view`.
/// It keeps no ticket list: the support block on the app-info screen is a submission form only
/// (an explicit decision), and the inquiry log is a separate admin screen behind `support.view`.
class SupportInquiryNotifier extends Notifier<SupportInquiryState> {
  @override
  SupportInquiryState build() => const SupportInquiryState();

  SupportRepository get _repo => ref.read(supportRepositoryProvider);

  /// إرسال الاستفسار — يتحقق محلياً أولاً ثم يرسل
  /// Submit the inquiry — validates locally first, then sends.
  ///
  /// [name] و[phone] يُرسلان اختياريين: صاحب الجلسة لا يحتاجهما، والزائر يمرّرهما بعد تحقق
  /// النموذج المحلي.
  /// [name] and [phone] are optional: a signed-in user needs neither, and a guest passes them
  /// after the form's own local validation.
  Future<void> submit({
    String? name,
    String? phone,
    required String message,
    String? appVersion,
    String? platform,
  }) async {
    if (state.submitting) return;

    state = state.copyWith(
      submitting: true,
      submitted: false,
      errorMessage: () => null,
    );

    final result = await _repo.submitInquiry(
      name: name,
      phone: phone,
      message: message,
      appVersion: appVersion,
      platform: platform,
    );

    if (!result.success) {
      state = state.copyWith(
        submitting: false,
        errorMessage: () => result.displayMessage,
      );

      return;
    }

    final data = result.data ?? const <String, dynamic>{};
    final rawId = data['ticket_id'];

    state = state.copyWith(
      submitting: false,
      submitted: true,
      errorMessage: () => null,
      ticketId: () => rawId is int ? rawId : int.tryParse('$rawId'),
    );
  }

  /// مسح الخطأ بعد عرضه (زر «حاول مرة أخرى»)
  /// Clear the error after it has been shown (the "try again" path).
  void clearError() {
    state = state.copyWith(errorMessage: () => null);
  }

  /// العودة إلى النموذج بعد نجاح الإرسال — «إرسال استفسار آخر»
  /// Return to the form after a success — the "send another inquiry" path.
  void reset() {
    state = const SupportInquiryState();
  }
}

final supportInquiryProvider =
    NotifierProvider<SupportInquiryNotifier, SupportInquiryState>(
      SupportInquiryNotifier.new,
    );
