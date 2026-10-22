import 'dart:convert';

import '../../../../core/storage/secure_storage_service.dart';
import '../models/home_layout.dart';

/// مستودع تخطيط الرئيسية — تخزين محلي فقط، بلا شبكة
/// Home-layout repository — local storage only, no network.
///
/// لا يُمرَّر إليه `DioClient` إطلاقًا: ميزة الاختصارات تفضيل جهاز، وأي طلب شبكة في هذا المسار
/// يعني إبطاء دخول البوابة مقابل لا شيء.
/// No `DioClient` is passed in: shortcuts are a device preference, and any request on this path
/// would slow the portal's first paint for nothing.
class HomeLayoutRepository {
  HomeLayoutRepository({required SecureStorageService storage})
    : _storage = storage;

  final SecureStorageService _storage;

  /// يقرأ تخطيط المستخدم؛ والبلوب التالف يعني «أول تشغيل» لا استثناء
  /// Reads the user's layout; a corrupt blob means "first run", never an exception.
  Future<HomeLayout> load(int userId) async {
    final raw = await _storage.getHomeLayout();
    if (raw == null || raw.trim().isEmpty) return HomeLayout.firstRun(userId);

    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      // التخزين الآمن قد يُبتر أو يُكتب بإصدار أقدم: الافتراضي أأمن من الانهيار
      // The secure blob can be truncated or written by an older build: defaults beat a crash.
      return HomeLayout.firstRun(userId);
    }

    return HomeLayout.fromJson(decoded, userId: userId);
  }

  Future<void> save(HomeLayout layout) =>
      _storage.saveHomeLayout(jsonEncode(layout.toJson()));

  Future<void> clear() => _storage.deleteHomeLayout();
}
