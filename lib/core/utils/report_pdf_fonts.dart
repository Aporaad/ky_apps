import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Helper shared by all report PDF builders (account statement, group trial balance,
/// customer statement, worker statement).
///
/// خط Cairo يُحمَّل الآن من الأصول المضمّنة داخل التطبيق (`assets/fonts/*.ttf`) بدلاً من
/// تنزيله من خدمة خطوط جوجل وقت التشغيل. السابق كان يعتمد `PdfGoogleFonts.cairoRegular()`
/// الذي يجلب الخط من `fonts.gstatic.com` عبر الإنترنت؛ وعلى نشر التطبيق داخل شبكة LAN
/// بلا إنترنت (حالة هذا المشروع: اتصال بالواي‑فاي المحلي للوصول إلى API فقط) يفشل التنزيل،
/// فيسقط مولّد PDF إلى خط Helvetica الافتراضي الذي لا يحوي صور العربية الاتصالّية، فتظهر
/// كل النصوص العربية في الطباعة/التصدير على شكل رموز. التحميل من الأصل المحلّي يزيل هذا
/// الاعتماد كلياً ويجعل الإخراج ثابتاً، ويُستخدم خط الشاشة نفسه (Cairo) فيتطابق التشكيل.
///
/// Cairo is now loaded from bundled assets instead of being downloaded from Google at
/// runtime. The previous `PdfGoogleFonts` path needed internet; on the offline LAN
/// deployment it failed and the document silently fell back to Helvetica, which has no
/// Arabic presentation-form glyphs, so every Arabic string printed as symbols. Loading
/// the local TTF removes that dependency and matches the on-screen Cairo theme. The
/// network loader is kept only as a last-resort fallback (e.g. a mis-packaged build).
///
/// يُستخدم من كل مولّدات PDF — يحمّل خط Cairo مرة واحدة ويخزّنه.
class ReportPdfFonts {
  ReportPdfFonts._();

  /// مسار أصول خط Cairo المضمّنة. Bundled Cairo font asset paths.
  static const String _regularAsset = 'assets/fonts/Cairo-Regular.ttf';
  static const String _boldAsset = 'assets/fonts/Cairo-Bold.ttf';

  static Future<pw.Font>? _regular;
  static Future<pw.Font>? _bold;

  /// يقرأ الخط من الأصل المحلّي، ويسقط إلى تنزيل الشبكة فقط إذا تعذّرت قراءة الأصل.
  /// Loads the font from the bundled asset, falling back to the network only if the
  /// asset cannot be read (defensive; the asset is shipped in every build).
  static Future<pw.Font> _loadAsset(
    String asset,
    Future<pw.Font> Function() networkFallback,
  ) async {
    try {
      final data = await rootBundle.load(asset);
      return pw.Font.ttf(data);
    } catch (_) {
      return networkFallback();
    }
  }

  static Future<pw.Font> get regular => _regular ??=
      _loadAsset(_regularAsset, PdfGoogleFonts.cairoRegular);

  static Future<pw.Font> get bold => _bold ??=
      _loadAsset(_boldAsset, PdfGoogleFonts.cairoBold);

  /// يبني `pw.ThemeData` مع خط Cairo عادي وعريض — يُستخدم كـ `Document(theme: ...)`
  /// لضمان تشكيل العربية بشكل صحيح في كل التقارير بدون fallback لـ Helvetica.
  static Future<pw.ThemeData> theme() async {
    return pw.ThemeData.withFont(
      base: await regular,
      bold: await bold,
      italic: await regular,
      boldItalic: await bold,
    );
  }
}
