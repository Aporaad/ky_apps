import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/account_group_statement_model.dart';
import '../models/account_model.dart';
import '../models/chart_account_model.dart';
import '../models/tree_export_row_model.dart';

// ================================================================
// نتيجة عملية الحساب
// ================================================================
class AccountResult {
  final bool success;
  final String message;
  final dynamic data;

  const AccountResult({
    required this.success,
    required this.message,
    this.data,
  });
}

// ================================================================
// مستودع بيانات الحسابات
// ================================================================
class AccountRepository {
  final DioClient client;

  AccountRepository({required this.client});

  void cancel() {
    // دعم دالة الإلغاء العامة عند الحاجة
  }

  // ============================================================
  // جلب هيكل الشجرة
  // ============================================================

  /// جلب الأقسام الرئيسية (ACCOUNT)
  Future<List<AccountModel>> fetchAccounts({CancelToken? cancelToken}) async {
    try {
      final resp = await client.dio.get(
        '/accounts/account',
        cancelToken: cancelToken,
      );
      final body = resp.data as Map<String, dynamic>;
      if (body['success'] == true) {
        return (body['data'] as List? ?? [])
            .map((e) => AccountModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) return [];
      rethrow;
    }
  }

  /// جلب الحسابات الفرعية (ACC_MAIN)
  Future<List<AccMainModel>> fetchAccMain({int? accNo, CancelToken? cancelToken}) async {
    try {
      final resp = await client.dio.get(
        '/accounts/main',
        queryParameters: {if (accNo != null) 'acc_no': accNo},
        cancelToken: cancelToken,
      );
      final body = resp.data as Map<String, dynamic>;
      if (body['success'] == true) {
        return (body['data'] as List? ?? [])
            .map((e) => AccMainModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) return [];
      rethrow;
    }
  }

  /// جلب الحسابات الجزئية (ACC_SUB)
  Future<List<AccSubModel>> fetchAccSub({int? accSub, CancelToken? cancelToken}) async {
    try {
      final resp = await client.dio.get(
        '/accounts/sub',
        queryParameters: {if (accSub != null) 'acc_sub': accSub},
        cancelToken: cancelToken,
      );
      final body = resp.data as Map<String, dynamic>;
      if (body['success'] == true) {
        return (body['data'] as List? ?? [])
            .map((e) => AccSubModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) return [];
      rethrow;
    }
  }

  /// جلب مجموعات الحسابات الجزئي (ACC_SUB_GROUP)
  Future<List<AccSubGroupModel>> fetchAccSubGroup({int? accPart, CancelToken? cancelToken}) async {
    try {
      final resp = await client.dio.get(
        '/accounts/sub-group',
        queryParameters: {if (accPart != null) 'acc_part': accPart},
        cancelToken: cancelToken,
      );
      final body = resp.data as Map<String, dynamic>;
      if (body['success'] == true) {
        return (body['data'] as List? ?? [])
            .map((e) => AccSubGroupModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) return [];
      rethrow;
    }
  }

  /// هيكل الشجرة المحاسبية فقط (أقسام → فروع → أجزاء → مجموعات) مع الأرصدة المجمّعة.
  /// The lazy skeleton: one request, ~135 structural nodes, balances rolled up from
  /// ENTRY_SUB on the server. Financial leaves load per expansion via [fetchTreeChildren].
  ///
  /// قراءة الشجرة تُمرَّر بمهلة استقبال أطول محلياً بدل تغيير المهلة العامة لكل التطبيق.
  /// The tree read gets a longer receive timeout locally, not globally in ApiConstants.
  Future<List<AccountTreeNode>> fetchAccountTree({
    String? fromDate,
    String? toDate,
    CancelToken? cancelToken,
  }) async {
    try {
      final resp = await client.dio.get(
        '/accounts/tree',
        queryParameters: {
          if (fromDate != null) 'from_date': fromDate,
          if (toDate != null) 'to_date': toDate,
        },
        options: Options(receiveTimeout: const Duration(seconds: 30)),
        cancelToken: cancelToken,
      );
      final body = resp.data as Map<String, dynamic>;
      if (body['success'] == true) {
        return (body['data'] as List? ?? [])
            .map((e) => AccountTreeNode.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) return [];
      rethrow;
    }
  }

  /// أبناء عقدة هيكلية (حسابات مالية) بترقيم صفحات — يُستدعى عند التوسيع أو «المزيد».
  /// Paged financial children of one structural node, fetched on expand / load-more.
  Future<TreeChildrenResult> fetchTreeChildren({
    required String level,
    int? groupId,
    int? accPart,
    String search = '',
    String sort = 'acc_no',
    String dir = 'asc',
    int page = 1,
    int limit = 50,
    String? fromDate,
    String? toDate,
    CancelToken? cancelToken,
  }) async {
    try {
      final resp = await client.dio.get(
        '/accounts/tree/children',
        queryParameters: {
          'level': level,
          if (groupId != null) 'group_id': groupId,
          if (accPart != null) 'acc_part': accPart,
          if (search.isNotEmpty) 'search': search,
          'sort': sort,
          'dir': dir,
          'page': page,
          'limit': limit,
          if (fromDate != null) 'from_date': fromDate,
          if (toDate != null) 'to_date': toDate,
        },
        options: Options(receiveTimeout: const Duration(seconds: 30)),
        cancelToken: cancelToken,
      );
      final body = resp.data as Map<String, dynamic>;
      if (body['success'] == true) {
        return TreeChildrenResult(
          leaves: (body['data'] as List? ?? [])
              .map((e) => AccountLeafModel.fromJson(e as Map<String, dynamic>))
              .toList(),
          total: _asInt(body['meta']?['total']),
          page: _asInt(body['meta']?['page'], fallback: page),
          limit: _asInt(body['meta']?['limit'], fallback: limit),
          totalPages: _asInt(body['meta']?['total_pages']),
          hasMore: body['meta']?['has_more'] == true,
        );
      }
      return TreeChildrenResult.empty(page: page, limit: limit);
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        return TreeChildrenResult.empty(page: page, limit: limit);
      }
      rethrow;
    }
  }

  /// بحث خادمي شامل في كل المستويات مع مسار الأب — لأداة بحث الشجرة.
  /// Server-side deep search across every level, with the parent path of each hit.
  Future<List<AccountTreeNode>> searchAccounts(
    String query, {
    int limit = 100,
    CancelToken? cancelToken,
  }) async {
    if (query.trim().isEmpty) return [];
    try {
      final resp = await client.dio.get(
        '/accounts/search',
        queryParameters: {'q': query.trim(), 'limit': limit},
        options: Options(receiveTimeout: const Duration(seconds: 30)),
        cancelToken: cancelToken,
      );
      final body = resp.data as Map<String, dynamic>;
      if (body['success'] == true) {
        return (body['data'] as List? ?? [])
            .map((e) => AccountTreeNode.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) return [];
      rethrow;
    }
  }

  /// تصدير الشجرة مسطّحة من الخادم، بكل المستويات التي اختارها المستخدم.
  /// Server-side flat export of the tree for the chosen levels.
  ///
  /// لماذا لا يُستعمل ما على الشاشة؟ الشجرة كسولة: الحسابات المالية تُجلب صفحة-بصفحة
  /// عند التوسيع فقط، فأي بناء من حالة الشاشة يطبع الأجزاء التي فتحها المستخدم وحده.
  /// المطبوعة يجب أن تُطلب من القاعدة لا من موضع التمرير.
  ///
  /// A long receive timeout is deliberate: `include_customers` asks for 20k+ ledger
  /// rows, which the 15 s default would cut off mid-download.
  Future<List<TreeExportRow>> fetchTreeExport(
    TreeExportScope scope, {
    CancelToken? cancelToken,
  }) async {
    try {
      final resp = await client.dio.get(
        '/accounts/export-tree',
        queryParameters: scope.toQuery(),
        options: Options(receiveTimeout: const Duration(seconds: 90)),
        cancelToken: cancelToken,
      );
      final body = resp.data as Map<String, dynamic>;
      if (body['success'] == true) {
        return (body['data'] as List? ?? [])
            .map((e) => TreeExportRow.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) return [];
      rethrow;
    }
  }

  /// دليل العملات لحقل العملة في نموذج الحساب.
  /// Currency directory for the account form's picker.
  ///
  /// المسار `/accounts/currencies` لا `/currencies`: الأخير خلف `currencies.view`،
  /// ومستخدمٌ بصلاحية `accounts.create` فقط لن يحصل عليه — فيظهر الحقل فارغاً مع أن
  /// النموذج يطلب منه الاختيار.
  Future<List<CurrencyOptionModel>> fetchCurrencyOptions({
    CancelToken? cancelToken,
  }) async {
    try {
      final resp = await client.dio.get(
        '/accounts/currencies',
        cancelToken: cancelToken,
      );
      final body = resp.data as Map<String, dynamic>;
      if (body['success'] == true) {
        return (body['data'] as List? ?? [])
            .map((e) => CurrencyOptionModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) return [];
      rethrow;
    }
  }

  /// نقطة بيانات مفردة لحساب مالي — لملء شاشة التعديل وورقة التفاصيل.
  /// Single ledger account: full CHART_ACC row + computed balance + parent chain.
  Future<Map<String, dynamic>?> fetchChartAccountDetail(
    int accNo, {
    CancelToken? cancelToken,
  }) async {
    try {
      final resp = await client.dio.get('/accounts/chart/$accNo', cancelToken: cancelToken);
      final body = resp.data as Map<String, dynamic>;
      if (body['success'] == true && body['data'] is Map) {
        return Map<String, dynamic>.from(body['data'] as Map);
      }
      return null;
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) return null;
      rethrow;
    }
  }

  /// معاينة الرقم الذي سيُمنح للعقدة الجديدة — يُحسب في الخادم بقواعد create*
  /// نفسها، فأي محاولة لإعادة اشتقاقه في Dart تنسخ قاعدة تراثية وتخطئ بها.
  /// Number preview: derived by the server's create* rules. Re-deriving it in Dart
  /// would duplicate a legacy numbering rule and drift from reality.
  /// [curNo] إلزامي لمستوى chart: الخانة الرابعة من رقم الحساب المالي هي رقمها، فلا
  /// رقم صحيح دون معرفة العملة أولاً / the chart level cannot preview a number
  /// without the currency, because that 4th digit *is* the currency.
  Future<int?> fetchNextNumber({
    required String level,
    int? groupId,
    int? accPart,
    int? accSub,
    int? accNo,
    int? curNo,
    CancelToken? cancelToken,
  }) async {
    try {
      final resp = await client.dio.get(
        '/accounts/next-number',
        queryParameters: {
          'level': level,
          if (groupId != null) 'group_id': groupId,
          if (accPart != null) 'acc_part': accPart,
          if (accSub != null) 'acc_sub': accSub,
          if (accNo != null) 'acc_no': accNo,
          if (curNo != null) 'cur_no': curNo,
        },
        cancelToken: cancelToken,
      );
      final body = resp.data as Map<String, dynamic>;
      if (body['success'] != true || body['data'] is! Map) return null;
      final data = body['data'] as Map;
      return _asInt(data['number'] ?? data['NUMBER']);
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) return null;
      return null;
    }
  }

  // ============================================================
  // نقاط الهيكل الإنشائية (ACC_MAIN / ACC_SUB) — خلف accounts.structure_manage
  // Structural nodes: creating a branch or a part reshapes the tree, not its rows.
  // ============================================================

  /// إنشاء حساب فرعي (ACC_MAIN) داخل قسم رئيسي.
  Future<AccountResult> createAccMain({
    required int accNo,
    required String subName,
    double? balance,
    int? curNo,
  }) async {
    return _postStructure('/accounts/main', {
      'acc_no': accNo,
      'sub_name': subName,
      if (balance != null) 'balance': balance,
      if (curNo != null) 'cur_no': curNo,
    });
  }

  /// تعديل حساب فرعي (ACC_MAIN).
  Future<AccountResult> updateAccMain(int accSub, Map<String, dynamic> data) async {
    return _putStructure('/accounts/main/$accSub', data);
  }

  /// إنشاء حساب جزئي (ACC_SUB) داخل حساب فرعي.
  Future<AccountResult> createAccSub({
    required int accSub,
    required String partName,
    double? balance,
    int? curNo,
  }) async {
    return _postStructure('/accounts/sub', {
      'acc_sub': accSub,
      'part_name': partName,
      if (balance != null) 'balance': balance,
      if (curNo != null) 'cur_no': curNo,
    });
  }

  /// تعديل حساب جزئي (ACC_SUB).
  Future<AccountResult> updateAccSub(int accPart, Map<String, dynamic> data) async {
    return _putStructure('/accounts/sub/$accPart', data);
  }

  /// تعديل قسم رئيسي (ACCOUNT): الاسم / الرصيد الافتتاحي / العملة.
  Future<AccountResult> updateAccount(int accNo, Map<String, dynamic> data) async {
    return _putStructure('/accounts/account/$accNo', data);
  }

  Future<AccountResult> _postStructure(String path, Map<String, dynamic> data) async {
    try {
      final resp = await client.dio.post(path, data: data);
      final body = resp.data as Map<String, dynamic>;
      return _structureResult(body);
    } catch (e) {
      return AccountResult(success: false, message: _structureError(e));
    }
  }

  Future<AccountResult> _putStructure(String path, Map<String, dynamic> data) async {
    try {
      final resp = await client.dio.put(path, data: data);
      final body = resp.data as Map<String, dynamic>;
      return _structureResult(body);
    } catch (e) {
      return AccountResult(success: false, message: _structureError(e));
    }
  }

  AccountResult _structureResult(Map<String, dynamic> body) => AccountResult(
    success: body['success'] == true,
    message: body['message']?.toString() ?? '',
    data: body['data'],
  );

  /// رسالة الخطأ كما كتبها الخادم إن وُجدت — الـ 422 يحمل سبب الرفض بالعربية.
  /// Prefer the server's own message: validation refusals are already in Arabic.
  String _structureError(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] is String) {
        final msg = data['message'] as String;
        if (msg.isNotEmpty) return msg;
      }
    }
    return 'خطأ: ${e.toString()}';
  }

  // ============================================================
  // الحسابات المالية (CHART_ACC)
  // ============================================================

  /// جلب الحسابات المالية مع بحث وترقيم
  Future<Map<String, dynamic>> fetchChartAccounts({
    String search = '',
    int page = 1,
    int limit = 50,
    int? groupId,
    CancelToken? cancelToken,
  }) async {
    try {
      final resp = await client.dio.get(
        '/accounts/chart',
        queryParameters: {
          if (search.isNotEmpty) 'search': search,
          'page': page,
          'limit': limit,
          if (groupId != null) 'group_id': groupId,
        },
        cancelToken: cancelToken,
      );
      final body = resp.data as Map<String, dynamic>;
      if (body['success'] == true) {
        final list =
            (body['data'] as List? ?? [])
                .map(
                  (e) => ChartAccountModel.fromJson(e as Map<String, dynamic>),
                )
                .toList();
        return {
          'data': list,
          'meta': body['meta'] as Map<String, dynamic>? ?? {},
        };
      }
      return {'data': [], 'meta': {}};
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        return {'data': [], 'meta': {}};
      }
      rethrow;
    }
  }

  /// إنشاء حساب مالي جديد (مجموعة حسابات جزئي)
  Future<AccountResult> createSubGroup({
    required String name,
    required int accPart,
  }) async {
    try {
      final resp = await client.dio.post(
        '/accounts/sub-group',
        data: {'acc_group_name': name, 'acc_part': accPart},
      );
      final body = resp.data as Map<String, dynamic>;
      return AccountResult(
        success: body['success'] == true,
        message: body['message']?.toString() ?? '',
        data: body['data'],
      );
    } catch (e) {
      return AccountResult(success: false, message: 'خطأ: ${e.toString()}');
    }
  }

  /// إنشاء حساب مالي (CHART_ACC) داخل مجموعة أو مباشرة تحت حساب جزئي.
  /// A ledger account under a group, or directly under a part when [accPart] is used
  /// without [groupId]. The server numbers the account inside a (part, currency) band:
  /// رقم الحساب = الجزء (3 خانات) + العملة (خانة واحدة) + التسلسل.
  /// [curNo] إلزامي — لا عمود عملة في CHART_ACC، فالخانة الرابعة من الرقم هي العملة.
  Future<AccountResult> createChartAccount({
    required String name,
    required int curNo,
    int? groupId,
    int? accPart,
    double? balance,
    double? limitedBalance,
    int? stoppingAcc,
    int? seq,
    String? accDate,
  }) async {
    try {
      final resp = await client.dio.post(
        '/accounts/chart',
        data: {
          'acc_name': name,
          'cur_no': curNo,
          if (groupId != null) 'group_id': groupId,
          if (accPart != null) 'acc_part': accPart,
          if (balance != null) 'balance': balance,
          if (limitedBalance != null) 'limited_balance': limitedBalance,
          if (stoppingAcc != null) 'stopping_acc': stoppingAcc,
          if (seq != null) 'seq': seq,
          if (accDate != null) 'acc_date': accDate,
        },
      );
      final body = resp.data as Map<String, dynamic>;
      return AccountResult(
        success: body['success'] == true,
        message: body['message']?.toString() ?? '',
        data: body['data'],
      );
    } catch (e) {
      return AccountResult(success: false, message: _structureError(e));
    }
  }

  /// تعديل حساب مالي
  Future<AccountResult> updateChartAccount(
    int accNo,
    Map<String, dynamic> data,
  ) async {
    try {
      final resp = await client.dio.put('/accounts/chart/$accNo', data: data);
      final body = resp.data as Map<String, dynamic>;
      return AccountResult(
        success: body['success'] == true,
        message: body['message']?.toString() ?? '',
      );
    } catch (e) {
      return AccountResult(success: false, message: 'خطأ: ${e.toString()}');
    }
  }

  /// كشف حساب مالي
  ///
  /// لا يُرسل `limit` إطلاقاً ما لم يُطلب صراحةً: الخادم يعيد **كل حركات الفترة**
  /// عند غيابه. كان هنا `limit: 50` ثابتاً فكان الكشف يعرض 50 سطراً فقط ويبدو
  /// كأن فلتر الفترة مُتجاهَل — وهو العطل الذي أُصلح.
  /// `limit` is omitted unless a caller pages explicitly, so the server returns every
  /// movement of the period. The previous hardcoded `limit: 50` truncated the statement.
  Future<AccountStatementData> fetchAccountStatement(
    int accNo, {
    String? fromDate,
    String? toDate,
    int? page,
    int? limit,
    CancelToken? cancelToken,
  }) async {
    try {
      final resp = await client.dio.get(
        '/accounts/chart/$accNo/statement',
        queryParameters: {
          if (fromDate != null) 'from_date': fromDate,
          if (toDate != null) 'to_date': toDate,
          if (page != null) 'page': page,
          if (limit != null) 'limit': limit,
        },
        cancelToken: cancelToken,
      );
      final body = resp.data as Map<String, dynamic>;
      if (body['success'] == true) {
        return AccountStatementData.fromJson(body);
      }
      return const AccountStatementData();
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        return const AccountStatementData();
      }
      rethrow;
    }
  }

