import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../app_config/data/models/app_config_model.dart';
import '../../../app_config/presentation/providers/app_config_notifier.dart';
import '../utils/external_links.dart';
import 'app_info_card.dart';

/// قسم «معلومات الشركة» — بطاقة هوية رسمية: الاسم والعنوان والموقع والتواصل ونبذة الخدمات
/// The "company information" section — an official identity card carrying the name, address,
/// website, contact details, and the services brief.
///
/// كل القيم تُقرأ من `appConfigNotifierProvider`، وهي حالة `GET /app-config` العامة التي تُغذّى
/// من `APP_SETTINGS` في قاعدة البيانات: تصل من الكاش فوراً ثم تُزامَن من الخادم، ويعمل القسم قبل
/// الدخول أيضاً. لا نص مكتوب في الواجهة — لوحة الإدارة وحدها تُغيّر ما يظهر هنا.
/// Every value comes from `appConfigNotifierProvider`, the public `GET /app-config` state backed by
/// the `APP_SETTINGS` table: it arrives from cache instantly, then re-syncs from the server, and it
/// works before login too. No wording is hardcoded in the UI — the admin screen alone changes what
/// appears here.
class CompanyInfoSection extends ConsumerWidget {
  const CompanyInfoSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appConfigNotifierProvider);

    return AppInfoCard(
      title: 'معلومات الشركة',
      icon: Icons.storefront_rounded,
      action: IconButton(
        onPressed: state.loading
            ? null
            : () => ref.read(appConfigNotifierProvider.notifier).refreshFromServer(),
        icon: const Icon(Icons.refresh_rounded, size: 20),
        color: AppColors.textSecondary,
        tooltip: 'تحديث بيانات الشركة',
        visualDensity: VisualDensity.compact,
      ),
      child: state.loading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          : _CompanyDetails(data: _CompanyData.from(state.config)),
    );
  }
}

/// بيانات البطاقة بعد التطبيع — كل حقل مرة واحدة، بلا تكرار ولا مسافات زائدة
/// The card's data, normalised: each field once, trimmed, with no duplication.
class _CompanyData {
  const _CompanyData({
    required this.name,
    required this.nameEn,
    required this.address,
    required this.addressEn,
    required this.website,
    required this.phone,
    required this.services,
  });

  factory _CompanyData.from(AppConfigModel config) {
    return _CompanyData(
      name: config.companyName.trim(),
      nameEn: config.companyNameEn.trim(),
      address: config.companyAddress.trim(),
      addressEn: config.companyAddressEn.trim(),
      website: config.companyWebsite.trim(),
      phone: config.companyPhone.trim(),
      services: config.companyServices.trim(),
    );
  }

  final String name;
  final String nameEn;
  final String address;
  final String addressEn;
  final String website;
  final String phone;
  final String services;

  /// هل في البطاقة ما يُعرض أصلاً؟
  /// Is there anything to show at all?
  bool get isEmpty =>
      name.isEmpty &&
      nameEn.isEmpty &&
      address.isEmpty &&
      website.isEmpty &&
      phone.isEmpty &&
      services.isEmpty;
}

/// محتوى البطاقة: كتلة الهوية ثم شبكة البيانات ثم نبذة الخدمات
/// The card body: the identity block, then the details grid, then the services brief.
class _CompanyDetails extends StatelessWidget {
  const _CompanyDetails({required this.data});

  final _CompanyData data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const _CompanyEmptyState();

