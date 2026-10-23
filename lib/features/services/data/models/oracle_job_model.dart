/// نموذج مهمة مجدولة — يقرأ `USER_SCHEDULER_JOBS`
/// Scheduler job model — read from USER_SCHEDULER_JOBS.
class OracleJobModel {
  final String jobName;
  final bool enabled;
  final String? repeatInterval;
  final String? jobType;
  final String? jobAction;
  final String? state;
  final String? lastStartDate;
  final String? nextRunDate;

  const OracleJobModel({
    required this.jobName,
    this.enabled = false,
    this.repeatInterval,
    this.jobType,
    this.jobAction,
    this.state,
    this.lastStartDate,
    this.nextRunDate,
  });

  factory OracleJobModel.fromJson(Map<String, dynamic> json) {
    // USER_SCHEDULER_JOBS عبر yajra يعود بحروف صغيرة snake_case (`job_name`).
    return OracleJobModel(
      jobName: (_s(json['JOB_NAME'] ?? json['job_name'])) ?? '',
      enabled: _s(json['ENABLED'] ?? json['enabled'])?.toUpperCase() == 'TRUE',
      repeatInterval: _s(json['REPEAT_INTERVAL'] ?? json['repeat_interval']),
      jobType: _s(json['JOB_TYPE'] ?? json['job_type']),
      jobAction: _s(json['JOB_ACTION'] ?? json['job_action']),
      state: _s(json['STATE'] ?? json['state']),
      lastStartDate: _s(json['LAST_START_DATE'] ?? json['last_start_date']),
      nextRunDate: _s(json['NEXT_RUN_DATE'] ?? json['next_run_date']),
    );
  }

  static String? _s(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }
}
