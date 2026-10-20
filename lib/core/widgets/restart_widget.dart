import 'package:flutter/material.dart';

import '../../routing/app_router.dart';

/// ودجت إعادة تشغيل التطبيق — يعيد تركيب الشجرة كاملة لتطبيق ألوان/خط جديد
/// Application restart widget — rebuilds the entire tree to apply new colors/font.
///
/// تُدعى `RestartWidget.restart()` بعد حفظ الألوان أو الخط: تُعاد تهيئة `AppPalette`
/// من أحدث تهيئة، ويُبني مفتاح جديد لأسفل الشجرة (فيُعاد إنشاء `ProviderScope` وكل
/// الشاشات)، ويُوجَّه الـ GoRouter إلى `/splash` لبدء نظيف. الاسم/الشعار لا يحتاجان هذا
/// (ينعكسان فوراً)، بينما الألوان والخط يحتاجان إعادة تشغيل لتفادي الانقلاب أثناء الجلسة.
/// `restart()` is called after saving colors/font: it re-seeds [AppPalette] from the latest
/// config, rebuilds the subtree under a fresh key (recreating `ProviderScope` and every
/// screen), and routes the GoRouter to `/splash`. Name/logo do not need it (instant);
/// colors and font do, to avoid mid-session jank.
class RestartWidget extends StatefulWidget {
  const RestartWidget({super.key, required this.child});

  final Widget child;

  /// نسخة الحالة الحيّة الوحيدة — تسمح بإعادة التشغيل من أي مكان دون سياق
  /// The single live state instance — enables restarting from anywhere without a context.
  static _RestartWidgetState? _instance;

  /// إعادة تشغيل التطبيق: تهيئة اللوحة + بناء جديد للشجرة + التوجيه إلى /splash
  /// Restart: re-seed the palette, rebuild the tree, and route to `/splash`.
  static void restart(VoidCallback reseedPalette) {
    reseedPalette();
    appRouter.go('/splash');
    _instance?._restartApp();
  }

  @override
  State<RestartWidget> createState() => _RestartWidgetState();
}

class _RestartWidgetState extends State<RestartWidget> {
  Key _treeKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    RestartWidget._instance = this;
  }

  @override
  void dispose() {
    if (RestartWidget._instance == this) RestartWidget._instance = null;
    super.dispose();
  }

  void _restartApp() {
    setState(() => _treeKey = UniqueKey());
  }

  @override
  Widget build(BuildContext context) {
    // مفتاح متغيّر أسفل الشجرة = إعادة تركيب كاملة لكل ما بداخله
    // A changing key below the subtree forces a full remount of everything inside it.
    return KeyedSubtree(key: _treeKey, child: widget.child);
  }
}
