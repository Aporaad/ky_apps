import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/app_user_model.dart';
import '../providers/admin_users_provider.dart';

/// شاشة اختيار مستخدم — تُرجع `AppUserModel` أو null
/// A user picker — returns an AppUserModel or null.
///
/// لماذا بحث خاص به لا `adminUsersProvider`؟ لأن المنتقي يُفتح فوق نموذجٍ أو شاشة منح، ولو شارك
/// حالة القائمة لغيّرت كل ضغطة بحث في المنتقي فلاتر الشاشة الأصلية وترتيبها وصفحتها. الحالة
/// هنا عابرة وتُلقى مع الشاشة.
/// Why its own search rather than adminUsersProvider: the picker opens on top of a form or the
/// grant screen, and sharing the list state would mean every keystroke here rewrote the other
/// screen's filters, sort, and page. This state is transient and dies with the screen.
class UserPickerScreen extends ConsumerStatefulWidget {
  final String title;
  final String subtitle;

  /// استبعاد المستخدم الحالي — شاشات المنح لا تختاره هدفاً بالخطأ
  /// Exclude a user — grant screens must not pick the wrong target by accident.
  final int? excludeUserId;

  const UserPickerScreen({
    required this.title,
    required this.subtitle,
    this.excludeUserId,
    super.key,
  });

  @override
  ConsumerState<UserPickerScreen> createState() => _UserPickerScreenState();
}

class _UserPickerScreenState extends ConsumerState<UserPickerScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final List<AppUserModel> _results = [];
  CancelToken? _cancelToken;
  Timer? _debounce;
  bool _isLoading = false;
  String? _error;

  /// حارس التسابق: الرد المتأخر لبحثٍ مُلغي كان سيدسّ نتائج قديمة فوق الجديدة
  /// Race guard: a late reply to a cancelled search would land older results on top.
  int _version = 0;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _cancelToken?.cancel('picker-closed');
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) _search(query.trim());
    });
  }

  Future<void> _search(String query) async {
    final version = ++_version;
    _cancelToken?.cancel('superseded');
    final token = CancelToken();
    _cancelToken = token;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(adminUserRepositoryProvider);
      final result = await repo.fetchUsers(
        search: query,
        page: 1,
        limit: 50,
        cancelToken: token,
      );
      if (version != _version || !mounted) return;

      setState(() {
        _results
          ..clear()
          ..addAll(
            result.items.where(
              (user) => user.userId != widget.excludeUserId,
            ),
          );
        _isLoading = false;
      });
    } on DioException catch (e) {
      if (CancelToken.isCancel(e) || version != _version || !mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'تعذّر البحث: ${e.message ?? e.type.name}';
      });
    } catch (e) {
      if (version != _version || !mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'تعذّر البحث: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              widget.subtitle,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              style: const TextStyle(fontSize: 14),
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'ابحث بالاسم أو رقم المستخدم…',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _debounce?.cancel();
                          _searchCtrl.clear();
                          _search('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surfaceSubtle,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 12),
            Text('جارٍ البحث…', style: TextStyle(color: AppColors.textMuted)),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 44, color: AppColors.error),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () => _search(_searchCtrl.text.trim()),
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

    if (_results.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_search_rounded, size: 50, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text(
              'لا يوجد مستخدم مطابق',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final user = _results[i];

        return InkWell(
          onTap: () => Navigator.pop(context, user),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: (user.isActivated ? AppColors.primary : AppColors.error)
                        .withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${user.userId}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: user.isActivated
                            ? AppColors.primary
                            : AppColors.error,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${user.userTypeLabel} · ${user.branchLabel} · صلاحيات ${user.grantsCount}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (!user.isActivated)
                  const _PickerBadge(label: 'معطّل', color: AppColors.error),
                const SizedBox(width: 6),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// شارة صغيرة في صف الاختيار
/// A small badge on a picker row.
class _PickerBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _PickerBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
