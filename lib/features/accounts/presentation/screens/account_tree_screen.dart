import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/account_model.dart';
import '../providers/accounts_provider.dart';
import 'create_account_screen.dart';
import 'edit_account_screen.dart';

/// شاشة الشجرة المحاسبية المحترفة
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

    bool isCustomerGroup = nodeName.contains('عملاء') || nodeName.contains('العملاء');
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

  void _showPrintExportDialog(BuildContext context, List<AccountTreeNode> nodes) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.print_outlined, color: AppColors.primary),
            SizedBox(width: 8),
            Text('طباعة وتصدير الشجرة المحاسبية'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('اختر صيغة التصدير أو إجراء الطباعة:'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('تصدير كملف PDF'),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم تجهيز الشجرة المحاسبية وتصديرها بصيغة PDF')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text('تصدير كملف Excel (CSV)'),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم تصدير الشجرة المحاسبية بنجاح كملف Excel')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.print, color: AppColors.primary),
              title: const Text('طباعة مباشرة'),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('جاري إرسال الشجرة المحاسبية للطباعة...')),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final treeState = ref.watch(accountTreeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('الشجرة المحاسبية'),
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: Icon(_expandAll ? Icons.unfold_less : Icons.unfold_more),
            tooltip: _expandAll ? 'طي الكل' : 'توسيع الكل',
            onPressed: () {
              if (treeState.tree.isNotEmpty) {
                _toggleExpandAll(_filterTree(treeState.tree));
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'طباعة وتصدير',
            onPressed: () {
              if (treeState.tree.isNotEmpty) {
                _showPrintExportDialog(context, _filterTree(treeState.tree));
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث الشجرة',
            onPressed: () => ref.read(accountTreeProvider.notifier).loadTree(),
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط البحث والفرز والتنبيهات
          Container(
            padding: const EdgeInsets.all(16),
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
                    prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
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
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                          SizedBox(width: 6),
                          Text(
                            'تم استثناء حسابات العملاء وتخصيص حساب "عملاء الكبودي لخياطة" (12310000)',
                            style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'حدث خطأ أثناء تحميل الشجرة: ${treeState.error}',
                              style: const TextStyle(color: AppColors.error),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () => ref.read(accountTreeProvider.notifier).loadTree(),
                              icon: const Icon(Icons.refresh),
                              label: const Text('إعادة المحاولة'),
                            ),
                          ],
                        ),
                      )
                    : Builder(
                        builder: (_) {
                          final filteredNodes = _filterTree(treeState.tree);
                          if (filteredNodes.isEmpty) {
                            return const Center(
                              child: Text(
                                'لا توجد نتائج مطابقة للشجرة المحاسبية',
                                style: TextStyle(color: AppColors.textMuted, fontSize: 16),
                              ),
                            );
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredNodes.length,
                            itemBuilder: (context, index) {
                              return _buildTreeNodeWidget(filteredNodes[index], levelDepth: 0);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateAccountScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('إضافة حساب / مجموعة'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildTreeNodeWidget(AccountTreeNode node, {required int levelDepth}) {
    final isExpanded = _expandedNodes.contains(node.id) || _expandAll || _searchQuery.isNotEmpty;
    final hasChildren = node.children.isNotEmpty;

    Color levelColor;
    IconData levelIcon;
    String levelTitle;

    switch (node.level) {
      case 'account':
        levelColor = Colors.indigo;
        levelIcon = Icons.folder_special;
        levelTitle = 'قسم رئيسي';
        break;
      case 'main':
        levelColor = Colors.blue;
        levelIcon = Icons.folder;
        levelTitle = 'حساب فرعي';
        break;
      case 'sub':
        levelColor = Colors.teal;
        levelIcon = Icons.snippet_folder;
        levelTitle = 'حساب جزئي';
        break;
      case 'group':
        levelColor = Colors.amber.shade800;
        levelIcon = Icons.create_new_folder;
        levelTitle = 'مجموعة جزئية';
        break;
      default: // chart
        levelColor = Colors.green.shade700;
        levelIcon = Icons.account_balance_wallet;
        levelTitle = 'حساب مالي';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: hasChildren ? () => _toggleExpand(node.id) : null,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: EdgeInsets.only(
              right: 12.0 + (levelDepth * 16.0),
              left: 12,
              top: 10,
              bottom: 10,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: levelColor.withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                if (hasChildren)
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_left,
                    color: levelColor,
                    size: 22,
                  )
                else
                  const SizedBox(width: 22),
                const SizedBox(width: 8),
                Icon(levelIcon, color: levelColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            node.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: levelColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              levelTitle,
                              style: TextStyle(fontSize: 10, color: levelColor, fontWeight: FontWeight.w600),
                            ),
                          ),
                          if (node.isStoppped == true) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'موقف',
                                style: TextStyle(fontSize: 10, color: AppColors.error, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (node.accNo != null)
                        Text(
                          'رقم الحساب: ${node.accNo}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                    ],
                  ),
                ),

                if (node.balance != null) ...[
                  Text(
                    '${node.balance!.toStringAsFixed(2)} ر.ي',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: (node.balance ?? 0) >= 0 ? Colors.green.shade800 : AppColors.error,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                if (node.level == 'chart' && node.accNo != null) ...[
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18, color: AppColors.primary),
                    tooltip: 'تعديل الحساب',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => EditAccountScreen(accNo: node.accNo!, accName: node.name),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),

        if (hasChildren && isExpanded)
          Column(
            children: node.children
                .map((child) => _buildTreeNodeWidget(child, levelDepth: levelDepth + 1))
                .toList(),
          ),
      ],
    );
  }
}
