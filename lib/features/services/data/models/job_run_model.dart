/// نموذج تشغيل مهمة — سجل `USER_SCHEDULER_JOB_RUN_DETAILS` (قراءة فقط)
/// Job run record — USER_SCHEDULER_JOB_RUN_DETAILS (read-only).
class JobRunModel {
  final String? logDate;
  final String? runDuration;
  final bool succeeded;
  final String? status;
  final String? error;
  final String? additionalInfo;

  const JobRunModel({
    this.logDate,
    this.runDuration,
    this.succeeded = false,
    this.status,
    this.error,
    this.additionalInfo,
  });

  factory JobRunModel.fromJson(Map<String, dynamic> json) {
    // USER_SCHEDULER_JOB_RUN_DETAILS عبر yajra يعود بحروف صغيرة (`log_date`, `error#`).
    return JobRunModel(
      logDate: _s(json['LOG_DATE'] ?? json['log_date']),
      runDuration: _s(json['RUN_DURATION'] ?? json['run_duration']),
      succeeded: _s(json['SUCCEEDED'] ?? json['succeeded'])?.toUpperCase() == 'TRUE',
      status: _s(json['STATUS'] ?? json['status']),
      error: _s(json['ERROR#'] ?? json['error#'] ?? json['ERROR'] ?? json['error']),
      additionalInfo: _s(json['ADDITIONAL_INFO'] ?? json['additional_info']),
    );
  }

  static String? _s(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }
}