    // نبني البطاقات مرة واحدة ثم نقرّر: بلا بيانات تواصل لا تُرسم الشبكة أصلاً
    // Build the tiles once, then decide: with no contact data the grid is never laid out.
    final tiles = _tiles(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _identity(),
        if (tiles.isNotEmpty) ...[
          const SizedBox(height: 12),
          _grid(context, tiles),
        ],
        if (data.services.isNotEmpty) ...[
          const SizedBox(height: 12),
          _ServicesPanel(text: data.services),
        ],
      ],
    );
  }

  /// كتلة الهوية: الاسم العربي يتصدّر، والإنجليزي تحته بخط لاتيني باهت — كترويسة مطبوعة
  /// The identity block: the Arabic name leads, the Latin variant sits beneath it in muted type —
  /// the arrangement of a printed letterhead.
  Widget _identity() {
    if (data.name.isEmpty && data.nameEn.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      // الشريط العمودي على جهة البداية (اليمين في RTL) — علامة ترويسة لا زخرفة
      // A vertical rule on the leading edge (the right in RTL) — a letterhead mark, not ornament.
      padding: const EdgeInsetsDirectional.only(start: 11),
      decoration: BoxDecoration(
        border: BorderDirectional(
          start: BorderSide(color: AppColors.primary, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data.name.isNotEmpty)
            Text(
              data.name,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                height: 1.35,
                color: AppColors.textPrimary,
              ),
            ),
          if (data.nameEn.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              data.nameEn,
              textDirection: TextDirection.ltr,
              style: TextStyle(
                fontSize: 10.5,
                letterSpacing: 0.4,
                height: 1.4,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// بطاقات البيانات الظاهرة فقط — الحقل الفارغ لا يترك بطاقة صامتة
  /// Only the tiles that carry a value; an empty field never leaves a blank tile behind.
  List<Widget> _tiles(BuildContext context) {
    return [
      if (data.address.isNotEmpty)
        _CompanyTile(
          icon: Icons.location_on_outlined,
          label: 'العنوان',
          value: data.address,
          // العنوان الإنجليزي يخدم الزائر الأجنبي ولا يحتاج بطاقة مستقلة
          // The Latin address serves a non-Arabic visitor and needs no tile of its own.
          secondary: data.addressEn.isEmpty ? null : data.addressEn,
          actionIcon: Icons.map_outlined,
          onTap: () => ExternalLinks.openMap(context, data.address),
        ),
      if (data.website.isNotEmpty)
        _CompanyTile(
          icon: Icons.language_rounded,
          label: 'الموقع الإلكتروني',
          value: data.website,
          latin: true,
          actionIcon: Icons.open_in_new_rounded,
          onTap: () => ExternalLinks.openUrl(context, data.website),
        ),
      if (data.phone.isNotEmpty)
        _CompanyTile(
          icon: Icons.call_outlined,
          label: 'الهاتف',
          value: data.phone,
          latin: true,
          actionIcon: Icons.dialpad_rounded,
          onTap: () => ExternalLinks.openTel(context, data.phone),
        ),
    ];
  }

  /// عمودان على الشاشات المتوسطة والواسعة، وعمود واحد على الهاتف
  /// Two columns on medium and wide screens, one column on a phone.
  ///
  /// في وضع العمودين تُبنى صفوفاً صفوفاً داخل `IntrinsicHeight` كي يتساوى ارتفاع بطاقتي الصف
  /// الواحد: بطاقة العنوان تحمل سطراً إنجليزياً إضافياً، وبدون التساوي تبدو الشبكة مكسورة.
  /// In two-column mode the tiles are laid out row by row inside an `IntrinsicHeight` so both tiles
  /// of a row share one height: the address tile carries an extra Latin line, and without the
  /// equalisation the grid reads as broken.
  Widget _grid(BuildContext context, List<Widget> tiles) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        final twoColumns = constraints.maxWidth >= 460 && tiles.length > 1;

        if (!twoColumns) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < tiles.length; i++) ...[
                if (i > 0) const SizedBox(height: spacing),
                tiles[i],
              ],
            ],
          );
        }

        final rows = <Widget>[];

        for (var i = 0; i < tiles.length; i += 2) {
          final second = i + 1 < tiles.length ? tiles[i + 1] : null;

          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: tiles[i]),
                  if (second != null) ...[
                    const SizedBox(width: spacing),
                    Expanded(child: second),
                  ],
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const SizedBox(height: spacing),
              rows[i],
            ],
          ],
        );
      },
    );
  }
}

/// بطاقة بيان واحدة: أيقونة وتسمية في الأعلى، القيمة أسفلها، ورمز الإجراء إن كان السطر فعّالاً
/// A single detail tile: an icon and a label on top, the value beneath, and the action's glyph when
/// the tile is tappable.
class _CompanyTile extends StatelessWidget {
  const _CompanyTile({
    required this.icon,
    required this.label,
    required this.value,
    this.secondary,
    this.latin = false,
    this.actionIcon,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;

  /// سطر ثانٍ باهت (العنوان الإنجليزي مثلاً) — `null` يعني لا سطر ثانٍ
  /// A muted second line (the Latin address, say) — null means there is none.
  final String? secondary;

  /// القيمة لاتينية (رقم/رابط): تُعرض باتجاه LTR كي لا ينقلب ترتيبها
  /// The value is Latin (a number/link): rendered LTR so its order never flips.
  final bool latin;

  /// رمز الإجراء في طرف البطاقة (خريطة/رابط/اتصال)
  /// The action's glyph at the tile's trailing edge (map/link/call).
  final IconData? actionIcon;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final interactive = onTap != null;
    final accent = interactive ? AppColors.accent : AppColors.textMuted;
    final radius = BorderRadius.circular(12);

    return Material(
      color: AppColors.surfaceSubtle,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 15, color: accent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  if (actionIcon != null)
                    Icon(actionIcon, size: 14, color: accent),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                value,
                textDirection: latin ? TextDirection.ltr : null,
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  height: 1.45,
                  color: interactive ? AppColors.accent : AppColors.textPrimary,
                ),
              ),
              if (secondary != null) ...[
                const SizedBox(height: 3),
                Text(
                  secondary!,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontSize: 10.5,
                    height: 1.4,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// نبذة الخدمات — لوحة مصبوغة خفيفة تفصل «كلام الشركة عن نفسها» عن بياناتها الجامدة
/// The services brief — a lightly tinted panel that separates what the company says about itself
/// from its hard data.
class _ServicesPanel extends StatelessWidget {
  const _ServicesPanel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.checkroom_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 7),
              Text(
                'نبذة عن خدماتنا',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            text,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.75,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// حالة الفراغ: لم يُضبط أي حقل بعد — نقولها صراحة بدل بطاقة صامتة
/// The empty state: not a single field is set — said plainly instead of rendering a silent card.
class _CompanyEmptyState extends StatelessWidget {
  const _CompanyEmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Icon(Icons.info_outline_rounded, size: 26, color: AppColors.textMuted),
          const SizedBox(height: 8),
          Text(
            'لم تُضف بيانات الشركة بعد',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'يكملها المدير من شاشة إعدادات التطبيق.',
            style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