  /// كشف حساب مفصل
  Future<Map<String, dynamic>> fetchDetailedStatement({
    required String type,
    String? id,
    String? fromDate,
    String? toDate,
    int? curNo,
    CancelToken? cancelToken,
  }) async {
    try {
      final resp = await client.dio.get(
        '/accounts/statement-detail',
        queryParameters: {
          'type': type,
          if (id != null) 'id': id,
          if (fromDate != null) 'from_date': fromDate,
          if (toDate != null) 'to_date': toDate,
          if (curNo != null) 'cur_no': curNo,
        },
        cancelToken: cancelToken,
      );
      final body = resp.data as Map<String, dynamic>;
      return body;
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) return {};
      rethrow;
    }
  }

  /// كشف حساب مجموعة حسابات جزئية (ميزان المراجعة)
  /// GET /accounts/group-statement — same try/cancel-token/error pattern as the
  /// adjacent statement/detail methods above; scope params are all optional and
  /// the server resolves the deepest one present (see AccountController::getGroupStatement).
  ///
  /// الترقيم إجباري في الواجهة: النطاق الواحد قد يمتد لعشرين ألف حساب، وجلبها
  /// دفعة واحدة كان يُفرّغ ذاكرة الجهاز. `limit` سقفه 2000 في الخادم، و`null`
  /// تعني «بلا ترقيم» (كل الصفوف) وهي مخصصة للتصدير الكامل فقط.
  /// `limit` null = no pagination at all (the full-export path only); the server
  /// caps a positive limit at 2000 rows. `includeTotals` is set once, on page 1.
  Future<TrialBalanceReport> fetchGroupStatement({
    int? accNo,
    int? accSub,
    int? accPart,
    int? groupId,
    String? fromDate,
    String? toDate,
    int? page,
    int? limit,
    bool includeTotals = true,
    CancelToken? cancelToken,
  }) async {
    try {
      final resp = await client.dio.get(
        '/accounts/group-statement',
        queryParameters: {
          if (accNo != null) 'acc_no': accNo,
          if (accSub != null) 'acc_sub': accSub,
          if (accPart != null) 'acc_part': accPart,
          if (groupId != null) 'group_id': groupId,
          if (fromDate != null) 'from_date': fromDate,
          if (toDate != null) 'to_date': toDate,
          if (page != null) 'page': page,
          if (limit != null) 'limit': limit,
          'include_totals': includeTotals ? 1 : 0,
        },
        cancelToken: cancelToken,
      );
      final body = resp.data as Map<String, dynamic>;
      if (body['success'] == true) {
        return TrialBalanceReport.fromJson(body);
      }
      return TrialBalanceReport.empty;
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        return TrialBalanceReport.empty;
      }
      rethrow;
    }
  }
}

// ================================================================
// صفحة أبناء لعقدة هيكلية — النتيجة مع معلومات الترقيم
// One page of lazy children, with the pagination meta the server returned.
// ================================================================
class TreeChildrenResult {
  final List<AccountLeafModel> leaves;
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final bool hasMore;

  const TreeChildrenResult({
    required this.leaves,
    this.total = 0,
    this.page = 1,
    this.limit = 50,
    this.totalPages = 0,
    this.hasMore = false,
  });

  factory TreeChildrenResult.empty({int page = 1, int limit = 50}) =>
      TreeChildrenResult(leaves: const [], page: page, limit: limit);
}

int _asInt(dynamic v, {int fallback = 0}) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? fallback;
}
