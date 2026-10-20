import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/app_config/presentation/providers/app_config_notifier.dart';

/// شعار التطبيق الموحّد — يستخدم الملف المحلي إن وُجد، وإلا الأصل المضمّن
/// Unified app logo — uses the locally-saved logo file when present, otherwise the bundled asset.
///
/// يراقب `appConfigNotifierProvider` فينعكس أي تغيير شعار فوراً على كل الشاشات دون إعادة تشغيل
/// (الشعار محلي بحت، لا يحتاج مزامنة). عند تعذّر قراءة الملف المحلي (تالف/محذوف) يسقط بهدوء
/// إلى الأصل المضمّن بدل الانهيار.
/// Watches the app-config state so any logo change reflects instantly everywhere (a local asset,
/// no restart needed). If the local file cannot be read, it falls back to the bundled asset.
class AppLogo extends ConsumerWidget {
  const AppLogo({
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.borderRadius,
  });

  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  /// الأصل الافتراضي المضمّن — الشعار الوحيد (شعار الشركة = شعار التطبيق)
  /// The bundled default asset — the single logo (company logo == app logo).
  static const String defaultAsset = 'assets/logo3.jpg';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // نراقب مسار الشعار فقط — لا نبني السمة كاملة هنا
    // Watch only the logo path — we do not rebuild the whole theme here.
    final logoPath =
        ref.watch(appConfigNotifierProvider.select((s) => s.logoPath));

    final Widget image;
    if (logoPath != null && logoPath.isNotEmpty && File(logoPath).existsSync()) {
      image = Image.file(
        File(logoPath),
        width: width,
        height: height,
        fit: fit,
        // سقوط آمن إلى الأصل إن فشل فك ترميز الملف المحلي
        // Safe fallback to the asset if the local file fails to decode.
        errorBuilder: (context, error, stackTrace) => _assetImage(),
      );
    } else {
      image = _assetImage();
    }

    if (borderRadius == null) return image;
    return ClipRRect(borderRadius: borderRadius!, child: image);
  }

  Widget _assetImage() {
    return Image.asset(
      defaultAsset,
      width: width,
      height: height,
      fit: fit,
    );
  }
}
