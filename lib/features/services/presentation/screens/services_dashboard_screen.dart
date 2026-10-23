import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/permission_codes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/permission_gate.dart';
import 'config/service_config_screen.dart';
import 'jobs/jobs_list_screen.dart';
import 'messaging/sms_log_screen.dart';
import 'messaging/whatsapp_log_screen.dart';
import 'providers/providers_list_screen.dart';

/// لوحة قسم «الخدمات والمزودين» — خمس بلاطات، كلٌّ خلف بوابته، تدفع شاشاتها أمرِيًّا
/// The «الخدمات والمزودين» dashboard — five tiles, each behind its own gate, pushing its screen.
///
/// كل بلاطة محروسة بأكواد العرض الخاصة بها لا بأكواد القسم مجتمعة: من يرى الرسائل لا يرى بالضرورة
/// إدارة المهام. البوابة تقرأ نفس المنح التي طبّقها الخادم، فلا تُعرض بلاطة يرفضها الـ API.
/// Each tile is gated by its own view code, not the union: seeing messages does not imply seeing
/// job control. The gate reads the very grants the API enforces, so a tile is never shown that 403s.
class ServicesDashboardScreen extends ConsumerWidget {
  const ServicesDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tiles = <_ServiceTile>[
      _ServiceTile(
        title: 'المزودون',
        subtitle: 'موفرو الخدمات واشتراكاتهم وبيانات الدخول',
        icon: Icons.local_shipping_outlined,
        color: const Color(0xFF2563EB),
        code: Perm.providersView,
        push: () => const ProvidersListScreen(),
      ),
      _ServiceTile(
        title: 'الرسائل النصية',
        subtitle: 'سجل طابور وأرشفة رسائل SMS',
        icon: Icons.sms_outlined,
        color: const Color(0xFF7C3AED),
        code: Perm.smsView,
        push: () => const SmsLogScreen(),
      ),
      _ServiceTile(
        title: 'رسائل واتساب',
        subtitle: 'سجل رسائل واتساب والملفات المرفقة',
        icon: Icons.whatshot_outlined,
        color: const Color(0xFF10B981),
        code: Perm.whatsappView,
        push: () => const WhatsappLogScreen(),
      ),
      _ServiceTile(
        title: 'إعدادات الخدمات',
        subtitle: 'بيانات الشركة (CORP) وقاموس الخدمات',
        icon: Icons.tune_outlined,
        color: const Color(0xFFD97706),
        code: Perm.servicesView,
        push: () => const ServiceConfigScreen(),
      ),
      _ServiceTile(
        title: 'المهام الزمنية',
        subtitle: 'مهام DBMS_SCHEDULER وسجل تشغيلها',
        icon: Icons.schedule_outlined,
        color: const Color(0xFFEF4444),
        code: Perm.jobsView,
        push: () => const JobsListScreen(),
      ),
    ];

    final visible = tiles.where((t) => ref.can(t.code)).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'الخدمات والمزودين',
        ),
      ),
      body: visible.isEmpty
          ? const _NoAccess()
          : LayoutBuilder(
              builder: (context, constraints) {
                // أعمدة متجاوبة + ارتفاع ثابت محسوب لكل بلاطة، فلا تجاوز للمساحة مهما طال النص.
                // Responsive columns with a computed fixed tile height — text can never overflow.
                final width = constraints.maxWidth;
                final columns = width >= 720
                    ? 3
                    : width >= 460
                        ? 2
                        : 1;
                const gap = 12.0;
                const pad = 16.0;
                const tileHeight = 84.0;
                final cellWidth =
                    (width - 2 * pad - gap * (columns - 1)) / columns;
                return GridView.builder(
                  padding: const EdgeInsets.all(pad),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: gap,
                    mainAxisSpacing: gap,
                    childAspectRatio: cellWidth / tileHeight,
                  ),
                  itemCount: visible.length,
                  itemBuilder: (_, i) => _TileWidget(tile: visible[i]),
                );
              },
            ),
    );
  }
}

/// بلاطة خدمة واحدة مع بياناتها
/// A single service tile with its metadata.
class _ServiceTile {
  const _ServiceTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.code,
    required this.push,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String code;
  final Widget Function() push;
}

class _TileWidget extends StatelessWidget {
  const _TileWidget({required this.tile});

  final _ServiceTile tile;

  @override
  Widget build(BuildContext context) {
    // البوابة تحرس الدخول؛ وإن غُيّرت المنح أثناء الجلسة تختفي البلاطة عند أول إعادة رسم
    // The gate guards entry; if grants change mid-session the tile disappears on the next rebuild.
    return PermissionGate(
      code: tile.code,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => tile.push()),
          ),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            // تخطيط أفقي مدمج: أيقونة + نص + سهم — ارتفاع ثابت يمنع أي تجاوز.
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: tile.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(tile.icon, color: tile.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tile.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        tile.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_left_rounded,
                    size: 20, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NoAccess extends StatelessWidget {
  const _NoAccess();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.lock_outline_rounded, size: 56, color: AppColors.textMuted),
            SizedBox(height: 14),
            Text(
              'لا توجد لديك صلاحيات عرض أي جزء من هذا القسم',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
