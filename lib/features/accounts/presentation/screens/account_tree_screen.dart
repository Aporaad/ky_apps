import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/account_model.dart';
import '../providers/accounts_provider.dart';
import 'create_account_screen.dart';
import 'edit_account_screen.dart';

/// شاشة الشجرة المحاسبية المحترفة - تصميم عصري، منظم ومتناسق
/// تعرض حسابات الشجرة مرتبة ومنظمة مع استثناء العملاء ما عدا "عملاء الكبودي للخياطة" (12310000)
class AccountTreeScreen extends ConsumerStatefulWidget {
  const AccountTreeScreen({super.key});

  @override
  ConsumerState<AccountTreeScreen> createState() => _AccountTreeScreenState();
}

class _AccountTreeScreenState extends ConsumerState<AccountTreeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<String> _expandedNodes = {};
  bool _expandAll = false;

  /// رقم الحساب الموحد للعملاء المسموح بظهوره فقط
  static const String allowedCustomerAccNo = '12310000';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// فلترة شجرة الحسابات واستثناء العملاء ما عدا الكبودي للخياطة
  List<AccountTreeNode> _filterTree(List<AccountTreeNode> nodes) {
    List<AccountTreeNode> filtered = [];
    for (var node in nodes) {
      final processedNode = _filterNode(node);
      if (processedNode != null) {
        filtered.add(processedNode);
      }
    }
    return filtered;
  }

  AccountTreeNode? _filterNode(AccountTreeNode node) {
    final nodeName = node.name.toLowerCase();
    final accNoStr = node.accNo?.toString() ?? '';

    bool isCustomerGroup =
        nodeName.contains('عملاء') || nodeName.contains('العملاء');
    if (isCustomerGroup) {
      if (accNoStr != allowedCustomerAccNo && !nodeName.contains('الكبودي')) {
        List<AccountTreeNode> keptChildren = [];
        for (var child in node.children) {
          final c = _filterNode(child);
          if (c != null) keptChildren.add(c);
        }
        if (keptChildren.isEmpty) return null;
        return AccountTreeNode(
          id: node.id,
          name: node.name,
          level: node.level,
          accNo: node.accNo,
          accSub: node.accSub,
          accPart: node.accPart,
          groupId: node.groupId,
          balance: node.balance,
          isStoppped: node.isStoppped,
          children: keptChildren,
        );
      }
    }

    List<AccountTreeNode> filteredChildren = [];
    for (var child in node.children) {
      final c = _filterNode(child);
      if (c != null) filteredChildren.add(c);
    }

    final filteredNode = AccountTreeNode(
      id: node.id,
      name: node.name,
      level: node.level,
      accNo: node.accNo,
      accSub: node.accSub,
      accPart: node.accPart,
      groupId: node.groupId,
      balance: node.balance,
      isStoppped: node.isStoppped,
      children: filteredChildren,
    );

    if (_searchQuery.isNotEmpty) {
      return filteredNode.matchesSearch(_searchQuery)
          ? filteredNode.filterBySearch(_searchQuery)
          : null;
    }

    return filteredNode;
  }

  void _toggleExpand(String id) {
    setState(() {
      if (_expandedNodes.contains(id)) {
        _expandedNodes.remove(id);
      } else {
        _expandedNodes.add(id);
      }
    });
  }

  void _toggleExpandAll(List<AccountTreeNode> nodes) {
    setState(() {
      _expandAll = !_expandAll;
      if (_expandAll) {
        _collectAllIds(nodes);
      } else {
        _expandedNodes.clear();
      }
    });
  }

  void _collectAllIds(List<AccountTreeNode> nodes) {
    for (var node in nodes) {
      _expandedNodes.add(node.id);
      _collectAllIds(node.children);
    }
  }

  @override
  Widget build(BuildContext context) {
    final treeState = ref.watch(accountTreeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'الشجرة المحاسبية',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: Icon(
              _expandAll ? Icons.unfold_less_rounded : Icons.unfold_more_rounded,
              size: 20,
            ),
            tooltip: _expandAll ? 'طي الكل' : 'توسيع الكل',
            onPressed: () {
              if (treeState.tree.isNotEmpty) {
                _toggleExpandAll(_filterTree(treeState.tree));
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: 'تحديث الشجرة',
            onPressed: () => ref.read(accountTreeProvider.notifier).loadTree(),
          ),
        ],
      ),
      body: Column(
        children: [
          // لوحة البحث والتنبيه المصغرة
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: AppColors.surface,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'بحث في الشجرة برقم الحساب أو الاسم...',
                    hintStyle: const TextStyle(fontSize: 12.5),
                    prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textMuted),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: AppColors.border.withValues(alpha: 0.6),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: AppColors.border.withValues(alpha: 0.6),
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 14, color: AppColors.primary),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'تخصيص: تم استثناء العملاء ما عدا "عملاء الكبودي للخياطة" (12310000)',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // محتوى الشجرة
          Expanded(
            child: treeState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : treeState.error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                size: 40,
                                color: AppColors.error,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'حدث خطأ أثناء تحميل الشجرة:\n${treeState.error}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 14),
                              OutlinedButton.icon(
                                onPressed: () =>
                                    ref.read(accountTreeProvider.notifier).loadTree(),
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('إعادة المحاولة'),
                                style: OutlinedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Builder(
                        builder: (_) {
                          final filteredNodes = _filterTree(treeState.tree);
                          if (filteredNodes.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.account_tree_outlined,
                                    size: 42,
                                    color: AppColors.textMuted.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'لا توجد حسابات مطابقة للبحث',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 80),
                            itemCount: filteredNodes.length,
                            itemBuilder: (context, index) {
                              return _buildTreeNodeWidget(
                                filteredNodes[index],
                                levelDepth: 0,
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateAccountScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        tooltip: 'إضافة حساب جديد',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTreeNodeWidget(
    AccountTreeNode node, {
    required int levelDepth,
  }) {
    final isExpanded =
        _expandedNodes.contains(node.id) || _expandAll || _searchQuery.isNotEmpty;
    final hasChildren = node.children.isNotEmpty;

    Color levelColor;
    IconData levelIcon;
    String levelTitle;

    switch (node.level) {
      case 'account':
        levelColor = const Color(0xFF283593);
        levelIcon = Icons.folder_special_rounded;
        levelTitle = 'رئيسي';
        break;
      case 'main':
        levelColor = const Color(0xFF1565C0);
        levelIcon = Icons.folder_rounded;
        levelTitle = 'فرعي';
        break;
      case 'sub':
        levelColor = const Color(0xFF00796B);
        levelIcon = Icons.snippet_folder_rounded;
        levelTitle = 'جزئي';
        break;
      case 'group':
        levelColor = const Color(0xFFD84315);
        levelIcon = Icons.create_new_folder_rounded;
        levelTitle = 'مجموعة';
        break;
      default: // chart
        levelColor = const Color(0xFF2E7D32);
        levelIcon = Icons.account_balance_wallet_rounded;
        levelTitle = 'مالي';
    }

    // تقييد إزاحة العمق بحيث لا تتجاوز 48 بكسل لمنع انضغاط النصوص في الهواتف الصغيرة
    final safeIndent = (levelDepth.clamp(0, 3) * 12.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 5),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: levelColor.withValues(alpha: 0.18),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.015),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: hasChildren ? () => _toggleExpand(node.id) : null,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: EdgeInsets.only(
                  right: 8.0 + safeIndent,
                  left: 8,
                  top: 8,
                  bottom: 8,
                ),
                child: Row(
                  children: [
                    // زر التوسيع / الطي
                    if (hasChildren)
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_down_rounded
                              : Icons.keyboard_arrow_left_rounded,
                          color: levelColor,
                          size: 20,
                        ),
                      )
                    else
                      const SizedBox(width: 22),
                    const SizedBox(width: 4),

                    // أيقونة نوع الحساب
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: levelColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(levelIcon, color: levelColor, size: 16),
                    ),
                    const SizedBox(width: 8),

                    // الاسم ورقم الحساب
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  node.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: levelColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  levelTitle,
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    color: levelColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (node.isStoppped == true) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'موقف',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: AppColors.error,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (node.accNo != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                'رقم: ${node.accNo}',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // الرصيد وزر التعديل
                    if (node.balance != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        '${node.balance!.toStringAsFixed(2)} ر.ي',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11.5,
                          color: (node.balance ?? 0) >= 0
                              ? const Color(0xFF2E7D32)
                              : AppColors.error,
                        ),
                      ),
                    ],

                    if (node.level == 'chart' && node.accNo != null) ...[
                      const SizedBox(width: 2),
                      InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => EditAccountScreen(
                                accNo: node.accNo!,
                                accName: node.name,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.edit_outlined,
                            size: 15,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),

        // الفروع والأبناء
        if (hasChildren && isExpanded)
          Column(
            children: node.children
                .map((child) =>
                    _buildTreeNodeWidget(child, levelDepth: levelDepth + 1))
                .toList(),
          ),
      ],
    );
  }
}
